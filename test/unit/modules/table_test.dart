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
      test('creates a contextual toolbar with Tabler table actions', () {
        final quill = _createQuill('<p><br></p>');
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));
        table.insertTable(2, 2);
        quill.setSelection(const Range(0, 0));
        table.updateContextToolbar();

        final contextToolbar = quill.container
            .querySelectorAll('div')
            .where((element) =>
                element.classes.contains('ql-table-context-toolbar'))
            .single;
        final actions = contextToolbar.querySelectorAll('button');
        expect(actions, hasLength(9));
        expect(contextToolbar.getAttribute('role'), 'toolbar');
        expect(actions.first.getAttribute('title'), 'Inserir linha acima');
        expect(actions.last.getAttribute('title'), 'Excluir tabela');
        expect(actions.first.innerHTML, contains('ti-row-insert-top'));
      });

      test('merge right and split preserve logical column count', () {
        final quill = _createQuill('''
          <table><tbody>
            <tr><td>a1</td><td>a2</td><td>a3</td></tr>
            <tr><td>b1</td><td>b2</td><td>b3</td></tr>
          </tbody></table>
        ''');
        final table = quill.getModule('table') as Table;
        quill.setSelection(const Range(0, 0));

        table.mergeCellRight();

        final rows = quill.root.querySelectorAll('tr');
        final firstRowCells = rows.first.querySelectorAll('td');
        expect(firstRowCells, hasLength(2));
        expect(firstRowCells.first.getAttribute('colspan'), '2');
        expect(firstRowCells.first.text, contains('a1'));
        expect(firstRowCells.first.text, contains('a2'));
        expect(rows.last.querySelectorAll('td'), hasLength(3));

        table.splitCell();

        final splitCells = rows.first.querySelectorAll('td');
        expect(splitCells, hasLength(3));
        expect(splitCells.first.hasAttribute('colspan'), isFalse);
      });

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

      test('getTable exposes the active hierarchy and cell offset', () {
        final quill = _setup();
        final table = quill.getModule('table') as Table;

        final context = table.getTable(const Range(1, 0));

        expect(context.table, isNotNull);
        expect(context.row, isNotNull);
        expect(context.cell, isNotNull);
        expect(context.cell!.element.text, 'a1');
        expect(context.offset, 1);

        final outsideQuill = _createQuill(
          '<p>outside</p><table><tbody><tr><td>inside</td></tr></tbody></table>',
        );
        final outsideTable = outsideQuill.getModule('table') as Table;
        final outsideContext = outsideTable.getTable(const Range(0, 0));
        expect(outsideContext.table, isNull);
        expect(outsideContext.row, isNull);
        expect(outsideContext.cell, isNull);
        expect(outsideContext.offset, -1);
      });

      test('insertRow and insertColumn accept upstream offsets directly', () {
        final rowQuill = _setup();
        final rowTable = rowQuill.getModule('table') as Table;
        rowQuill.setSelection(const Range(0, 0));
        rowTable.insertRow(1);
        expect(rowQuill.root.querySelectorAll('tr'), hasLength(3));
        expect(
          rowQuill.root.querySelectorAll('tr')[1].querySelectorAll('td'),
          hasLength(3),
        );

        final columnQuill = _setup();
        final columnTable = columnQuill.getModule('table') as Table;
        columnQuill.setSelection(const Range(0, 0));
        columnTable.insertColumn(1);
        final rows = columnQuill.root.querySelectorAll('tr');
        expect(rows, hasLength(2));
        expect(rows.every((row) => row.querySelectorAll('td').length == 4),
            isTrue);
        expect(rows.first.querySelectorAll('td')[1].innerHTML, '<br>');
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
        quill.updateContents(Delta()
          ..retain(18)
          ..insert('\n'));
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
