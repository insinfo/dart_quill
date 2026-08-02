import 'dart:math';

import '../model/index.dart';
import 'step.dart';
import 'map.dart';

class ReplaceStep extends Step {
  final int from;
  final int to;
  final Slice slice;
  final bool structure;

  ReplaceStep(this.from, this.to, this.slice, [this.structure = false]);

  @override
  StepResult apply(PMNode doc) {
    if (structure && _contentBetween(doc, from, to)) {
      return StepResult.fail("Structure replace would overwrite content");
    }
    return StepResult.fromReplace(doc, from, to, slice);
  }

  @override
  StepMap getMap() {
    return StepMap([from, to - from, slice.size]);
  }

  @override
  Step invert(PMNode doc) {
    return ReplaceStep(from, from + slice.size, doc.slice(from, to));
  }

  @override
  Step? map(Mappable mapping) {
    MapResult toRes = mapping.mapResult(to, -1);
    MapResult fromRes = (from == to && MAP_BIAS < 0) ? toRes : mapping.mapResult(from, 1);
    if (fromRes.deletedAcross && toRes.deletedAcross) return null;
    return ReplaceStep(fromRes.pos, max(fromRes.pos, toRes.pos), slice, structure);
  }

  @override
  Step? merge(Step other) {
    if (other is! ReplaceStep || other.structure || structure) return null;

    if (from + slice.size == other.from && slice.openEnd == 0 && other.slice.openStart == 0) {
      Slice mergedSlice = (slice.size + other.slice.size == 0)
          ? Slice.empty
          : Slice(slice.content.append(other.slice.content), slice.openStart, other.slice.openEnd);
      return ReplaceStep(from, to + (other.to - other.from), mergedSlice, structure);
    } else if (other.to == from && slice.openStart == 0 && other.slice.openEnd == 0) {
      Slice mergedSlice = (slice.size + other.slice.size == 0)
          ? Slice.empty
          : Slice(other.slice.content.append(slice.content), other.slice.openStart, slice.openEnd);
      return ReplaceStep(other.from, to, mergedSlice, structure);
    } else {
      return null;
    }
  }

  @override
  dynamic toJSON() {
    Map<String, dynamic> json = {"stepType": "replace", "from": from, "to": to};
    if (slice.size > 0) json["slice"] = slice.toJSON();
    if (structure) json["structure"] = true;
    return json;
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['from'] is! int || json['to'] is! int) {
      throw RangeError("Invalid input for ReplaceStep.fromJSON");
    }
    return ReplaceStep(
        json['from'], json['to'], Slice.fromJSON(schema, json['slice']), json['structure'] == true);
  }

  static int MAP_BIAS = 1;
}

class ReplaceAroundStep extends Step {
  final int from;
  final int to;
  final int gapFrom;
  final int gapTo;
  final Slice slice;
  final int insert;
  final bool structure;

  ReplaceAroundStep(this.from, this.to, this.gapFrom, this.gapTo, this.slice, this.insert,
      [this.structure = false]);

  @override
  StepResult apply(PMNode doc) {
    if (structure &&
        (_contentBetween(doc, from, gapFrom) || _contentBetween(doc, gapTo, to))) {
      return StepResult.fail("Structure gap-replace would overwrite content");
    }

    Slice gap = doc.slice(gapFrom, gapTo);
    if (gap.openStart > 0 || gap.openEnd > 0) {
      return StepResult.fail("Gap is not a flat range");
    }
    Slice? inserted = slice.insertAt(insert, gap.content);
    if (inserted == null) return StepResult.fail("Content does not fit in gap");
    return StepResult.fromReplace(doc, from, to, inserted);
  }

  @override
  StepMap getMap() {
    return StepMap([
      from, gapFrom - from, insert,
      gapTo, to - gapTo, slice.size - insert
    ]);
  }

  @override
  Step invert(PMNode doc) {
    int gap = gapTo - gapFrom;
    return ReplaceAroundStep(
        from,
        from + slice.size + gap,
        from + insert,
        from + insert + gap,
        doc.slice(from, to).removeBetween(gapFrom - from, gapTo - from),
        gapFrom - from,
        structure);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult fromRes = mapping.mapResult(from, 1);
    MapResult toRes = mapping.mapResult(to, -1);
    int gapFromMap = from == gapFrom ? fromRes.pos : mapping.map(gapFrom, -1);
    int gapToMap = to == gapTo ? toRes.pos : mapping.map(gapTo, 1);
    
    if ((fromRes.deletedAcross && toRes.deletedAcross) || gapFromMap < fromRes.pos || gapToMap > toRes.pos) {
      return null;
    }
    return ReplaceAroundStep(fromRes.pos, toRes.pos, gapFromMap, gapToMap, slice, insert, structure);
  }

  @override
  dynamic toJSON() {
    Map<String, dynamic> json = {
      "stepType": "replaceAround",
      "from": from,
      "to": to,
      "gapFrom": gapFrom,
      "gapTo": gapTo,
      "insert": insert
    };
    if (slice.size > 0) json["slice"] = slice.toJSON();
    if (structure) json["structure"] = true;
    return json;
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['from'] is! int ||
        json['to'] is! int ||
        json['gapFrom'] is! int ||
        json['gapTo'] is! int ||
        json['insert'] is! int) {
      throw RangeError("Invalid input for ReplaceAroundStep.fromJSON");
    }
    return ReplaceAroundStep(json['from'], json['to'], json['gapFrom'], json['gapTo'],
        Slice.fromJSON(schema, json['slice']), json['insert'], json['structure'] == true);
  }
}

bool _contentBetween(PMNode doc, int from, int to) {
  ResolvedPos fromPos = doc.resolve(from);
  int dist = to - from;
  int depth = fromPos.depth;
  
  while (dist > 0 && depth > 0 && fromPos.indexAfter(depth) == fromPos.node(depth).childCount) {
    depth--;
    dist--;
  }
  
  if (dist > 0) {
    PMNode? next = fromPos.node(depth).maybeChild(fromPos.indexAfter(depth));
    while (dist > 0) {
      if (next == null || next.isLeaf) return true;
      next = next.firstChild;
      dist--;
    }
  }
  return false;
}

void registerReplaceSteps() {
  Step.jsonID("replace", ReplaceStep.fromJSON);
  Step.jsonID("replaceAround", ReplaceAroundStep.fromJSON);
}
