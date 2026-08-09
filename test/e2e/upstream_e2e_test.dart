@TestOn('vm')
@Timeout(Duration(minutes: 45))
library;

/// Port of the Quill upstream end-to-end suite,
/// `referencias/quilljs/test/e2e/{history,replaceSelection,list}.spec.ts`.
///
/// These are the specs the upstream project itself considers unfalsifiable by
/// unit tests: undo/redo *selection* restoration, replacing a selection with
/// real typing (where the inherited format of the replacement is decided by
/// the cursor, not by the delta), IME composition, and caret navigation across
/// list items — whose `.ql-ui` marker sits inside the line and is exactly what
/// makes Home/arrow keys land on the wrong index when it is mishandled.
///
/// The helpers on [E2eApp] are a transcription of upstream's `EditorPage`
/// page object, so each case below reads like the TypeScript original.
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import 'support/e2e_app.dart';

/// Upstream's `SHORTKEY`: Control everywhere except macOS.
const Key shortKey = Key.control;

void main() {
  late E2eApp app;

  setUpAll(() async => app = await E2eApp.start());
  tearDownAll(() async => app.stop());

  Future<void> undo() async {
    await app.page.keyboard.down(shortKey);
    await app.page.keyboard.press(Key.keyZ);
    await app.page.keyboard.up(shortKey);
    await app.settle(60);
  }

  Future<void> redo() async {
    await app.page.keyboard.down(shortKey);
    await app.page.keyboard.down(Key.shift);
    await app.page.keyboard.press(Key.keyZ);
    await app.page.keyboard.up(Key.shift);
    await app.page.keyboard.up(shortKey);
    await app.settle(60);
  }

  Future<void> bold() async {
    await app.page.keyboard.down(shortKey);
    await app.page.keyboard.press(Key.keyB);
    await app.page.keyboard.up(shortKey);
    await app.settle(60);
  }

  // ---------------------------------------------------------------------------
  // history.spec.ts
  // ---------------------------------------------------------------------------

  group('history', () {
    setUp(() async {
      await app.reload();
      await app.setContents([
        {'insert': '1234\n'}
      ]);
      await app.cutoffHistory();
    });

    test('skip changes reverted by api', () async {
      await app.setHistoryUserOnly(true);
      await app.moveCursorAfterText('12');
      await app.page.keyboard.type('a');
      await app.settle(120);
      await app.cutoffHistory();
      await app.selectText('34');
      await bold();
      await app.cutoffHistory();
      await app.updateContents([
        {'retain': 3},
        {
          'retain': 2,
          'attributes': {'bold': null}
        },
      ]);
      await undo();

      expect(await app.getContents(), [
        {'insert': '1234\n'}
      ]);
    });

    test('clipboard', () async {
      await app.moveCursorAfterText('2');
      await app.page.keyboard.type('a');
      await app.selectText('a');
      await app.shortcut(Key.keyC);
      await app.settle(80);
      await undo();

      expect(await app.getContents(), [
        {'insert': '1234\n'}
      ]);
    });

    group('selection', () {
      test('typing', () async {
        await app.moveCursorAfterText('2');
        await app.page.keyboard.type('a');
        await app.settle(120);
        await app.cutoffHistory();
        await app.page.keyboard.type('b');
        await app.settle(120);
        await app.cutoffHistory();
        await app.page.keyboard.press(Key.backspace);
        await app.settle(120);
        await app.cutoffHistory();
        await app.page.keyboard.type('c');
        await app.settle(120);
        await app.cutoffHistory();

        await undo();
        expect(await app.getSelection(), {'index': 3, 'length': 0});
        await undo();
        expect(await app.getSelection(), {'index': 4, 'length': 0});
        await undo();
        expect(await app.getSelection(), {'index': 3, 'length': 0});
        await undo();
        expect(await app.getSelection(), {'index': 2, 'length': 0});
      });

      test('delete forward', () async {
        await app.moveCursorAfterText('3');
        await app.page.keyboard.press(Key.backspace);
        await undo();
        expect(await app.getSelection(), {'index': 3, 'length': 0});
        await redo();
        expect(await app.getSelection(), {'index': 2, 'length': 0});
      });

      test('delete selection', () async {
        await app.selectText('23');
        await app.page.keyboard.press(Key.backspace);
        await undo();
        expect(await app.getSelection(), {'index': 1, 'length': 2});
        await redo();
        expect(await app.getSelection(), {'index': 1, 'length': 0});
      });

      test('format selection', () async {
        await app.selectText('23');
        await bold();
        await undo();
        expect(await app.getSelection(), {'index': 1, 'length': 2});
        await redo();
        expect(await app.getSelection(), {'index': 1, 'length': 2});
      });

      test('combine operations', () async {
        await app.selectText('23');
        await app.page.keyboard.type('a');
        await app.settle(120);
        await app.cutoffHistory();
        await app.page.keyboard.type('bc');
        await app.settle(120);

        await undo();
        expect(await app.getSelection(), {'index': 2, 'length': 0});
        await undo();
        expect(await app.getSelection(), {'index': 1, 'length': 2});
        await redo();
        expect(await app.getSelection(), {'index': 2, 'length': 0});
        await redo();
        expect(await app.getSelection(), {'index': 4, 'length': 0});
      });

      test('api changes', () async {
        await app.setHistoryUserOnly(true);
        await app.selectText('23');
        await app.page.keyboard.press(Key.backspace);
        await app.settle(120);
        await app.cutoffHistory();
        await app.page.keyboard.type('a');
        await app.settle(120);
        await app.cutoffHistory();
        await app.updateContents([
          {'insert': '0'}
        ]);

        await undo();
        expect(await app.getSelection(), {'index': 2, 'length': 0});
        await undo();
        expect(await app.getSelection(), {'index': 2, 'length': 2});
      });

      test('programmatic user changes', () async {
        await app.moveCursorAfterText('12');
        await app.page.keyboard.type('a');
        await app.settle(120);
        await app.cutoffHistory();
        await app.updateContents([
          {'insert': '0'}
        ], source: 'user');

        await undo();
        expect(await app.getSelection(), {'index': 3, 'length': 0});
      });

      test('no user selection', () async {
        await app.updateContents([
          {'retain': 3},
          {'insert': '0'},
        ], source: 'user');
        await app.page.click('.ql-editor');
        await app.settle(60);
        await undo();
        expect(await app.getSelection(), {'index': 3, 'length': 0});
      });
    });
  });

  // ---------------------------------------------------------------------------
  // replaceSelection.spec.ts
  // ---------------------------------------------------------------------------

  group('replace selection', () {
    setUp(() async => app.reload());

    group('replace a colored text', () {
      test('after a normal text', () async {
        await app.setContents([
          {'insert': '1'},
          {
            'insert': '2',
            'attributes': {'color': 'red'}
          },
          {'insert': '3\n'},
        ]);
        await app.selectText('2', '3');
        await app.page.keyboard.type('a');
        await app.settle(80);

        expect(await app.rootHtml(),
            '<p>1<span style="color: red;">a</span></p>');
        expect(await app.getContents(), [
          {'insert': '1'},
          {
            'insert': 'a',
            'attributes': {'color': 'red'}
          },
          {'insert': '\n'},
        ]);
      });

      test('with Enter key', () async {
        await app.setContents([
          {'insert': '1'},
          {
            'insert': '2',
            'attributes': {'color': 'red'}
          },
          {'insert': '3\n'},
        ]);
        await app.selectText('2', '3');
        await app.page.keyboard.press(Key.enter);
        await app.settle(80);

        expect(await app.rootHtml(), '<p>1</p><p><br></p>');
        expect(await app.getContents(), [
          {'insert': '1\n\n'}
        ]);
      });

      test('with IME', () async {
        await app.setContents([
          {'insert': '1'},
          {
            'insert': '2',
            'attributes': {'color': 'red'}
          },
          {'insert': '3\n'},
        ]);
        await app.selectText('2', '3');
        await app.typeWordWithIME('我');
        await app.settle(120);

        expect(await app.rootHtml(), '<p>1我</p>');
        expect(await app.getContents(), [
          {'insert': '1我\n'}
        ]);
      });

      test('after a bold text', () async {
        await app.setContents([
          {
            'insert': '1',
            'attributes': {'bold': true}
          },
          {
            'insert': '2',
            'attributes': {'color': 'red'}
          },
          {'insert': '3\n'},
        ]);
        await app.selectText('2', '3');
        await app.page.keyboard.type('a');
        await app.settle(80);

        expect(await app.rootHtml(),
            '<p><strong>1</strong><span style="color: red;">a</span></p>');
        expect(await app.getContents(), [
          {
            'insert': '1',
            'attributes': {'bold': true}
          },
          {
            'insert': 'a',
            'attributes': {'color': 'red'}
          },
          {'insert': '\n'},
        ]);
      });

      test('across lines', () async {
        await app.setContents([
          {
            'insert': 'header',
            'attributes': {'color': 'red'}
          },
          {
            'insert': '\n',
            'attributes': {'header': 1}
          },
          {'insert': 'text\n'},
        ]);
        await app.selectText('header', 'text');
        await app.page.keyboard.type('a');
        await app.settle(80);

        expect(await app.rootHtml(),
            '<h1><span style="color: red;">a</span></h1>');
        expect(await app.getContents(), [
          {
            'insert': 'a',
            'attributes': {'color': 'red'}
          },
          {
            'insert': '\n',
            'attributes': {'header': 1}
          },
        ]);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // list.spec.ts — every case runs for both list types, like upstream's loop.
  // ---------------------------------------------------------------------------

  for (final list in const ['bullet', 'checked']) {
    group('list ($list)', () {
      setUp(() async => app.reload());

      test('jump to line start', () async {
        await app.setContents([
          {'insert': 'item 1'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);
        await app.page.click('.ql-editor');
        await app.moveCursorAfterText('item 1');
        await app.page.keyboard.press(Key.home);
        // internal(uiNode): wait for selectionchange to fire
        await app.settle(500);

        expect(await app.getSelection(), {'index': 0, 'length': 0});

        await app.settle(500);
        await app.page.keyboard.type('start ');
        await app.settle(80);

        expect(await app.getContents(), [
          {'insert': 'start item 1'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);
      });

      test('move to previous/next line', () async {
        const firstLine = 'first line';
        await app.setContents([
          {'insert': firstLine},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
          {'insert': 'second line'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);

        await app.setSelection(firstLine.length + 2, 0);
        await app.page.keyboard.press(Key.arrowLeft);
        await app.page.keyboard.press(Key.arrowLeft);
        await app.settle(80);
        expect(await app.getSelection(), {'index': firstLine.length, 'length': 0});

        await app.page.keyboard.press(Key.arrowRight);
        await app.settle(500); // internal(uiNode)
        await app.page.keyboard.press(Key.arrowRight);
        await app.settle(80);
        expect(
          await app.getSelection(),
          {'index': firstLine.length + 2, 'length': 0},
        );
      });

      test('RTL support', () async {
        const firstLine = 'اللغة العربية';
        await app.setContents([
          {'insert': firstLine},
          {
            'insert': '\n',
            'attributes': {'list': list, 'direction': 'rtl'}
          },
          {'insert': 'توحيد اللهجات العربية'},
          {
            'insert': '\n',
            'attributes': {'list': list, 'direction': 'rtl'}
          },
        ]);

        await app.setSelection(firstLine.length + 2, 0);
        await app.page.keyboard.press(Key.arrowRight);
        await app.page.keyboard.press(Key.arrowRight);
        await app.settle(80);
        expect(await app.getSelection(), {'index': firstLine.length, 'length': 0});

        await app.page.keyboard.press(Key.arrowLeft);
        await app.settle(500); // internal(uiNode)
        await app.page.keyboard.press(Key.arrowLeft);
        await app.settle(80);
        expect(
          await app.getSelection(),
          {'index': firstLine.length + 2, 'length': 0},
        );
      });

      test('extend selection to previous/next line', () async {
        await app.setContents([
          {'insert': 'first line'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
          {'insert': 'second line'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);

        await app.moveCursorTo('s_econd');
        await app.page.keyboard.down(Key.shift);
        await app.page.keyboard.press(Key.arrowLeft);
        await app.page.keyboard.press(Key.arrowLeft);
        await app.page.keyboard.up(Key.shift);
        await app.page.keyboard.type('a');
        await app.settle(80);

        expect(await app.getContents(), [
          {'insert': 'first lineaecond line'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);
      });

      // https://github.com/slab/quill/issues/3837
      test('typing at beginning with IME', () async {
        await app.setContents([
          {'insert': 'item 1'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
          {'insert': ''},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);

        await app.setSelection(7, 0);
        await app.typeWordWithIME('我');
        await app.settle(120);

        expect(await app.getContents(), [
          {'insert': 'item 1'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
          {'insert': '我'},
          {
            'insert': '\n',
            'attributes': {'list': list}
          },
        ]);
      });

      test('typing in an empty editor with IME and press Backspace', () async {
        await app.setContents([
          {'insert': '\n'}
        ]);

        await app.setSelection(9, 0);
        await app.typeWordWithIME('我');
        await app.page.keyboard.press(Key.backspace);
        await app.settle(120);

        expect(await app.getContents(), [
          {'insert': '\n'}
        ]);
      });
    });
  }

  group('checklist', () {
    setUp(() async => app.reload());

    test('checklist is checkable', () async {
      await app.setContents([
        {'insert': 'item 1'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'}
        },
      ]);
      await app.setSelection(7, 0);

      final rect = await app.rectOf('.ql-editor li');
      final x = (rect['left'] as num) + 5;
      final y = (rect['top'] as num) + 5;

      await app.page.mouse.click(Point(x, y));
      await app.settle(120);
      expect(await app.getContents(), [
        {'insert': 'item 1'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        },
      ]);

      await app.page.mouse.click(Point(x, y));
      await app.settle(120);
      expect(await app.getContents(), [
        {'insert': 'item 1'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'}
        },
      ]);
    });
  });
}
