import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

DomElement _createContainer([String html = '']) {
  ensureQuillTestInitialized();
  final container = testAdapter.document.createElement('div');
  if (html.isNotEmpty) {
    container.innerHTML = normalizeHTML(html);
  }
  testAdapter.document.body.append(container);
  addTearDown(container.remove);
  return container;
}

class _ToolbarFixture {
  _ToolbarFixture(this.quill, this.toolbar);

  final Quill quill;
  final Toolbar toolbar;

  DomElement get container => toolbar.container!;
}

DomElement _requireElement(DomElement? element) {
  expect(element, isNotNull);
  return element!;
}

DomElement? _getButtonByClass(
  DomElement container,
  String className, {
  String? value,
}) {
  for (final button in container.querySelectorAll('button')) {
    if (!button.classes.contains(className)) {
      continue;
    }
    if (value != null && (button.getAttribute('value') ?? '') != value) {
      continue;
    }
    return button;
  }
  return null;
}

DomElement? _getSelectByClass(DomElement container, String className) {
  for (final select in container.querySelectorAll('select')) {
    if (select.classes.contains(className)) {
      return select;
    }
  }
  return null;
}

_ToolbarFixture _createToolbarFixture() {
  final html = normalizeHTML('''
    <p>0123</p>
    <p><strong>5678</strong></p>
    <p><a href="http://quilljs.com/">0123</a></p>
    <h1>Title</h1>
    <h2>Subhead</h2>
    <p>Normal</p>
    <p>Sup<sup>12</sup></p>
  ''');

  final quill = createTestQuill(
    initialHtml: html,
    modules: {
      'toolbar': [
        ['bold', 'link'],
        [
          {
            'header': [1, 2, false]
          },
        ],
        [
          {'header': ''},
          {'header': '2'},
        ],
      ],
    },
    theme: 'snow',
  );

  final toolbar = quill.theme.modules['toolbar'] as Toolbar;
  return _ToolbarFixture(quill, toolbar);
}

