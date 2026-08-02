import 'dart:math';
import '../model/index.dart';
import 'step.dart';
import 'replace_step.dart';
import 'transform.dart';
import 'structure.dart';

Step? replaceStep(PMNode doc, int from, [int? to, Slice? slice]) {
  to ??= from;
  slice ??= Slice.empty;
  if (from == to && slice.size == 0) return null;

  ResolvedPos fromPos = doc.resolve(from);
  ResolvedPos toPos = doc.resolve(to);
  
  if (_fitsTrivially(fromPos, toPos, slice)) {
    return ReplaceStep(from, to, slice);
  }
  return _Fitter(fromPos, toPos, slice).fit();
}

bool _fitsTrivially(ResolvedPos fromPos, ResolvedPos toPos, Slice slice) {
  return slice.openStart == 0 && slice.openEnd == 0 && fromPos.start() == toPos.start() &&
      fromPos.parent.canReplace(fromPos.index(), toPos.index(), slice.content);
}

class _Fittable {
  final int sliceDepth;
  final int frontierDepth;
  final PMNode? parent;
  final Fragment? inject;
  final List<NodeType>? wrap;

  _Fittable(this.sliceDepth, this.frontierDepth, this.parent, this.inject, this.wrap);
}

class _FrontierNode {
  final NodeType type;
  ContentMatch match;

  _FrontierNode(this.type, this.match);
}

class _Fitter {
  final ResolvedPos fromPos;
  final ResolvedPos toPos;
  Slice unplaced;
  List<_FrontierNode> frontier = [];
  Fragment placed = Fragment.empty;

  _Fitter(this.fromPos, this.toPos, this.unplaced) {
    for (int i = 0; i <= fromPos.depth; i++) {
      PMNode node = fromPos.node(i);
      frontier.add(_FrontierNode(node.type, node.contentMatchAt(fromPos.indexAfter(i))));
    }

    for (int i = fromPos.depth; i > 0; i--) {
      placed = Fragment.from(fromPos.node(i).copy(placed));
    }
  }

  int get depth => frontier.length - 1;

  Step? fit() {
    while (unplaced.size > 0) {
      _Fittable? fitRes = _findFittable();
      if (fitRes != null) {
        _placeNodes(fitRes);
      } else {
        if (!_openMore()) {
          _dropNode();
        }
      }
    }
    
    int moveInline = _mustMoveInline();
    int placedSize = placed.size - depth - fromPos.depth;
    ResolvedPos? finalTo = _close(moveInline < 0 ? toPos : fromPos.doc.resolve(moveInline));
    if (finalTo == null) return null;

    Fragment content = placed;
    int openStart = fromPos.depth;
    int openEnd = finalTo.depth;
    while (openStart > 0 && openEnd > 0 && content.childCount == 1) {
      content = content.firstChild!.content;
      openStart--;
      openEnd--;
    }
    Slice slice = Slice(content, openStart, openEnd);
    if (moveInline > -1) {
      return ReplaceAroundStep(fromPos.pos, moveInline, toPos.pos, toPos.end(), slice, placedSize);
    }
    if (slice.size > 0 || fromPos.pos != toPos.pos) {
      return ReplaceStep(fromPos.pos, finalTo.pos, slice);
    }
    return null;
  }

  _Fittable? _findFittable() {
    int startDepth = unplaced.openStart;
    Fragment cur = unplaced.content;
    int openEnd = unplaced.openEnd;
    for (int d = 0; d < startDepth; d++) {
      PMNode node = cur.firstChild!;
      if (cur.childCount > 1) openEnd = 0;
      if (node.type.spec.isolating == true && openEnd <= d) {
        startDepth = d;
        break;
      }
      cur = node.content;
    }

    for (int pass = 1; pass <= 2; pass++) {
      for (int sliceDepth = pass == 1 ? startDepth : unplaced.openStart; sliceDepth >= 0; sliceDepth--) {
        Fragment fragment;
        PMNode? parent;
        if (sliceDepth > 0) {
          parent = _contentAt(unplaced.content, sliceDepth - 1).firstChild;
          fragment = parent!.content;
        } else {
          fragment = unplaced.content;
        }
        PMNode? first = fragment.firstChild;
        for (int frontierDepth = depth; frontierDepth >= 0; frontierDepth--) {
          _FrontierNode fNode = frontier[frontierDepth];
          NodeType type = fNode.type;
          ContentMatch match = fNode.match;
          List<NodeType>? wrap;
          Fragment? inject;

          if (pass == 1 && (first != null ? match.matchType(first.type) != null || (inject = match.fillBefore(Fragment.from(first), false)) != null : parent != null && type.compatibleContent(parent.type))) {
            return _Fittable(sliceDepth, frontierDepth, parent, inject, null);
          } else if (pass == 2 && first != null && (wrap = match.findWrapping(first.type)) != null) {
            return _Fittable(sliceDepth, frontierDepth, parent, null, wrap);
          }
          if (parent != null && match.matchType(parent.type) != null) break;
        }
      }
    }
    return null;
  }

