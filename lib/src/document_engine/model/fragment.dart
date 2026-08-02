import 'dart:math';

import 'node.dart';
import 'schema.dart';
import 'diff.dart';

/// A fragment represents a node's collection of child nodes.
///
/// Like nodes, fragments are persistent data structures, and you
/// should not mutate them or their content. Rather, you create new
/// instances whenever needed. The API tries to make this easy.
class Fragment {
  /// The size of the fragment, which is the total of the size of
  /// its content nodes.
  final int size;

  /// The child nodes in this fragment.
  final List<PMNode> content;

  /// @internal
  Fragment(this.content, [int? size])
      : size = size ?? content.fold(0, (sum, n) => sum + n.nodeSize);

  /// Invoke a callback for all descendant nodes between the given two
  /// positions (relative to start of this fragment). Doesn't descend
  /// into a node when the callback returns `false`.
  void nodesBetween(
      int from,
      int to,
      bool? Function(PMNode node, int start, PMNode? parent, int index) f,
      [int nodeStart = 0,
      PMNode? parent]) {
    for (int i = 0, pos = 0; pos < to; i++) {
      PMNode child = content[i];
      int end = pos + child.nodeSize;
      if (end > from &&
          f(child, nodeStart + pos, parent, i) != false &&
          child.content.size > 0) {
        int start = pos + 1;
        child.nodesBetween(
            max(0, from - start),
            min(child.content.size, to - start),
            f,
            nodeStart + start);
      }
      pos = end;
    }
  }

  /// Call the given callback for every descendant node. `pos` will be
  /// relative to the start of the fragment. The callback may return
  /// `false` to prevent traversal of a given node's children.
  void descendants(bool? Function(PMNode node, int pos, PMNode? parent, int index) f) {
    nodesBetween(0, size, f);
  }

  /// Extract the text between `from` and `to`.
  String textBetween(int from, int to,
      {String? blockSeparator, String? Function(PMNode)? leafText}) {
    String text = "";
    bool first = true;
    nodesBetween(from, to, (node, pos, parent, index) {
      String nodeText = node.isText
          ? node.text!.substring(max(from, pos) - pos, min(to, pos + node.text!.length) - pos)
          : !node.isLeaf
              ? ""
              : leafText != null
                  ? leafText(node) ?? ""
                  : node.type.spec.leafText != null
                      ? (node.type.spec.leafText!(node) ?? "")
                      : "";
      if (node.isBlock &&
          (node.isLeaf && nodeText.isNotEmpty || node.isTextblock) &&
          blockSeparator != null) {
        if (first) {
          first = false;
        } else {
          text += blockSeparator;
        }
      }
      text += nodeText;
      return null;
    }, 0);
    return text;
  }

  /// Create a new fragment containing the combined content of this
  /// fragment and the other.
  Fragment append(Fragment other) {
    if (other.size == 0) return this;
    if (size == 0) return other;
    PMNode last = lastChild!;
    PMNode first = other.firstChild!;
    List<PMNode> newContent = List.of(content);
    int i = 0;
    if (last.isText && last.sameMarkup(first)) {
      newContent[newContent.length - 1] =
          (last as TextNode).withText(last.text + (first as TextNode).text);
      i = 1;
    }
    for (; i < other.content.length; i++) {
      newContent.add(other.content[i]);
    }
    return Fragment(newContent, size + other.size);
  }

  /// Cut out the sub-fragment between the two given positions.
  Fragment cut(int from, [int? to]) {
    to ??= size;
    if (from == 0 && to == size) return this;
    List<PMNode> result = [];
    int newSize = 0;
    if (to > from) {
      for (int i = 0, pos = 0; pos < to; i++) {
        PMNode child = content[i];
        int end = pos + child.nodeSize;
        if (end > from) {
          if (pos < from || end > to) {
            if (child.isText) {
              child = child.cut(
                  max(0, from - pos), min(child.text!.length, to - pos));
            } else {
              child = child.cut(max(0, from - pos - 1),
                  min(child.content.size, to - pos - 1));
            }
          }
          result.add(child);
          newSize += child.nodeSize;
        }
        pos = end;
      }
    }
    return Fragment(result, newSize);
  }

  /// @internal
  Fragment cutByIndex(int from, int to) {
    if (from == to) return Fragment.empty;
    if (from == 0 && to == content.length) return this;
    return Fragment(content.sublist(from, to));
  }

  /// Create a new fragment in which the node at the given index is
  /// replaced by the given node.
  Fragment replaceChild(int index, PMNode node) {
    PMNode current = content[index];
    if (current == node) return this;
    List<PMNode> copy = List.of(content);
    int newSize = size + node.nodeSize - current.nodeSize;
    copy[index] = node;
    return Fragment(copy, newSize);
  }

  /// Create a new fragment by prepending the given node to this
  /// fragment.
  Fragment addToStart(PMNode node) {
    return Fragment([node, ...content], size + node.nodeSize);
  }

