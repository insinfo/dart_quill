import '../model/index.dart';
import 'transform.dart';
import 'replace_step.dart';
import 'mark.dart';


bool _canCut(PMNode node, int start, int end) {
  return (start == 0 || node.canReplace(start, node.childCount)) && (end == node.childCount || node.canReplace(0, end));
}

int? liftTarget(NodeRange range) {
  PMNode parent = range.parent;
  Fragment content = parent.content.cutByIndex(range.startIndex, range.endIndex);
  for (int depth = range.depth, contentBefore = 0, contentAfter = 0;; --depth) {
    PMNode node = range.$from.node(depth);
    int index = range.$from.index(depth) + contentBefore;
    int endIndex = range.$to.indexAfter(depth) - contentAfter;
    if (depth < range.depth && node.canReplace(index, endIndex, content)) return depth;
    if (depth == 0 || node.type.spec.isolating == true || !_canCut(node, index, endIndex)) break;
    if (index > 0) contentBefore = 1;
    if (endIndex < node.childCount) contentAfter = 1;
  }
  return null;
}

void lift(Transform tr, NodeRange range, int target) {
  ResolvedPos fromPos = range.$from;
  ResolvedPos toPos = range.$to;
  int depth = range.depth;

  int gapStart = fromPos.before(depth + 1);
  int gapEnd = toPos.after(depth + 1);
  int start = gapStart;
  int end = gapEnd;

  Fragment before = Fragment.empty;
  int openStart = 0;
  for (int d = depth; d > target; d--) {
    bool splitting = false;
    if (splitting || fromPos.index(d) > 0) {
      splitting = true;
      before = Fragment.from(fromPos.node(d).copy(before));
      openStart++;
    } else {
      start--;
    }
  }

  Fragment after = Fragment.empty;
  int openEnd = 0;
  for (int d = depth; d > target; d--) {
    bool splitting = false;
    if (splitting || toPos.after(d + 1) < toPos.end(d)) {
      splitting = true;
      after = Fragment.from(toPos.node(d).copy(after));
      openEnd++;
    } else {
      end++;
    }
  }

  tr.step(ReplaceAroundStep(start, end, gapStart, gapEnd, Slice(before.append(after), openStart, openEnd), before.size - openStart, true));
}

class Wrapping {
  final NodeType type;
  final Map<String, dynamic>? attrs;

  Wrapping(this.type, [this.attrs]);
}

List<Wrapping>? findWrapping(NodeRange range, NodeType nodeType, [Map<String, dynamic>? attrs, NodeRange? innerRange]) {
  innerRange ??= range;
  List<NodeType>? around = _findWrappingOutside(range, nodeType);
  List<NodeType>? inner = around != null ? _findWrappingInside(innerRange, nodeType) : null;
  if (inner == null) return null;
  
  List<Wrapping> result = around!.map((t) => Wrapping(t, null)).toList();
  result.add(Wrapping(nodeType, attrs));
  result.addAll(inner.map((t) => Wrapping(t, null)));
  return result;
}

List<NodeType>? _findWrappingOutside(NodeRange range, NodeType type) {
  PMNode parent = range.parent;
  int startIndex = range.startIndex;
  int endIndex = range.endIndex;
  List<NodeType>? around = parent.contentMatchAt(startIndex).findWrapping(type);
  if (around == null) return null;
  NodeType outer = around.isNotEmpty ? around[0] : type;
  return parent.canReplaceWith(startIndex, endIndex, outer) ? around : null;
}

List<NodeType>? _findWrappingInside(NodeRange range, NodeType type) {
  PMNode parent = range.parent;
  int startIndex = range.startIndex;
  int endIndex = range.endIndex;
  PMNode inner = parent.child(startIndex);
  List<NodeType>? inside = type.contentMatch.findWrapping(inner.type);
  if (inside == null) return null;
  NodeType lastType = inside.isNotEmpty ? inside.last : type;
  ContentMatch? innerMatch = lastType.contentMatch;
  for (int i = startIndex; innerMatch != null && i < endIndex; i++) {
    innerMatch = innerMatch.matchType(parent.child(i).type);
  }
  if (innerMatch == null || !innerMatch.validEnd) return null;
  return inside;
}

