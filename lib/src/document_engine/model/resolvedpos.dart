import 'node.dart';
import 'mark.dart';
import 'fragment.dart';

/// You can `resolve` a position to get more
/// information about it. Objects of this class represent such a
/// resolved position, providing various pieces of context
/// information, and some helper methods.
class ResolvedPos {
  final int pos;
  final List<dynamic> path;
  final int parentOffset;
  late final int depth;

  /// @internal
  ResolvedPos(this.pos, this.path, this.parentOffset) {
    depth = (path.length ~/ 3) - 1;
  }

  /// @internal
  int resolveDepth([int? val]) {
    if (val == null) return depth;
    if (val < 0) return depth + val;
    return val;
  }

  /// The parent node that the position points into.
  PMNode get parent => node(depth);

  /// The root node in which the position was resolved.
  PMNode get doc => node(0);

  /// The ancestor node at the given level.
  PMNode node([int? d]) {
    return path[resolveDepth(d) * 3] as PMNode;
  }

  /// The index into the ancestor at the given level.
  int index([int? d]) {
    return path[resolveDepth(d) * 3 + 1] as int;
  }

  /// The index pointing after this position into the ancestor at the given level.
  int indexAfter([int? d]) {
    int rDepth = resolveDepth(d);
    return index(rDepth) + (rDepth == depth && textOffset == 0 ? 0 : 1);
  }

  /// The (absolute) position at the start of the node at the given level.
  int start([int? d]) {
    int rDepth = resolveDepth(d);
    return rDepth == 0 ? 0 : (path[rDepth * 3 - 1] as int) + 1;
  }

  /// The (absolute) position at the end of the node at the given level.
  int end([int? d]) {
    int rDepth = resolveDepth(d);
    return start(rDepth) + node(rDepth).content.size;
  }

  /// The (absolute) position directly before the wrapping node at the given level.
  int before([int? d]) {
    int rDepth = resolveDepth(d);
    if (rDepth == 0) throw RangeError("There is no position before the top-level node");
    return rDepth == depth + 1 ? pos : path[rDepth * 3 - 1] as int;
  }

  /// The (absolute) position directly after the wrapping node at the given level.
  int after([int? d]) {
    int rDepth = resolveDepth(d);
    if (rDepth == 0) throw RangeError("There is no position after the top-level node");
    return rDepth == depth + 1 ? pos : (path[rDepth * 3 - 1] as int) + node(rDepth).nodeSize;
  }

  /// When this position points into a text node, this returns the distance between the position and the start of the text node.
  int get textOffset => pos - (path.last as int);

  /// Get the node directly after the position, if any.
  PMNode? get nodeAfter {
    PMNode p = parent;
    int idx = index(depth);
    if (idx == p.childCount) return null;
    int dOff = pos - (path.last as int);
    PMNode child = p.child(idx);
    return dOff > 0 ? child.cut(dOff) : child;
  }

  /// Get the node directly before the position, if any.
  PMNode? get nodeBefore {
    int idx = index(depth);
    int dOff = pos - (path.last as int);
    if (dOff > 0) return parent.child(idx).cut(0, dOff);
    return idx == 0 ? null : parent.child(idx - 1);
  }

  /// Get the position at the given index in the parent node at the given depth.
  int posAtIndex(int index, [int? d]) {
    int rDepth = resolveDepth(d);
    PMNode n = path[rDepth * 3] as PMNode;
    int p = rDepth == 0 ? 0 : (path[rDepth * 3 - 1] as int) + 1;
    for (int i = 0; i < index; i++) p += n.child(i).nodeSize;
    return p;
  }

  /// Get the marks at this position.
  List<Mark> marks() {
    PMNode p = parent;
    int idx = index();
    if (p.content.size == 0) return Mark.none;
    if (textOffset > 0) return p.child(idx).marks;

    PMNode? main = p.maybeChild(idx - 1);
    PMNode? other = p.maybeChild(idx);
    if (main == null) {
      PMNode? tmp = main;
      main = other;
      other = tmp;
    }

    List<Mark> marks = main!.marks;
    for (int i = 0; i < marks.length; i++) {
      if (marks[i].type.spec.inclusive == false &&
          (other == null || !marks[i].isInSet(other.marks))) {
        marks = marks[i].removeFromSet(marks);
        i--;
      }
    }
    return marks;
  }

