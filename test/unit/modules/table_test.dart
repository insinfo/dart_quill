import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/table.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

Quill _createQuill(String html) {
  return createTestQuill(
    initialHtml: html,
    modules: {'table': true},
  );
}

void main() {
  group('Table Module', () {
    group('insert table', () {
      test('empty', () {
        final quill = _createQuill('<p><br></p>');
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertTable(2, 3);
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td><br></td><td><br></td><td><br></td></tr>
                <tr><td><br></td><td><br></td><td><br></td></tr>
              </tbody>
            </table>
            <p><br></p>
            ''',
          ),
        );
      });

      test('split', () {
        final quill = _createQuill('<p>0123</p>');
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(2, 0));
        table.insertTable(2, 3);
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>01</td><td><br></td><td><br></td></tr>
                <tr><td><br></td><td><br></td><td><br></td></tr>
              </tbody>
            </table>
            <p>23</p>
            ''',
          ),
        );
      });
    });

    group('modify table', () {
      Quill _setup() {
        const html = '''
          <table>
            <tbody>
              <tr><td>a1</td><td>a2</td><td>a3</td></tr>
              <tr><td>b1</td><td>b2</td><td>b3</td></tr>
            </tbody>
          </table>
        ''';
        return _createQuill(html);
      }

      test('insertRowAbove', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertRowAbove();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td><br></td><td><br></td><td><br></td></tr>
                <tr><td>a1</td><td>a2</td><td>a3</td></tr>
                <tr><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('insertRowBelow', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertRowBelow();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>a1</td><td>a2</td><td>a3</td></tr>
                <tr><td><br></td><td><br></td><td><br></td></tr>
                <tr><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('insertColumnLeft', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertColumnLeft();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td><br></td><td>a1</td><td>a2</td><td>a3</td></tr>
                <tr><td><br></td><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('insertColumnRight', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertColumnRight();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>a1</td><td><br></td><td>a2</td><td>a3</td></tr>
                <tr><td>b1</td><td><br></td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('deleteRow', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.deleteRow();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('deleteColumn', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.deleteColumn();
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>a2</td><td>a3</td></tr>
                <tr><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('insertText before', () {
        final quill = _setup();
        quill.updateContents(Delta()..insert('\n'));
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <p><br></p>
            <table>
              <tbody>
                <tr><td>a1</td><td>a2</td><td>a3</td></tr>
                <tr><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            ''',
          ),
        );
      });

      test('insertText after', () {
        final quill = _setup();
        quill.updateContents(Delta()..retain(18)..insert('\n'));
        expect(
          quill.root,
          quill.root.toEqualHTML(
            '''
            <table>
              <tbody>
                <tr><td>a1</td><td>a2</td><td>a3</td></tr>
                <tr><td>b1</td><td>b2</td><td>b3</td></tr>
              </tbody>
            </table>
            <p><br></p>
            ''',
          ),
        );
      });
    });
  });
}