  bool _openMore() {
    Fragment content = unplaced.content;
    int openStart = unplaced.openStart;
    int openEnd = unplaced.openEnd;
    Fragment inner = _contentAt(content, openStart);
    if (inner.childCount == 0 || inner.firstChild!.isLeaf) return false;
    unplaced = Slice(
      content,
      openStart + 1,
      max(openEnd, inner.size + openStart >= content.size - openEnd ? openStart + 1 : 0),
    );
    return true;
  }

  void _dropNode() {
    Fragment content = unplaced.content;
    int openStart = unplaced.openStart;
    int openEnd = unplaced.openEnd;
    Fragment inner = _contentAt(content, openStart);
    if (inner.childCount <= 1 && openStart > 0) {
      bool openAtEnd = content.size - openStart <= openStart + inner.size;
      unplaced = Slice(
        _dropFromFragment(content, openStart - 1, 1),
        openStart - 1,
        openAtEnd ? openStart - 1 : openEnd,
      );
    } else {
      unplaced = Slice(_dropFromFragment(content, openStart, 1), openStart, openEnd);
    }
  }

  void _placeNodes(_Fittable fittable) {
    while (depth > fittable.frontierDepth) _closeFrontierNode();
    if (fittable.wrap != null) {
      for (int i = 0; i < fittable.wrap!.length; i++) {
        _openFrontierNode(fittable.wrap![i]);
      }
    }

    Slice slice = unplaced;
    Fragment fragment = fittable.parent != null ? fittable.parent!.content : slice.content;
    int openStart = slice.openStart - fittable.sliceDepth;
    int taken = 0;
    List<PMNode> add = [];
    _FrontierNode fNode = frontier[fittable.frontierDepth];
    ContentMatch? match = fNode.match;
    NodeType type = fNode.type;

    if (fittable.inject != null) {
      for (int i = 0; i < fittable.inject!.childCount; i++) {
        add.add(fittable.inject!.child(i));
      }
      match = match.matchFragment(fittable.inject!);
    }

    int openEndCount = (fragment.size + fittable.sliceDepth) - (slice.content.size - slice.openEnd);
    while (taken < fragment.childCount) {
      PMNode next = fragment.child(taken);
      ContentMatch? matches = match!.matchType(next.type);
      if (matches == null) break;
      taken++;
      if (taken > 1 || openStart == 0 || next.content.size > 0) {
        match = matches;
        add.add(_closeNodeStart(
          next.mark(type.allowedMarks(next.marks)),
          taken == 1 ? openStart : 0,
          taken == fragment.childCount ? openEndCount : -1,
        ));
      }
    }

    bool toEnd = taken == fragment.childCount;
    if (!toEnd) openEndCount = -1;

    placed = _addToFragment(placed, fittable.frontierDepth, Fragment.from(add));
    frontier[fittable.frontierDepth].match = match!;

    if (toEnd && openEndCount < 0 && fittable.parent != null && fittable.parent!.type == frontier[depth].type && frontier.length > 1) {
      _closeFrontierNode();
    }

    Fragment cur = fragment;
    for (int i = 0; i < openEndCount; i++) {
      PMNode node = cur.lastChild!;
      frontier.add(_FrontierNode(node.type, node.contentMatchAt(node.childCount)));
      cur = node.content;
    }

    if (!toEnd) {
      unplaced = Slice(_dropFromFragment(slice.content, fittable.sliceDepth, taken), slice.openStart, slice.openEnd);
    } else if (fittable.sliceDepth == 0) {
      unplaced = Slice.empty;
    } else {
      unplaced = Slice(_dropFromFragment(slice.content, fittable.sliceDepth - 1, 1), fittable.sliceDepth - 1, openEndCount < 0 ? slice.openEnd : fittable.sliceDepth - 1);
    }
  }

