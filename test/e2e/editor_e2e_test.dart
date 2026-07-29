@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

/// End-to-end coverage of the core editor driven by REAL user input:
/// trusted keystrokes, mouse clicks on toolbar controls and picker items.
///
/// Every assertion checks the MODEL (the delta the editor would hand to an
/// application) as well as the rendered DOM — a document that looks right on
/// screen while the model is empty is precisely the failure mode that only
/// real-input tests expose.
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import 'support/e2e_app.dart';

void main() {
  late E2eApp app;

  setUpAll(() async => app = await E2eApp.start());
  tearDownAll(() async => app.stop());

  group('typing and text editing', () {
    test('typed text reaches the document model', () async {
      await app.resetEditor();
      await app.type('Isaque Neves');

      expect(await app.editorText(), 'Isaque Neves');
      expect(await app.contents(), contains('Isaque Neves'));
    });

    test('Enter splits the line and Backspace joins it back', () async {
      await app.resetEditor();
      await app.type('primeira');
      await app.page.keyboard.press(Key.enter);
      await app.type('segunda');

      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor p").length'),
          2);
      expect(await app.contents(), contains(r'primeira\nsegunda'));

      // Backspacing through the second line merges it back into the first.
      for (var i = 0; i < 'segunda'.length + 1; i++) {
        await app.page.keyboard.press(Key.backspace);
      }
      expect(await app.editorText(), 'primeira');
      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor p").length'),
          1);
    });

    test('typing keeps the caret advancing (no caret reset)', () async {
      await app.resetEditor();
      await app.type('abc');
      expect(await app.selection(), '3:0',
          reason: 'the caret must sit after the typed text');
    });
  });

  group('inline formats via toolbar buttons', () {
    test('Bold formats the selection and keeps it selected', () async {
      await app.typeAndSelect('negrito');
      await app.clickToolbarButton('bold');

      expect(await app.contents(), contains('"bold":true'));
      expect(await app.editorHtml(), contains('<strong>negrito</strong>'));
      expect(await app.nativeSelection(), 'negrito',
          reason: 'the toolbar click must not drop the selection');
      expect(await app.isToolbarButtonActive('bold'), isTrue);

      // Toggling off, still without re-selecting.
      await app.clickToolbarButton('bold');
      expect(await app.editorHtml(), isNot(contains('<strong>')));
      expect(await app.isToolbarButtonActive('bold'), isFalse);
    });

    test('Italic and Underline format the selection', () async {
      await app.typeAndSelect('estilos');
      await app.clickToolbarButton('italic');
      await app.clickToolbarButton('underline');

      final contents = await app.contents();
      expect(contents, contains('"italic":true'));
      expect(contents, contains('"underline":true'));
      final html = await app.editorHtml();
      expect(html, contains('<em>'));
      expect(html, contains('<u>'));
    });

    test('Ctrl+B / Ctrl+I keyboard shortcuts format the selection', () async {
      await app.typeAndSelect('atalho');
      await app.shortcut(Key.keyB);
      await app.shortcut(Key.keyI);

      final contents = await app.contents();
      expect(contents, contains('"bold":true'));
      expect(contents, contains('"italic":true'));
    });

    test('collapsed Ctrl+B applies a pending format to what is typed next',
        () async {
      await app.resetEditor();
      await app.type('normal ');
      await app.shortcut(Key.keyB);
      await app.type('forte');

      expect(await app.editorText(), 'normal forte',
          reason: 'no zero-width guard may leak into the text');
      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor strong")?.textContent'),
          'forte');
    });
  });

  group('block formats', () {
    test('Heading 1 converts the line and Normal reverts it', () async {
      await app.typeAndSelect('Titulo');
      await app.pickFromPicker('ql-header', '1');

      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor h1")?.textContent'),
          'Titulo');
      expect(await app.contents(), contains('"header":1'));

      await app.pickFromPicker('ql-header', null);
      expect(await app.eval<bool>(
          '() => document.querySelector(".ql-editor h1") === null'),
          isTrue);
      expect(await app.editorText(), 'Titulo',
          reason: 'reverting the header must not delete the text');
    });

    test('ordered and bullet list buttons switch the line type', () async {
      await app.typeAndSelect('item');
      await app.clickToolbarButton('list', value: 'ordered');

      expect(await app.contents(), contains('"list":"ordered"'));
      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor li")'
          '?.getAttribute("data-list")'),
          'ordered');

      await app.selectAll();
      await app.clickToolbarButton('list', value: 'bullet');
      expect(await app.contents(), contains('"list":"bullet"'));
      // Upstream's model keeps the <ol> container and switches data-list.
      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor li")'
          '?.getAttribute("data-list")'),
          'bullet');
      expect(await app.eval<bool>(
          '() => document.querySelector(".ql-editor ol") !== null'),
          isTrue);
    });

    test('clicking the same list button again removes the list', () async {
      await app.typeAndSelect('alterna');
      await app.clickToolbarButton('list', value: 'ordered');
      expect(await app.contents(), contains('"list":"ordered"'));

      await app.selectAll();
      await app.clickToolbarButton('list', value: 'ordered');
      expect(await app.contents(), isNot(contains('"list"')),
          reason: 'the list format toggles off');
      expect(await app.editorText(), 'alterna');
    });

    test('a multi-line selection becomes a list of several items', () async {
      await app.resetEditor();
      await app.type('um');
      await app.page.keyboard.press(Key.enter);
      await app.type('dois');
      await app.selectAll();
      await app.clickToolbarButton('list', value: 'bullet');

      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor li").length'),
          2);
    });

    test('alignment picker centers, right-aligns, justifies and resets',
        () async {
      await app.typeAndSelect('alinhado');

      for (final align in ['center', 'right', 'justify']) {
        await app.pickFromPicker('ql-align', align);
        expect(await app.contents(), contains('"align":"$align"'),
            reason: 'align $align must reach the model');
        expect(await app.eval<bool>(
            '() => document.querySelector(".ql-editor .ql-align-$align")'
            ' !== null'),
            isTrue,
            reason: 'align $align must reach the DOM');
        await app.selectAll();
      }

      await app.pickFromPicker('ql-align', null);
      expect(await app.contents(), isNot(contains('"align"')));
    });

    test('code-block turns the line into code', () async {
      await app.typeAndSelect('print(1)');
      await app.clickToolbarButton('code-block');
      expect(await app.contents(), contains('code-block'));
    });
  });

  group('colors', () {
    test('the text color picker paints the selection', () async {
      await app.typeAndSelect('colorido');
      await app.pickFromPicker('ql-color', '#e60000');

      expect(await app.contents(), contains('"color":"#e60000"'));
      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor span")?.style?.color'),
          'rgb(230, 0, 0)');
    });

    test('the highlight color picker paints the background', () async {
      await app.typeAndSelect('realce');
      await app.pickFromPicker('ql-background', '#ffff00');

      expect(await app.contents(), contains('"background":"#ffff00"'));
      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor span")'
          '?.style?.backgroundColor'),
          'rgb(255, 255, 0)');
    });
  });

  group('link', () {
    test('the link button opens the editor and Enter saves the anchor',
        () async {
      await app.typeAndSelect('quilljs');
      await app.clickToolbarButton('link');
      await app.settle(200);

      final tooltip = await app.eval<Map<String, dynamic>>('''() => {
        const el = document.querySelector('.ql-tooltip');
        return {
          visible: el != null && !el.classList.contains('ql-hidden'),
          editing: el?.classList.contains('ql-editing'),
          mode: el?.getAttribute('data-mode'),
        };
      }''');
      expect(tooltip['visible'], isTrue,
          reason: 'the link editor must survive the click that opened it '
              '($tooltip)');
      expect(tooltip['editing'], isTrue);
      expect(tooltip['mode'], 'link');

      await app.page.type('.ql-tooltip input', 'https://quilljs.com');
      await app.page.keyboard.press(Key.enter);

      expect(await app.eval<String?>(
          '() => document.querySelector(".ql-editor a")?.getAttribute("href")'),
          'https://quilljs.com');
      expect(await app.contents(), contains('quilljs.com'));
      expect(await app.eval<bool>(
          '() => document.querySelector(".ql-tooltip")'
          '.classList.contains("ql-hidden")'),
          isTrue);
    });
  });

  group('clean and history', () {
    test('the clean button strips inline and block formats', () async {
      await app.typeAndSelect('sujo');
      await app.clickToolbarButton('bold');
      await app.selectAll();
      await app.pickFromPicker('ql-header', '2');
      await app.selectAll();
      await app.clickToolbarButton('clean');

      final contents = await app.contents();
      expect(contents, isNot(contains('"bold"')));
      expect(contents, isNot(contains('"header"')));
      expect(await app.editorText(), 'sujo',
          reason: 'clean removes formats, never the text');
    });

    test('Ctrl+Z undoes a format and Ctrl+Y redoes it', () async {
      await app.typeAndSelect('historia');
      // History merges changes that happen within `delay` (1s) into one undo
      // entry; pausing makes the bold its own step, so the assertion is
      // about undo and not about the merge window.
      await app.settle(1200);
      await app.clickToolbarButton('bold');
      expect(await app.contents(), contains('"bold":true'));

      await app.shortcut(Key.keyZ);
      await app.settle(200);
      expect(await app.contents(), isNot(contains('"bold":true')),
          reason: 'undo must revert the formatting');
      expect(await app.editorText(), 'historia');

      await app.shortcut(Key.keyY);
      await app.settle(200);
      expect(await app.contents(), contains('"bold":true'),
          reason: 'redo must reapply it');
    });
  });

  group('clipboard with real events', () {
    test('Ctrl+C then Ctrl+V duplicates the selected text', () async {
      await app.typeAndSelect('copia');
      await app.shortcut(Key.keyC);
      await app.page.keyboard.press(Key.arrowRight);
      await app.shortcut(Key.keyV);

      expect(await app.editorText(), 'copiacopia');
    });

    test('a copy event exposes both text/plain and text/html', () async {
      await app.typeAndSelect('abc');
      await app.clickToolbarButton('bold');
      final payload = await app.eval<Map<String, dynamic>>('''() => {
        const dt = new DataTransfer();
        const event = new ClipboardEvent('copy',
            {clipboardData: dt, bubbles: true, cancelable: true});
        document.querySelector('.ql-editor').dispatchEvent(event);
        return {text: dt.getData('text/plain'), html: dt.getData('text/html')};
      }''');
      expect(payload['text'], 'abc');
      expect('${payload['html']}', contains('<strong>'));
    });

    test('pasting external HTML keeps its formatting', () async {
      await app.resetEditor();
      await app.type('inicio-');
      await app.page.keyboard.press(Key.end);
      await app.eval<void>('''() => {
        const dt = new DataTransfer();
        dt.setData('text/html', '<strong>colado</strong>');
        dt.setData('text/plain', 'colado');
        document.querySelector('.ql-editor').dispatchEvent(new ClipboardEvent(
            'paste', {clipboardData: dt, bubbles: true, cancelable: true}));
      }''');
      await app.settle();

      expect(await app.editorText(), 'inicio-colado');
      expect(await app.contents(), contains('"bold":true'));
    });
  });
}
