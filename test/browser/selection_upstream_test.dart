@TestOn('browser')
library selection_upstream_test;

/// Browser port of
/// `referencias/quilljs/test/unit/core/selection.spec.ts`.
///
/// The factory constructs Scroll + Selection directly, like the upstream
/// factory. Going through Clipboard would exercise a different normalization
/// path and could hide selection/blot-coordinate defects.
import 'dart:async';
import 'dart:js_interop';

import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/blots/cursor.dart';
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/formats/abstract/attributor.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

const _selectionFormats = <String>{
  'bold',
  'underline',
  'italic',
  'strike',
  'image',
  'link',
  'color',
  'background',
  'size',
};

const _coreBlots = <String>{
  'block',
  'break',
  'cursor',
  'inline',
  'scroll',
  'text',
  'list',
  'list-container',
};

String _normalizeHtml(String html) =>
    html.replaceAll(RegExp(r'\r?\n\s*'), '').trim();

Selection _createSelection(String html, {web.HTMLElement? container}) {
  final registry = Registry();
  for (final definition in Quill.registeredDefinitions.entries) {
    final value = definition.value;
    if (value is RegistryEntry &&
        (_coreBlots.contains(value.blotName) ||
            _selectionFormats.contains(value.blotName))) {
      registry.register(value);
    } else if (value is Attributor &&
        _selectionFormats.contains(value.attrName) &&
        definition.key.startsWith('formats/')) {
      registry.registerAttributor(value);
    }
  }

  final root = web.document.createElement('div') as web.HTMLElement;
  root.innerHTML = _normalizeHtml(html).toJS;
  (container ?? web.document.body!).appendChild(root);
  addTearDown(() => root.remove());
  final emitter = Emitter();
  final scroll = Scroll(registry, HtmlDomElement(root), emitter: emitter);
  return Selection(scroll, emitter);
}

void _expectRange(Range? actual, int index, [int length = 0]) {
  expect(actual, isNotNull);
  expect(actual!.index, index);
  expect(actual.length, length);
}

web.Element _rawRoot(Selection selection) =>
    (selection.root as HtmlDomElement).node as web.Element;

void _removeUiNodes(web.Element root) {
  var nodes = root.querySelectorAll('.ql-ui');
  while (nodes.length > 0) {
    (nodes.item(0) as web.Element?)?.remove();
    nodes = root.querySelectorAll('.ql-ui');
  }
}

void _expectHtml(Selection selection, String expected) {
  final holder = web.document.createElement('div') as web.HTMLElement;
  holder.innerHTML = _normalizeHtml(expected).toJS;
  _removeUiNodes(holder);
  final actual = _rawRoot(selection).cloneNode(true) as web.Element;
  _removeUiNodes(actual);
  expect(actual.innerHTML, holder.innerHTML);
}