  int _mustMoveInline() {
    if (!toPos.parent.isTextblock) return -1;
    _FrontierNode top = frontier[depth];
    if (!top.type.isTextblock || _contentAfterFits(toPos, toPos.depth, top.type, top.match, false) == null) {
      return -1;
    }
    if (toPos.depth == depth) {
      var level = _findCloseLevel(toPos);
      if (level != null && level.depth == depth) return -1;
    }
    int d = toPos.depth;
    int after = toPos.after(d);
    while (d > 1 && after == toPos.end(d - 1)) {
      d--;
      after++;
    }
    return after;
  }

  _CloseLevel? _findCloseLevel(ResolvedPos toPosArg) {
    for (int i = min(depth, toPosArg.depth); i >= 0; i--) {
      _FrontierNode fNode = frontier[i];
      ContentMatch match = fNode.match;
      NodeType type = fNode.type;
      bool dropInner = i < toPosArg.depth && toPosArg.end(i + 1) == toPosArg.pos + (toPosArg.depth - (i + 1));
      Fragment? fit = _contentAfterFits(toPosArg, i, type, match, dropInner);
      if (fit == null) continue;
      
      bool valid = true;
      for (int d = i - 1; d >= 0; d--) {
        _FrontierNode dfNode = frontier[d];
        Fragment? matches = _contentAfterFits(toPosArg, d, dfNode.type, dfNode.match, true);
        if (matches == null || matches.childCount > 0) {
          valid = false;
          break;
        }
      }
      if (valid) return _CloseLevel(i, fit, dropInner ? toPosArg.doc.resolve(toPosArg.after(i + 1)) : toPosArg);
    }
    return null;
  }

  ResolvedPos? _close(ResolvedPos toPosArg) {
    _CloseLevel? close = _findCloseLevel(toPosArg);
    if (close == null) return null;

    while (depth > close.depth) _closeFrontierNode();
    if (close.fit.childCount > 0) placed = _addToFragment(placed, close.depth, close.fit);
    toPosArg = close.move;
    for (int d = close.depth + 1; d <= toPosArg.depth; d++) {
      PMNode node = toPosArg.node(d);
      Fragment add = node.type.contentMatch.fillBefore(node.content, true, toPosArg.index(d))!;
      _openFrontierNode(node.type, node.attrs, add);
    }
    return toPosArg;
  }

  void _openFrontierNode(NodeType type, [Map<String, dynamic>? attrs, Fragment? content]) {
    _FrontierNode top = frontier[depth];
    top.match = top.match.matchType(type)!;
    placed = _addToFragment(placed, depth, Fragment.from(type.create(attrs, content)));
    frontier.add(_FrontierNode(type, type.contentMatch));
  }

  void _closeFrontierNode() {
    _FrontierNode open = frontier.removeLast();
    Fragment add = open.match.fillBefore(Fragment.empty, true)!;
    if (add.childCount > 0) placed = _addToFragment(placed, frontier.length, add);
  }
}

class _CloseLevel {
  final int depth;
  final Fragment fit;
  final ResolvedPos move;

  _CloseLevel(this.depth, this.fit, this.move);
}

Fragment _dropFromFragment(Fragment fragment, int depth, int count) {
  if (depth == 0) return fragment.cutByIndex(count, fragment.childCount);
  return fragment.replaceChild(0, fragment.firstChild!.copy(_dropFromFragment(fragment.firstChild!.content, depth - 1, count)));
}

Fragment _addToFragment(Fragment fragment, int depth, Fragment content) {
  if (depth == 0) return fragment.append(content);
  return fragment.replaceChild(fragment.childCount - 1, fragment.lastChild!.copy(_addToFragment(fragment.lastChild!.content, depth - 1, content)));
}

Fragment _contentAt(Fragment fragment, int depth) {
  for (int i = 0; i < depth; i++) fragment = fragment.firstChild!.content;
  return fragment;
}