  /// Get the marks after the current position, if any, except those that are non-inclusive.
  List<Mark>? marksAcross(ResolvedPos endPos) {
    PMNode? afterNode = parent.maybeChild(index());
    if (afterNode == null || !afterNode.isInline) return null;

    List<Mark> m = afterNode.marks;
    PMNode? next = endPos.parent.maybeChild(endPos.index());
    for (int i = 0; i < m.length; i++) {
      if (m[i].type.spec.inclusive == false &&
          (next == null || !m[i].isInSet(next.marks))) {
        m = m[i].removeFromSet(m);
        i--;
      }
    }
    return m;
  }

  /// The depth up to which this position and the given position share the same parent nodes.
  int sharedDepth(int otherPos) {
    for (int d = depth; d > 0; d--) {
      if (start(d) <= otherPos && end(d) >= otherPos) return d;
    }
    return 0;
  }

  /// Returns a range based on the place where this position and the given position diverge.
  NodeRange? blockRange([ResolvedPos? other, bool Function(PMNode node)? pred]) {
    other ??= this;
    if (other.pos < pos) return other.blockRange(this);
    for (int d = depth - (parent.inlineContent || pos == other.pos ? 1 : 0); d >= 0; d--) {
      if (other.pos <= end(d) && (pred == null || pred(node(d)))) {
        return NodeRange(this, other, d);
      }
    }
    return null;
  }

  /// Query whether the given position shares the same parent node.
  bool sameParent(ResolvedPos other) {
    return pos - parentOffset == other.pos - other.parentOffset;
  }

  /// Return the greater of this and the given position.
  ResolvedPos max(ResolvedPos other) {
    return other.pos > pos ? other : this;
  }

  /// Return the smaller of this and the given position.
  ResolvedPos min(ResolvedPos other) {
    return other.pos < pos ? other : this;
  }

  @override
  String toString() {
    String str = "";
    for (int i = 1; i <= depth; i++) {
      str += (str.isNotEmpty ? "/" : "") + "${node(i).type.name}_${index(i - 1)}";
    }
    return "$str:$parentOffset";
  }

  static ResolvedPos resolve(PMNode doc, int pos) {
    if (!(pos >= 0 && pos <= doc.content.size)) {
      throw RangeError("Position $pos out of range");
    }
    List<dynamic> path = [];
    int start = 0, parentOffset = pos;
    PMNode currentNode = doc;
    while (true) {
      IndexOffset io = currentNode.content.findIndex(parentOffset);
      int rem = parentOffset - io.offset;
      path.add(currentNode);
      path.add(io.index);
      path.add(start + io.offset);
      if (rem == 0) break;
      currentNode = currentNode.child(io.index);
      if (currentNode.isText) break;
      parentOffset = rem - 1;
      start += io.offset + 1;
    }
    return ResolvedPos(pos, path, parentOffset);
  }

  static ResolvedPos resolveCached(PMNode doc, int pos) {
    ResolveCache cache = _resolveCache[doc] ??= ResolveCache();
    for (int i = 0; i < cache.elts.length; i++) {
      ResolvedPos elt = cache.elts[i];
      if (elt.pos == pos) return elt;
    }
    ResolvedPos result = ResolvedPos.resolve(doc, pos);
    if (cache.elts.length < 12) {
      cache.elts.add(result);
    } else {
      cache.elts[cache.i] = result;
    }
    cache.i = (cache.i + 1) % 12;
    return result;
  }
}

class ResolveCache {
  List<ResolvedPos> elts = [];
  int i = 0;
}

final Expando<ResolveCache> _resolveCache = Expando<ResolveCache>();

/// Represents a flat range of content, i.e. one that starts and ends in the same node.
class NodeRange {
  final ResolvedPos $from;
  final ResolvedPos $to;
  final int depth;

  NodeRange(this.$from, this.$to, this.depth);

  int get start => $from.before(depth + 1);
  int get end => $to.after(depth + 1);

  PMNode get parent => $from.node(depth);
  int get startIndex => $from.index(depth);
  int get endIndex => $to.indexAfter(depth);
}
