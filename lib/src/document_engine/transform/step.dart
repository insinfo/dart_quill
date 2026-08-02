import '../model/index.dart';
import 'map.dart';

final Map<String, Step Function(Schema, dynamic)> stepsByID = {};

abstract class Step {
  StepResult apply(PMNode doc);
  
  StepMap getMap() => StepMap.empty;
  
  Step invert(PMNode doc);
  
  Step? map(Mappable mapping);
  
  Step? merge(Step other) => null;
  
  dynamic toJSON();
  
  static Step fromJSON(Schema schema, dynamic json) {
    if (json == null || json['stepType'] == null) {
      throw RangeError("Invalid input for Step.fromJSON");
    }
    var type = stepsByID[json['stepType']];
    if (type == null) {
      print("AVAILABLE KEYS IN stepsByID: ${stepsByID.keys.toList()}");
      print("REQUESTED KEY: '${json['stepType']}' (length: ${json['stepType'].toString().length})");
      throw RangeError("No step type ${json['stepType']} defined");
    }
    return type(schema, json);
  }

  static void jsonID(String id, Step Function(Schema, dynamic) stepClass) {
    if (stepsByID.containsKey(id)) {
      throw RangeError("Duplicate use of step JSON ID $id");
    }
    stepsByID[id] = stepClass;
  }
}

class StepResult {
  final PMNode? doc;
  final String? failed;

  StepResult(this.doc, this.failed);

  static StepResult ok(PMNode doc) => StepResult(doc, null);
  
  static StepResult fail(String message) => StepResult(null, message);
  
  static StepResult fromReplace(PMNode doc, int from, int to, Slice slice) {
    try {
      return StepResult.ok(doc.replace(from, to, slice));
    } catch (e) {
      if (e is ReplaceError) return StepResult.fail(e.message);
      rethrow;
    }
  }
}