PMNode _closeNodeStart(PMNode node, int openStart, int openEnd) {
  if (openStart <= 0) return node;
  Fragment frag = node.content;
  if (openStart > 1) {
    frag = frag.replaceChild(0, _closeNodeStart(frag.firstChild!, openStart - 1, frag.childCount == 1 ? openEnd - 1 : 0));
  }
  if (openStart > 0) {
    frag = node.type.contentMatch.fillBefore(frag)!.append(frag);
    if (openEnd <= 0) {
      frag = frag.append(node.type.contentMatch.matchFragment(frag)!.fillBefore(Fragment.empty, true)!);
    }
  }
  return node.copy(frag);
}

Fragment? _contentAfterFits(ResolvedPos toPos, int depth, NodeType type, ContentMatch match, bool open) {
  PMNode node = toPos.node(depth);
  int index = open ? toPos.indexAfter(depth) : toPos.index(depth);
  if (index == node.childCount && !type.compatibleContent(node.type)) return null;
  Fragment? fit = match.fillBefore(node.content, true, index);
  return (fit != null && !_invalidMarks(type, node.content, index)) ? fit : null;
}

bool _invalidMarks(NodeType type, Fragment fragment, int start) {
  for (int i = start; i < fragment.childCount; i++) {
    if (!type.allowsMarks(fragment.child(i).marks)) return true;
  }
  return false;
}

bool _definesContent(NodeType type) {
  return type.spec.defining == true || type.spec.definingForContent == true;
}

void replaceRange(Transform tr, int from, int to, Slice slice) {
  if (slice.size == 0) {
    deleteRange(tr, from, to);
    return;
  }

  ResolvedPos fromPos = tr.doc.resolve(from);
  ResolvedPos toPos = tr.doc.resolve(to);
  if (_fitsTrivially(fromPos, toPos, slice)) {
    tr.step(ReplaceStep(from, to, slice));
    return;
  }

  List<int> targetDepths = _coveredDepths(fromPos, toPos);
  if (targetDepths.isNotEmpty && targetDepths.last == 0) targetDepths.removeLast();
  int preferredTarget = -(fromPos.depth + 1);
  targetDepths.insert(0, preferredTarget);

  for (int d = fromPos.depth, pos = fromPos.pos - 1; d > 0; d--, pos--) {
    NodeSpec spec = fromPos.node(d).type.spec;
    if (spec.defining == true || spec.definingAsContext == true || spec.isolating == true) break;
    if (targetDepths.contains(d)) {
      preferredTarget = d;
    } else if (fromPos.before(d) == pos) {
      targetDepths.insert(1, -d);
    }
  }

  int preferredTargetIndex = targetDepths.indexOf(preferredTarget);
  List<PMNode> leftNodes = [];
  int preferredDepth = slice.openStart;
  Fragment content = slice.content;
  for (int i = 0;; i++) {
    PMNode? node = content.firstChild;
    if (node == null) break;
    leftNodes.add(node);
    if (i == slice.openStart) break;
    content = node.content;
  }

  for (int d = preferredDepth - 1; d >= 0; d--) {
    PMNode leftNode = leftNodes[d];
    bool def = _definesContent(leftNode.type);
    if (def && !leftNode.sameMarkup(fromPos.node(preferredTarget.abs() - 1))) {
      preferredDepth = d;
    } else if (def || !leftNode.type.isTextblock) {
      break;
    }
  }

  for (int j = slice.openStart; j >= 0; j--) {
    int openDepth = (j + preferredDepth + 1) % (slice.openStart + 1);
    PMNode? insert = openDepth < leftNodes.length ? leftNodes[openDepth] : null;
    if (insert == null) continue;
    for (int i = 0; i < targetDepths.length; i++) {
      int targetDepth = targetDepths[(i + preferredTargetIndex) % targetDepths.length];
      bool expand = true;
      if (targetDepth < 0) {
        expand = false;
        targetDepth = -targetDepth;
      }
      PMNode parent = fromPos.node(targetDepth - 1);
      int index = fromPos.index(targetDepth - 1);
      if (parent.canReplaceWith(index, index, insert.type, insert.marks)) {
        tr.replace(fromPos.before(targetDepth), expand ? toPos.after(targetDepth) : to, Slice(_closeFragment(slice.content, 0, slice.openStart, openDepth), openDepth, slice.openEnd));
        return;
      }
    }
  }

  int startSteps = tr.steps.length;
  for (int i = targetDepths.length - 1; i >= 0; i--) {
    tr.replace(from, to, slice);
    if (tr.steps.length > startSteps) break;
    int depth = targetDepths[i];
    if (depth < 0) continue;
    from = fromPos.before(depth);
    to = toPos.after(depth);
  }
}

