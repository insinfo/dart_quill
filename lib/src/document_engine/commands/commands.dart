import 'dart:math';
import '../model/index.dart';
import '../transform/index.dart';
import '../state/index.dart';

class PlatformHelper {
  static bool isMac = false;
}

/// Delete the selection, if there is one.
bool deleteSelection(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  if (state.selection.empty) return false;
  if (dispatch != null) dispatch(state.tr.deleteSelection().scrollIntoView());
  return true;
}

ResolvedPos? atBlockStart(EditorState state, [dynamic view]) {
  final selection = state.selection;
  if (selection is! TextSelection) return null;
  final $cursor = selection.$cursor;
  if ($cursor == null) return null;
  if (view != null) {
    try {
      if (view.endOfTextblock("backward", state) as bool == false) {
        return null;
      }
    } catch (_) {
      if ($cursor.parentOffset > 0) return null;
    }
  } else {
    if ($cursor.parentOffset > 0) return null;
  }
  return $cursor;
}

ResolvedPos? findCutBefore(ResolvedPos $pos) {
  if ($pos.parent.type.spec.isolating != true) {
    for (int i = $pos.depth - 1; i >= 0; i--) {
      if ($pos.index(i) > 0) {
        return $pos.doc.resolve($pos.before(i + 1));
      }
      if ($pos.node(i).type.spec.isolating == true) break;
    }
  }
  return null;
}

bool textblockAt(PMNode node, String side, [bool only = false]) {
  PMNode? scan = node;
  while (scan != null) {
    if (scan.isTextblock) return true;
    if (only && scan.childCount != 1) return false;
    scan = side == "start" ? scan.firstChild : scan.lastChild;
  }
  return false;
}

/// If the selection is empty and at the start of a textblock, try to
/// reduce the distance between that block and the one before it—if
/// there's a block directly before it that can be joined, join them.
bool joinBackward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $cursor = atBlockStart(state, view);
  if ($cursor == null) return false;

  final $cut = findCutBefore($cursor);

  // If there is no node before this, try to lift
  if ($cut == null) {
    final range = $cursor.blockRange();
    final target = range != null ? liftTarget(range) : null;
    if (target == null) return false;
    if (dispatch != null) {
      final tr = state.tr;
      tr.lift(range!, target);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }

  final before = $cut.nodeBefore!;
  // Apply the joining algorithm
  if (deleteBarrier(state, $cut, dispatch, -1)) return true;

  // If the node below has no content and the node above is
  // selectable, delete the node below and select the one above.
  if ($cursor.parent.content.size == 0 &&
      (textblockAt(before, "end") || NodeSelection.isSelectable(before))) {
    for (int depth = $cursor.depth;; depth--) {
      final delStep = replaceStep(state.doc, $cursor.before(depth), $cursor.after(depth), Slice.empty);
      if (delStep is ReplaceStep && delStep.slice.size < delStep.to - delStep.from) {
        if (dispatch != null) {
          final tr = state.tr;
          tr.step(delStep);
          tr.setSelection(textblockAt(before, "end")
              ? Selection.findFrom(tr.doc.resolve(tr.mapping.map($cut.pos, -1)), -1)!
              : NodeSelection.create(tr.doc, $cut.pos - before.nodeSize));
          dispatch(tr.scrollIntoView());
        }
        return true;
      }
      if (depth == 1 || $cursor.node(depth - 1).childCount > 1) break;
    }
  }

  // If the node before is an atom, delete it
  if (before.isAtom && $cut.depth == $cursor.depth - 1) {
    if (dispatch != null) {
      final tr = state.tr;
      tr.delete($cut.pos - before.nodeSize, $cut.pos);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }

  return false;
}


/// A more limited form of `joinBackward` that only tries to join the
/// current textblock to the one before it.
bool joinTextblockBackward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $cursor = atBlockStart(state, view);
  if ($cursor == null) return false;
  final $cut = findCutBefore($cursor);
  return $cut != null ? joinTextblocksAround(state, $cut, dispatch) : false;
}

/// A more limited form of `joinForward` that only tries to join the
/// current textblock to the one after it.
bool joinTextblockForward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $cursor = atBlockEnd(state, view);
  if ($cursor == null) return false;
  final $cut = findCutAfter($cursor);
  return $cut != null ? joinTextblocksAround(state, $cut, dispatch) : false;
}

