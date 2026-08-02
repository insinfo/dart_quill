import '../model/index.dart';
import 'step.dart';
import 'transform.dart';
import 'mark_step.dart';
import 'replace_step.dart';
import 'dart:math';

void addMark(Transform tr, int from, int to, Mark mark) {
  List<Step> removed = [];
  List<Step> added = [];
  RemoveMarkStep? removing;
  AddMarkStep? adding;

  tr.doc.nodesBetween(from, to, (node, pos, parent, index) {
    if (!node.isInline) return true;
    List<Mark> marks = node.marks;
    if (!mark.isInSet(marks) && parent!.type.allowsMarkType(mark.type)) {
      int start = max(pos, from);
      int end = min(pos + node.nodeSize, to);
      List<Mark> newSet = mark.addToSet(marks);

      for (int i = 0; i < marks.length; i++) {
        if (!marks[i].isInSet(newSet)) {
          if (removing != null && removing!.to == start && removing!.mark.eq(marks[i])) {
            removing = RemoveMarkStep(removing!.from, end, removing!.mark);
            removed[removed.length - 1] = removing!;
          } else {
            removing = RemoveMarkStep(start, end, marks[i]);
            removed.add(removing!);
          }
        }
      }

      if (adding != null && adding!.to == start) {
        adding = AddMarkStep(adding!.from, end, adding!.mark);
        added[added.length - 1] = adding!;
      } else {
        adding = AddMarkStep(start, end, mark);
        added.add(adding!);
      }
    }
    return true;
  });

  for (var s in removed) {
    tr.step(s);
  }
  for (var s in added) {
    tr.step(s);
  }
}

class _MatchedMark {
  final Mark style;
  final int from;
  int to;
  int step;
  _MatchedMark(this.style, this.from, this.to, this.step);
}

void removeMark(Transform tr, int from, int to, [dynamic mark]) {
  List<_MatchedMark> matched = [];
  int step = 0;
  
  tr.doc.nodesBetween(from, to, (node, pos, parent, index) {
    if (!node.isInline) return true;
    step++;
    List<Mark>? toRemove;
    
    if (mark is MarkType) {
      List<Mark> set = node.marks;
      Mark? found;
      while ((found = mark.isInSet(set)) != null) {
        toRemove ??= [];
        toRemove.add(found!);
        set = found.removeFromSet(set);
      }
    } else if (mark is Mark) {
      if (mark.isInSet(node.marks)) {
        toRemove = [mark];
      }
    } else if (mark == null) {
      toRemove = List.from(node.marks);
    }
    
    if (toRemove != null && toRemove.isNotEmpty) {
      int end = min(pos + node.nodeSize, to);
      for (int i = 0; i < toRemove.length; i++) {
        Mark style = toRemove[i];
        _MatchedMark? found;
        for (int j = 0; j < matched.length; j++) {
          _MatchedMark m = matched[j];
          if (m.step == step - 1 && style.eq(m.style)) {
            found = m;
            break;
          }
        }
        if (found != null) {
          found.to = end;
          found.step = step;
        } else {
          matched.add(_MatchedMark(style, max(pos, from), end, step));
        }
      }
    }
    return true;
  });
  
  for (var m in matched) {
    tr.step(RemoveMarkStep(m.from, m.to, m.style));
  }
}

void clearIncompatible(Transform tr, int pos, NodeType parentType, [ContentMatch? match, bool clearNewlines = true]) {
  match ??= parentType.contentMatch;
  PMNode node = tr.doc.nodeAt(pos)!;
  List<Step> replSteps = [];
  int cur = pos + 1;
  
  for (int i = 0; i < node.childCount; i++) {
    PMNode child = node.child(i);
    int end = cur + child.nodeSize;
    ContentMatch? allowed = match!.matchType(child.type);
    
    if (allowed == null) {
      replSteps.add(ReplaceStep(cur, end, Slice.empty));
    } else {
      match = allowed;
      for (int j = 0; j < child.marks.length; j++) {
        if (!parentType.allowsMarkType(child.marks[j].type)) {
          tr.step(RemoveMarkStep(cur, end, child.marks[j]));
        }
      }

      if (clearNewlines && child.isText && parentType.whitespace != "pre") {
        RegExp newline = RegExp(r'\r?\n|\r');
        Iterable<Match> matches = newline.allMatches(child.text!);
        Slice? slice;
        for (Match m in matches) {
          if (slice == null) {
            slice = Slice(Fragment.from(parentType.schema.text(" ", parentType.allowedMarks(child.marks))), 0, 0);
          }
          replSteps.add(ReplaceStep(cur + m.start, cur + m.start + m.group(0)!.length, slice));
        }
      }
    }
    cur = end;
  }
  
  if (!match!.validEnd) {
    Fragment? fill = match.fillBefore(Fragment.empty, true);
    tr.replace(cur, cur, Slice(fill!, 0, 0));
  }
  
  for (int i = replSteps.length - 1; i >= 0; i--) {
    tr.step(replSteps[i]);
  }
}