Fragment _closeFragment(Fragment fragment, int depth, int oldOpen, int newOpen, [PMNode? parent]) {
  if (depth < oldOpen) {
    PMNode first = fragment.firstChild!;
    fragment = fragment.replaceChild(0, first.copy(_closeFragment(first.content, depth + 1, oldOpen, newOpen, first)));
  }
  if (depth > newOpen) {
    ContentMatch match = parent!.contentMatchAt(0);
    Fragment start = match.fillBefore(fragment)!.append(fragment);
    fragment = start.append(match.matchFragment(start)!.fillBefore(Fragment.empty, true)!);
  }
  return fragment;
}

void replaceRangeWith(Transform tr, int from, int to, PMNode node) {
  if (!node.isInline && from == to && tr.doc.resolve(from).parent.content.size > 0) {
    int? point = insertPoint(tr.doc, from, node.type);
    if (point != null) {
      from = point;
      to = point;
    }
  }
  tr.replaceRange(from, to, Slice(Fragment.from(node), 0, 0));
}

void deleteRange(Transform tr, int from, int to) {
  ResolvedPos fromPos = tr.doc.resolve(from);
  ResolvedPos toPos = tr.doc.resolve(to);

  if (fromPos.parent.isTextblock && toPos.parent.isTextblock && fromPos.start() != toPos.start() && fromPos.parentOffset == 0 && toPos.parentOffset == 0) {
    int shared = fromPos.sharedDepth(to);
    bool isolated = false;
    for (int d = fromPos.depth; d > shared; d--) {
      if (fromPos.node(d).type.spec.isolating == true) isolated = true;
    }
    for (int d = toPos.depth; d > shared; d--) {
      if (toPos.node(d).type.spec.isolating == true) isolated = true;
    }
    if (!isolated) {
      for (int d = fromPos.depth; d > 0 && from == fromPos.start(d); d--) from = fromPos.before(d);
      for (int d = toPos.depth; d > 0 && to == toPos.start(d); d--) to = toPos.before(d);
      fromPos = tr.doc.resolve(from);
      toPos = tr.doc.resolve(to);
    }
  }

  List<int> covered = _coveredDepths(fromPos, toPos);
  for (int i = 0; i < covered.length; i++) {
    int depth = covered[i];
    bool last = i == covered.length - 1;
    if ((last && depth == 0) || fromPos.node(depth).type.contentMatch.validEnd) {
      tr.delete(fromPos.start(depth), toPos.end(depth));
      return;
    }
    if (depth > 0 && (last || fromPos.node(depth - 1).canReplace(fromPos.index(depth - 1), toPos.indexAfter(depth - 1)))) {
      tr.delete(fromPos.before(depth), toPos.after(depth));
      return;
    }
  }
  for (int d = 1; d <= fromPos.depth && d <= toPos.depth; d++) {
    if (from - fromPos.start(d) == fromPos.depth - d && to > fromPos.end(d) && toPos.end(d) - to != toPos.depth - d && fromPos.start(d - 1) == toPos.start(d - 1) && fromPos.node(d - 1).canReplace(fromPos.index(d - 1), toPos.index(d - 1))) {
      tr.delete(fromPos.before(d), to);
      return;
    }
  }
  tr.delete(from, to);
}

List<int> _coveredDepths(ResolvedPos fromPos, ResolvedPos toPos) {
  List<int> result = [];
  int minDepth = min(fromPos.depth, toPos.depth);
  for (int d = minDepth; d >= 0; d--) {
    int start = fromPos.start(d);
    if (start < fromPos.pos - (fromPos.depth - d) || toPos.end(d) > toPos.pos + (toPos.depth - d) || fromPos.node(d).type.spec.isolating == true || toPos.node(d).type.spec.isolating == true) {
      break;
    }
    if (start == toPos.start(d) || (d == fromPos.depth && d == toPos.depth && fromPos.parent.inlineContent && toPos.parent.inlineContent && d > 0 && toPos.start(d - 1) == start - 1)) {
      result.add(d);
    }
  }
  return result;
}
