import 'package:dart_quill/src/core/instances.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  test('instances are keyed weakly and can be unregistered', () {
    final node = testAdapter.document.createElement('div');
    final value = Object();

    quillInstances.register(node, value);
    expect(quillInstances.get<Object>(node), same(value));
    expect(quillInstances.get<String>(node), isNull);

    quillInstances.unregister(node);
    expect(quillInstances.get<Object>(node), isNull);
  });
}
