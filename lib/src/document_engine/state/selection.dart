import '../model/index.dart';
import '../transform/index.dart';
import 'transaction.dart';

class SelectionRange {
  final ResolvedPos fromRes;
  final ResolvedPos toRes;

  SelectionRange(this.fromRes, this.toRes);
}

abstract class SelectionBookmark {
  SelectionBookmark map(Mapping mapping);
  Selection resolve(PMNode doc);
}

typedef SelectionFromJSON = Selection Function(PMNode doc, Map<String, dynamic> json);

abstract class Selection {
  final ResolvedPos anchorRes;
  final ResolvedPos headRes;
  final List<SelectionRange> ranges;

  Selection(this.anchorRes, this.headRes, [List<SelectionRange>? ranges])
      : ranges = ranges ?? [SelectionRange(anchorRes.min(headRes), anchorRes.max(headRes))];

  int get anchor => anchorRes.pos;
  int get head => headRes.pos;
  int get from => fromRes.pos;
  int get to => toRes.pos;
  ResolvedPos get fromRes => ranges[0].fromRes;
  ResolvedPos get toRes => ranges[0].toRes;
  ResolvedPos get $from => fromRes;
  ResolvedPos get $to => toRes;


  bool get empty {
    for (int i = 0; i < ranges.length; i++) {
      if (ranges[i].fromRes.pos != ranges[i].toRes.pos) return false;
    }
    return true;
  }

  bool eq(Selection selection);
  Selection map(PMNode doc, Mapping mapping);

  Slice content() {
    return fromRes.doc.slice(from, to, true);
  }

  void replace(Transaction tr, [Slice? content]) {
    content ??= Slice.empty;
    PMNode? lastNode = content.content.lastChild;
    PMNode? lastParent;
    for (int i = 0; i < content.openEnd; i++) {
      lastParent = lastNode;
      lastNode = lastNode?.lastChild;
    }

    int mapFrom = tr.steps.length;
    for (int i = 0; i < ranges.length; i++) {
      ResolvedPos fromRes = ranges[i].fromRes;
      ResolvedPos toRes = ranges[i].toRes;
      var mapping = tr.mapping.slice(mapFrom);
      tr.replaceRange(mapping.map(fromRes.pos), mapping.map(toRes.pos), i > 0 ? Slice.empty : content);
      if (i == 0) {
        selectionToInsertionEnd(tr, mapFrom, (lastNode != null ? lastNode.isInline : lastParent != null && lastParent.isTextblock) ? -1 : 1);
      }
    }
  }

  void replaceWith(Transaction tr, PMNode node) {
    int mapFrom = tr.steps.length;
    for (int i = 0; i < ranges.length; i++) {
      ResolvedPos fromRes = ranges[i].fromRes;
      ResolvedPos toRes = ranges[i].toRes;
      var mapping = tr.mapping.slice(mapFrom);
      int start = mapping.map(fromRes.pos);
      int end = mapping.map(toRes.pos);
      if (i > 0) {
        tr.deleteRange(start, end);
      } else {
        tr.replaceRangeWith(start, end, node);
        selectionToInsertionEnd(tr, mapFrom, node.isInline ? -1 : 1);
      }
    }
  }

  Map<String, dynamic> toJSON();

  static Map<String, SelectionFromJSON> classesById = {};

  static void jsonID(String id, SelectionFromJSON fromJSON) {
    if (classesById.containsKey(id)) throw RangeError("Duplicate use of selection JSON ID $id");
    classesById[id] = fromJSON;
  }

  static Selection fromJSON(PMNode doc, Map<String, dynamic> json) {
    _ensureSelectionJsonRegistered();
    if (json['type'] == null) throw RangeError("Invalid input for Selection.fromJSON");
    SelectionFromJSON? cls = classesById[json['type']];
    if (cls == null) throw RangeError("No selection type ${json['type']} defined");
    return cls(doc, json);
  }

  static Selection? findFrom(ResolvedPos pos, int dir, [bool textOnly = false]) {
    Selection? inner = pos.parent.inlineContent ? TextSelection(pos) : findSelectionIn(pos.node(0), pos.parent, pos.pos, pos.index(), dir, textOnly);
    if (inner != null) return inner;

    for (int depth = pos.depth - 1; depth >= 0; depth--) {
      Selection? found = dir < 0
          ? findSelectionIn(pos.node(0), pos.node(depth), pos.before(depth + 1), pos.index(depth), dir, textOnly)
          : findSelectionIn(pos.node(0), pos.node(depth), pos.after(depth + 1), pos.index(depth) + 1, dir, textOnly);
      if (found != null) return found;
    }
    return null;
  }

  static Selection near(ResolvedPos pos, [int bias = 1]) {
    return findFrom(pos, bias) ?? findFrom(pos, -bias) ?? AllSelection(pos.node(0));
  }

  static Selection atStart(PMNode doc) {
    return findSelectionIn(doc, doc, 0, 0, 1) ?? AllSelection(doc);
  }

  static Selection atEnd(PMNode doc) {
    return findSelectionIn(doc, doc, doc.content.size, doc.childCount, -1) ?? AllSelection(doc);
  }

  SelectionBookmark getBookmark() {
    return TextSelection.between(anchorRes, headRes).getBookmark();
  }

  bool get visible => true;
}

// Stubs for functions not yet defined completely in this file:

