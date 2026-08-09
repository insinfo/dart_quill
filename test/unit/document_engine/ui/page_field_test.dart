/// O campo Nº de Página: inserir o CAMPO, não o número.
///
/// A diferença que estes testes protegem é a única que importa aqui: um
/// cabeçalho com o texto "1" diz "1" em todas as páginas; um cabeçalho com
/// o campo `PAGE` diz 1, 2, 3… O compositor já resolvia campos IMPORTADOS —
/// o que faltava era o caminho de criação, e ele tem de produzir exatamente
/// a mesma forma, senão o layout resolve e o Word não reconhece.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();

  late DomAdapter adapter;
  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  PMNode paragraph(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  /// Os marcadores de campo do documento, em ordem.
  List<String> fieldMarkersOf(PMNode doc) {
    final markers = <String>[];
    doc.descendants((node, pos, parent, index) {
      if (node.type.name != 'opaqueInline') return true;
      final insert = node.attrs['insert'];
      if (insert is Map && insert['fieldMarker'] != null) {
        markers.add('${insert['fieldMarker']}');
      }
      return true;
    });
    return markers;
  }

  String? fieldXmlOf(PMNode doc, String marker) {
    String? xml;
    doc.descendants((node, pos, parent, index) {
      if (xml != null || node.type.name != 'opaqueInline') return true;
      final insert = node.attrs['insert'];
      if (insert is Map && insert['fieldMarker'] == marker) {
        xml = '${insert['officeXml']}';
      }
      return true;
    });
    return xml;
  }

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node('doc', null, Fragment.from([paragraph('capa')])),
        schema: schema,
      );

  test('insere a sequência begin/instrução/separate/end, não texto', () {
    final editor = mount();
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, 1)));

    insertPageField(editor);

    expect(fieldMarkersOf(editor.state.doc),
        ['begin', 'instruction', 'separate', 'end']);
    // Nenhum dígito foi escrito como TEXTO — é isso que evita o "1" em
    // todas as páginas.
    expect(editor.state.doc.textContent, 'capa');
  });

  test('o officeXml é o do OOXML, para o Word reconhecer no arquivo', () {
    final editor = mount();
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, 1)));

    insertPageField(editor);

    expect(fieldXmlOf(editor.state.doc, 'begin'),
        '<w:fldChar w:fldCharType="begin"/>');
    expect(
        fieldXmlOf(editor.state.doc, 'instruction'), contains('<w:instrText'));
    expect(fieldXmlOf(editor.state.doc, 'instruction'), contains(' PAGE '));
    expect(fieldXmlOf(editor.state.doc, 'separate'),
        '<w:fldChar w:fldCharType="separate"/>');
    expect(fieldXmlOf(editor.state.doc, 'end'),
        '<w:fldChar w:fldCharType="end"/>');
  });

  test('NUMPAGES usa a mesma forma com outra instrução', () {
    final editor = mount();
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, 1)));

    insertPageField(editor, command: 'NUMPAGES');

    expect(fieldXmlOf(editor.state.doc, 'instruction'), contains(' NUMPAGES '));
    var command = '';
    editor.state.doc.descendants((node, pos, parent, index) {
      final insert =
          node.type.name == 'opaqueInline' ? node.attrs['insert'] : null;
      if (insert is Map && insert['fieldMarker'] == 'separate') {
        command = '${insert['fieldCommand']}';
      }
      return true;
    });
    expect(command, 'NUMPAGES');
  });

  test('o COMPOSITOR resolve o campo criado, página a página', () {
    // Um rodapé com o campo, exatamente como a sessão de cabeçalho o
    // deixaria: "Página " + campo PAGE.
    final editor = mount();
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, 1)));
    insertPageField(editor);
    // O parágrafo editado vira a região.
    final region =
        schema.node('doc', null, Fragment.from([editor.state.doc.child(0)]));

    final composer = LayoutComposer(footer: region);
    final graph = composer.compose(schema.node(
        'doc',
        null,
        Fragment.from([
          for (var i = 0; i < 120; i++)
            paragraph('Parágrafo $i com texto suficiente para paginar.'),
        ])));
    expect(graph.pages.length, greaterThan(2));

    String footerText(PageLayout page) => [
          for (final fragment in page.footer)
            for (final line in fragment.lines)
              for (final segment in line.segments) segment.text
        ].join();

    expect(footerText(graph.pages[0]), contains('1'));
    expect(footerText(graph.pages[1]), contains('2'));
    expect(footerText(graph.pages[2]), contains('3'),
        reason: 'o campo resolve POR PÁGINA — é para isso que ele existe');
  });

  test('undo remove o campo inteiro, não marcador por marcador', () {
    final editor = mount();
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, 1)));
    insertPageField(editor);
    expect(fieldMarkersOf(editor.state.doc), hasLength(4));

    editor.runCommand('undo');

    expect(fieldMarkersOf(editor.state.doc), isEmpty);
  });
}