void main() {
  group('Toolbar addControls', () {
    test('generated controls expose localized titles', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            [
              {'list': 'bullet'},
              {'table': '3x3'},
              'clean',
            ],
          ]));

      expect(_getButtonByClass(container, 'ql-list')?.getAttribute('title'),
          'Lista com marcadores');
      expect(_getButtonByClass(container, 'ql-table')?.getAttribute('title'),
          'Inserir tabela');
      expect(_getButtonByClass(container, 'ql-clean')?.getAttribute('title'),
          'Limpar formatação');
    });

    test('single group', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            ['bold', 'italic'],
          ]));

      expectHTML(
        container,
        '''
        <span class="ql-formats">
          <button class="ql-bold" type="button" aria-label="bold" aria-pressed="false"></button>
          <button class="ql-italic" type="button" aria-label="italic" aria-pressed="false"></button>
        </span>
        ''',
      );
    });

    test('multiple groups', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            ['bold', 'italic'],
            ['underline', 'strike'],
          ]));

      expectHTML(
        container,
        '''
        <span class="ql-formats">
          <button class="ql-bold" type="button" aria-label="bold" aria-pressed="false"></button>
          <button class="ql-italic" type="button" aria-label="italic" aria-pressed="false"></button>
        </span>
        <span class="ql-formats">
          <button class="ql-underline" type="button" aria-label="underline" aria-pressed="false"></button>
          <button class="ql-strike" type="button" aria-label="strike" aria-pressed="false"></button>
        </span>
        ''',
      );
    });

    test('button with value', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            [
              'bold',
              {'header': '2'}
            ],
          ]));

      expectHTML(
        container,
        '''
        <span class="ql-formats">
          <button class="ql-bold" type="button" aria-label="bold" aria-pressed="false"></button>
          <button class="ql-header" type="button" value="2" aria-label="header: 2" aria-pressed="false"></button>
        </span>
        ''',
      );
    });

    test('select control', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            [
              {
                'size': ['10px', false, '18px', '32px'],
              },
            ],
          ]));

      expectHTML(
        container,
        '''
        <span class="ql-formats">
          <select class="ql-size" aria-label="size">
            <option value="10px"></option>
            <option selected="selected"></option>
            <option value="18px"></option>
            <option value="32px"></option>
          </select>
        </span>
        ''',
      );
    });

    test('complex layout', () {
      final container = _createContainer();
      addControls(
          container,
          ToolbarConfig([
            [
              {
                'font': [false, 'sans-serif', 'monospace']
              },
              {
                'size': ['10px', false, '18px', '32px']
              },
            ],
            ['bold', 'italic', 'underline', 'strike'],
            [
              {'list': 'ordered'},
              {'list': 'bullet'},
              {
                'align': [false, 'center', 'right', 'justify']
              },
            ],
            ['link', 'image'],
          ]));

      expectHTML(
        container,
        '''
        <span class="ql-formats">
          <select class="ql-font" aria-label="font">
            <option selected="selected"></option>
            <option value="sans-serif"></option>
            <option value="monospace"></option>
          </select>
          <select class="ql-size" aria-label="size">
            <option value="10px"></option>
            <option selected="selected"></option>
            <option value="18px"></option>
            <option value="32px"></option>
          </select>
        </span>
        <span class="ql-formats">
          <button class="ql-bold" type="button" aria-label="bold" aria-pressed="false"></button>
          <button class="ql-italic" type="button" aria-label="italic" aria-pressed="false"></button>
          <button class="ql-underline" type="button" aria-label="underline" aria-pressed="false"></button>
          <button class="ql-strike" type="button" aria-label="strike" aria-pressed="false"></button>
        </span>
        <span class="ql-formats">
          <button class="ql-list" type="button" value="ordered" aria-label="list: ordered" aria-pressed="false"></button>
          <button class="ql-list" type="button" value="bullet" aria-label="list: bullet" aria-pressed="false"></button>
          <select class="ql-align" aria-label="align">
            <option selected="selected"></option>
            <option value="center"></option>
            <option value="right"></option>
            <option value="justify"></option>
          </select>
        </span>
        <span class="ql-formats">
          <button class="ql-link" type="button" aria-label="link" aria-pressed="false"></button>
          <button class="ql-image" type="button" aria-label="image" aria-pressed="false"></button>
        </span>
        ''',
      );
    });
  });

  group('Toolbar active state updates', () {
    test('table button builds a quill-table-better style 10x10 picker', () {
      final quill = createTestQuill(
        initialHtml: '<p><br></p>',
        modules: {
          'toolbar': [
            [
              {'table': '3x3'}
            ],
          ],
        },
        theme: 'snow',
      );
      final toolbar = quill.getModule('toolbar') as Toolbar;
      final pickers = toolbar.container!
          .querySelectorAll('div')
          .where((element) =>
              element.classes.contains('ql-table-select-container'))
          .toList();
      expect(pickers, hasLength(1), reason: toolbar.container!.innerHTML);
      final picker = pickers.single;
      final cells = picker
          .querySelectorAll('span')
          .where((element) => element.hasAttribute('data-row'))
          .toList();

      expect(cells, hasLength(100));
      expect(cells.first.getAttribute('data-row'), '1');
      expect(cells.first.getAttribute('data-column'), '1');
      expect(cells.last.getAttribute('data-row'), '10');
      expect(cells.last.getAttribute('data-column'), '10');
      expect(picker.getAttribute('role'), 'dialog');
    });

    test('block formats apply to every selected line', () {
      final quill = createTestQuill(initialHtml: '<p>one</p><p>two</p>');
      quill.setSelection(const Range(0, 7), source: EmitterSource.USER);

      quill.format('align', 'center', source: EmitterSource.USER);

      final paragraphs = quill.root.querySelectorAll('p');
      expect(paragraphs, hasLength(2));
      expect(paragraphs.every((p) => p.classes.contains('ql-align-center')),
          isTrue,
          reason: quill.root.innerHTML);

      quill.format('list', 'bullet', source: EmitterSource.USER);
      expect(quill.root.querySelectorAll('li'), hasLength(2));
      expect(quill.getFormat(0)['list'], equals('bullet'));
      expect(quill.getFormat(4)['list'], equals('bullet'));
    });

    test('clean removes inline styles and list formatting', () {
      final quill = createTestQuill(
        initialHtml: '<ul><li><strong>one</strong></li><li>two</li></ul>',
      );

      quill.removeFormat(0, 7, source: EmitterSource.USER);

      expect(quill.root.querySelectorAll('ul'), isEmpty,
          reason: quill.root.innerHTML);
      expect(quill.root.querySelectorAll('li'), isEmpty);
      expect(quill.root.querySelectorAll('strong'), isEmpty);
      expect(quill.root.querySelectorAll('p'), hasLength(2));
    });

    test('toggle button reflects formats', () {
      final fixture = _createToolbarFixture();
      final boldButton = _requireElement(
        _getButtonByClass(fixture.container, 'ql-bold'),
      );

      fixture.quill.setSelection(const Range(7, 0), source: EmitterSource.USER);
      expect(boldButton.classes.contains('ql-active'), isTrue);
      expect(boldButton.getAttribute('aria-pressed'), equals('true'));

      fixture.quill.setSelection(const Range(2, 0), source: EmitterSource.USER);
      expect(boldButton.classes.contains('ql-active'), isFalse);
      expect(boldButton.getAttribute('aria-pressed'), equals('false'));
    });

    test('link button toggles with selection', () {
      final fixture = _createToolbarFixture();
      final linkButton = _requireElement(
        _getButtonByClass(fixture.container, 'ql-link'),
      );

      fixture.quill
          .setSelection(const Range(12, 0), source: EmitterSource.USER);
      expect(linkButton.classes.contains('ql-active'), isTrue);
      expect(linkButton.getAttribute('aria-pressed'), equals('true'));

      fixture.quill.setSelection(const Range(2, 0), source: EmitterSource.USER);
      expect(linkButton.classes.contains('ql-active'), isFalse);
      expect(linkButton.getAttribute('aria-pressed'), equals('false'));
    });

    test('dropdown selection tracks formats', () {
      final fixture = _createToolbarFixture();
      final sizeSelect = _requireElement(
        _getSelectByClass(fixture.container, 'ql-header'),
      );
      final options = sizeSelect.querySelectorAll('option');

      bool isSelected(int index) => options[index].hasAttribute('selected');
      bool noneSelected() =>
          options.every((opt) => !opt.hasAttribute('selected'));

      fixture.quill
          .setSelection(const Range(15, 0), source: EmitterSource.USER);
      expect(fixture.quill.getFormat(15, 0)['header'], equals(1));
      expect(isSelected(0), isTrue);

      fixture.quill
          .setSelection(const Range(21, 0), source: EmitterSource.USER);
      expect(fixture.quill.getFormat(21, 0)['header'], equals(2));
      expect(isSelected(1), isTrue);

      fixture.quill
          .setSelection(const Range(15, 13), source: EmitterSource.USER);
      expect(noneSelected(), isTrue);

      fixture.quill.setSelection(const Range(2, 0), source: EmitterSource.USER);
      expect(fixture.quill.getFormat(2, 0).containsKey('header'), isFalse);
      expect(isSelected(2), isTrue);
    });

    test('custom buttons reflect header buttons', () {
      final fixture = _createToolbarFixture();
      final centerButton = _requireElement(
        _getButtonByClass(fixture.container, 'ql-header', value: '2'),
      );
      final defaultButton = _requireElement(
        _getButtonByClass(fixture.container, 'ql-header', value: ''),
      );

      fixture.quill
          .setSelection(const Range(21, 0), source: EmitterSource.USER);
      expect(centerButton.classes.contains('ql-active'), isTrue);
      expect(defaultButton.classes.contains('ql-active'), isFalse);
      expect(centerButton.getAttribute('aria-pressed'), equals('true'));
      expect(defaultButton.getAttribute('aria-pressed'), equals('false'));

      fixture.quill.setSelection(const Range(2, 0), source: EmitterSource.USER);
      expect(centerButton.classes.contains('ql-active'), isFalse);
      expect(defaultButton.classes.contains('ql-active'), isTrue);
      expect(centerButton.getAttribute('aria-pressed'), equals('false'));
      expect(defaultButton.getAttribute('aria-pressed'), equals('true'));

      fixture.toolbar.update(null);
      expect(centerButton.classes.contains('ql-active'), isFalse);
      expect(defaultButton.classes.contains('ql-active'), isFalse);
      expect(centerButton.getAttribute('aria-pressed'), equals('false'));
      expect(defaultButton.getAttribute('aria-pressed'), equals('false'));
    });

    test('toolbar updates after formatting', () {
      final fixture = _createToolbarFixture();
      final boldButton = _requireElement(
        _getButtonByClass(fixture.container, 'ql-bold'),
      );

      fixture.quill.setSelection(const Range(1, 2), source: EmitterSource.USER);
      expect(boldButton.classes.contains('ql-active'), isFalse);

      fixture.quill.format('bold', true, source: EmitterSource.USER);
      expect(boldButton.classes.contains('ql-active'), isTrue);
    });
  });
}