void wrap(Transform tr, NodeRange range, List<Wrapping> wrappers) {
  Fragment content = Fragment.empty;
  for (int i = wrappers.length - 1; i >= 0; i--) {
    if (content.size > 0) {
      ContentMatch? match = wrappers[i].type.contentMatch.matchFragment(content);
      if (match == null || !match.validEnd) {
        throw RangeError("Wrapper type given to Transform.wrap does not form valid content of its parent wrapper");
      }
    }
    content = Fragment.from(wrappers[i].type.create(wrappers[i].attrs, content));
  }

  int start = range.start;
  int end = range.end;
  tr.step(ReplaceAroundStep(start, end, start, end, Slice(content, 0, 0), wrappers.length, true));
}

void setBlockType(Transform tr, int from, int to, NodeType type, [dynamic attrs]) {
  if (!type.isTextblock) throw RangeError("Type given to setBlockType should be a textblock");
  int mapFrom = tr.steps.length;
  tr.doc.nodesBetween(from, to, (node, pos, parent, index) {
    Map<String, dynamic>? attrsHere = attrs is Function ? attrs(node) : attrs;
    if (node.isTextblock && !node.hasMarkup(type, attrsHere) && _canChangeType(tr.doc, tr.mapping.slice(mapFrom).map(pos), type)) {
      bool? convertNewlines;
      if (type.schema.linebreakReplacement != null) {
        bool pre = type.whitespace == "pre";
        bool supportLinebreak = type.contentMatch.matchType(type.schema.linebreakReplacement!) != null;
        if (pre && !supportLinebreak) {
          convertNewlines = false;
        } else if (!pre && supportLinebreak) {
          convertNewlines = true;
        }
      }
      
      if (convertNewlines == false) _replaceLinebreaks(tr, node, pos, mapFrom);
      clearIncompatible(tr, tr.mapping.slice(mapFrom).map(pos, 1), type, null, convertNewlines == null);
      var mapping = tr.mapping.slice(mapFrom);
      int startM = mapping.map(pos, 1);
      int endM = mapping.map(pos + node.nodeSize, 1);
      tr.step(ReplaceAroundStep(startM, endM, startM + 1, endM - 1, Slice(Fragment.from(type.create(attrsHere, null, node.marks)), 0, 0), 1, true));
      if (convertNewlines == true) _replaceNewlines(tr, node, pos, mapFrom);
      return false;
    }
    return true;
  });
}

void _replaceNewlines(Transform tr, PMNode node, int pos, int mapFrom) {
  node.forEach((child, offset, index) {
    if (child.isText) {
      RegExp newline = RegExp(r'\r?\n|\r');
      Iterable<Match> matches = newline.allMatches(child.text!);
      for (Match m in matches) {
        int start = tr.mapping.slice(mapFrom).map(pos + 1 + offset + m.start);
        tr.replaceWith(start, start + 1, node.type.schema.linebreakReplacement!.create());
      }
    }
  });
}

void _replaceLinebreaks(Transform tr, PMNode node, int pos, int mapFrom) {
  node.forEach((child, offset, index) {
    if (child.type == child.type.schema.linebreakReplacement) {
      int start = tr.mapping.slice(mapFrom).map(pos + 1 + offset);
      tr.replaceWith(start, start + 1, node.type.schema.text("\n"));
    }
  });
}

bool _canChangeType(PMNode doc, int pos, NodeType type) {
  ResolvedPos posRes = doc.resolve(pos);
  int index = posRes.index();
  return posRes.parent.canReplaceWith(index, index + 1, type);
}

void setNodeMarkup(Transform tr, int pos, [NodeType? type, Map<String, dynamic>? attrs, List<Mark>? marks]) {
  PMNode? node = tr.doc.nodeAt(pos);
  if (node == null) throw RangeError("No node at given position");
  type ??= node.type;
  PMNode newNode = type.create(attrs, null, marks ?? node.marks);
  if (node.isLeaf) {
    tr.replaceWith(pos, pos + node.nodeSize, newNode);
    return;
  }
  if (!type.validContent(node.content)) throw RangeError("Invalid content for node type \${type.name}");
  tr.step(ReplaceAroundStep(pos, pos + node.nodeSize, pos + 1, pos + node.nodeSize - 1, Slice(Fragment.from(newNode), 0, 0), 1, true));
}

