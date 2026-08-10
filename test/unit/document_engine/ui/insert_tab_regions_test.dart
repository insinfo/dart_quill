/// Aba Inserir — dropdowns Cabeçalho, Rodapé e Número de Página (F10).
///
/// Não há motor novo aqui, e é exatamente isso que os testes verificam: os
/// itens têm de cair na MESMA sessão que o duplo clique na região abre e no
/// MESMO `insertPageField` da aba contextual. Dois caminhos para entrar no
/// cabeçalho que terminassem em estados diferentes dariam um deles com bugs
/// que ninguém procura.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
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

  OfficeWordEditor mount({String? headerText}) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node('doc', null, Fragment.from([paragraph('corpo')])),
        schema: schema,
        options: OfficeWordEditorOptions(headerText: headerText),
      );

  void click(DomElement el) => (el as FakeDomElement)
      .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: el));

  void openTab(String text) {
    for (final t in host.querySelectorAll('.dq-office-ribbon-tab')) {
      if (t.textContent == text) {
        click(t);
        return;
      }
    }
    fail('aba $text não encontrada');
  }

  DomElement ribbonButton(String title) {
    for (final b in host.querySelectorAll('.dq-office-btn')) {
      if ((b.getAttribute('title') ?? '') == title) return b;
    }
    fail('botão "$title" não encontrado na aba corrente');
  }

  DomElement menuItem(String label) {
    for (final item in host.querySelectorAll('.dq-office-menu-item')) {
      if ((item.textContent ?? '').contains(label)) return item;
    }
    fail('item de menu "$label" não encontrado');
  }

  /// Os marcadores de campo de [doc], em ordem.
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

  test('a aba Inserir oferece os três dropdowns', () {
    mount();
    openTab('Inserir');

    expect(ribbonButton('Cabeçalho'), isNotNull);
    expect(ribbonButton('Rodapé'), isNotNull);
    expect(ribbonButton('Número de Página'), isNotNull);
  });

  test('"Editar Cabeçalho" abre a MESMA sessão do duplo clique', () {
    final e = mount();
    openTab('Inserir');
    click(ribbonButton('Cabeçalho'));
    click(menuItem('Editar Cabeçalho'));

    expect(e.headerFooter.isActive, isTrue);
    expect(e.headerFooter.isHeader, isTrue);
    expect(e.activeView, same(e.headerFooter.regionView));
  });

  test('"Editar Rodapé" entra pela região de baixo', () {
    final e = mount();
    openTab('Inserir');
    click(ribbonButton('Rodapé'));
    click(menuItem('Editar Rodapé'));

    expect(e.headerFooter.isActive, isTrue);
    expect(e.headerFooter.isHeader, isFalse);
  });

  test('"Remover Cabeçalho" fica DESABILITADO quando não há cabeçalho', () {
    mount();
    openTab('Inserir');
    click(ribbonButton('Cabeçalho'));

    final item = menuItem('Remover Cabeçalho');
    expect(item.classes.contains('dq-office-menu-item-disabled'), isTrue,
        reason: 'um item que não tem o que fazer diz isso, não finge agir');
  });

  test('"Remover Cabeçalho" esvazia a região quando ela tem conteúdo', () {
    final e = mount(headerText: 'Relatório anual');
    openTab('Inserir');
    click(ribbonButton('Cabeçalho'));
    click(menuItem('Remover Cabeçalho'));

    final ref = e.regionForPage(0, isHeader: true);
    expect(ref.doc?.textContent ?? '', isEmpty);
  });

  test('"Posição Atual" insere o CAMPO no corpo, não um número', () {
    final e = mount();
    openTab('Inserir');
    e.view.dispatch(
        e.state.tr..setSelection(TextSelection.create(e.state.doc, 1)));
    click(ribbonButton('Número de Página'));
    click(menuItem('Posição Atual'));

    expect(fieldMarkersOf(e.state.doc),
        ['begin', 'instruction', 'separate', 'end']);
    // Nenhum dígito virou texto: é isso que evita "1" em todas as páginas.
    expect(e.state.doc.textContent, 'corpo');
  });

  test('"Fim da Página" abre o rodapé e põe o campo LÁ', () {
    final e = mount();
    openTab('Inserir');
    click(ribbonButton('Número de Página'));
    click(menuItem('Fim da Página'));

    expect(e.headerFooter.isActive, isTrue);
    expect(e.headerFooter.isHeader, isFalse);
    expect(fieldMarkersOf(e.activeView.state.doc),
        ['begin', 'instruction', 'separate', 'end']);
    expect(fieldMarkersOf(e.state.doc), isEmpty,
        reason: 'o campo do rodapé não pode vazar para o corpo');
  });

  test('"Total de Páginas" insere NUMPAGES', () {
    final e = mount();
    openTab('Inserir');
    e.view.dispatch(
        e.state.tr..setSelection(TextSelection.create(e.state.doc, 1)));
    click(ribbonButton('Número de Página'));
    click(menuItem('Total de Páginas'));

    var instruction = '';
    e.state.doc.descendants((node, pos, parent, index) {
      final insert = node.attrs['insert'];
      if (insert is Map && insert['fieldMarker'] == 'instruction') {
        instruction = '${insert['officeXml']}';
      }
      return true;
    });
    expect(instruction, contains('NUMPAGES'));
  });
}
