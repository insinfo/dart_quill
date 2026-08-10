/// Inserir → Folha de Rosto (F10).
///
/// O critério aqui não é "inseriu parágrafos": é a capa ser uma PÁGINA de
/// verdade (o documento passa a ter uma página a mais e o texto antigo
/// começa na seguinte), ser DESENHADA com o corpo que ela declara, e chegar
/// ao arquivo com essa mesma formatação. Uma capa que só existe na tela seria
/// pior que nenhuma — o usuário só descobre ao abrir o DOCX no Word.
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/docx/validator.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
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

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node(
            'doc', null, Fragment.from([paragraph('primeiro parágrafo')])),
        schema: schema,
      );

  void click(DomElement el) => (el as FakeDomElement)
      .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: el));

  test('a aba Inserir abre a galeria e o item insere a capa', () {
    final e = mount();
    for (final tab in host.querySelectorAll('.dq-office-ribbon-tab')) {
      if (tab.textContent == 'Inserir') click(tab);
    }
    DomElement? button;
    for (final b in host.querySelectorAll('.dq-office-btn')) {
      if ((b.getAttribute('title') ?? '') == 'Folha de Rosto') button = b;
    }
    expect(button, isNotNull, reason: 'o botão tem de existir na aba Inserir');
    click(button!);

    DomElement? item;
    for (final entry in host.querySelectorAll('.dq-office-menu-item')) {
      if ((entry.textContent ?? '').contains('Centralizada')) item = entry;
    }
    expect(item, isNotNull);
    click(item!);

    expect(e.pageGraph.pages, hasLength(2));
    expect(host.textContent, contains(officeCoverTitlePlaceholder));
  });

  test('a galeria não promete capas que o compositor não desenha', () {
    // Duas capas TIPOGRÁFICAS. Se um dia aparecer uma com faixa colorida
    // aqui, é porque o compositor passou a desenhar forma decorativa.
    expect(
        officeCoverPageLayouts.map((l) => l.id), ['centralizada', 'alinhada']);
  });

  test('a capa vira a PÁGINA 1 e empurra o documento para a página 2', () {
    final e = mount();
    expect(e.pageGraph.pages, hasLength(1));

    insertCoverPage(e, 'centralizada');

    expect(e.pageGraph.pages, hasLength(2),
        reason: 'uma folha de rosto que divide a página com o texto não é '
            'uma folha de rosto');
    // O parágrafo que era o primeiro abre a página 2.
    final second = e.pageGraph.pages[1].fragments.first;
    expect(second.docPos, isNotNull);
    expect(e.state.doc.child(e.state.doc.childCount - 1).textContent,
        'primeiro parágrafo');
  });

  test('a capa é PROJETADA com os textos de exemplo', () {
    final e = mount();
    insertCoverPage(e, 'centralizada');

    final text = host.textContent ?? '';
    expect(text, contains(officeCoverTitlePlaceholder));
    expect(text, contains(officeCoverSubtitlePlaceholder));
    expect(text, contains(officeCoverAuthorPlaceholder));
  });

  test('os títulos e nomes informados substituem os exemplos', () {
    final e = mount();
    insertCoverPage(
      e,
      'alinhada',
      title: 'Estudo Técnico Preliminar',
      subtitle: 'Contratação de serviços',
      author: 'Secretaria de TI',
      date: DateTime(2026, 8, 9),
    );

    final text = host.textContent ?? '';
    expect(text, contains('Estudo Técnico Preliminar'));
    expect(text, contains('Contratação de serviços'));
    expect(text, contains('Secretaria de TI'));
    expect(text, contains('09/08/2026'));
  });

  test('o título é COMPOSTO no corpo que ele declara', () {
    final e = mount();
    insertCoverPage(e, 'centralizada');

    // O corpo vem de uma marca de run, não do mapa de bloco: é a marca que
    // sobrevive à exportação.
    final title = e.state.doc.child(0);
    final marks = title.firstChild!.marks.map((m) => m.type.name).toList();
    expect(marks, contains('size'));
    expect(marks, contains('bold'));

    // E o compositor DESENHA nesse corpo: a linha do título é mais alta que
    // a de um parágrafo comum.
    final page = e.pageGraph.pages.first;
    final first = page.fragments.whereType<BlockFragment>().first;
    expect(first.lines.first.segments.first.style.sizePt, 28);
    expect(first.lines.first.segments.first.style.bold, isTrue);
  });

  test('as capas centralizada e alinhada diferem no alinhamento composto', () {
    final centered = mount();
    insertCoverPage(centered, 'centralizada');
    final centeredAlign = centered.pageGraph.pages.first.fragments
        .whereType<BlockFragment>()
        .first
        .align;
    editor?.dispose();
    editor = null;
    host.remove();
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);

    final left = mount();
    insertCoverPage(left, 'alinhada');
    final leftAlign = left.pageGraph.pages.first.fragments
        .whereType<BlockFragment>()
        .first
        .align;

    expect(centeredAlign, isNot(leftAlign));
  });

  test('um id inexistente não escreve nada', () {
    final e = mount();
    final before = e.state.doc;

    expect(insertCoverPage(e, 'faceta'), isFalse);

    expect(identical(e.state.doc, before), isTrue);
  });

  test('inserir a capa é UM passo de undo', () {
    final e = mount();
    final before = e.state.doc;
    insertCoverPage(e, 'centralizada');

    e.runCommand('undo');

    expect(e.state.doc.eq(before), isTrue);
    expect(e.pageGraph.pages, hasLength(1));
  });

  test('a capa exportada abre com o mesmo corpo e a mesma quebra', () {
    final e = mount();
    insertCoverPage(e, 'centralizada', title: 'CAPA EXPORTADA');
    final bytes = e.exportDocx();

    expect(DocxValidator.validate(bytes), isEmpty);
    final xml = ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;
    expect(xml, contains('CAPA EXPORTADA'));
    // 28 pt = 56 meios-pontos. Sem isto o título sairia no corpo padrão.
    expect(xml, contains('w:sz w:val="56"'));
    expect(xml, contains('<w:pageBreakBefore'),
        reason: 'sem a quebra o Word abriria a capa colada no texto');

    // E reabrir devolve a mesma capa.
    final reopened = OfficeDocxCodec(schema: schema)
        .import(Uint8List.fromList(bytes), includePackageResources: false);
    final body = PMNode.fromJSON(schema, reopened.snapshot.body);
    expect(body.child(0).textContent, 'CAPA EXPORTADA');
  });
}
