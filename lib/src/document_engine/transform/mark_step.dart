import 'dart:math';

import '../model/index.dart';
import 'step.dart';
import 'map.dart';

Fragment _mapFragment(Fragment fragment, PMNode Function(PMNode, PMNode, int) f, PMNode parent) {
  List<PMNode> mapped = [];
  for (int i = 0; i < fragment.childCount; i++) {
    PMNode child = fragment.child(i);
    if (child.content.size > 0) {
      child = child.copy(_mapFragment(child.content, f, child));
    }
    if (child.isInline) {
      child = f(child, parent, i);
    }
    mapped.add(child);
  }
  return Fragment.fromArray(mapped);
}

class AddMarkStep extends Step {
  final int from;
  final int to;
  final Mark mark;

  AddMarkStep(this.from, this.to, this.mark);

  @override
  StepResult apply(PMNode doc) {
    Slice oldSlice = doc.slice(from, to);
    ResolvedPos fromPos = doc.resolve(from);
    PMNode parent = fromPos.node(fromPos.sharedDepth(to));
    
    Slice slice = Slice(_mapFragment(oldSlice.content, (node, parentNode, i) {
      if (!node.isAtom || !parentNode.type.allowsMarkType(mark.type)) return node;
      return node.mark(mark.addToSet(node.marks));
    }, parent), oldSlice.openStart, oldSlice.openEnd);
    
    return StepResult.fromReplace(doc, from, to, slice);
  }

  @override
  Step invert(PMNode doc) {
    return RemoveMarkStep(from, to, mark);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult fromRes = mapping.mapResult(from, 1);
    MapResult toRes = mapping.mapResult(to, -1);
    if ((fromRes.deleted && toRes.deleted) || fromRes.pos >= toRes.pos) return null;
    return AddMarkStep(fromRes.pos, toRes.pos, mark);
  }

  @override
  Step? merge(Step other) {
    if (other is AddMarkStep && other.mark.eq(mark) && from <= other.to && to >= other.from) {
      return AddMarkStep(min(from, other.from), max(to, other.to), mark);
    }
    return null;
  }

  @override
  dynamic toJSON() {
    return {"stepType": "addMark", "mark": mark.toJSON(), "from": from, "to": to};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['from'] is! int || json['to'] is! int) {
      throw RangeError("Invalid input for AddMarkStep.fromJSON");
    }
    return AddMarkStep(json['from'], json['to'], schema.markFromJSON(json['mark']));
  }
}

class RemoveMarkStep extends Step {
  final int from;
  final int to;
  final Mark mark;

  RemoveMarkStep(this.from, this.to, this.mark);

  @override
  StepResult apply(PMNode doc) {
    Slice oldSlice = doc.slice(from, to);
    Slice slice = Slice(_mapFragment(oldSlice.content, (node, parentNode, i) {
      return node.mark(mark.removeFromSet(node.marks));
    }, doc), oldSlice.openStart, oldSlice.openEnd);
    return StepResult.fromReplace(doc, from, to, slice);
  }

  @override
  Step invert(PMNode doc) {
    return AddMarkStep(from, to, mark);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult fromRes = mapping.mapResult(from, 1);
    MapResult toRes = mapping.mapResult(to, -1);
    if ((fromRes.deleted && toRes.deleted) || fromRes.pos >= toRes.pos) return null;
    return RemoveMarkStep(fromRes.pos, toRes.pos, mark);
  }

  @override
  Step? merge(Step other) {
    if (other is RemoveMarkStep && other.mark.eq(mark) && from <= other.to && to >= other.from) {
      return RemoveMarkStep(min(from, other.from), max(to, other.to), mark);
    }
    return null;
  }

  @override
  dynamic toJSON() {
    return {"stepType": "removeMark", "mark": mark.toJSON(), "from": from, "to": to};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['from'] is! int || json['to'] is! int) {
      throw RangeError("Invalid input for RemoveMarkStep.fromJSON");
    }
    return RemoveMarkStep(json['from'], json['to'], schema.markFromJSON(json['mark']));
  }
}

class AddNodeMarkStep extends Step {
  final int pos;
  final Mark mark;

  AddNodeMarkStep(this.pos, this.mark);

  @override
  StepResult apply(PMNode doc) {
    PMNode? node = doc.nodeAt(pos);
    if (node == null) return StepResult.fail("No node at mark step's position");
    PMNode updated = node.type.create(node.attrs, null, mark.addToSet(node.marks));
    return StepResult.fromReplace(doc, pos, pos + 1, Slice(Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
  }

  @override
  Step invert(PMNode doc) {
    PMNode? node = doc.nodeAt(pos);
    if (node != null) {
      List<Mark> newSet = mark.addToSet(node.marks);
      if (newSet.length == node.marks.length) {
        for (int i = 0; i < node.marks.length; i++) {
          if (!node.marks[i].isInSet(newSet)) {
            return AddNodeMarkStep(pos, node.marks[i]);
          }
        }
        return AddNodeMarkStep(pos, mark);
      }
    }
    return RemoveNodeMarkStep(pos, mark);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult posRes = mapping.mapResult(pos, 1);
    return posRes.deletedAfter ? null : AddNodeMarkStep(posRes.pos, mark);
  }

  @override
  dynamic toJSON() {
    return {"stepType": "addNodeMark", "pos": pos, "mark": mark.toJSON()};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['pos'] is! int) {
      throw RangeError("Invalid input for AddNodeMarkStep.fromJSON");
    }
    return AddNodeMarkStep(json['pos'], schema.markFromJSON(json['mark']));
  }
}

class RemoveNodeMarkStep extends Step {
  final int pos;
  final Mark mark;

  RemoveNodeMarkStep(this.pos, this.mark);

  @override
  StepResult apply(PMNode doc) {
    PMNode? node = doc.nodeAt(pos);
    if (node == null) return StepResult.fail("No node at mark step's position");
    PMNode updated = node.type.create(node.attrs, null, mark.removeFromSet(node.marks));
    return StepResult.fromReplace(doc, pos, pos + 1, Slice(Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
  }

  @override
  Step invert(PMNode doc) {
    PMNode? node = doc.nodeAt(pos);
    if (node == null || !mark.isInSet(node.marks)) return this;
    return AddNodeMarkStep(pos, mark);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult posRes = mapping.mapResult(pos, 1);
    return posRes.deletedAfter ? null : RemoveNodeMarkStep(posRes.pos, mark);
  }

  @override
  dynamic toJSON() {
    return {"stepType": "removeNodeMark", "pos": pos, "mark": mark.toJSON()};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['pos'] is! int) {
      throw RangeError("Invalid input for RemoveNodeMarkStep.fromJSON");
    }
    return RemoveNodeMarkStep(json['pos'], schema.markFromJSON(json['mark']));
  }
}

void registerMarkSteps() {
  Step.jsonID("addMark", AddMarkStep.fromJSON);
  Step.jsonID("removeMark", RemoveMarkStep.fromJSON);
  Step.jsonID("addNodeMark", AddNodeMarkStep.fromJSON);
  Step.jsonID("removeNodeMark", RemoveNodeMarkStep.fromJSON);
}
