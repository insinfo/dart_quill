import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/core/quill.spec.ts`.
///
/// Not ported, with reason:
/// * `expandConfig` / `overload` / the `registry` and `formats` options — the
///   port has no `expandConfig`, and `overload` exists to emulate JavaScript
///   argument overloading, which Dart expresses with named parameters;
/// * `scrollSelectionIntoView` — needs layout, covered in
///   `test/browser/scroll_selection_into_view_test.dart`;
/// * `events > user text insert` — needs a MutationObserver, covered in
///   `test/browser/model_reconcile_test.dart`.

/// Records the TEXT_CHANGE payloads, which is what the spec asserts through
/// its emitter spy.
class _TextChanges {
  final List<({Delta change, Delta old, String source})> events = [];

  void listen(Quill quill) {
    quill.on(EmitterEvents.TEXT_CHANGE,
        (dynamic change, dynamic old, dynamic source) {
      events.add((
        change: change as Delta,
        old: old as Delta,
        source: source as String,
      ));
    });
  }

  void expectLast(Delta change, Delta old, String source) {
    expect(events, isNotEmpty, reason: 'no TEXT_CHANGE was emitted');
    final last = events.last;
    expect(last.change.toJson(), change.toJson());
    expect(last.old.toJson(), old.toJson());
    expect(last.source, source);
  }
}

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Quill', () {
    test('imports', () {
      for (final entry in Quill.registeredDefinitions.entries) {
        expect(entry.value, isNotNull, reason: entry.key);
        expect(Quill.importDefinition(entry.key), same(entry.value));
      }
    });

    group('register', () {
      RegistryEntry entry(String name) => RegistryEntry(
            blotName: name,
            scope: Scope.INLINE_BLOT,
            create: ([dynamic value]) =>
                throw UnsupportedError('registration-only test blot'),
          );

      test('register(path, target)', () {
        dynamic counterFactory(Quill quill, dynamic options) => Object();
        Quill.register('modules/upstream-counter', counterFactory);

        expect(
          Quill.importDefinition('modules/upstream-counter'),
          same(counterFactory),
        );
      });

      test('register(formats)', () {
        final counter = entry('upstream-my-counter');
        Quill.register(counter);

        expect(
          Quill.importDefinition('formats/upstream-my-counter'),
          same(counter),
        );
      });

      test('register(targets)', () {
        final blot = entry('upstream-a-blot');
        dynamic moduleFactory(Quill quill, dynamic options) => Object();
        Quill.register({
          'formats/upstream-a-blot': blot,
          'modules/upstream-a-module': moduleFactory,
        });

        expect(
          Quill.importDefinition('formats/upstream-a-blot'),
          same(blot),
        );
        expect(
          Quill.importDefinition('modules/upstream-a-module'),
          same(moduleFactory),
        );
      });
    });

    group('construction', () {
      test('empty', () {
        final quill = createEditorQuill('');
        expectDelta(quill.getContents(), Delta()..insert('\n'));
        expect(quill.root.innerHTML, '<p><br></p>');
      });

      test('text', () {
        final quill = createEditorQuill('0123');
        expectDelta(quill.getContents(), Delta()..insert('0123\n'));
        expect(quill.root.innerHTML, '<p>0123</p>');
      });

      test('newlines', () {
        final quill = createEditorQuill('<p><br></p><p><br></p><p><br></p>');
        expectDelta(quill.getContents(), Delta()..insert('\n\n\n'));
        expect(quill.root.innerHTML, '<p><br></p><p><br></p><p><br></p>');
      });

      test('formatted ending', () {
        final quill = createEditorQuill('<p class="ql-align-center">Test</p>');
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('Test')
            ..insert('\n', {'align': 'center'}),
        );
        expect(quill.root.innerHTML, '<p class="ql-align-center">Test</p>');
      });
    });

    group('api', () {
      late Quill quill;
      late Delta oldDelta;
      late _TextChanges changes;

      setUp(() {
        quill = createEditorQuill('<p>0123<em>45</em>67</p>');
        oldDelta = quill.getContents();
        changes = _TextChanges()..listen(quill);
      });

      test('deleteText()', () {
        quill.deleteText(3, 2);
        expect(quill.root.innerHTML, '<p>012<em>5</em>67</p>');
        changes.expectLast(
          Delta()
            ..retain(3)
            ..delete(2),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('format()', () {
        quill.setSelection(const Range(3, 2));
        quill.format('bold', true);
        expect(quill.root.innerHTML,
            '<p>012<strong>3<em>4</em></strong><em>5</em>67</p>');
        changes.expectLast(
          Delta()
            ..retain(3)
            ..retain(2, {'bold': true}),
          oldDelta,
          EmitterSource.API,
        );
        expect(quill.getSelection()?.index, 3);
        expect(quill.getSelection()?.length, 2);
      });

      test('formatLine()', () {
        quill.formatLine(1, 1, 'header', 2);
        expect(quill.root.innerHTML, '<h2>0123<em>45</em>67</h2>');
        changes.expectLast(
          Delta()
            ..retain(8)
            ..retain(1, {'header': 2}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('single format', () {
        quill.formatText(3, 2, 'bold', true);
        expect(quill.root.innerHTML,
            '<p>012<strong>3<em>4</em></strong><em>5</em>67</p>');
        changes.expectLast(
          Delta()
            ..retain(3)
            ..retain(2, {'bold': true}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('format object', () {
        quill.formatTextFormats(3, 2, {'bold': true});
        expect(quill.root.innerHTML,
            '<p>012<strong>3<em>4</em></strong><em>5</em>67</p>');
        changes.expectLast(
          Delta()
            ..retain(3)
            ..retain(2, {'bold': true}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('insertEmbed()', () {
        quill.insertEmbed(5, 'image', '/assets/favicon.png');
        expect(quill.root.innerHTML,
            '<p>0123<em>4<img src="/assets/favicon.png">5</em>67</p>');
        changes.expectLast(
          Delta()
            ..retain(5)
            ..insert({'image': '/assets/favicon.png'}, {'italic': true}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('insertText()', () {
        quill.insertText(5, '|', formats: {'bold': true});
        expect(
          quill.root.innerHTML,
          '<p>0123<em>4</em><strong><em>|</em></strong><em>5</em>67</p>',
        );
        changes.expectLast(
          Delta()
            ..retain(5)
            ..insert('|', {'bold': true, 'italic': true}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('enable/disable', () {
        quill.disable();
        expect(quill.root.getAttribute('contenteditable'), 'false');
        quill.enable();
        expect(quill.root.getAttribute('contenteditable'), isNotNull);
      });

      test('getFormat()', () {
        expect(quill.getFormat(5), {'italic': true});
      });

      test('getSelection()', () {
        expect(quill.getSelection(), isNull);
        quill.setSelection(const Range(1, 2));
        expect(quill.getSelection()?.index, 1);
        expect(quill.getSelection()?.length, 2);
      });

      test('removeFormat()', () {
        quill.removeFormat(5, 1);
        expect(quill.root.innerHTML, '<p>0123<em>4</em>567</p>');
        changes.expectLast(
          Delta()
            ..retain(5)
            ..retain(1, {'italic': null}),
          oldDelta,
          EmitterSource.API,
        );
      });

      test('updateContents() delta', () {
        final delta = Delta()
          ..retain(5)
          ..insert('|');
        quill.updateContents(delta);
        expect(quill.root.innerHTML, '<p>0123<em>4</em>|<em>5</em>67</p>');
        changes.expectLast(delta, oldDelta, EmitterSource.API);
      });

      test('updateContents() ops array', () {
        final operations = <Operation>[
          Operation.retain(5),
          Operation.insert('|'),
        ];
        final delta = Delta.fromOperations(operations);
        quill.updateContents(delta);
        expect(quill.root.innerHTML, '<p>0123<em>4</em>|<em>5</em>67</p>');
        changes.expectLast(delta, oldDelta, EmitterSource.API);
      });
    });

    group('events', () {
      test('api text insert', () {
        final quill = createEditorQuill('<p>0123</p>');
        quill.update();
        final oldDelta = quill.getContents();
        final changes = _TextChanges()..listen(quill);

        quill.insertText(2, '!');

        changes.expectLast(
          Delta()
            ..retain(2)
            ..insert('!'),
          oldDelta,
          EmitterSource.API,
        );
      });
    });

    group('setContents()', () {
      test('empty', () {
        final quill = createEditorQuill('');
        final delta = Delta()..insert('\n');
        quill.setContents(delta);
        expectDelta(quill.getContents(), delta);
        expect(quill.root.innerHTML, '<p><br></p>');
      });

      test('single line', () {
        final quill = createEditorQuill('');
        final delta = Delta()..insert('Hello World!\n');
        quill.setContents(delta);
        expectDelta(quill.getContents(), delta);
        expect(quill.root.innerHTML, '<p>Hello World!</p>');
      });

      test('multiple lines', () {
        final quill = createEditorQuill('');
        final delta = Delta()..insert('Hello\n\nWorld!\n');
        quill.setContents(delta);
        expectDelta(quill.getContents(), delta);
        expect(quill.root.innerHTML, '<p>Hello</p><p><br></p><p>World!</p>');
      });

      test('basic formats', () {
        final quill = createEditorQuill('');
        final delta = Delta()
          ..insert('Welcome')
          ..insert('\n', {'header': 1})
          ..insert('Hello\n')
          ..insert('World')
          ..insert('!', {'bold': true})
          ..insert('\n');
        quill.setContents(delta);
        expectDelta(quill.getContents(), delta);
        expect(
          quill.root.innerHTML,
          '<h1>Welcome</h1><p>Hello</p><p>World<strong>!</strong></p>',
        );
      });

      test('array of operations', () {
        final quill = createEditorQuill('');
        final delta = Delta.fromOperations([
          Operation.insert('test'),
          Operation.insert('123', {'bold': true}),
          Operation.insert('\n'),
        ]);
        quill.setContents(delta);
        expectDelta(quill.getContents(), delta);
      });

      test('no trailing newline', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        quill.setContents(Delta()..insert('0123'));
        expectDelta(quill.getContents(), Delta()..insert('0123\n'));
      });

      test('inline formatting', () {
        final quill =
            createEditorQuill('<p><strong>Bold</strong></p><p>Not bold</p>');
        final contents = quill.getContents();
        quill.setContents(contents);
        expectDelta(quill.getContents(), contents);
      });

      test('block embed', () {
        final quill = createEditorQuill('<p>Hello World!</p>');
        final contents = Delta()..insert({'video': '#'});
        quill.setContents(contents);
        expectDelta(quill.getContents(), contents);
      });
    });

    group('getText()', () {
      test('return all text by default', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getText(), 'Welcome\n');
      });

      test('works when only provide index', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getText(2), 'lcome\n');
      });

      test('works when provide index and length', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getText(2, 3), 'lco');
      });

      test('works with range', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        const range = Range(2, 3);
        expect(quill.getText(range.index, range.length), 'lco');
      });
    });

    group('getSemanticHTML()', () {
      test('return all html by default', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getSemanticHTML(), '<h1>Welcome</h1>');
      });

      test('works when only provide index', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getSemanticHTML(2), 'lcome');
      });

      test('works when provide index and length', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        expect(quill.getSemanticHTML(2, 3), 'lco');
      });

      test('works with range', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        const range = Range(2, 3);
        expect(quill.getSemanticHTML(range.index, range.length), 'lco');
      });
    });

    group('setText()', () {
      test('overwrite', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        quill.setText('abc');
        expect(quill.root.innerHTML, '<p>abc</p>');
      });

      test('set to newline', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        quill.setText('\n');
        expect(quill.root.innerHTML, '<p><br></p>');
      });

      test('multiple newlines', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        quill.setText('\n\n');
        expect(quill.root.innerHTML, '<p><br></p><p><br></p>');
      });

      test('content with trailing newline', () {
        final quill = createEditorQuill('<h1>Welcome</h1>');
        quill.setText('abc\n');
        expect(quill.root.innerHTML, '<p>abc</p>');
      });

      test('return carriage', () {
        final quill = createEditorQuill('<p>Test</p>');
        quill.setText('\r');
        expect(quill.root.innerHTML, '<p><br></p>');
      });

      test('return carriage newline', () {
        final quill = createEditorQuill('<p>Test</p>');
        quill.setText('\r\n');
        expect(quill.root.innerHTML, '<p><br></p>');
      });
    });

    group('placeholder', () {
      Quill setup() => createEditorQuill(
            '<p></p>',
            options:
                ThemeOptions(placeholder: 'a great day to be a placeholder'),
          );

      test('blank editor', () {
        final quill = setup();
        expect(quill.root.getAttribute('data-placeholder'),
            'a great day to be a placeholder');
        expect(quill.root.classes.contains('ql-blank'), isTrue);
      });

      test('with text', () {
        final quill = setup();
        quill.setText('test');
        expect(quill.root.classes.contains('ql-blank'), isFalse);
      });

      test('formatted line', () {
        final quill = setup();
        quill.formatLine(0, 1, 'list', 'ordered');
        expect(quill.root.classes.contains('ql-blank'), isFalse);
      });
    });
  });
}
