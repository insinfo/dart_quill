import 'fragment.dart';
import 'schema.dart';
import 'node.dart';
import 'resolvedpos.dart';

class ReplaceError extends Error {
  final String message;
  ReplaceError(this.message);

  @override
  String toString() => "ReplaceError: $message";
}

/// A slice represents a piece cut out of a larger document.
class Slice {
  final Fragment content;
  final int openStart;
  final int openEnd;

  Slice(this.content, this.openStart, this.openEnd);

  int get size => content.size - openStart - openEnd;

  /// @internal
  Slice? insertAt(int pos, Fragment fragment) {
    Fragment? newContent = _insertInto(content, pos + openStart, fragment, openStart + 1, openEnd + 1);
    return newContent != null ? Slice(newContent, openStart, openEnd) : null;
  }

  /// @internal
  Slice removeBetween(int from, int to) {
    return Slice(_removeRange(content, from + openStart, to + openStart), openStart, openEnd);
  }

  bool eq(Slice other) {
    return content.eq(other.content) && openStart == other.openStart && openEnd == other.openEnd;
  }

  @override
  String toString() => "$content($openStart,$openEnd)";

  dynamic toJSON() {
    if (content.size == 0) return null;
    Map<String, dynamic> json = {'content': content.toJSON()};
    if (openStart > 0) json['openStart'] = openStart;
    if (openEnd > 0) json['openEnd'] = openEnd;
    return json;
  }

  static Slice fromJSON(Schema schema, dynamic json) {
    if (json == null) return empty;
    dynamic openStart = json['openStart'] ?? 0;
    dynamic openEnd = json['openEnd'] ?? 0;
    if (openStart is! int || openEnd is! int) {
      throw RangeError("Invalid input for Slice.fromJSON");
    }
    return Slice(Fragment.fromJSON(schema, json['content']), openStart, openEnd);
  }

  static Slice maxOpen(Fragment fragment, [bool openIsolating = true]) {
    int openStart = 0, openEnd = 0;
    for (PMNode? n = fragment.firstChild; n != null && !n.isLeaf && (openIsolating || n.type.spec.isolating != true); n = n.firstChild) {
      openStart++;
    }
    for (PMNode? n = fragment.lastChild; n != null && !n.isLeaf && (openIsolating || n.type.spec.isolating != true); n = n.lastChild) {
      openEnd++;
    }
    return Slice(fragment, openStart, openEnd);
  }

  static final Slice empty = Slice(Fragment.empty, 0, 0);
}

Fragment _removeRange(Fragment content, int from, int to) {
  IndexOffset fromIo = content.findIndex(from);
  PMNode? child = content.maybeChild(fromIo.index);
  IndexOffset toIo = content.findIndex(to);

  if (fromIo.offset == from || child!.isText) {
    if (toIo.offset != to && !content.child(toIo.index).isText) {
      throw RangeError("Removing non-flat range");
    }
    return content.cut(0, from).append(content.cut(to));
  }
  if (fromIo.index != toIo.index) {
    throw RangeError("Removing non-flat range");
  }
  return content.replaceChild(
      fromIo.index,
      child.copy(_removeRange(
          child.content, from - fromIo.offset - 1, to - fromIo.offset - 1)));
}

Fragment? _insertInto(Fragment content, int dist, Fragment insert, int openStart, int openEnd, [PMNode? parent]) {
  IndexOffset io = content.findIndex(dist);
  PMNode? child = content.maybeChild(io.index);
  if (io.offset == dist || child!.isText) {
    if (parent != null && openStart <= 0 && openEnd <= 0 && !parent.canReplace(io.index, io.index, insert)) {
      return null;
    }
    return content.cut(0, dist).append(insert).append(content.cut(dist));
  }
  Fragment? inner = _insertInto(child.content, dist - io.offset - 1, insert,
      io.index == 0 ? openStart - 1 : 0,
      io.index == content.childCount - 1 ? openEnd - 1 : 0, child);
  return inner != null ? content.replaceChild(io.index, child.copy(inner)) : null;
}

PMNode replace(ResolvedPos $from, ResolvedPos $to, Slice slice) {
  if (slice.openStart > $from.depth) {
    throw ReplaceError("Inserted content deeper than insertion position");
  }
  if ($from.depth - slice.openStart != $to.depth - slice.openEnd) {
    throw ReplaceError("Inconsistent open depths");
  }
  return _replaceOuter($from, $to, slice, 0);
}

