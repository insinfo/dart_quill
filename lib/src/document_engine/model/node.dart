import 'fragment.dart';
import 'mark.dart';
import 'schema.dart';
import 'replace.dart' hide replace;
import 'replace.dart' as replace_lib show replace;
import 'resolvedpos.dart';
import 'comparedeep.dart';
import 'content.dart';

const Map<String, dynamic> emptyAttrs = {};

/// This class represents a node in the tree that makes up a
/// ProseMirror document. So a document is an instance of `PMNode`, with
/// children that are also instances of `PMNode`.
class PMNode {
  /// The type of node that this is.
  final NodeType type;

  /// An object mapping attribute names to values.
  final Map<String, dynamic> attrs;

  /// A container holding the node's children.
  final Fragment content;

  /// The marks applied to this node.
  final List<Mark> marks;

  /// @internal
  PMNode(this.type, this.attrs, [Fragment? content, this.marks = Mark.none])
      : content = content ?? Fragment.empty;

  /// The array of this node's child nodes.
  List<PMNode> get children => content.content;

  /// For text nodes, this contains the node's text content.
  String? get text => null;

  /// The size of this node, as defined by the integer-based indexing scheme.
  int get nodeSize => isLeaf ? 1 : 2 + content.size;

  /// The number of children that the node has.
  int get childCount => content.childCount;

  /// Get the child node at the given index.
  PMNode child(int index) => content.child(index);

  /// Get the child node at the given index, if it exists.
  PMNode? maybeChild(int index) => content.maybeChild(index);

  /// Call `f` for every child node.
  void forEach(void Function(PMNode node, int offset, int index) f) {
    content.forEach(f);
  }

  /// Invoke a callback for all descendant nodes recursively.
  void nodesBetween(
      int from,
      int to,
      bool? Function(PMNode node, int pos, PMNode? parent, int index) f,
      [int startPos = 0]) {
    content.nodesBetween(from, to, f, startPos, this);
  }

  /// Call the given callback for every descendant node.
  void descendants(
      bool? Function(PMNode node, int pos, PMNode? parent, int index) f) {
    nodesBetween(0, content.size, f);
  }

  /// Concatenates all the text nodes found in this fragment and its children.
  String get textContent {
    if (isLeaf && type.spec.leafText != null) {
      return type.spec.leafText!(this) ?? "";
    }
    return textBetween(0, content.size, blockSeparator: "");
  }

  /// Get all text between positions `from` and `to`.
  String textBetween(int from, int to,
      {String? blockSeparator, String? Function(PMNode)? leafText}) {
    return content.textBetween(from, to,
        blockSeparator: blockSeparator, leafText: leafText);
  }

  /// Returns this node's first child.
  PMNode? get firstChild => content.firstChild;

  /// Returns this node's last child.
  PMNode? get lastChild => content.lastChild;

  /// Test whether two nodes represent the same piece of document.
  bool eq(PMNode other) {
    return identical(this, other) ||
        (sameMarkup(other) && content.eq(other.content));
  }

  /// Compare the markup (type, attributes, and marks) of this node to another.
  bool sameMarkup(PMNode other) {
    return hasMarkup(other.type, other.attrs, other.marks);
  }

  /// Check whether this node's markup correspond to the given type, attrs, and marks.
  bool hasMarkup(NodeType type,
      [Map<String, dynamic>? attrs, List<Mark>? marks]) {
    return this.type == type &&
        compareDeep(this.attrs, attrs ?? type.defaultAttrs) &&
        Mark.sameSet(this.marks, marks ?? Mark.none);
  }

  /// Create a new node with the same markup as this node, containing the given content.
  PMNode copy([Fragment? content]) {
    if (content == this.content) return this;
    return PMNode(type, attrs, content, marks);
  }

  /// Create a copy of this node, with the given set of marks.
  PMNode mark(List<Mark> marks) {
    if (marks == this.marks) return this;
    return PMNode(type, attrs, content, marks);
  }

  /// Create a copy of this node with only the content between the given positions.
  PMNode cut(int from, [int? to]) {
    to ??= content.size;
    if (from == 0 && to == content.size) return this;
    return copy(content.cut(from, to));
  }

