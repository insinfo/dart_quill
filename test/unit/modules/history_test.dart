import 'dart:async';

import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/history.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

class _HistorySetup {
  _HistorySetup(this.quill, this.original);

  final Quill quill;
  final Delta original;
}

_HistorySetup _setupHistory({Map<String, dynamic>? overrides}) {
  final historyConfig = <String, dynamic>{'delay': 400};
  if (overrides != null) {
    historyConfig.addAll(overrides);
  }
  final quill = createTestQuill(
    initialHtml: '<p>The lazy fox</p>',
    modules: {'history': historyConfig},
  );
  final original = Delta.from(quill.getContents());
  return _HistorySetup(quill, original);
}

Future<void> _sleep(int milliseconds) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  group('History', () {
    group('getLastChangeIndex', () {
      late Quill quill;

      setUp(() {
        quill = createTestQuill();
      });

      test('delete', () {
        final delta = Delta()
          ..retain(4)
          ..delete(2);
        expect(getLastChangeIndex(quill.scroll, delta), equals(4));
      });

      test('delete with inserts', () {
        final delta = Delta()
          ..retain(4)
          ..insert('test')
          ..delete(2);
        expect(getLastChangeIndex(quill.scroll, delta), equals(8));
      });

      test('insert text', () {
        final delta = Delta()
          ..retain(4)
          ..insert('testing');
        expect(getLastChangeIndex(quill.scroll, delta), equals(11));
      });

      test('insert embed', () {
        final delta = Delta()
          ..retain(4)
          ..insert({'image': true});
        expect(getLastChangeIndex(quill.scroll, delta), equals(5));
      });

      test('insert with deletes', () {
        final delta = Delta()
          ..retain(4)
          ..delete(3)
          ..insert('!');
        expect(getLastChangeIndex(quill.scroll, delta), equals(5));
      });

      test('format', () {
        final delta = Delta()
          ..retain(4)
          ..retain(3, {'bold': true});
        expect(getLastChangeIndex(quill.scroll, delta), equals(7));
      });

      test('format newline', () {
        final delta = Delta()
          ..retain(4)
          ..retain(1, {'align': 'left'});
        expect(getLastChangeIndex(quill.scroll, delta), equals(4));
      });

      test('format mixed', () {
        final delta = Delta()
          ..retain(4)
          ..retain(1, {'align': 'left', 'bold': true});
        expect(getLastChangeIndex(quill.scroll, delta), equals(4));
      });

      test('insert newline', () {
        final delta = Delta()
          ..retain(4)
          ..insert('a\n');
        expect(getLastChangeIndex(quill.scroll, delta), equals(5));
      });

      test('multiple newline inserts', () {
        final delta = Delta()
          ..retain(4)
          ..insert('ab\n\n');
        expect(getLastChangeIndex(quill.scroll, delta), equals(7));
      });
    });

    group('undo/redo', () {
      test('limits undo stack size', () {
        final setup = _setupHistory(overrides: {'delay': 0, 'maxStack': 2});
        final quill = setup.quill;
        for (final text in ['A', 'B', 'C']) {
          quill.insertText(0, text, source: EmitterSource.USER);
        }
        expect(quill.history.stack.undo.length, equals(2));
      });

      test('emits selection changes', () {
        final setup = _setupHistory(overrides: {'delay': 0});
        final quill = setup.quill;
        quill.insertText(0, 'foo', source: EmitterSource.USER);
        final events = <List<dynamic>>[];
        quill.on(
          EmitterEvents.SELECTION_CHANGE,
          (dynamic range, dynamic oldRange, dynamic source) {
            events.add([range, oldRange, source]);
          },
        );
        quill.history.undo();
        expect(events.length, equals(1));
        expect(events.first[0], isA<Range>());
        expect(events.first[1], isNull);
        expect(events.first[2], equals(EmitterSource.USER));
      });

      test('user change', () {
        final setup = _setupHistory(overrides: {'delay': 0});
        final quill = setup.quill;
        final original = setup.original;
        quill.updateContents(
          Delta()
            ..retain(12)
            ..insert('es'),
          source: EmitterSource.USER,
        );
        final changed = Delta.from(quill.getContents());
        expect(changed, isNot(equals(original)));
        quill.history.undo();
        expectDelta(quill.getContents(), original);
        quill.history.redo();
        expectDelta(quill.getContents(), changed);
      });

      test('merge changes', () {
        final setup = _setupHistory();
        final quill = setup.quill;
        final original = setup.original;
        expect(quill.history.stack.undo.length, equals(0));
        quill.updateContents(
          Delta()
            ..retain(12)
            ..insert('e'),
          source: EmitterSource.USER,
        );
        expect(quill.history.stack.undo.length, equals(1));
        quill.updateContents(
          Delta()
            ..retain(13)
            ..insert('s'),
          source: EmitterSource.USER,
        );
        expect(quill.history.stack.undo.length, equals(1));
        quill.history.undo();
        expectDelta(quill.getContents(), original);
        expect(quill.history.stack.undo.length, equals(0));
      });

      test('dont merge changes', () async {
        final setup = _setupHistory();
        final quill = setup.quill;
        expect(quill.history.stack.undo.length, equals(0));
        quill.updateContents(
          Delta()
            ..retain(12)
            ..insert('e'),
          source: EmitterSource.USER,
        );
        expect(quill.history.stack.undo.length, equals(1));
        final delay = (quill.history.options.delay * 1.25).ceil();
        await _sleep(delay);
        quill.updateContents(
          Delta()
            ..retain(13)
            ..insert('s'),
          source: EmitterSource.USER,
        );
        expect(quill.history.stack.undo.length, equals(2));
      });

      test('multiple undos', () async {
        final setup = _setupHistory();
        final quill = setup.quill;
        final original = setup.original;
        expect(quill.history.stack.undo.length, equals(0));
        quill.updateContents(
          Delta()
            ..retain(12)
            ..insert('e'),
          source: EmitterSource.USER,
        );
        final contents = Delta.from(quill.getContents());
        final delay = (quill.history.options.delay * 1.25).ceil();
        await _sleep(delay);
        quill.updateContents(
          Delta()
            ..retain(13)
            ..insert('s'),
          source: EmitterSource.USER,
        );
        quill.history.undo();
        expectDelta(quill.getContents(), contents);
        quill.history.undo();
        expectDelta(quill.getContents(), original);
      });

      test('transform api change', () {
        final setup = _setupHistory();
        final quill = setup.quill;
        quill.history.options.userOnly = true;
        quill.updateContents(
          Delta()
            ..retain(12)
            ..insert('es'),
          source: EmitterSource.USER,
        );
        quill.history.lastRecorded = 0;
        quill.updateContents(
          Delta()
            ..retain(14)
            ..insert('!'),
          source: EmitterSource.USER,
        );
        quill.history.undo();
        quill.updateContents(
          Delta()
            ..retain(4)
            ..delete(5),
          source: EmitterSource.API,
        );
        expectDelta(
          quill.getContents(),
          Delta()..insert('The foxes\n'),
        );
        quill.history.undo();
        expectDelta(
          quill.getContents(),
          Delta()..insert('The fox\n'),
        );
        quill.history.redo();
        expectDelta(
          quill.getContents(),
          Delta()..insert('The foxes\n'),
        );
        quill.history.redo();
        expectDelta(
          quill.getContents(),
          Delta()..insert('The foxes!\n'),
        );
      });

      test('transform preserve intention', () {
        final setup = _setupHistory(overrides: {'userOnly': true});
        final quill = setup.quill;
        final url = 'https://www.google.com/';
        quill.updateContents(
          Delta()..insert(url, {'link': url}),
          source: EmitterSource.USER,
        );
        quill.history.lastRecorded = 0;
        quill.updateContents(
          Delta()
            ..delete(url.length)
            ..insert('Google', {'link': url}),
          source: EmitterSource.API,
        );
        quill.history.lastRecorded = 0;
        final insertionIndex = quill.getText().length - 1;
        quill.updateContents(
          Delta()
            ..retain(insertionIndex)
            ..insert('!'),
          source: EmitterSource.USER,
        );
        quill.history.lastRecorded = 0;
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('Google', {'link': url})
            ..insert('The lazy fox!\n'),
        );
        quill.history.undo();
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('Google', {'link': url})
            ..insert('The lazy fox\n'),
        );
        quill.history.undo();
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('Google', {'link': url})
            ..insert('The lazy fox\n'),
        );
      });

      test('ignore remote changes', () {
        final setup = _setupHistory();
        final quill = setup.quill;
        quill.history.options.delay = 0;
        quill.history.options.userOnly = true;
        quill.setContents(Delta()..insert('\n'));
        quill.insertText(0, 'a', source: EmitterSource.USER);
        quill.insertText(1, 'b', source: EmitterSource.API);
        quill.insertText(2, 'c', source: EmitterSource.USER);
        quill.insertText(3, 'd', source: EmitterSource.API);
        expect(quill.getText(), equals('abcd\n'));
        quill.history.undo();
        expect(quill.getText(), equals('abd\n'));
        quill.history.undo();
        expect(quill.getText(), equals('bd\n'));
        quill.history.redo();
        expect(quill.getText(), equals('abd\n'));
        quill.history.redo();
        expect(quill.getText(), equals('abcd\n'));
      });

      test('correctly transform against remote changes', () {
        final setup = _setupHistory(overrides: {'delay': 0, 'userOnly': true});
        final quill = setup.quill;
        quill.setContents(Delta()..insert('b\n'));
        quill.insertText(1, 'd', source: EmitterSource.USER);
        quill.insertText(0, 'a', source: EmitterSource.USER);
        quill.insertText(2, 'c', source: EmitterSource.API);
        expect(quill.getText(), equals('abcd\n'));
        quill.history.undo();
        expect(quill.getText(), equals('bcd\n'));
        quill.history.undo();
        expect(quill.getText(), equals('bc\n'));
        quill.history.redo();
        expect(quill.getText(), equals('bcd\n'));
        quill.history.redo();
        expect(quill.getText(), equals('abcd\n'));
      });

      test('correctly transform against remote changes breaking up an insert',
          () {
        final setup = _setupHistory(overrides: {'delay': 0, 'userOnly': true});
        final quill = setup.quill;
        quill.setContents(Delta()..insert('\n'));
        quill.insertText(0, 'ABC', source: EmitterSource.USER);
        quill.insertText(3, '4', source: EmitterSource.API);
        quill.insertText(2, '3', source: EmitterSource.API);
        quill.insertText(1, '2', source: EmitterSource.API);
        quill.insertText(0, '1', source: EmitterSource.API);
        expect(quill.getText(), equals('1A2B3C4\n'));
        quill.history.undo();
        expect(quill.getText(), equals('1234\n'));
        quill.history.redo();
        expect(quill.getText(), equals('1A2B3C4\n'));
        quill.history.undo();
        expect(quill.getText(), equals('1234\n'));
        quill.history.redo();
        expect(quill.getText(), equals('1A2B3C4\n'));
      });
    });
  });
}