PMNode _replaceOuter(ResolvedPos $from, ResolvedPos $to, Slice slice, int depth) {
  int index = $from.index(depth);
  PMNode node = $from.node(depth);

  if (index == $to.index(depth) && depth < $from.depth - slice.openStart) {
    PMNode inner = _replaceOuter($from, $to, slice, depth + 1);
    return node.copy(node.content.replaceChild(index, inner));
  } else if (slice.content.size == 0) {
    return _close(node, _replaceTwoWay($from, $to, depth));
  } else if (slice.openStart == 0 && slice.openEnd == 0 && $from.depth == depth && $to.depth == depth) {
    PMNode parent = $from.parent;
    Fragment content = parent.content;
    return _close(parent, content.cut(0, $from.parentOffset).append(slice.content).append(content.cut($to.parentOffset)));
  } else {
    _PreparedSlice p = _prepareSliceForReplace(slice, $from);
    return _close(node, _replaceThreeWay($from, p.start, p.end, $to, depth));
  }
}

void _checkJoin(PMNode main, PMNode sub) {
  if (!sub.type.compatibleContent(main.type)) {
    throw ReplaceError("Cannot join ${sub.type.name} onto ${main.type.name}");
  }
}

PMNode _joinable(ResolvedPos $before, ResolvedPos $after, int depth) {
  PMNode node = $before.node(depth);
  _checkJoin(node, $after.node(depth));
  return node;
}

void _addNode(PMNode child, List<PMNode> target) {
  int last = target.length - 1;
  if (last >= 0 && child.isText && child.sameMarkup(target[last])) {
    target[last] = (target[last] as TextNode).withText((target[last] as TextNode).text + (child as TextNode).text);
  } else {
    target.add(child);
  }
}

void _addRange(ResolvedPos? $start, ResolvedPos? $end, int depth, List<PMNode> target) {
  PMNode node = ($end ?? $start)!.node(depth);
  int startIndex = 0;
  int endIndex = $end != null ? $end.index(depth) : node.childCount;
  if ($start != null) {
    startIndex = $start.index(depth);
    if ($start.depth > depth) {
      startIndex++;
    } else if ($start.textOffset > 0) {
      _addNode($start.nodeAfter!, target);
      startIndex++;
    }
  }
  for (int i = startIndex; i < endIndex; i++) {
    _addNode(node.child(i), target);
  }
  if ($end != null && $end.depth == depth && $end.textOffset > 0) {
    _addNode($end.nodeBefore!, target);
  }
}

PMNode _close(PMNode node, Fragment content) {
  if (!node.type.validContent(content)) {
    throw ReplaceError("Invalid content for node ${node.type.name}");
  }
  return node.copy(content);
}

Fragment _replaceThreeWay(ResolvedPos $from, ResolvedPos $start, ResolvedPos $end, ResolvedPos $to, int depth) {
  PMNode? openStart = $from.depth > depth ? _joinable($from, $start, depth + 1) : null;
  PMNode? openEnd = $to.depth > depth ? _joinable($end, $to, depth + 1) : null;

  List<PMNode> content = [];
  _addRange(null, $from, depth, content);

  if (openStart != null && openEnd != null && $start.index(depth) == $end.index(depth)) {
    _checkJoin(openStart, openEnd);
    _addNode(_close(openStart, _replaceThreeWay($from, $start, $end, $to, depth + 1)), content);
  } else {
    if (openStart != null) {
      _addNode(_close(openStart, _replaceTwoWay($from, $start, depth + 1)), content);
    }
    _addRange($start, $end, depth, content);
    if (openEnd != null) {
      _addNode(_close(openEnd, _replaceTwoWay($end, $to, depth + 1)), content);
    }
  }
  _addRange($to, null, depth, content);
  return Fragment(content);
}

Fragment _replaceTwoWay(ResolvedPos $from, ResolvedPos $to, int depth) {
  List<PMNode> content = [];
  _addRange(null, $from, depth, content);
  if ($from.depth > depth) {
    PMNode type = _joinable($from, $to, depth + 1);
    _addNode(_close(type, _replaceTwoWay($from, $to, depth + 1)), content);
  }
  _addRange($to, null, depth, content);
  return Fragment(content);
}

_PreparedSlice _prepareSliceForReplace(Slice slice, ResolvedPos $along) {
  int extra = $along.depth - slice.openStart;
  PMNode parent = $along.node(extra);
  PMNode node = parent.copy(slice.content);
  for (int i = extra - 1; i >= 0; i--) {
    node = $along.node(i).copy(Fragment.from(node));
  }
  return _PreparedSlice(
      node.resolveNoCache(slice.openStart + extra),
      node.resolveNoCache(node.content.size - slice.openEnd - extra));
}

class _PreparedSlice {
  final ResolvedPos start;
  final ResolvedPos end;
  _PreparedSlice(this.start, this.end);
}
