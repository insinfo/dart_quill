/// "Margens Personalizadas…" e "Mais Tamanhos de Papel…".
///
/// A regra que estes testes protegem não é o formulário — é a RECUSA. Uma
/// geometria impossível (margens que somam mais que o papel) não pode ser
/// aplicada pela metade nem saturada em silêncio: o usuário veria uma página
/// em branco sem entender o porquê. O diálogo devolve `null` e o documento
/// fica como estava.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/page_setup_dialog.dart';
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

  const a4 = PageSetupTwips(
    widthTwips: 11906,
    heightTwips: 16838,
    marginTopTwips: 1418,
    marginRightTwips: 1701,
    marginBottomTwips: 1418,
    marginLeftTwips: 1701,
    headerDistanceTwips: 709,
    footerDistanceTwips: 709,
  );

  group('conversão do formulário', () {
    test('cm com vírgula decimal vira twips — é o que o usuário digita', () {
      final next = officePageSetupFromForm({'marginTop': '2,5'}, a4);
      expect(next, isNotNull);
      expect(next!.marginTopTwips, 1418, reason: '2,5 cm = 1417,5 twips');
    });

    test('ponto decimal também é aceito', () {
      final next = officePageSetupFromForm({'marginLeft': '3.0'}, a4);
      expect(next!.marginLeftTwips, 1701);
    });

    test('campo vazio mantém o valor vigente, não zera', () {
      final next = officePageSetupFromForm({'marginTop': '  '}, a4);
      expect(next!.marginTopTwips, a4.marginTopTwips);
    });

    test('a distância do cabeçalho é editável — nenhum preset a toca', () {
      final next = officePageSetupFromForm(
          {'headerDistance': '1,5', 'footerDistance': '0,8'}, a4);
      expect(next!.headerDistanceTwips, 851);
      expect(next.footerDistanceTwips, 454);
    });

    test('a grade do documento sobrevive: ela não está no formulário', () {
      const withGrid = PageSetupTwips(
        widthTwips: 11906,
        heightTwips: 16838,
        documentGridLinePitchTwips: 312,
        documentGridType: 'lines',
      );
      final next = officePageSetupFromForm({'marginTop': '2,0'}, withGrid);
      expect(next!.documentGridLinePitchTwips, 312,
          reason: 'recriá-la a partir de valores não vistos apagaria a '
              'métrica do documento importado');
      expect(next.documentGridType, 'lines');
    });
  });

  group('recusa em bloco', () {
    test('margens laterais maiores que o papel não aplicam NADA', () {
      final next = officePageSetupFromForm(
          {'marginLeft': '12,0', 'marginRight': '12,0'}, a4);
      expect(next, isNull,
          reason: 'a largura de conteúdo seria negativa; aplicar deixaria a '
              'página em branco sem explicação');
    });

    test('margens verticais maiores que o papel não aplicam NADA', () {
      final next = officePageSetupFromForm(
          {'marginTop': '16,0', 'marginBottom': '16,0'}, a4);
      expect(next, isNull);
    });

    test('papel menor que meia polegada é recusado', () {
      final next = officePageSetupFromForm({'width': '0,5'}, a4);
      expect(next, isNull);
    });

    test('valor não numérico é recusado, não vira zero', () {
      final next = officePageSetupFromForm({'marginTop': 'dois'}, a4);
      expect(next, isNull);
    });

    test('valor negativo é recusado', () {
      final next = officePageSetupFromForm({'marginTop': '-1'}, a4);
      expect(next, isNull);
    });
  });

  group('no editor', () {
    OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
          host: host,
          adapter: adapter,
          schema: schema,
          document: schema.node(
              'doc',
              null,
              Fragment.from([
                schema.node('paragraph', null,
                    Fragment.from([schema.text('parágrafo')])),
              ])),
        );

    test('trocar largura por altura é o que muda a orientação', () {
      final e = mount();
      final dialog = openPageSetupDialog(e, focusPaper: true);
      expect(dialog.isOpen, isTrue);

      final next = officePageSetupFromForm(
          {'width': '29,70', 'height': '21,00'}, e.pageSetup);
      e.setPageSetup(next!);

      final page = e.pageGraph.pages.first.setup;
      expect(page.widthTwips, greaterThan(page.heightTwips),
          reason: 'a página composta virou paisagem');
    });

    test('a geometria escolhida REPAGINA o documento de verdade', () {
      final e = mount();
      final antes = e.pageGraph.pages.first.setup.marginLeftTwips;

      final next = officePageSetupFromForm({'marginLeft': '5,0'}, e.pageSetup);
      e.setPageSetup(next!);

      expect(e.pageGraph.pages.first.setup.marginLeftTwips, 2835);
      expect(
          e.pageGraph.pages.first.setup.marginLeftTwips, isNot(equals(antes)));
    });

    test('os dois itens do menu Layout abrem o mesmo formulário', () {
      final e = mount();
      final margens = openPageSetupDialog(e);
      expect(margens.title, 'Configurar Página');
      margens.close();

      final papel = openPageSetupDialog(e, focusPaper: true);
      expect(papel.title, 'Tamanho do Papel');
      expect(papel.fields.map((field) => field.key),
          margens.fields.map((field) => field.key),
          reason: 'a geometria da página é uma coisa só; dois formulários '
              'fariam o usuário confirmar duas vezes');
    });
  });
}