  /// Create a new fragment by appending the given node to this
  /// fragment.
  Fragment addToEnd(PMNode node) {
    return Fragment([...content, node], size + node.nodeSize);
  }

  /// Compare this fragment to another one.
  bool eq(Fragment other) {
    if (content.length != other.content.length) return false;
    for (int i = 0; i < content.length; i++) {
      if (!content[i].eq(other.content[i])) return false;
    }
    return true;
  }

  /// The first child of the fragment, or `null` if it is empty.
  PMNode? get firstChild => content.isNotEmpty ? content.first : null;

  /// The last child of the fragment, or `null` if it is empty.
  PMNode? get lastChild => content.isNotEmpty ? content.last : null;

  /// The number of child nodes in this fragment.
  int get childCount => content.length;

  /// Get the child node at the given index. Raise an error when the
  /// index is out of range.
  PMNode child(int index) {
    if (index < 0 || index >= content.length) {
      throw RangeError("Index $index out of range for $this");
    }
    return content[index];
  }

  /// Get the child node at the given index, if it exists.
  PMNode? maybeChild(int index) {
    if (index < 0 || index >= content.length) return null;
    return content[index];
  }

  /// Call `f` for every child node, passing the node, its offset
  /// into this parent node, and its index.
  void forEach(void Function(PMNode node, int offset, int index) f) {
    for (int i = 0, p = 0; i < content.length; i++) {
      PMNode childNode = content[i];
      f(childNode, p, i);
      p += childNode.nodeSize;
    }
  }

  /// Find the first position at which this fragment and another
  /// fragment differ, or `null` if they are the same.
  int? findDiffStart(Fragment other, [int pos = 0]) {
    return Diff.findDiffStart(this, other, pos);
  }

  /// Find the first position, searching from the end, at which this
  /// fragment and the given fragment differ, or `null` if they are
  /// the same. Since this position will not be the same in both
  /// nodes, an object with two separate positions is returned.
  DiffEndResult? findDiffEnd(Fragment other, [int? pos, int? otherPos]) {
    return Diff.findDiffEnd(this, other, pos ?? size, otherPos ?? other.size);
  }

  /// Find the index and inner offset corresponding to a given relative
  /// position in this fragment.
  IndexOffset findIndex(int pos) {
    if (pos == 0) return IndexOffset(0, pos);
    if (pos == size) return IndexOffset(content.length, pos);
    if (pos > size || pos < 0) {
      throw RangeError("Position $pos outside of fragment ($this)");
    }
    for (int i = 0, curPos = 0;; i++) {
      PMNode current = child(i);
      int end = curPos + current.nodeSize;
      if (end >= pos) {
        if (end == pos) return IndexOffset(i + 1, end);
        return IndexOffset(i, curPos);
      }
      curPos = end;
    }
  }

  /// Return a debugging string that describes this fragment.
  @override
  String toString() => "<${toStringInner()}>";

  /// @internal
  String toStringInner() => content.map((e) => e.toString()).join(", ");

  /// Create a JSON-serializeable representation of this fragment.
  dynamic toJSON() {
    return content.isNotEmpty ? content.map((n) => n.toJSON()).toList() : null;
  }

  /// Deserialize a fragment from its JSON representation.
  static Fragment fromJSON(Schema schema, dynamic value) {
    if (value == null) return Fragment.empty;
    if (value is! List) throw RangeError("Invalid input for Fragment.fromJSON");
    return Fragment.fromArray(value.map((e) => schema.nodeFromJSON(e)).toList());
  }

  /// Build a fragment from an array of nodes. Ensures that adjacent
  /// text nodes with the same marks are joined together.
  static Fragment fromArray(List<PMNode> array) {
    if (array.isEmpty) return Fragment.empty;
    List<PMNode>? joined;
    int size = 0;
    for (int i = 0; i < array.length; i++) {
      PMNode node = array[i];
      size += node.nodeSize;
      if (i > 0 && node.isText && array[i - 1].sameMarkup(node)) {
        joined ??= array.sublist(0, i);
        joined[joined.length - 1] = (joined.last as TextNode).withText(
            (joined.last as TextNode).text + (node as TextNode).text);
      } else if (joined != null) {
        joined.add(node);
      }
    }
    return Fragment(joined ?? array, size);
  }

  /// Create a fragment from something that can be interpreted as a
  /// set of nodes.
  static Fragment from(dynamic nodes) {
    if (nodes == null) return Fragment.empty;
    if (nodes is Fragment) return nodes;
    if (nodes is List<PMNode>) return fromArray(nodes);
    if (nodes is PMNode) return Fragment([nodes], nodes.nodeSize);
    throw RangeError("Can not convert $nodes to a Fragment");
  }

  /// An empty fragment.
  static final Fragment empty = Fragment([], 0);
}

class IndexOffset {
  final int index;
  final int offset;
  IndexOffset(this.index, this.offset);
}
