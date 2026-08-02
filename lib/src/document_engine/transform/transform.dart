import 'dart:math';

import '../model/index.dart';
import 'map.dart';
import 'step.dart';
import 'mark.dart' as mark_lib;
import 'replace.dart' as replace_lib;
import 'structure.dart' as structure_lib;
import 'attr_step.dart';
import 'mark_step.dart';

class TransformError extends Error {
  final String message;
  TransformError(this.message);

  @override
  String toString() => "TransformError: $message";
}

class Transform {
  final List<Step> steps = [];
  final List<PMNode> docs = [];
  final Mapping mapping = Mapping();
  PMNode doc;

  Transform(this.doc);

  PMNode get before => docs.isNotEmpty ? docs[0] : doc;

  Transform step(Step stepObj) {
    StepResult result = maybeStep(stepObj);
    if (result.failed != null) throw TransformError(result.failed!);
    return this;
  }

  StepResult maybeStep(Step stepObj) {
    StepResult result = stepObj.apply(doc);
    if (result.failed == null) addStep(stepObj, result.doc!);
    return result;
  }

  bool get docChanged => steps.isNotEmpty;

  Map<String, int>? changedRange() {
    int from = 1000000000;
    int to = -1000000000;
    for (int i = 0; i < mapping.maps.length; i++) {
      StepMap map = mapping.maps[i];
      if (i > 0) {
        from = map.map(from, 1);
        to = map.map(to, -1);
      }
      map.forEach((oldStart, oldEnd, newStart, newEnd) {
        from = min(from, newStart);
        to = max(to, newEnd);
      });
    }
    return from == 1000000000 ? null : {"from": from, "to": to};
  }

  void addStep(Step stepObj, PMNode newDoc) {
    docs.add(doc);
    steps.add(stepObj);
    mapping.appendMap(stepObj.getMap());
    doc = newDoc;
  }

  Transform replace(int from, [int? to, Slice? slice]) {
    to ??= from;
    slice ??= Slice.empty;
    Step? stepObj = replace_lib.replaceStep(doc, from, to, slice);
    if (stepObj != null) step(stepObj);
    return this;
  }

  Transform replaceWith(int from, int to, dynamic content) {
    Fragment fragment;
    if (content is Fragment) {
      fragment = content;
    } else if (content is PMNode) {
      fragment = Fragment.from(content);
    } else if (content is List<PMNode>) {
      fragment = Fragment.fromArray(content);
    } else {
      throw ArgumentError("Invalid content for replaceWith");
    }
    return replace(from, to, Slice(fragment, 0, 0));
  }

  Transform delete(int from, int to) {
    return replace(from, to, Slice.empty);
  }

  Transform insert(int pos, dynamic content) {
    return replaceWith(pos, pos, content);
  }

  Transform replaceRange(int from, int to, Slice slice) {
    replace_lib.replaceRange(this, from, to, slice);
    return this;
  }

  Transform replaceRangeWith(int from, int to, PMNode node) {
    replace_lib.replaceRangeWith(this, from, to, node);
    return this;
  }

  Transform deleteRange(int from, int to) {
    replace_lib.deleteRange(this, from, to);
    return this;
  }

  Transform lift(NodeRange range, int target) {
    structure_lib.lift(this, range, target);
    return this;
  }

  Transform join(int pos, [int depth = 1]) {
    structure_lib.join(this, pos, depth);
    return this;
  }

  Transform wrap(NodeRange range, List<structure_lib.Wrapping> wrappers) {
    structure_lib.wrap(this, range, wrappers);
    return this;
  }

  Transform setBlockType(int from, [int? to, NodeType? type, dynamic attrs]) {
    to ??= from;
    if (type != null) structure_lib.setBlockType(this, from, to, type, attrs);
    return this;
  }

  Transform setNodeMarkup(int pos, [NodeType? type, Map<String, dynamic>? attrs, List<Mark>? marks]) {
    structure_lib.setNodeMarkup(this, pos, type, attrs, marks);
    return this;
  }

  Transform setNodeAttribute(int pos, String attr, dynamic value) {
    step(AttrStep(pos, attr, value));
    return this;
  }

  Transform setDocAttribute(String attr, dynamic value) {
    step(DocAttrStep(attr, value));
    return this;
  }

  Transform addNodeMark(int pos, Mark mark) {
    step(AddNodeMarkStep(pos, mark));
    return this;
  }

  Transform removeNodeMark(int pos, dynamic mark) {
    PMNode? node = doc.nodeAt(pos);
    if (node == null) throw RangeError("No node at position \$pos");
    
    if (mark is Mark) {
      if (mark.isInSet(node.marks)) step(RemoveNodeMarkStep(pos, mark));
    } else if (mark is MarkType) {
      List<Mark> set = node.marks;
      Mark? found;
      List<Step> removeSteps = [];
      while ((found = mark.isInSet(set)) != null) {
        removeSteps.add(RemoveNodeMarkStep(pos, found!));
        set = found.removeFromSet(set);
      }
      for (int i = removeSteps.length - 1; i >= 0; i--) {
        step(removeSteps[i]);
      }
    }
    return this;
  }

  Transform split(int pos, [int depth = 1, List<structure_lib.Wrapping?>? typesAfter]) {
    structure_lib.split(this, pos, depth, typesAfter);
    return this;
  }

  Transform addMark(int from, int to, Mark mark) {
    mark_lib.addMark(this, from, to, mark);
    return this;
  }

  Transform removeMark(int from, int to, [dynamic mark]) {
    mark_lib.removeMark(this, from, to, mark);
    return this;
  }

  Transform clearIncompatible(int pos, NodeType parentType, [ContentMatch? match]) {
    mark_lib.clearIncompatible(this, pos, parentType, match);
    return this;
  }
}