bool joinTextblocksAround(EditorState state, ResolvedPos $cut, [void Function(Transaction tr)? dispatch]) {
  PMNode before = $cut.nodeBefore!;
  PMNode beforeText = before;
  int beforePos = $cut.pos - 1;
  while (!beforeText.isTextblock) {
    if (beforeText.type.spec.isolating == true) return false;
    final child = beforeText.lastChild;
    if (child == null) return false;
    beforeText = child;
    beforePos--;
  }

  PMNode after = $cut.nodeAfter!;
  PMNode afterText = after;
  int afterPos = $cut.pos + 1;
  while (!afterText.isTextblock) {
    if (afterText.type.spec.isolating == true) return false;
    final child = afterText.firstChild;
    if (child == null) return false;
    afterText = child;
    afterPos++;
  }

  final step = replaceStep(state.doc, beforePos, afterPos, Slice.empty);
  if (step is! ReplaceStep || step.from != beforePos || step.slice.size >= afterPos - beforePos) return false;

  if (dispatch != null) {
    final tr = state.tr;
    tr.step(step);
    tr.setSelection(TextSelection.create(tr.doc, beforePos));
    dispatch(tr.scrollIntoView());
  }
  return true;

}

/// When the selection is empty and at the start of a textblock, select
/// the node before that textblock, if possible.
bool selectNodeBackward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final head = state.selection.headRes;
  final empty = state.selection.empty;
  ResolvedPos? $cut = head;
  if (!empty) return false;

  if (head.parent.isTextblock) {
    if (view != null) {
      try {
        if (view.endOfTextblock("backward", state) as bool == false) {
          return false;
        }
      } catch (_) {
        if (head.parentOffset > 0) return false;
      }
    } else {
      if (head.parentOffset > 0) return false;
    }
    $cut = findCutBefore(head);
  }
  if ($cut == null) return false;
  final node = $cut.nodeBefore;
  if (node == null || !NodeSelection.isSelectable(node)) return false;
  if (dispatch != null) {
    dispatch(state.tr.setSelection(NodeSelection.create(state.doc, $cut.pos - node.nodeSize)).scrollIntoView());
  }
  return true;
}

ResolvedPos? atBlockEnd(EditorState state, [dynamic view]) {
  final selection = state.selection;
  if (selection is! TextSelection) return null;
  final $cursor = selection.$cursor;
  if ($cursor == null) return null;
  if (view != null) {
    try {
      if (view.endOfTextblock("forward", state) as bool == false) {
        return null;
      }
    } catch (_) {
      if ($cursor.parentOffset < $cursor.parent.content.size) return null;
    }
  } else {
    if ($cursor.parentOffset < $cursor.parent.content.size) return null;
  }
  return $cursor;
}

ResolvedPos? findCutAfter(ResolvedPos $pos) {
  if ($pos.parent.type.spec.isolating != true) {
    for (int i = $pos.depth - 1; i >= 0; i--) {
      final parent = $pos.node(i);
      if ($pos.index(i) + 1 < parent.childCount) {
        return $pos.doc.resolve($pos.after(i + 1));
      }
      if (parent.type.spec.isolating == true) break;
    }
  }
  return null;
}

/// If the selection is empty and the cursor is at the end of a
/// textblock, try to reduce or remove the boundary between that block
/// and the one after it.
bool joinForward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $cursor = atBlockEnd(state, view);
  if ($cursor == null) return false;

  final $cut = findCutAfter($cursor);
  if ($cut == null) return false;

  final after = $cut.nodeAfter!;
  if (deleteBarrier(state, $cut, dispatch, 1)) return true;

  if ($cursor.parent.content.size == 0 &&
      (textblockAt(after, "start") || NodeSelection.isSelectable(after))) {
    final delStep = replaceStep(state.doc, $cursor.before(), $cursor.after(), Slice.empty);
    if (delStep is ReplaceStep && delStep.slice.size < delStep.to - delStep.from) {
      if (dispatch != null) {
        final tr = state.tr;
        tr.step(delStep);
        tr.setSelection(textblockAt(after, "start")
            ? Selection.findFrom(tr.doc.resolve(tr.mapping.map($cut.pos)), 1)!
            : NodeSelection.create(tr.doc, tr.mapping.map($cut.pos)));
        dispatch(tr.scrollIntoView());
      }
      return true;
    }
  }

  if (after.isAtom && $cut.depth == $cursor.depth - 1) {
    if (dispatch != null) {
      final tr = state.tr;
      tr.delete($cut.pos, $cut.pos + after.nodeSize);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }

  return false;
}