void main() {
  setUpAll(initializeQuill);

  group('Selection.focus()', () {
    ({Selection selection, web.HTMLTextAreaElement textarea}) setup() {
      final container = web.document.createElement('div') as web.HTMLElement;
      web.document.body!.appendChild(container);
      addTearDown(() => container.remove());
      final textarea =
          web.document.createElement('textarea') as web.HTMLTextAreaElement;
      container.appendChild(textarea);
      final selection = _createSelection('<p>0123</p>', container: container);
      textarea
        ..focus()
        ..select();
      return (selection: selection, textarea: textarea);
    }

    test('initial focus', () {
      final fixture = setup();
      expect(fixture.selection.hasFocus(), isFalse);
      fixture.selection.focus();
      expect(fixture.selection.hasFocus(), isTrue);
    });

    test('restore last range', () {
      final fixture = setup();
      fixture.selection.setRange(const Range(1, 2));
      fixture.textarea
        ..focus()
        ..select();
      expect(fixture.selection.hasFocus(), isFalse);
      fixture.selection.focus();
      expect(fixture.selection.hasFocus(), isTrue);
      _expectRange(fixture.selection.getRange(), 1, 2);
    });
  });

  group('Selection.getRange()', () {
    test('empty document', () {
      final selection = _createSelection('');
      selection.setNativeRange(selection.root.querySelector('br'), 0);
      _expectRange(selection.getRange(), 0);
    });

    test('empty line', () {
      final selection = _createSelection('<p>0</p><p><br></p><p>3</p>');
      selection.setNativeRange(selection.root.querySelector('br'), 0);
      _expectRange(selection.getRange(), 2);
    });

    test('end of line', () {
      final selection = _createSelection('<p>0</p>');
      selection.setNativeRange(selection.root.firstChild!.firstChild!, 1);
      _expectRange(selection.getRange(), 1);
    });

    test('text node', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setNativeRange(selection.root.firstChild!.firstChild!, 1);
      _expectRange(selection.getRange(), 1);
    });

    test('line boundaries', () {
      final selection = _createSelection('<p><br></p><p>12</p>');
      selection.setNativeRange(
        selection.root.firstChild!,
        0,
        selection.root.lastChild!.lastChild!,
        2,
      );
      _expectRange(selection.getRange(), 0, 3);
    });

    test('nested text node', () {
      final selection = _createSelection(
        '<p><strong><em>01</em></strong></p>'
        '<ol><li data-list="bullet"><em><u>34</u></em></li></ol>',
      );
      selection.setNativeRange(
        selection.root.querySelector('em')!.firstChild!,
        1,
        selection.root.querySelector('u')!.firstChild!,
        1,
      );
      _expectRange(selection.getRange(), 1, 3);
    });

    test('between embed across lines', () {
      final selection = _createSelection(
        '<p><img src="/assets/favicon.png">'
        '<img src="/assets/favicon.png"></p>'
        '<p><img src="/assets/favicon.png">'
        '<img src="/assets/favicon.png"></p>',
      );
      selection.setNativeRange(
        selection.root.firstChild!,
        1,
        selection.root.lastChild!,
        1,
      );
      _expectRange(selection.getRange(), 1, 3);
    });

    test('between embed across list', () {
      final selection = _createSelection(
        '<p><img src="/assets/favicon.png">'
        '<img src="/assets/favicon.png"></p>'
        '<ol><li data-list="bullet"><img src="/assets/favicon.png">'
        '<img src="/assets/favicon.png"></li></ol>',
      );
      selection.setNativeRange(
        selection.root.firstChild!,
        1,
        selection.root.lastChild!.firstChild!,
        2,
      );
      _expectRange(selection.getRange(), 1, 3);
    });

    test('between inlines', () {
      final selection =
          _createSelection('<p><em>01</em><s>23</s><u>45</u></p>');
      final line = selection.root.firstChild!;
      selection.setNativeRange(line, 1, line, 2);
      _expectRange(selection.getRange(), 2, 2);
    });

    test('between blocks', () {
      final selection = _createSelection(
        '<p>01</p><p><br></p>'
        '<ol><li data-list="bullet">45</li>'
        '<li data-list="bullet">78</li></ol>',
      );
      selection.setNativeRange(selection.root, 1, selection.root.lastChild!, 1);
      _expectRange(selection.getRange(), 3, 4);
    });

    test('wrong input', () {
      final container = web.document.createElement('div') as web.HTMLElement;
      web.document.body!.appendChild(container);
      addTearDown(() => container.remove());
      final textarea =
          web.document.createElement('textarea') as web.HTMLTextAreaElement;
      container.appendChild(textarea);
      final selection = _createSelection('<p>0123</p>', container: container);
      textarea
        ..focus()
        ..select();
      expect(selection.getRange(), isNull);
    });
  });

  group('Selection.setRange()', () {
    for (final testCase in <(String, String, Range)>[
      ('empty document', '', const Range(0)),
      (
        'empty lines',
        '<p><br></p><ol><li data-list="bullet"><br></li></ol>',
        const Range(0, 1)
      ),
      (
        'nested text node',
        '<p><strong><em>01</em></strong></p>'
            '<ol><li data-list="bullet"><em><u>34</u></em></li></ol>',
        const Range(1, 3)
      ),
      (
        'between inlines',
        '<p><em>01</em><s>23</s><u>45</u></p>',
        const Range(2, 2)
      ),
      (
        'single embed',
        '<p><img src="/assets/favicon.png"></p>',
        const Range(1)
      ),
      (
        'between embeds',
        '<p><img src="/assets/favicon.png">'
            '<img src="/assets/favicon.png"></p>'
            '<ol><li data-list="bullet"><img src="/assets/favicon.png">'
            '<img src="/assets/favicon.png"></li></ol>',
        const Range(1, 3)
      ),
    ]) {
      test(testCase.$1, () {
        final selection = _createSelection(testCase.$2);
        selection.setRange(testCase.$3);
        _expectRange(
            selection.getRange(), testCase.$3.index, testCase.$3.length);
        expect(selection.hasFocus(), isTrue);
      });
    }

    test('null', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(1));
      expect(selection.getRange(), isNotNull);
      selection.setRange(null);
      expect(selection.getRange(), isNull);
      expect(selection.hasFocus(), isFalse);
    });

    test('after format', () async {
      final selection = _createSelection('<p>0123 567 9012</p>');
      selection.setRange(const Range(5));
      selection.format('bold', true);
      selection.format('bold', false);
      selection.setRange(const Range(8));
      await Future<void>.delayed(Duration.zero);
      _expectRange(selection.getRange(), 8);
    });
  });

  group('Selection.format()', () {
    test('trailing', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(4));
      selection.format('bold', true);
      _expectRange(selection.getRange(), 4);
      _expectHtml(selection,
          '<p>0123<strong><span class="ql-cursor">${Cursor.kContents}</span></strong></p>');
    });

    test('split nodes', () {
      final selection = _createSelection('<p><em>0123</em></p>');
      selection.setRange(const Range(2));
      selection.format('bold', true);
      _expectRange(selection.getRange(), 2);
      _expectHtml(
        selection,
        '<p><em>01</em><strong><em><span class="ql-cursor">'
        '${Cursor.kContents}</span></em></strong><em>23</em></p>',
      );
    });

    test('between characters', () {
      final selection = _createSelection('<p><em>0</em><strong>1</strong></p>');
      selection.setRange(const Range(1));
      selection.format('underline', true);
      _expectRange(selection.getRange(), 1);
      _expectHtml(
        selection,
        '<p><em>0<u><span class="ql-cursor">${Cursor.kContents}'
        '</span></u></em><strong>1</strong></p>',
      );
    });

    test('empty line', () {
      final selection = _createSelection('<p><br></p>');
      selection.setRange(const Range(0));
      selection.format('bold', true);
      _expectRange(selection.getRange(), 0);
      _expectHtml(selection,
          '<p><strong><span class="ql-cursor">${Cursor.kContents}</span></strong></p>');
    });

    test('cursor interference', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(2));
      selection.format('underline', true);
      selection.scroll.update();
      final nativeNode = selection.getNativeRange()?.start.node as HtmlDomText?;
      expect(nativeNode?.node,
          same((selection.cursorBlot!.textNode as HtmlDomText).node));
    });

    test('multiple', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(2));
      selection
        ..format('color', 'red')
        ..format('italic', true)
        ..format('underline', true)
        ..format('background', 'blue');
      _expectRange(selection.getRange(), 2);
      _expectHtml(
        selection,
        '<p>01<em style="color: red; background-color: blue;">'
        '<u><span class="ql-cursor">${Cursor.kContents}</span></u>'
        '</em>23</p>',
      );
    });

    test('remove format', () {
      final selection = _createSelection('<p><strong>0123</strong></p>');
      selection.setRange(const Range(2));
      selection
        ..format('italic', true)
        ..format('underline', true)
        ..format('italic', false);
      _expectRange(selection.getRange(), 2);
      _expectHtml(
        selection,
        '<p><strong>01<u><span class="ql-cursor">${Cursor.kContents}'
        '</span></u>23</strong></p>',
      );
    });

    test('selection change cleanup', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(2));
      selection.format('italic', true);
      selection.setRange(const Range(0));
      selection.scroll.update();
      _expectHtml(selection, '<p>0123</p>');
    });

    test('text change cleanup', () {
      final selection = _createSelection('<p>0123</p>');
      selection.setRange(const Range(2));
      selection.format('italic', true);
      final cursor = selection.cursorBlot!;
      cursor.textNode.data = '${Cursor.kContents}|';
      selection.setNativeRange(cursor.textNode, 2);
      selection.scroll.update();
      _expectHtml(selection, '<p>01<em>|</em>23</p>');
    });

    test('no cleanup', () {
      final selection = _createSelection('<p>0123</p><p><br></p>');
      selection.setRange(const Range(2));
      selection.format('italic', true);
      selection.root.lastChild!.remove();
      selection.scroll.update();
      _expectRange(selection.getRange(), 2);
      _expectHtml(
        selection,
        '<p>01<em><span class="ql-cursor">${Cursor.kContents}'
        '</span></em>23</p>',
      );
    });

    group('unlink cursor', () {
      test('one level', () {
        final selection = _createSelection(
          '<p><strong><a href="https://example.com">link</a></strong></p>'
          '<p><br></p>',
        );
        selection.setRange(const Range(4));
        selection.format('bold', false);
        _expectHtml(
          selection,
          '<p><strong><a href="https://example.com">link</a></strong>'
          '<span class="ql-cursor">${Cursor.kContents}</span></p>'
          '<p><br></p>',
        );
      });

      test('nested formats', () {
        final selection = _createSelection(
          '<p><strong><em><a href="https://example.com">bold</a>'
          '</em></strong></p><p><br></p>',
        );
        selection.setRange(const Range(4));
        selection.format('italic', false);
        _expectHtml(
          selection,
          '<p><strong><em><a href="https://example.com">bold</a></em>'
          '<span class="ql-cursor">${Cursor.kContents}</span></strong></p>'
          '<p><br></p>',
        );
      });

      test('ignore link format', () {
        final selection =
            _createSelection('<p><strong>bold</strong></p><p><br></p>');
        selection.setRange(const Range(4));
        selection.format('link', 'https://example.com');
        _expectHtml(
          selection,
          '<p><strong>bold<span class="ql-cursor">${Cursor.kContents}'
          '</span></strong></p><p><br></p>',
        );
      });
    });
  });

  group('Selection.getBounds()', () {
    ({
      double height,
      double left,
      double lineHeight,
      double top,
      double width,
      web.HTMLElement container,
    }) setup() {
      final container = web.document.createElement('div') as web.HTMLElement;
      container
        ..classList.add('ql-editor')
        ..style.fontFamily = 'monospace'
        ..style.lineHeight = '18px';
      web.document.body!.appendChild(container);
      addTearDown(() => container.remove());

      final style = web.document.createElement('style') as web.HTMLStyleElement;
      style.textContent =
          '.ql-editor p, .ql-editor img { margin: 0; padding: 0; border: 0; }';
      web.document.body!.appendChild(style);
      addTearDown(() => style.remove());

      final div = web.document.createElement('div') as web.HTMLElement;
      div
        ..style.border = '1px solid #777'
        ..innerHTML = '<p><span>0</span></p>'.toJS;
      container.appendChild(div);
      final span = div.querySelector('span') as web.HTMLElement;
      final rect = span.getBoundingClientRect();
      final reference = (
        height: rect.height,
        left: rect.left,
        lineHeight:
            (span.parentElement! as web.HTMLElement).offsetHeight.toDouble(),
        top: rect.top,
        width: rect.width,
        container: container,
      );
      div.remove();
      return reference;
    }

    test('empty document', () {
      final ref = setup();
      final selection =
          _createSelection('<p><br></p>', container: ref.container);
      final bounds = selection.getBounds(0)!;
      expect(bounds['left'], closeTo(ref.left, 3));
      expect(bounds['height'], closeTo(ref.height, 3));
      expect(bounds['top'], closeTo(ref.top, 3));
    });

    test('empty line', () {
      final ref = setup();
      final selection = _createSelection(
        '<p>0000</p><p><br></p><p>0000</p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(5)!;
      expect(bounds['left'], closeTo(ref.left, 3));
      expect(bounds['height'], closeTo(ref.height, 3));
      expect(bounds['top'], closeTo(ref.top + ref.lineHeight, 3));
    });

    test('plain text', () {
      final ref = setup();
      final selection =
          _createSelection('<p>0123</p>', container: ref.container);
      final bounds = selection.getBounds(2)!;
      expect(bounds['left'], closeTo(ref.left + ref.width * 2, 2));
      expect(bounds['height'], closeTo(ref.height, 1));
      expect(bounds['top'], closeTo(ref.top, 1));
    });

    test('multiple characters', () {
      final ref = setup();
      final selection =
          _createSelection('<p>0123</p>', container: ref.container);
      final bounds = selection.getBounds(1, 2)!;
      expect(bounds['left'], closeTo(ref.left + ref.width, 2));
      expect(bounds['height'], closeTo(ref.height, 1));
      expect(bounds['top'], closeTo(ref.top, 1));
      expect(bounds['width'], closeTo(ref.width * 2, 2));
    });

    test('start of line', () {
      final ref = setup();
      final selection = _createSelection(
        '<p>0000</p><p>0000</p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(5)!;
      expect(bounds['left'], closeTo(ref.left, 1));
      expect(bounds['height'], closeTo(ref.height, 1));
      expect(bounds['top'], closeTo(ref.top + ref.lineHeight, 1));
    });

    test('end of line', () {
      final ref = setup();
      final selection = _createSelection(
        '<p>0000</p><p>0000</p><p>0000</p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(9)!;
      expect(bounds['left'], closeTo(ref.left + ref.width * 4, 4));
      expect(bounds['height'], closeTo(ref.height, 1));
      expect(bounds['top'], closeTo(ref.top + ref.lineHeight, 1));
    });

    test('selection starting at end of text node', () {
      final ref = setup();
      ref.container.style.width = '${ref.width * 4}px';
      final selection = _createSelection(
        '<p>0000<b>0000</b>0000</p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(4, 1)!;
      expect(bounds['width'], closeTo(ref.width, 1));
    });

    test('multiple lines', () {
      final ref = setup();
      final selection = _createSelection(
        '<p>0000</p><p>0000</p><p>0000</p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(2, 4)!;
      expect(bounds['left'], closeTo(ref.left, 1));
      expect(bounds['height'], closeTo(ref.height * 2, 3));
      expect(bounds['top'], closeTo(ref.top, 1));
      expect(bounds['width'], greaterThan(3 * ref.width));
    });

    test('large text', () {
      final ref = setup();
      final selection = _createSelection(
        '<p><span class="ql-size-large">0000</span></p>',
        container: ref.container,
      );
      final span = _rawRoot(selection).querySelector('span') as web.HTMLElement;
      final bounds = selection.getBounds(2)!;
      expect(
        bounds['left'],
        closeTo(ref.left + span.offsetWidth.toDouble() / 2, 3),
      );
      expect(bounds['height'], closeTo(span.offsetHeight.toDouble(), 3));
      expect(bounds['top'], closeTo(ref.top, 3));
    });

    test('image', () {
      final ref = setup();
      final selection = _createSelection(
        '<p><img src="/assets/favicon.png" width="32px" height="32px">'
        '<img src="/assets/favicon.png" width="32px" height="32px"></p>',
        container: ref.container,
      );
      final bounds = selection.getBounds(1)!;
      expect(bounds['left'], closeTo(ref.left + 32, 1));
      expect(bounds['height'], closeTo(32, 1));
      expect(bounds['top'], closeTo(ref.top, 3));
    });

    test('beyond document', () {
      final selection = _createSelection('<p>0123</p>');
      expect(() => selection.getBounds(10), returnsNormally);
      expect(() => selection.getBounds(0, 10), returnsNormally);
    });
  });
}
