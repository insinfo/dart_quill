import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  group('Emitter', () {
    test('emit and on', () {
      final emitter = Emitter();
      dynamic received;
      emitter.on('abc', (dynamic data) {
        received = data;
      });

      emitter.emit('abc', {'hello': 'world'});

      expect(received, equals({'hello': 'world'}));
    });

    test('listenDOM', () {
      final quill = createTestQuill();
      final body = testAdapter.document.body;
      var calls = 0;

      quill.emitter.listenDOM('click', body, (DomEvent event) {
        calls += 1;
      });

      void dispatchClick() {
        final event = FakeDomEvent('click', body);
        if (body.contains(quill.container)) {
          quill.emitter.handleDOM('click', event);
        }
      }

      dispatchClick();
      expect(calls, equals(1));

      quill.container.remove();
      dispatchClick();
      expect(calls, equals(1));

      body.append(quill.container);
      dispatchClick();
      expect(calls, equals(2));
    });
  });
}