/// When the selection is empty and at the end of a textblock, select
/// the node coming after that textblock, if possible.
bool selectNodeForward(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final head = state.selection.headRes;
  final empty = state.selection.empty;
  ResolvedPos? $cut = head;
  if (!empty) return false;
  if (head.parent.isTextblock) {
    if (view != null) {
      try {
        if (view.endOfTextblock("forward", state) as bool == false) {
          return false;
        }
      } catch (_) {
        if (head.parentOffset < head.parent.content.size) return false;
      }
    } else {
      if (head.parentOffset < head.parent.content.size) return false;
    }
    $cut = findCutAfter(head);
  }
  if ($cut == null) return false;
  final node = $cut.nodeAfter;
  if (node == null || !NodeSelection.isSelectable(node)) return false;
  if (dispatch != null) {
    final tr = state.tr;
    tr.setSelection(NodeSelection.create(state.doc, $cut.pos));
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// Join the selected block or, if there is a text selection, the
/// closest ancestor block of the selection that can be joined, with
/// the sibling above it.
bool joinUp(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final sel = state.selection;
  final nodeSel = sel is NodeSelection;
  int? point;
  if (nodeSel) {
    if (sel.node.isTextblock || !canJoin(state.doc, sel.from)) return false;
    point = sel.from;
  } else {
    point = joinPoint(state.doc, sel.from, -1);
    if (point == null) return false;
  }
  if (dispatch != null) {
    final tr = state.tr;
    tr.join(point);
    if (nodeSel) {

      tr.setSelection(NodeSelection.create(tr.doc, point - state.doc.resolve(point).nodeBefore!.nodeSize));
    }
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// Join the selected block, or the closest ancestor of the selection
/// that can be joined, with the sibling after it.
bool joinDown(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final sel = state.selection;
  int? point;
  if (sel is NodeSelection) {
    if (sel.node.isTextblock || !canJoin(state.doc, sel.to)) return false;
    point = sel.to;
  } else {
    point = joinPoint(state.doc, sel.to, 1);
    if (point == null) return false;
  }
  if (dispatch != null) {
    final tr = state.tr;
    tr.join(point);
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// Lift the selected block, or the closest ancestor block of the
/// selection that can be lifted, out of its parent node.
bool lift(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $from = state.selection.$from;
  final $to = state.selection.$to;
  final range = $from.blockRange($to);
  final target = range != null ? liftTarget(range) : null;
  if (target == null) return false;
  if (dispatch != null) {
    final tr = state.tr;
    tr.lift(range!, target);
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// If the selection is in a node whose type has a truthy code spec,
/// replace the selection with a newline character.
bool newlineInCode(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $head = state.selection.headRes;
  final $anchor = state.selection.anchorRes;
  if ($head.parent.type.spec.code != true || !$head.sameParent($anchor)) return false;
  if (dispatch != null) {
    final tr = state.tr;
    tr.insertText("\n");
    dispatch(tr.scrollIntoView());
  }
  return true;
}

NodeType? defaultBlockAt(ContentMatch match) {
  for (int i = 0; i < match.edgeCount; i++) {
    final type = match.edge(i).type;
    if (type.isTextblock && !type.hasRequiredAttrs()) return type;
  }
  return null;
}

/// When the selection is in a node with a truthy code spec, create a
/// default block after the code block, and move the cursor there.
bool exitCode(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $head = state.selection.headRes;
  final $anchor = state.selection.anchorRes;
  if ($head.parent.type.spec.code != true || !$head.sameParent($anchor)) return false;
  final above = $head.node(-1);
  final after = $head.indexAfter(-1);
  final type = defaultBlockAt(above.contentMatchAt(after));
  if (type == null || !above.canReplaceWith(after, after, type)) return false;
  if (dispatch != null) {
    final pos = $head.after();
    final tr = state.tr;
    tr.replaceWith(pos, pos, type.createAndFill()!);
    tr.setSelection(Selection.near(tr.doc.resolve(pos), 1));
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// If a block node is selected, create an empty paragraph before (if
/// it is its parent's first child) or after it.
bool createParagraphNear(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final sel = state.selection;
  final $from = sel.$from;
  final $to = sel.$to;
  if (sel is AllSelection || $from.parent.inlineContent || $to.parent.inlineContent) return false;
  final type = defaultBlockAt($to.parent.contentMatchAt($to.indexAfter()));
  if (type == null || !type.isTextblock) return false;
  if (dispatch != null) {
    final side = ($from.parentOffset == 0 && $to.index() < $to.parent.childCount ? $from : $to).pos;
    final tr = state.tr;
    tr.insert(side, type.createAndFill()!);
    tr.setSelection(TextSelection.create(tr.doc, side + 1));
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// If the cursor is in an empty textblock that can be lifted, lift the
/// block.
bool liftEmptyBlock(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final selection = state.selection;
  if (selection is! TextSelection) return false;
  final $cursor = selection.$cursor;
  if ($cursor == null || $cursor.parent.content.size > 0) return false;
  if ($cursor.depth > 1 && $cursor.after() != $cursor.end(-1)) {
    final before = $cursor.before();
    if (canSplit(state.doc, before)) {
      if (dispatch != null) {
        final tr = state.tr;
        tr.split(before);
        dispatch(tr.scrollIntoView());
      }
      return true;
    }
  }
  final range = $cursor.blockRange();
  final target = range != null ? liftTarget(range) : null;
  if (target == null) return false;
  if (dispatch != null) {
    final tr = state.tr;
    tr.lift(range!, target);
    dispatch(tr.scrollIntoView());
  }
  return true;
}

/// Create a variant of `splitBlock` that uses a custom function to
/// determine the type of the newly split off block.
Command splitBlockAs([
  Map<String, dynamic>? Function(PMNode node, bool atEnd, ResolvedPos $pos)? splitNode,
]) {
  return (state, [dispatch, view]) {
    final sel = state.selection;
    final $from = sel.$from;
    final $to = sel.$to;

    if (sel is NodeSelection && sel.node.isBlock) {
      if ($from.parentOffset == 0 || !canSplit(state.doc, $from.pos)) return false;
      if (dispatch != null) {
        final tr = state.tr;
        tr.split($from.pos);
        dispatch(tr.scrollIntoView());
      }
      return true;
    }


    if ($from.depth == 0) return false;
    final List<Wrapping?> types = [];
    int? splitDepth;
    NodeType? deflt;
    bool atEnd = false;
    bool atStart = false;

    for (int d = $from.depth;; d--) {
      final node = $from.node(d);
      if (node.isBlock) {
        atEnd = $from.end(d) == $from.pos + ($from.depth - d);
        atStart = $from.start(d) == $from.pos - ($from.depth - d);
        deflt = defaultBlockAt($from.node(d - 1).contentMatchAt($from.indexAfter(d - 1)));
        final splitTypeInfo = splitNode != null ? splitNode($to.parent, atEnd, $from) : null;
        if (splitTypeInfo != null) {
          types.insert(0, Wrapping(splitTypeInfo['type'] as NodeType, splitTypeInfo['attrs'] as Map<String, dynamic>?));
        } else if (atEnd && deflt != null) {
          types.insert(0, Wrapping(deflt, null));
        } else {
          types.insert(0, null);
        }
        splitDepth = d;
        break;
      } else {
        if (d == 1) return false;
        types.insert(0, null);
      }
    }

    final tr = state.tr;
    if (sel is TextSelection || sel is AllSelection) {
      tr.deleteSelection();
    }
    final splitPos = tr.mapping.map($from.pos);
    bool can = canSplit(tr.doc, splitPos, types.length, types);
    if (!can) {
      if (deflt != null) {
        types[0] = Wrapping(deflt, null);
        can = canSplit(tr.doc, splitPos, types.length, types);
      }
    }
    if (!can) return false;
    tr.split(splitPos, types.length, types);
    if (!atEnd && atStart && $from.node(splitDepth).type != deflt) {
      final first = tr.mapping.map($from.before(splitDepth));
      final $first = tr.doc.resolve(first);
      if (deflt != null && $from.node(splitDepth - 1).canReplaceWith($first.index(), $first.index() + 1, deflt)) {
        tr.setNodeMarkup(tr.mapping.map($from.before(splitDepth)), deflt);
      }
    }

    if (dispatch != null) dispatch(tr.scrollIntoView());
    return true;
  };
}

/// Split the parent block of the selection. If the selection is a text
/// selection, also delete its content.
final Command splitBlock = splitBlockAs();

/// Acts like `splitBlock`, but without resetting the set of active
/// marks at the cursor.
bool splitBlockKeepMarks(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  return splitBlock(state, dispatch != null ? (tr) {
    final marks = state.storedMarks ?? (state.selection.$to.parentOffset > 0 ? state.selection.$from.marks() : null);
    if (marks != null) tr.ensureMarks(marks);
    dispatch(tr);
  } : null, view);
}

/// Move the selection to the node wrapping the current selection, if
/// any. (Will not select the document node.)
bool selectParentNode(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  final $from = state.selection.$from;
  final to = state.selection.to;
  final same = $from.sharedDepth(to);
  if (same == 0) return false;
  final pos = $from.before(same);
  if (dispatch != null) {
    final tr = state.tr;
    tr.setSelection(NodeSelection.create(state.doc, pos));
    dispatch(tr);
  }
  return true;
}

/// Select the whole document.
bool selectAll(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]) {
  if (dispatch != null) {
    final tr = state.tr;
    tr.setSelection(AllSelection(state.doc));
    dispatch(tr);
  }
  return true;
}

bool joinMaybeClear(EditorState state, ResolvedPos $pos, void Function(Transaction tr)? dispatch) {
  final before = $pos.nodeBefore;
  final after = $pos.nodeAfter;
  final index = $pos.index();
  if (before == null || after == null || !before.type.compatibleContent(after.type)) return false;
  if (before.content.size == 0 && $pos.parent.canReplace(index - 1, index)) {
    if (dispatch != null) {
      final tr = state.tr;
      tr.delete($pos.pos - before.nodeSize, $pos.pos);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }
  if (!$pos.parent.canReplace(index, index + 1) || !(after.isTextblock || canJoin(state.doc, $pos.pos))) {
    return false;
  }
  if (dispatch != null) {
    final tr = state.tr;
    tr.join($pos.pos);
    dispatch(tr.scrollIntoView());
  }
  return true;
}

bool deleteBarrier(EditorState state, ResolvedPos $cut, void Function(Transaction tr)? dispatch, int dir) {
  final before = $cut.nodeBefore!;
  final after = $cut.nodeAfter!;
  final isolated = before.type.spec.isolating == true || after.type.spec.isolating == true;
  if (!isolated && joinMaybeClear(state, $cut, dispatch)) return true;

  final canDelAfter = !isolated && $cut.parent.canReplace($cut.index(), $cut.index() + 1);
  if (canDelAfter) {
    final m = before.contentMatchAt(before.childCount);
    final w = m.findWrapping(after.type);
    if (w != null && m.matchType(w.isNotEmpty ? w[0] : after.type)!.validEnd) {
      if (dispatch != null) {
        final end = $cut.pos + after.nodeSize;
        Fragment wrap = Fragment.empty;
        for (int i = w.length - 1; i >= 0; i--) {
          wrap = Fragment.from(w[i].create(null, wrap));
        }
        wrap = Fragment.from(before.copy(wrap));
        final tr = state.tr;
        tr.step(ReplaceAroundStep($cut.pos - 1, end, $cut.pos, end, Slice(wrap, 1, 0), w.length, true));
        final $joinAt = tr.doc.resolve(end + 2 * w.length);
        if ($joinAt.nodeAfter != null && $joinAt.nodeAfter!.type == before.type &&
            canJoin(tr.doc, $joinAt.pos)) {
          tr.join($joinAt.pos);
        }
        dispatch(tr.scrollIntoView());
      }
      return true;
    }
  }


  final selAfter = after.type.spec.isolating == true || (dir > 0 && isolated) ? null : Selection.findFrom($cut, 1);
  final range = selAfter != null ? selAfter.$from.blockRange(selAfter.$to) : null;
  final target = range != null ? liftTarget(range) : null;
  if (target != null && target >= $cut.depth) {
    if (dispatch != null) {
      final tr = state.tr;
      tr.lift(range!, target);
      dispatch(tr.scrollIntoView());
    }
    return true;
  }

  if (canDelAfter && textblockAt(after, "start", true) && textblockAt(before, "end")) {
    PMNode at = before;
    final List<PMNode> wrap = [];
    while (true) {
      wrap.add(at);
      if (at.isTextblock) break;
      at = at.lastChild!;
    }
    PMNode afterText = after;
    int afterDepth = 1;
    while (!afterText.isTextblock) {
      afterText = afterText.firstChild!;
      afterDepth++;
    }
    if (at.canReplace(at.childCount, at.childCount, afterText.content)) {
      if (dispatch != null) {
        Fragment end = Fragment.empty;
        for (int i = wrap.length - 1; i >= 0; i--) {
          end = Fragment.from(wrap[i].copy(end));
        }
        final tr = state.tr;
        tr.step(ReplaceAroundStep($cut.pos - wrap.length, $cut.pos + after.nodeSize,
            $cut.pos + afterDepth, $cut.pos + after.nodeSize - afterDepth,
            Slice(end, wrap.length, 0), 0, true));
        dispatch(tr.scrollIntoView());
      }
      return true;
    }
  }

  return false;
}

Command selectTextblockSide(int side) {
  return (state, [dispatch, view]) {
    final sel = state.selection;
    ResolvedPos $pos = side < 0 ? sel.$from : sel.$to;
    int depth = $pos.depth;
    while ($pos.node(depth).isInline) {
      if (depth == 0) return false;
      depth--;
    }
    if (!$pos.node(depth).isTextblock) return false;
    if (dispatch != null) {
      final tr = state.tr;
      tr.setSelection(TextSelection.create(
          state.doc, side < 0 ? $pos.start(depth) : $pos.end(depth)));
      dispatch(tr);
    }
    return true;
  };
}

final Command selectTextblockStart = selectTextblockSide(-1);
final Command selectTextblockEnd = selectTextblockSide(1);

/// Wrap the selection in a node of the given type with the given attributes.
Command wrapIn(NodeType nodeType, [Map<String, dynamic>? attrs]) {
  return (state, [dispatch, view]) {
    final $from = state.selection.$from;
    final $to = state.selection.$to;
    final range = $from.blockRange($to);
    final List<Wrapping>? wrapping = range != null ? findWrapping(range, nodeType, attrs) : null;
    if (wrapping == null) return false;
    if (dispatch != null) {
      final tr = state.tr;
      tr.wrap(range!, wrapping);
      dispatch(tr.scrollIntoView());
    }
    return true;
  };
}

/// Returns a command that tries to set the selected textblocks to the
/// given node type with the given attributes.
Command setBlockType(NodeType nodeType, [Map<String, dynamic>? attrs]) {
  return (state, [dispatch, view]) {
    bool applicable = false;
    for (int i = 0; i < state.selection.ranges.length && !applicable; i++) {
      final from = state.selection.ranges[i].fromRes.pos;
      final to = state.selection.ranges[i].toRes.pos;
      state.doc.nodesBetween(from, to, (node, pos, parent, index) {
        if (applicable) return false;
        if (!node.isTextblock || node.hasMarkup(nodeType, attrs)) return true;
        if (node.type == nodeType) {
          applicable = true;
        } else {
          final $pos = state.doc.resolve(pos);
          final index = $pos.index();
          applicable = $pos.parent.canReplaceWith(index, index + 1, nodeType);
        }
        return true;
      });
    }
    if (!applicable) return false;
    if (dispatch != null) {
      final tr = state.tr;
      for (int i = 0; i < state.selection.ranges.length; i++) {
        final from = state.selection.ranges[i].fromRes.pos;
        final to = state.selection.ranges[i].toRes.pos;
        tr.setBlockType(from, to, nodeType, attrs);
      }
      dispatch(tr.scrollIntoView());
    }
    return true;
  };
}

bool markApplies(PMNode doc, List<SelectionRange> ranges, MarkType type, bool enterAtoms) {
  for (int i = 0; i < ranges.length; i++) {
    final $from = ranges[i].fromRes;
    final $to = ranges[i].toRes;
    bool can = $from.depth == 0 ? doc.inlineContent && doc.type.allowsMarkType(type) : false;
    doc.nodesBetween($from.pos, $to.pos, (node, pos, parent, index) {
      if (can || (!enterAtoms && node.isAtom && node.isInline && pos >= $from.pos && pos + node.nodeSize <= $to.pos)) {
        return false;
      }
      can = node.inlineContent && node.type.allowsMarkType(type);
      return true;
    });
    if (can) return true;
  }
  return false;
}

List<SelectionRange> removeInlineAtoms(List<SelectionRange> ranges) {
  final List<SelectionRange> result = [];
  for (int i = 0; i < ranges.length; i++) {
    ResolvedPos $from = ranges[i].fromRes;
    final ResolvedPos $to = ranges[i].toRes;
    $from.doc.nodesBetween($from.pos, $to.pos, (node, pos, parent, index) {
      if (node.isAtom && node.content.size > 0 && node.isInline && pos >= $from.pos && pos + node.nodeSize <= $to.pos) {
        if (pos + 1 > $from.pos) {
          result.add(SelectionRange($from, $from.doc.resolve(pos + 1)));
        }
        $from = $from.doc.resolve(pos + 1 + node.content.size);
        return false;
      }
      return true;
    });
    if ($from.pos < $to.pos) {
      result.add(SelectionRange($from, $to));
    }
  }
  return result;
}

/// Create a command function that toggles the given mark with the given attributes.
Command toggleMark(MarkType markType, [Map<String, dynamic>? attrs, Map<String, dynamic>? options]) {
  final removeWhenPresent = (options?['removeWhenPresent'] ?? true) as bool;
  final enterAtoms = (options?['enterInlineAtoms'] ?? true) as bool;
  final dropSpace = !(options?['includeWhitespace'] ?? false);
  return (state, [dispatch, view]) {
    final selection = state.selection;
    final empty = selection.empty;
    final $cursor = selection is TextSelection ? selection.$cursor : null;
    final ranges = selection.ranges;
    if ((empty && $cursor == null) || !markApplies(state.doc, ranges, markType, enterAtoms)) return false;
    if (dispatch != null) {
      if ($cursor != null) {
        final tr = state.tr;
        if (markType.isInSet(state.storedMarks ?? $cursor.marks()) != null) {
          tr.removeStoredMark(markType);
        } else {
          tr.addStoredMark(markType.create(attrs));
        }
        dispatch(tr);
      } else {
        bool add = true;
        List<SelectionRange> resolvedRanges = ranges;
        if (!enterAtoms) resolvedRanges = removeInlineAtoms(ranges);
        final tr = state.tr;
        if (removeWhenPresent) {
          add = !resolvedRanges.any((r) => state.doc.rangeHasMark(r.fromRes.pos, r.toRes.pos, markType));
        } else {
          add = !resolvedRanges.every((r) {
            bool missing = false;
            tr.doc.nodesBetween(r.fromRes.pos, r.toRes.pos, (node, pos, parent, index) {
              if (missing) return false;
              missing = markType.isInSet(node.marks) == null && parent != null && parent.type.allowsMarkType(markType) &&
                !(node.isText && node.text != null && RegExp(r'^\s*$').hasMatch(node.text!.substring(max(0, r.fromRes.pos - pos), min(node.nodeSize, r.toRes.pos - pos))));
              return true;
            });
            return !missing;
          });
        }
        for (int i = 0; i < resolvedRanges.length; i++) {
          final $from = resolvedRanges[i].fromRes;
          final $to = resolvedRanges[i].toRes;
          if (!add) {
            tr.removeMark($from.pos, $to.pos, markType);
          } else {
            int from = $from.pos;
            int to = $to.pos;
            final start = $from.nodeAfter;
            final end = $to.nodeBefore;
            final spaceStart = (dropSpace && start != null && start.isText) ? RegExp(r'^\s*').firstMatch(start.text!)![0]!.length : 0;
            final spaceEnd = (dropSpace && end != null && end.isText) ? RegExp(r'\s*$').firstMatch(end.text!)![0]!.length : 0;
            if (from + spaceStart < to) {
              from += spaceStart;
              to -= spaceEnd;
            }
            tr.addMark(from, to, markType.create(attrs));
          }
        }
        dispatch(tr.scrollIntoView());
      }
    }
    return true;
  };
}


void Function(Transaction tr) wrapDispatchForJoin(void Function(Transaction tr) dispatch, bool Function(PMNode a, PMNode b) isJoinable) {
  return (tr) {
    if (!tr.isGeneric) return dispatch(tr);

    final List<int> ranges = [];
    for (int i = 0; i < tr.mapping.maps.length; i++) {
      final map = tr.mapping.maps[i];
      for (int j = 0; j < ranges.length; j++) {
        ranges[j] = map.map(ranges[j]);
      }
      map.forEach((_s, _e, from, to) => ranges.addAll([from, to]));
    }

    final List<int> joinable = [];
    for (int i = 0; i < ranges.length; i += 2) {
      final from = ranges[i];
      final to = ranges[i + 1];
      final $from = tr.doc.resolve(from);
      final depth = $from.sharedDepth(to);
      final parent = $from.node(depth);
      int index = $from.indexAfter(depth);
      int pos = $from.after(depth + 1);
      for (; pos <= to; ++index) {
        final after = parent.maybeChild(index);
        if (after == null) break;
        if (index > 0 && !joinable.contains(pos)) {
          final before = parent.child(index - 1);
          if (before.type == after.type && isJoinable(before, after)) {
            joinable.add(pos);
          }
        }
        pos += after.nodeSize;
      }
    }
    joinable.sort((a, b) => a - b);
    for (int i = joinable.length - 1; i >= 0; i--) {
      if (canJoin(tr.doc, joinable[i])) tr.join(joinable[i]);
    }
    dispatch(tr);
  };
}

/// Wrap a command so that, when it produces a transform that causes
/// two joinable nodes to end up next to each other, those are joined.
Command autoJoin(Command command, dynamic isJoinable) {
  bool Function(PMNode a, PMNode b) canJoinPredicate;
  if (isJoinable is List<String>) {
    final list = isJoinable;
    canJoinPredicate = (a, b) => list.contains(a.type.name);
  } else {
    canJoinPredicate = isJoinable as bool Function(PMNode a, PMNode b);
  }
  return (state, [dispatch, view]) {
    return command(
      state,
      dispatch != null ? wrapDispatchForJoin(dispatch, canJoinPredicate) : null,
      view,
    );
  };
}

/// Combine a number of command functions into a single function (which
/// calls them one by one until one returns true).
Command chainCommands(List<Command> commands) {
  return (state, [dispatch, view]) {
    for (int i = 0; i < commands.length; i++) {
      if (commands[i](state, dispatch, view)) return true;
    }
    return false;
  };
}

final Command backspaceCommand = chainCommands([deleteSelection, joinBackward, selectNodeBackward]);
final Command deleteCommand = chainCommands([deleteSelection, joinForward, selectNodeForward]);

/// A basic keymap containing bindings not specific to any schema.
final Map<String, Command> pcBaseKeymap = {
  "Enter": chainCommands([newlineInCode, createParagraphNear, liftEmptyBlock, splitBlock]),
  "Mod-Enter": exitCode,
  "Backspace": backspaceCommand,
  "Mod-Backspace": backspaceCommand,
  "Shift-Backspace": backspaceCommand,
  "Delete": deleteCommand,
  "Mod-Delete": deleteCommand,
  "Mod-a": selectAll,
};

/// A copy of `pcBaseKeymap` that also binds Mac specific keys.
final Map<String, Command> macBaseKeymap = {
  "Ctrl-h": pcBaseKeymap["Backspace"]!,
  "Alt-Backspace": pcBaseKeymap["Mod-Backspace"]!,
  "Ctrl-d": pcBaseKeymap["Delete"]!,
  "Ctrl-Alt-Backspace": pcBaseKeymap["Mod-Delete"]!,
  "Alt-Delete": pcBaseKeymap["Mod-Delete"]!,
  "Alt-d": pcBaseKeymap["Mod-Delete"]!,
  "Ctrl-a": selectTextblockStart,
  "Ctrl-e": selectTextblockEnd,
  ...pcBaseKeymap,
};

/// Depending on the detected platform (via PlatformHelper.isMac), this holds
/// pcBaseKeymap or macBaseKeymap.
Map<String, Command> get baseKeymap => PlatformHelper.isMac ? macBaseKeymap : pcBaseKeymap;
