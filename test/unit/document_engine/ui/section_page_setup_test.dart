/// B3: a aba Layout num documento com várias seções.
///
/// O caso real é o TR: capa e corpo em retrato, anexo de tabela em paisagem.
/// Antes, trocar a margem na capa apagava `_sections` inteira — e o anexo
/// virava retrato sem ninguém pedir. E, mesmo antes de qualquer edição, a
/// régua e os dropdowns liam `_setup`, que o compositor IGNORA quando há
/// seções: a UI descrevia uma página que não estava na tela.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
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

  /// Um parágrafo comum, ou o ÚLTIMO de uma seção quando [endsSection].
  PMNode paragraph(String text, {bool endsSection = false}) => schema.node(
        'paragraph',
        endsSection
            ? {
                'style': const {'sectionBreak': true}
              }
            : null,
        Fragment.from([schema.text(text)]),
      );

  const retrato = PageSetupTwips(
      widthTwips: 11906,
      heightTwips: 16838,
      marginTopTwips: 1440,
      marginRightTwips: 1440,
      marginBottomTwips: 1440,
      marginLeftTwips: 1440);
  const paisagem = PageSetupTwips(
      widthTwips: 16838,
      heightTwips: 11906,
      marginTopTwips: 1440,
      marginRightTwips: 1440,
      marginBottomTwips: 1440,
      marginLeftTwips: 1440);
  const capaMargemLarga = PageSetupTwips(
      widthTwips: 11906,
      heightTwips: 16838,
      marginTopTwips: 1440,
      marginRightTwips: 1440,
      marginBottomTwips: 1440,
      marginLeftTwips: 2880);
  const anexoMargemAlta = PageSetupTwips(
      widthTwips: 16838,
      heightTwips: 11906,
      marginTopTwips: 720,
      marginRightTwips: 1440,
      marginBottomTwips: 1440,
      marginLeftTwips: 1440);
  const anexoLarguraNova = PageSetupTwips(
      widthTwips: 20000,
      heightTwips: 11906,
      marginTopTwips: 1440,
      marginRightTwips: 1440,
      marginBottomTwips: 1440,
      marginLeftTwips: 1440);

  /// Capa (retrato) | corpo (retrato) | anexo (paisagem).
  OfficeWordEditor mountThreeSections() {
    final e = editor = OfficeWordEditor.mount(
      host: host,
      adapter: adapter,
      document: schema.node('doc', null, Fragment.from([paragraph('vazio')])),
      schema: schema,
    );
    e.openDocument(
      schema.node(
          'doc',
          null,
          Fragment.from([
            paragraph('capa', endsSection: true),
            paragraph('corpo', endsSection: true),
            paragraph('anexo'),
          ])),
      setup: retrato,
      sections: const [retrato, retrato, paisagem],
    );
    return e;
  }

  void placeCursorIn(OfficeWordEditor e, String text) {
    final doc = e.state.doc;
    var offset = 0;
    for (var i = 0; i < doc.childCount; i++) {
      final block = doc.child(i);
      if (block.textContent == text) {
        e.view.dispatch(
            e.state.tr..setSelection(TextSelection.create(doc, offset + 1)));
        return;
      }
      offset += block.nodeSize;
    }
    fail('parágrafo "$text" não encontrado');
  }

  /// O cursor no FIM do parágrafo — é ali que se pede uma quebra.
  void placeCursorAtEndOf(OfficeWordEditor e, String text) {
    final doc = e.state.doc;
    var offset = 0;
    for (var i = 0; i < doc.childCount; i++) {
      final block = doc.child(i);
      if (block.textContent == text) {
        e.view.dispatch(e.state.tr
          ..setSelection(
              TextSelection.create(doc, offset + block.nodeSize - 1)));
        return;
      }
      offset += block.nodeSize;
    }
    fail('parágrafo "$text" não encontrado');
  }

  group('leitura', () {
    test('pageSetup segue a seção do cursor, não o setup do documento', () {
      final e = mountThreeSections();

      placeCursorIn(e, 'capa');
      expect(e.pageSetup.widthTwips, retrato.widthTwips);

      placeCursorIn(e, 'anexo');
      expect(e.pageSetup.widthTwips, paisagem.widthTwips,
          reason: 'a régua tem de descrever a página que está desenhada');
      expect(e.pageSetup.heightTwips, paisagem.heightTwips);
    });

    test('sem seções importadas continua sendo o setup do documento', () {
      final e = editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node('doc', null, Fragment.from([paragraph('a')])),
        schema: schema,
      );
      e.openDocument(schema.node('doc', null, Fragment.from([paragraph('a')])),
          setup: paisagem);
      expect(e.pageSetup.widthTwips, paisagem.widthTwips);
    });
  });

  group('criar seção (menu Quebras > Próxima Página)', () {
    OfficeWordEditor mountSingle() {
      final e = editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node('doc', null, Fragment.from([paragraph('x')])),
        schema: schema,
      );
      e.openDocument(
          schema.node(
              'doc',
              null,
              Fragment.from(
                  [paragraph('capa'), paragraph('corpo do documento')])),
          setup: retrato);
      return e;
    }

    test('marca o bloco E cria a entrada em sections — sem as duas, nada', () {
      final e = mountSingle();
      placeCursorAtEndOf(e, 'capa');

      expect(actions.insertSectionBreak(e), isTrue);

      // A marca ficou no bloco que TERMINA a seção, não no que começa.
      final style = e.state.doc.child(0).attrs['style'];
      expect(style is Map && style['sectionBreak'] == true, isTrue,
          reason: 'a capa termina a primeira seção');
      // E a geometria da seção nova existe: sem ela o compositor ignoraria
      // a marca.
      placeCursorIn(e, 'corpo do documento');
      e.setPageSetup(paisagem);
      expect(e.pageSetup.widthTwips, paisagem.widthTwips);
      placeCursorIn(e, 'capa');
      expect(e.pageSetup.widthTwips, retrato.widthTwips,
          reason: 'a capa ficou na seção antiga, em retrato');
    });

    test('a seção nova nasce igual: a quebra sozinha não muda a tela', () {
      final e = mountSingle();
      final antes = e.pageGraph.pages.first.setup.widthTwips;
      placeCursorIn(e, 'corpo do documento');

      actions.insertSectionBreak(e);

      for (final page in e.pageGraph.pages) {
        expect(page.setup.widthTwips, antes);
      }
    });

    test('a seção nova abre uma página nova', () {
      final e = mountSingle();
      expect(e.pageGraph.pages, hasLength(1));
      placeCursorIn(e, 'corpo do documento');

      actions.insertSectionBreak(e);

      expect(e.pageGraph.pages, hasLength(2),
          reason: 'é uma quebra de "Próxima Página"');
    });
  });

  group('escrita', () {
    test('editar a capa NÃO endireita o anexo em paisagem', () {
      final e = mountThreeSections();

      placeCursorIn(e, 'capa');
      e.setPageSetup(capaMargemLarga);

      expect(e.pageSetup.marginLeftTwips, 2880,
          reason: 'a capa recebeu a margem');

      placeCursorIn(e, 'anexo');
      expect(e.pageSetup.widthTwips, paisagem.widthTwips,
          reason: 'B3: o anexo continua paisagem');
      expect(e.pageSetup.marginLeftTwips, paisagem.marginLeftTwips,
          reason: 'e não herdou a margem escolhida na capa');
    });

    test('editar o anexo não mexe na capa', () {
      final e = mountThreeSections();

      placeCursorIn(e, 'anexo');
      e.setPageSetup(anexoMargemAlta);

      expect(e.pageSetup.marginTopTwips, 720);
      placeCursorIn(e, 'capa');
      expect(e.pageSetup.marginTopTwips, retrato.marginTopTwips);
      expect(e.pageSetup.widthTwips, retrato.widthTwips);
    });

    test('a página composta usa a geometria nova da seção editada', () {
      final e = mountThreeSections();
      placeCursorIn(e, 'anexo');

      e.setPageSetup(anexoLarguraNova);

      // A terceira seção é a última: a última página é a dela.
      expect(e.pageGraph.pages.last.setup.widthTwips, 20000);
      expect(e.pageGraph.pages.first.setup.widthTwips, retrato.widthTwips);
    });

    test('num documento de uma seção a escolha vale para o documento', () {
      final e = editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node('doc', null, Fragment.from([paragraph('a')])),
        schema: schema,
      );
      e.openDocument(schema.node('doc', null, Fragment.from([paragraph('a')])),
          setup: retrato);

      e.setPageSetup(paisagem);

      expect(e.pageSetup.widthTwips, paisagem.widthTwips);
      expect(e.pageGraph.pages.first.setup.widthTwips, paisagem.widthTwips);
    });
  });
}
