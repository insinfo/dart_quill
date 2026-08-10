/// F10 — verificação ortográfica NATIVA do browser na projeção.
///
/// O sublinhado do corretor é PINTURA, não DOM: ligá-lo não fere a regra de
/// ouro do projeto (o browser nunca muta a projeção). O que fere é a outra
/// ponta — aceitar uma sugestão no menu do corretor chega como
/// `beforeinput/insertReplacementText`. Antes deste trabalho esse `inputType`
/// caía no ramo "não sei tratar": era cancelado e nada acontecia, ou seja, o
/// corretor sublinhava e não corrigia.
///
/// Estes testes fixam as duas metades: o atributo é decidido pelo editor (não
/// herdado da página hospedeira) e a correção entra pelo MODELO.
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

  OfficeWordEditor mount({bool spellcheck = false, PMNode? box}) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node(
            'doc',
            null,
            Fragment.from([
              if (box != null)
                schema.node('paragraph', null, Fragment.from([box])),
              paragraph('texot do documento'),
            ])),
        schema: schema,
        options: OfficeWordEditorOptions(spellcheck: spellcheck),
      );

  List<String?> spellcheckAttributes() => [
        for (final content in host.querySelectorAll('.dq-office-page-content'))
          content.getAttribute('spellcheck'),
      ];

  group('o atributo', () {
    test('a projeção nasce com o corretor DESLIGADO', () {
      mount();
      expect(spellcheckAttributes(), everyElement('false'));
    });

    test('a opção do hospedeiro liga o corretor na superfície editável', () {
      mount(spellcheck: true);
      expect(spellcheckAttributes(), isNotEmpty);
      expect(spellcheckAttributes(), everyElement('true'));
    });

    test('o atributo é sempre escrito — nunca herdado da página', () {
      mount();
      // Num contenteditable o padrão do browser é HERDAR `spellcheck` do
      // ancestral: omitir o atributo deixaria a decisão com o host.
      expect(spellcheckAttributes().where((v) => v == null), isEmpty);
    });

    test('o cabeçalho em edição segue a mesma opção do corpo', () {
      final e = mount(spellcheck: true);
      e.headerFooter.enter(header: true, pageIndex: 0);

      final region = host.querySelector('.dq-office-hf-surface') ??
          host.querySelector('.dq-office-hf-region');
      expect(region, isNotNull,
          reason: 'a sessão de cabeçalho tem de montar uma superfície');
      final contents = region!.querySelectorAll('.dq-office-page-content');
      expect(contents, isNotEmpty);
      for (final content in contents) {
        expect(content.getAttribute('spellcheck'), 'true',
            reason: 'o corretor não pode valer no corpo e não no cabeçalho');
      }
    });

    test('a caixa de texto em edição segue a mesma opção do corpo', () {
      final e = mount(
        spellcheck: true,
        box: schema.node('textBox', {
          'text': 'na caixa',
          'width': 2880,
          'height': 1440,
        }),
      );
      insertTextBox(e, enterEditing: false);
      // A caixa recém-inserida é a que a sessão abre; entrar por ela evita
      // depender da ordem das caixas na projeção.
      final surface = host.querySelector('.dq-office-tb-surface');
      expect(surface, isNull, reason: 'nenhuma sessão aberta ainda');

      e.textBoxSession.enter(1);
      final open = host.querySelector('.dq-office-tb-surface');
      expect(open, isNotNull);
      for (final content in open!.querySelectorAll('.dq-office-page-content')) {
        expect(content.getAttribute('spellcheck'), 'true');
      }
    });
  });

  group('aceitar uma sugestão do corretor', () {
    /// O `beforeinput` que o browser manda ao aceitar uma sugestão: a seleção
    /// nativa fica COLAPSADA dentro da palavra e o alvo real vem em
    /// `getTargetRanges`.
    void acceptSuggestion({
      required int caret,
      required int wordFrom,
      required int wordTo,
      required String replacement,
      bool withTargetRange = true,
    }) {
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final at = map.domPositionFor(pages, caret)!;
      adapter.setSelectionByNodes(at.node, at.offset, at.node, at.offset);
      final from = map.domPositionFor(pages, wordFrom)!;
      final to = map.domPositionFor(pages, wordTo)!;
      (pages as FakeDomElement).dispatchEvent(
        'beforeinput',
        FakeDomInputEvent(
          type: 'beforeinput',
          target: pages,
          inputType: 'insertReplacementText',
          data: replacement,
          targetRanges: [
            if (withTargetRange)
              DomNativeRange(
                startContainer: from.node,
                startOffset: from.offset,
                endContainer: to.node,
                endOffset: to.offset,
              ),
          ],
        ),
      );
    }

    test('a palavra errada é SUBSTITUÍDA, não a sugestão inserida no meio', () {
      final e = mount(spellcheck: true);
      // "texot do documento": a palavra ocupa as posições 1..6.
      acceptSuggestion(
          caret: 1 + 3, wordFrom: 1, wordTo: 1 + 5, replacement: 'texto');

      expect(e.state.doc.textContent, 'texto do documento');
    });

    test('a projeção acompanha o modelo depois da correção', () {
      final e = mount(spellcheck: true);
      acceptSuggestion(
          caret: 1 + 3, wordFrom: 1, wordTo: 1 + 5, replacement: 'texto');

      expect(host.textContent, contains('texto do documento'));
      expect(host.textContent, isNot(contains('texot')),
          reason: 'projeção e modelo divergirem é a corrupção silenciosa que '
              'o cancelamento de beforeinput existe para impedir');
      // E é UMA transação: desfazer devolve a palavra original.
      e.runCommand('undo');
      expect(e.state.doc.textContent, 'texot do documento');
    });

    test('sem intervalo alvo NADA é escrito', () {
      final e = mount(spellcheck: true);
      acceptSuggestion(
        caret: 1 + 3,
        wordFrom: 1,
        wordTo: 1 + 5,
        replacement: 'texto',
        withTargetRange: false,
      );

      // Adivinhar o intervalo a partir do caret inseriria a sugestão NO MEIO
      // da palavra ("texsugestãoot"). Não fazer nada é a perda visível.
      expect(e.state.doc.textContent, 'texot do documento');
    });
  });
}