Selection? findSelectionIn(PMNode doc, PMNode node, int pos, int index, int dir, [bool textOnly = false]) {
  if (node.inlineContent) return TextSelection.create(doc, pos);
  for (int i = index - (dir > 0 ? 0 : 1); dir > 0 ? i < node.childCount : i >= 0; i += dir) {
    PMNode child = node.child(i);
    if (!child.isAtom) {
      Selection? inner = findSelectionIn(doc, child, pos + dir, dir < 0 ? child.childCount : 0, dir, textOnly);
      if (inner != null) return inner;
    } else if (!textOnly && NodeSelection.isSelectable(child)) {
      return NodeSelection.create(doc, pos - (dir < 0 ? child.nodeSize : 0));
    }
    pos += child.nodeSize * dir;
  }
  return null;
}

class TextSelection extends Selection {
  TextSelection(ResolvedPos pos, [ResolvedPos? head]) : super(pos, head ?? pos);

  ResolvedPos? get $cursor => anchorRes.pos == headRes.pos ? anchorRes : null;

  @override
  SelectionBookmark getBookmark() {
    return TextBookmark(anchor, head);
  }


  @override
  bool get visible => true;


  @override
  bool eq(Selection other) {
    return other is TextSelection && other.anchor == anchor && other.head == head;
  }

  @override
  Selection map(PMNode doc, Mapping mapping) {
    ResolvedPos mappedAnchor = doc.resolve(mapping.map(anchor));
    return TextSelection(mappedAnchor, doc.resolve(mapping.map(head)));
  }

  @override
  Map<String, dynamic> toJSON() {
    return {"type": "text", "anchor": anchor, "head": head};
  }

  static TextSelection create(PMNode doc, int anchor, [int? head]) {
    ResolvedPos anchorRes = doc.resolve(anchor);
    return TextSelection(anchorRes, head != null ? doc.resolve(head) : anchorRes);
  }

  static Selection between(ResolvedPos anchorRes, ResolvedPos headRes, [int? bias]) {
    ResolvedPos dDir = anchorRes.pos > headRes.pos ? anchorRes : headRes;
    if (dDir.parent.inlineContent) return TextSelection(anchorRes, headRes);
    Selection? found = Selection.findFrom(headRes, bias ?? (anchorRes.pos > headRes.pos ? 1 : -1), true);
    if (found != null) {
      Selection? foundAnchor = Selection.findFrom(anchorRes, bias ?? (headRes.pos > anchorRes.pos ? 1 : -1), true);
      return TextSelection(foundAnchor != null ? foundAnchor.anchorRes : found.anchorRes, found.headRes);
    }
    return TextSelection(anchorRes, headRes);
  }
}
class NodeSelection extends Selection {
  final PMNode node;

  NodeSelection(ResolvedPos posRes) : node = posRes.nodeAfter!, super(posRes, posRes.node(0).resolve(posRes.pos + posRes.nodeAfter!.nodeSize));

  @override
  bool eq(Selection other) {
    return other is NodeSelection && other.anchor == anchor;
  }

  @override
  Selection map(PMNode doc, Mapping mapping) {
    MapResult mapped = mapping.mapResult(anchor, 1);
    ResolvedPos posRes = doc.resolve(mapped.pos);
    if (mapped.deleted) return Selection.near(posRes);
    return NodeSelection(posRes);
  }

  @override
  SelectionBookmark getBookmark() {
    return NodeBookmark(anchor);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {"type": "node", "anchor": anchor};
  }


  static NodeSelection create(PMNode doc, int from) {
    return NodeSelection(doc.resolve(from));
  }

  static bool isSelectable(PMNode node) {
    return !node.isText && node.type.spec.selectable != false;
  }
}

class AllSelection extends Selection {
  AllSelection(PMNode doc) : super(doc.resolve(0), doc.resolve(doc.content.size));

  @override
  bool eq(Selection other) {
    return other is AllSelection;
  }

  @override
  Selection map(PMNode doc, Mapping mapping) {
    return AllSelection(doc);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {"type": "all"};
  }
}

bool _selectionJsonRegistered = false;

void _ensureSelectionJsonRegistered() {
  if (_selectionJsonRegistered) return;
  Selection.jsonID("text", (doc, json) => TextSelection.create(doc, json["anchor"] as int, json["head"] as int?));
  Selection.jsonID("node", (doc, json) => NodeSelection.create(doc, json["anchor"] as int));
  Selection.jsonID("all", (doc, json) => AllSelection(doc));
  _selectionJsonRegistered = true;
}

class TextBookmark implements SelectionBookmark {
  final int anchor;
  final int head;

  TextBookmark(this.anchor, this.head);

  @override
  SelectionBookmark map(Mapping mapping) {
    return TextBookmark(mapping.map(anchor), mapping.map(head));
  }

  @override
  Selection resolve(PMNode doc) {
    return TextSelection.between(doc.resolve(anchor), doc.resolve(head));
  }
}

class NodeBookmark implements SelectionBookmark {
  final int anchor;

  NodeBookmark(this.anchor);

  @override
  SelectionBookmark map(Mapping mapping) {
    final mapped = mapping.mapResult(anchor, 1);
    return mapped.deleted
        ? TextBookmark(mapped.pos, mapped.pos)
        : NodeBookmark(mapped.pos);
  }

  @override
  Selection resolve(PMNode doc) {
    final $pos = doc.resolve(anchor);
    final node = $pos.nodeAfter;
    if (node != null && NodeSelection.isSelectable(node)) {
      return NodeSelection($pos);
    }
    return Selection.near($pos);
  }
}
