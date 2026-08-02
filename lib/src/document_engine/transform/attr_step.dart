import '../model/index.dart';
import 'step.dart';
import 'map.dart';

class AttrStep extends Step {
  final int pos;
  final String attr;
  final dynamic value;

  AttrStep(this.pos, this.attr, this.value);

  @override
  StepResult apply(PMNode doc) {
    PMNode? node = doc.nodeAt(pos);
    if (node == null) return StepResult.fail("No node at attribute step's position");
    Map<String, dynamic> attrs = Map.from(node.attrs);
    attrs[attr] = value;
    PMNode updated = node.type.create(attrs, null, node.marks);
    return StepResult.fromReplace(doc, pos, pos + 1, Slice(Fragment.from(updated), 0, node.isLeaf ? 0 : 1));
  }

  @override
  StepMap getMap() {
    return StepMap.empty;
  }

  @override
  Step invert(PMNode doc) {
    return AttrStep(pos, attr, doc.nodeAt(pos)!.attrs[attr]);
  }

  @override
  Step? map(Mappable mapping) {
    MapResult posRes = mapping.mapResult(pos, 1);
    return posRes.deletedAfter ? null : AttrStep(posRes.pos, attr, value);
  }

  @override
  dynamic toJSON() {
    return {"stepType": "attr", "pos": pos, "attr": attr, "value": value};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['pos'] is! int || json['attr'] is! String) {
      throw RangeError("Invalid input for AttrStep.fromJSON");
    }
    return AttrStep(json['pos'], json['attr'], json['value']);
  }
}

class DocAttrStep extends Step {
  final String attr;
  final dynamic value;

  DocAttrStep(this.attr, this.value);

  @override
  StepResult apply(PMNode doc) {
    Map<String, dynamic> attrs = Map.from(doc.attrs);
    attrs[attr] = value;
    PMNode updated = doc.type.create(attrs, doc.content, doc.marks);
    return StepResult.ok(updated);
  }

  @override
  StepMap getMap() {
    return StepMap.empty;
  }

  @override
  Step invert(PMNode doc) {
    return DocAttrStep(attr, doc.attrs[attr]);
  }

  @override
  Step? map(Mappable mapping) {
    return this;
  }

  @override
  dynamic toJSON() {
    return {"stepType": "docAttr", "attr": attr, "value": value};
  }

  static Step fromJSON(Schema schema, dynamic json) {
    if (json['attr'] is! String) {
      throw RangeError("Invalid input for DocAttrStep.fromJSON");
    }
    return DocAttrStep(json['attr'], json['value']);
  }
}

void registerAttrSteps() {
  Step.jsonID("attr", AttrStep.fromJSON);
  Step.jsonID("docAttr", DocAttrStep.fromJSON);
}
