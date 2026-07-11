@TestOn('browser')
library icon_theme_test;

import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Quill _createQuill(QuillIconTheme iconTheme) {
  final wrapper = web.document.createElement('div');
  final host = web.document.createElement('div');
  wrapper.appendChild(host);
  web.document.body!.appendChild(wrapper);
  return Quill(
    HtmlDomElement(host),
    options: ThemeOptions(
      theme: 'snow',
      iconTheme: iconTheme,
      modules: {
        'toolbar': {
          'container': [
            [
              {
                'header': [false, '1', '2', '3']
              },
              {'font': []},
            ],
            ['bold', 'italic'],
            [
              {'list': 'ordered'},
              {'align': []},
            ],
            ['image'],
          ],
        },
      },
    ),
  );
}

web.Element _toolbarFor(Quill quill) {
  final container = (quill.container as HtmlDomElement).node as web.Element;
  return container.parentElement!.querySelector('.ql-toolbar')!;
}

void _dispatchMouse(web.Element element, String type) {
  element.dispatchEvent(
    web.MouseEvent(
      type,
      web.MouseEventInit(bubbles: true, cancelable: true),
    ),
  );
}

void main() {
  setUpAll(initializeQuill);

  test('SVG remains the default icon theme', () {
    final quill = _createQuill(QuillIconTheme.svg);
    final toolbar = _toolbarFor(quill);

    expect(toolbar.querySelector('button.ql-bold svg'), isNotNull);
    expect(toolbar.classList.contains('ql-icons-tabler'), isFalse);
  });

  test('Tabler theme renders font icon markup for buttons and pickers', () {
    final quill = _createQuill(QuillIconTheme.tabler);
    final toolbar = _toolbarFor(quill);

    expect(toolbar.classList.contains('ql-icons-tabler'), isTrue);
    expect(toolbar.querySelector('button.ql-bold .ti-bold'), isNotNull);
    expect(
      toolbar.querySelector('button.ql-list .ti-list-numbers'),
      isNotNull,
    );
    expect(toolbar.querySelector('button.ql-image .ti-photo'), isNotNull);
    expect(
      toolbar.querySelector('.ql-header .ql-picker-label .ti-selector'),
      isNotNull,
    );
    expect(
      toolbar.querySelector('.ql-font .ql-picker-label .ti-selector'),
      isNotNull,
    );
    expect(
      toolbar.querySelector('.ql-align .ql-picker-label .ti-align-left'),
      isNotNull,
    );
    expect(toolbar.querySelector('svg'), isNull);
  });

  test('toolbar button preserves the selected range while formatting', () {
    final quill = _createQuill(QuillIconTheme.tabler);
    final toolbar = _toolbarFor(quill);
    quill.insertText(0, 'Isaque neves');
    quill.setSelection(const Range(0, 12), source: 'user');

    final bold = toolbar.querySelector('button.ql-bold')!;
    _dispatchMouse(bold, 'mousedown');

    expect(quill.getFormat(0, 12)['bold'], isTrue);
    expect(quill.getSelection()?.index, equals(0));
    expect(quill.getSelection()?.length, equals(12));
  });

  test('picker preserves the selected range while formatting', () {
    final quill = _createQuill(QuillIconTheme.tabler);
    final toolbar = _toolbarFor(quill);
    quill.insertText(0, 'Isaque neves');
    quill.setSelection(const Range(0, 12), source: 'user');

    final fontPicker = toolbar.querySelector('.ql-font.ql-picker')!;
    final label = fontPicker.querySelector('.ql-picker-label')!;
    final serif = fontPicker.querySelector(
      '.ql-picker-item[data-value="serif"]',
    )!;
    _dispatchMouse(label, 'mousedown');
    _dispatchMouse(serif, 'mousedown');

    expect(label.getAttribute('data-value'), equals('serif'));
    expect(serif.classList.contains('ql-selected'), isTrue);
    expect(quill.getFormat(0, 12)['font'], equals('serif'));
    expect(quill.getSelection()?.index, equals(0));
    expect(quill.getSelection()?.length, equals(12));
  });
}
