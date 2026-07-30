import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/formats/table.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/formats/table.spec.ts`.
Editor _createEditor(String html) => Editor(createScrollWithFormats(html, [
      'formats/table-container',
      'formats/table-body',
      'formats/table-row',
      'formats/table',
      'formats/header',
    ]));

final Delta _tableDelta = Delta()
  ..insert('A1')
  ..insert('\n', {'table': 'a'})
  ..insert('A2')
  ..insert('\n', {'table': 'a'})
  ..insert('A3')
  ..insert('\n', {'table': 'a'})
  ..insert('B1')
  ..insert('\n', {'table': 'b'})
  ..insert('B2')
  ..insert('\n', {'table': 'b'})
  ..insert('B3')
  ..insert('\n', {'table': 'b'})
  ..insert('C1')
  ..insert('\n', {'table': 'c'})
  ..insert('C2')
  ..insert('\n', {'table': 'c'})
  ..insert('C3')
  ..insert('\n', {'table': 'c'});

const String _tableHtml = '''
  <table>
    <tbody>
      <tr>
        <td data-row="a">A1</td>
        <td data-row="a">A2</td>
        <td data-row="a">A3</td>
      </tr>
      <tr>
        <td data-row="b">B1</td>
        <td data-row="b">B2</td>
        <td data-row="b">B3</td>
      </tr>
      <tr>
        <td data-row="c">C1</td>
        <td data-row="c">C2</td>
        <td data-row="c">C3</td>
      </tr>
    </tbody>
  </table>
''';

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Table', () {
    test('initialize', () {
      final editor = _createEditor(_tableHtml);
      expectDelta(editor.getDelta(), _tableDelta);
      expect(editor.scroll.element, EqualHTML(_tableHtml));
    });

    test('add', () {
      final editor = _createEditor('');
      editor.applyDelta(Delta.from(_tableDelta)..delete(1));
      expect(editor.scroll.element, EqualHTML(_tableHtml));
    });

    test('add format plaintext', () {
      final editor = _createEditor('<p>Test</p>');
      editor.formatLine(0, 5, {'table': 'a'});
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody><tr>
            <td data-row="a">Test</td>
          </tr></tbody></table>
        '''),
      );
    });

    test('add format replace', () {
      final editor = _createEditor('<h1>Test</h1>');
      editor.formatLine(0, 5, {'table': 'a'});
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody><tr>
            <td data-row="a">Test</td>
          </tr></tbody></table>
        '''),
      );
    });

    test('remove format plaintext', () {
      final editor =
          _createEditor('<table><tr><td data-row="a">Test</td></tr></table>');
      editor.formatLine(0, 5, {'table': null});
      expect(editor.scroll.element, EqualHTML('<p>Test</p>'));
    });

    test('remove format replace', () {
      final editor =
          _createEditor('<table><tr><td data-row="a">Test</td></tr></table>');
      editor.formatLine(0, 5, {'header': 1});
      expect(editor.scroll.element, EqualHTML('<h1>Test</h1>'));
    });

    test('group rows', () {
      final editor = _createEditor('''
        <table><tbody>
          <tr><td data-row="a">A</td></tr>
          <tr><td data-row="a">B</td></tr>
        </tbody></table>
      ''');
      final table = editor.scroll.children.first as TableContainer;
      final body = table.children.first as TableBody;
      (body.children.first as TableRow).optimize();
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody><tr>
            <td data-row="a">A</td>
            <td data-row="a">B</td>
          </tr></tbody></table>
        '''),
      );
    });

    test('split rows', () {
      final editor = _createEditor('''
        <table><tbody><tr>
          <td data-row="a">A</td><td data-row="b">B</td>
        </tr></tbody></table>
      ''');
      final table = editor.scroll.children.first as TableContainer;
      final body = table.children.first as TableBody;
      (body.children.first as TableRow).optimize();
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="a">A</td></tr>
            <tr><td data-row="b">B</td></tr>
          </tbody></table>
        '''),
      );
    });

    test('group and split rows', () {
      final editor = _createEditor('''
        <table><tbody>
          <tr><td data-row="a">A</td><td data-row="b">B1</td></tr>
          <tr><td data-row="b">B2</td></tr>
        </tbody></table>
      ''');
      final table = editor.scroll.children.first as TableContainer;
      final body = table.children.first as TableBody;
      (body.children.first as TableRow).optimize();
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="a">A</td></tr>
            <tr><td data-row="b">B1</td><td data-row="b">B2</td></tr>
          </tbody></table>
        '''),
      );
    });

    test('balance cells', () {
      final editor = _createEditor('''
        <table><tbody>
          <tr><td data-row="a">A1</td></tr>
          <tr><td data-row="b">B1</td><td data-row="b">B2</td></tr>
          <tr><td data-row="c">C1</td><td data-row="c">C2</td>
              <td data-row="c">C3</td></tr>
        </tbody></table>
      ''');
      (editor.scroll.children.first as TableContainer).balanceCells();
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="a">A1</td><td data-row="a"><br></td>
                <td data-row="a"><br></td></tr>
            <tr><td data-row="b">B1</td><td data-row="b">B2</td>
                <td data-row="b"><br></td></tr>
            <tr><td data-row="c">C1</td><td data-row="c">C2</td>
                <td data-row="c">C3</td></tr>
          </tbody></table>
        '''),
      );
    });

    test('format', () {
      final editor = _createEditor('<p>a</p><p>b</p><p>1</p><p>2</p>');
      editor.formatLine(0, 4, {'table': 'a'});
      editor.formatLine(4, 4, {'table': 'b'});
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="a">a</td><td data-row="a">b</td></tr>
            <tr><td data-row="b">1</td><td data-row="b">2</td></tr>
          </tbody></table>
        '''),
      );
    });

    test('applyDelta', () {
      final editor = _createEditor('<p><br></p>');
      editor.applyDelta(
        Delta()
          ..insert('\n\n', {'table': 'a'})
          ..insert('\n\n', {'table': 'b'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="a"><br></td><td data-row="a"><br></td></tr>
            <tr><td data-row="b"><br></td><td data-row="b"><br></td></tr>
          </tbody></table>
          <p><br></p>
        '''),
      );
    });

    test('unbalanced table applyDelta', () {
      final editor = _createEditor('<p><br></p>');
      editor.applyDelta(
        Delta()
          ..insert('A1\nB1\nC1\n', {'table': '1'})
          ..insert('A2\nB2\nC2\n', {'table': '2'})
          ..insert('A3\nB3\n', {'table': '3'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="1">A1</td><td data-row="1">B1</td>
                <td data-row="1">C1</td></tr>
            <tr><td data-row="2">A2</td><td data-row="2">B2</td>
                <td data-row="2">C2</td></tr>
            <tr><td data-row="3">A3</td><td data-row="3">B3</td></tr>
          </tbody></table>
          <p><br></p>
        '''),
      );
    });

    test('existing table applyDelta', () {
      final editor = _createEditor('''
        <table><tbody>
          <tr><td data-row="1">A1</td></tr>
          <tr><td data-row="2"><br></td><td data-row="2">B1</td></tr>
        </tbody></table>
      ''');
      editor.applyDelta(
        Delta()
          ..retain(3)
          ..retain(1, {'table': '1'})
          ..insert('\n', {'table': '2'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <table><tbody>
            <tr><td data-row="1">A1</td><td data-row="1"><br></td></tr>
            <tr><td data-row="2"><br></td><td data-row="2">B1</td></tr>
          </tbody></table>
        '''),
      );
    });
  });
}