bool canSplit(PMNode doc, int pos, [int depth = 1, List<Wrapping?>? typesAfter]) {
  ResolvedPos posRes = doc.resolve(pos);
  int base = posRes.depth - depth;
  Wrapping? innerType = (typesAfter != null && typesAfter.isNotEmpty) ? typesAfter.last : null;
  NodeType innerNodeType = innerType != null ? innerType.type : posRes.parent.type;
  
  if (base < 0 || posRes.parent.type.spec.isolating == true || !posRes.parent.canReplace(posRes.index(), posRes.parent.childCount) || !innerNodeType.validContent(posRes.parent.content.cutByIndex(posRes.index(), posRes.parent.childCount))) {
    return false;
  }
  for (int d = posRes.depth - 1, i = depth - 2; d > base; d--, i--) {
    PMNode node = posRes.node(d);
    int index = posRes.index(d);
    if (node.type.spec.isolating == true) return false;
    Fragment rest = node.content.cutByIndex(index, node.childCount);
    Wrapping? overrideChild = typesAfter != null && i + 1 < typesAfter.length ? typesAfter[i + 1] : null;
    if (overrideChild != null) {
      rest = rest.replaceChild(0, overrideChild.type.create(overrideChild.attrs));
    }
    Wrapping? afterType = typesAfter != null && i >= 0 && i < typesAfter.length ? typesAfter[i] : null;
    NodeType after = afterType != null ? afterType.type : node.type;
    if (!node.canReplace(index + 1, node.childCount) || !after.validContent(rest)) return false;
  }
  int index = posRes.indexAfter(base);
  Wrapping? baseType = typesAfter != null && typesAfter.isNotEmpty ? typesAfter[0] : null;
  return posRes.node(base).canReplaceWith(index, index, baseType != null ? baseType.type : posRes.node(base + 1).type);
}

void split(Transform tr, int pos, [int depth = 1, List<Wrapping?>? typesAfter]) {
  ResolvedPos posRes = tr.doc.resolve(pos);
  Fragment before = Fragment.empty;
  Fragment after = Fragment.empty;
  for (int d = posRes.depth, e = posRes.depth - depth, i = depth - 1; d > e; d--, i--) {
    before = Fragment.from(posRes.node(d).copy(before));
    Wrapping? typeAfter = typesAfter != null && i >= 0 && i < typesAfter.length ? typesAfter[i] : null;
    after = Fragment.from(typeAfter != null ? typeAfter.type.create(typeAfter.attrs, after) : posRes.node(d).copy(after));
  }
  tr.step(ReplaceStep(pos, pos, Slice(before.append(after), depth, depth), true));
}

bool canJoin(PMNode doc, int pos) {
  ResolvedPos posRes = doc.resolve(pos);
  int index = posRes.index();
  return _joinable(posRes.nodeBefore, posRes.nodeAfter) && posRes.parent.canReplace(index, index + 1);
}

bool _canAppendWithSubstitutedLinebreaks(PMNode a, PMNode b) {
  if (b.content.size == 0) a.type.compatibleContent(b.type);
  ContentMatch? match = a.contentMatchAt(a.childCount);
  NodeType? linebreakReplacement = a.type.schema.linebreakReplacement;
  for (int i = 0; i < b.childCount; i++) {
    PMNode child = b.child(i);
    NodeType type = child.type == linebreakReplacement ? a.type.schema.nodes['text']! : child.type;
    match = match?.matchType(type);
    if (match == null) return false;
    if (!a.type.allowsMarks(child.marks)) return false;
  }
  return match!.validEnd;
}

bool _joinable(PMNode? a, PMNode? b) {
  return a != null && b != null && !a.isLeaf && _canAppendWithSubstitutedLinebreaks(a, b);
}

int? joinPoint(PMNode doc, int pos, [int dir = -1]) {
  ResolvedPos posRes = doc.resolve(pos);
  for (int d = posRes.depth;; d--) {
    PMNode? before, after;
    int index = posRes.index(d);
    if (d == posRes.depth) {
      before = posRes.nodeBefore;
      after = posRes.nodeAfter;
    } else if (dir > 0) {
      before = posRes.node(d + 1);
      index++;
      after = posRes.node(d).maybeChild(index);
    } else {
      before = posRes.node(d).maybeChild(index - 1);
      after = posRes.node(d + 1);
    }
    if (before != null && !before.isTextblock && _joinable(before, after) && posRes.node(d).canReplace(index, index + 1)) {
      return pos;
    }
    if (d == 0) break;
    pos = dir < 0 ? posRes.before(d) : posRes.after(d);
  }
  return null;
}