  /// Cut out the part of the document between the given positions.
  Slice slice(int from, [int? to, bool includeParents = false]) {
    to ??= content.size;
    if (from == to) return Slice.empty;

    ResolvedPos $from = resolve(from);
    ResolvedPos $to = resolve(to);
    int depth = includeParents ? 0 : $from.sharedDepth(to);
    int start = $from.start(depth);
    PMNode node = $from.node(depth);
    Fragment sliceContent = node.content.cut($from.pos - start, $to.pos - start);
    return Slice(sliceContent, $from.depth - depth, $to.depth - depth);
  }

  /// Replace the part of the document between the given positions with the given slice.
  PMNode replace(int from, int to, Slice slice) {
    return replace_lib.replace(resolve(from), resolve(to), slice);
  }

  /// Find the node directly after the given position.
  PMNode? nodeAt(int pos) {
    PMNode? node = this;
    while (true) {
      IndexOffset io = node!.content.findIndex(pos);
      node = node.maybeChild(io.index);
      if (node == null) return null;
      if (io.offset == pos || node.isText) return node;
      pos -= io.offset + 1;
    }
  }

  /// Find the (direct) child node after the given offset.
  NodeIndexOffset childAfter(int pos) {
    IndexOffset io = content.findIndex(pos);
    return NodeIndexOffset(content.maybeChild(io.index), io.index, io.offset);
  }

  /// Find the (direct) child node before the given offset.
  NodeIndexOffset childBefore(int pos) {
    if (pos == 0) return NodeIndexOffset(null, 0, 0);
    IndexOffset io = content.findIndex(pos);
    if (io.offset < pos) {
      return NodeIndexOffset(content.child(io.index), io.index, io.offset);
    }
    PMNode node = content.child(io.index - 1);
    return NodeIndexOffset(
        node, io.index - 1, io.offset - node.nodeSize);
  }

  /// Resolve the given position in the document.
  ResolvedPos resolve(int pos) {
    return ResolvedPos.resolveCached(this, pos);
  }

  /// @internal
  ResolvedPos resolveNoCache(int pos) {
    return ResolvedPos.resolve(this, pos);
  }

  /// Test whether a given mark or mark type occurs in this document between two positions.
  bool rangeHasMark(int from, int to, dynamic markOrType) {
    bool found = false;
    if (to > from) {
      nodesBetween(from, to, (node, pos, parent, index) {
        if (markOrType is MarkType) {
          if (markOrType.isInSet(node.marks) != null) found = true;
        } else if (markOrType is Mark) {
          if (markOrType.isInSet(node.marks)) found = true;
        }
        return !found;
      });
    }
    return found;
  }

  /// True when this is a block (non-inline node).
  bool get isBlock => type.isBlock;

  /// True when this is a textblock node.
  bool get isTextblock => type.isTextblock;

  /// True when this node allows inline content.
  bool get inlineContent => type.inlineContent;

  /// True when this is an inline node.
  bool get isInline => type.isInline;

  /// True when this is a text node.
  bool get isText => type.isText;

  /// True when this is a leaf node.
  bool get isLeaf => type.isLeaf;

  /// True when this is an atom.
  bool get isAtom => type.isAtom;

  /// Return a string representation of this node for debugging purposes.
  @override
  String toString() {
    if (type.spec.toDebugString != null) {
      return type.spec.toDebugString!(this) ?? "";
    }
    String name = type.name;
    if (content.size > 0) {
      name += "(${content.toStringInner()})";
    }
    return _wrapMarks(marks, name);
  }

  /// Get the content match in this node at the given index.
  ContentMatch contentMatchAt(int index) {
    ContentMatch? match = type.contentMatch.matchFragment(content, 0, index);
    if (match == null) {
      throw StateError("Called contentMatchAt on a node with invalid content");
    }
    return match;
  }

  /// Test whether replacing the range between `from` and `to` would leave the node's content valid.
  bool canReplace(int from, int to,
      [Fragment? replacement, int start = 0, int? end]) {
    replacement ??= Fragment.empty;
    end ??= replacement.childCount;
    ContentMatch? one =
        contentMatchAt(from).matchFragment(replacement, start, end);
    ContentMatch? two = one?.matchFragment(content, to);
    if (two == null || !two.validEnd) return false;
    for (int i = start; i < end; i++) {
      if (!type.allowsMarks(replacement.child(i).marks)) return false;
    }
    return true;
  }