Transform join(Transform tr, int pos, int depth) {
  bool? convertNewlines;
  NodeType? linebreakReplacement = tr.doc.type.schema.linebreakReplacement;
  ResolvedPos beforePos = tr.doc.resolve(pos - depth);
  NodeType beforeType = beforePos.node().type;
  
  if (linebreakReplacement != null && beforeType.inlineContent) {
    bool pre = beforeType.whitespace == "pre";
    bool supportLinebreak = beforeType.contentMatch.matchType(linebreakReplacement) != null;
    if (pre && !supportLinebreak) {
      convertNewlines = false;
    } else if (!pre && supportLinebreak) {
      convertNewlines = true;
    }
  }
  
  int mapFrom = tr.steps.length;
  if (convertNewlines == false) {
    ResolvedPos afterPos = tr.doc.resolve(pos + depth);
    _replaceLinebreaks(tr, afterPos.node(), afterPos.before(), mapFrom);
  }
  
  if (beforeType.inlineContent) {
    clearIncompatible(tr, pos + depth - 1, beforeType, beforePos.node().contentMatchAt(beforePos.index()), convertNewlines == null);
  }
  
  var mapping = tr.mapping.slice(mapFrom);
  int start = mapping.map(pos - depth);
  tr.step(ReplaceStep(start, mapping.map(pos + depth, -1), Slice.empty, true));
  
  if (convertNewlines == true) {
    ResolvedPos fullPos = tr.doc.resolve(start);
    _replaceNewlines(tr, fullPos.node(), fullPos.before(), tr.steps.length);
  }
  
  return tr;
}

int? insertPoint(PMNode doc, int pos, NodeType nodeType) {
  ResolvedPos posRes = doc.resolve(pos);
  if (posRes.parent.canReplaceWith(posRes.index(), posRes.index(), nodeType)) return pos;
  if (posRes.parentOffset == 0) {
    for (int d = posRes.depth - 1; d >= 0; d--) {
      int index = posRes.index(d);
      if (posRes.node(d).canReplaceWith(index, index, nodeType)) return posRes.before(d + 1);
      if (index > 0) return null;
    }
  }
  if (posRes.parentOffset == posRes.parent.content.size) {
    for (int d = posRes.depth - 1; d >= 0; d--) {
      int index = posRes.indexAfter(d);
      if (posRes.node(d).canReplaceWith(index, index, nodeType)) return posRes.after(d + 1);
      if (index < posRes.node(d).childCount) return null;
    }
  }
  return null;
}

int? dropPoint(PMNode doc, int pos, Slice slice) {
  ResolvedPos posRes = doc.resolve(pos);
  if (slice.content.size == 0) return pos;
  Fragment content = slice.content;
  for (int i = 0; i < slice.openStart; i++) {
    content = content.firstChild!.content;
  }
  for (int pass = 1; pass <= (slice.openStart == 0 && slice.size > 0 ? 2 : 1); pass++) {
    for (int d = posRes.depth; d >= 0; d--) {
      int bias = d == posRes.depth ? 0 : posRes.pos <= (posRes.start(d + 1) + posRes.end(d + 1)) / 2 ? -1 : 1;
      int insertPos = posRes.index(d) + (bias > 0 ? 1 : 0);
      PMNode parent = posRes.node(d);
      bool fits = false;
      if (pass == 1) {
        fits = parent.canReplace(insertPos, insertPos, content);
      } else {
        List<NodeType>? wrapping = parent.contentMatchAt(insertPos).findWrapping(content.firstChild!.type);
        fits = wrapping != null && parent.canReplaceWith(insertPos, insertPos, wrapping[0]);
      }
      if (fits) {
        return bias == 0 ? posRes.pos : bias < 0 ? posRes.before(d + 1) : posRes.after(d + 1);
      }
    }
  }
  return null;
}