  /// Test whether replacing the range `from` to `to` with a node of the given type would leave it valid.
  bool canReplaceWith(int from, int to, NodeType type, [List<Mark>? marks]) {
    if (marks != null && !this.type.allowsMarks(marks)) return false;
    ContentMatch? start = contentMatchAt(from).matchType(type);
    ContentMatch? end = start?.matchFragment(content, to);
    return end != null ? end.validEnd : false;
  }

  /// Test whether the given node's content could be appended to this node.
  bool canAppend(PMNode other) {
    if (other.content.size > 0) {
      return canReplace(childCount, childCount, other.content);
    } else {
      return type.compatibleContent(other.type);
    }
  }

  /// Check whether this node and its descendants conform to the schema.
  void check() {
    type.checkContent(content);
    type.checkAttrs(attrs);
    List<Mark> copy = Mark.none;
    for (int i = 0; i < marks.length; i++) {
      Mark mark = marks[i];
      mark.type.checkAttrs(mark.attrs);
      copy = mark.addToSet(copy);
    }
    if (!Mark.sameSet(copy, marks)) {
      throw RangeError(
          "Invalid collection of marks for node ${type.name}: ${marks.map((m) => m.type.name)}");
    }
    content.forEach((node, offset, index) => node.check());
  }

  /// Return a JSON-serializeable representation of this node.
  dynamic toJSON() {
    Map<String, dynamic> obj = {'type': type.name};
    if (attrs.isNotEmpty) {
      obj['attrs'] = attrs;
    }
    if (content.size > 0) {
      obj['content'] = content.toJSON();
    }
    if (marks.isNotEmpty) {
      obj['marks'] = marks.map((m) => m.toJSON()).toList();
    }
    return obj;
  }

  /// Deserialize a node from its JSON representation.
  static PMNode fromJSON(Schema schema, dynamic json) {
    if (json == null) throw RangeError("Invalid input for Node.fromJSON");
    List<Mark>? marks;
    if (json['marks'] != null) {
      if (json['marks'] is! List) {
        throw RangeError("Invalid mark data for Node.fromJSON");
      }
      marks = (json['marks'] as List).map((m) => schema.markFromJSON(m)).toList();
    }
    if (json['type'] == "text") {
      if (json['text'] is! String) {
        throw RangeError("Invalid text node in JSON");
      }
      return schema.text(json['text'], marks);
    }
    Fragment content = Fragment.fromJSON(schema, json['content']);
    PMNode node =
        schema.nodeType(json['type']).create(json['attrs'], content, marks);
    node.type.checkAttrs(node.attrs);
    return node;
  }
}

class TextNode extends PMNode {
  @override
  final String text;

  /// @internal
  TextNode(NodeType type, Map<String, dynamic> attrs, this.text,
      [List<Mark>? marks])
      : super(type, attrs, null, marks ?? Mark.none) {
    if (text.isEmpty) {
      throw RangeError("Empty text nodes are not allowed");
    }
  }

  @override
  String toString() {
    if (type.spec.toDebugString != null) {
      return type.spec.toDebugString!(this) ?? "";
    }
    return _wrapMarks(marks, '"$text"');
  }

  @override
  String get textContent => text;

  @override
  String textBetween(int from, int to,
      {String? blockSeparator, String? Function(PMNode)? leafText}) {
    return text.substring(from, to);
  }

  @override
  int get nodeSize => text.length;

  @override
  TextNode mark(List<Mark> marks) {
    if (marks == this.marks) return this;
    return TextNode(type, attrs, text, marks);
  }

  TextNode withText(String text) {
    if (text == this.text) return this;
    return TextNode(type, attrs, text, marks);
  }

  @override
  TextNode cut(int from, [int? to]) {
    to ??= text.length;
    if (from == 0 && to == text.length) return this;
    return withText(text.substring(from, to));
  }

  @override
  bool eq(PMNode other) {
    return sameMarkup(other) && other is TextNode && text == other.text;
  }

  @override
  dynamic toJSON() {
    var base = super.toJSON();
    base['text'] = text;
    return base;
  }
}

String _wrapMarks(List<Mark> marks, String str) {
  for (int i = marks.length - 1; i >= 0; i--) {
    str = "${marks[i].type.name}($str)";
  }
  return str;
}

class NodeIndexOffset {
  final PMNode? node;
  final int index;
  final int offset;

  NodeIndexOffset(this.node, this.index, this.offset);
}
