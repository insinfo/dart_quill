/// Objetos DENTRO do cabeçalho/rodapé, a caixa de texto flutuante que não se
/// deixava selecionar e a moldura da região.
///
/// Os três defeitos que estes testes protegem apareceram juntos no timbre de
/// um documento real (brasão + quadro "Continuação de Processo" no
/// cabeçalho):
///
/// 1. **clicar numa caixa flutuante não selecionava nada** — o visual dela é
///    filho do FRAGMENTO, não da linha, e o mapa de posições devolvia null;
///    sem [NodeSelection] não há moldura, alça nem ícone de layout;
/// 2. **o adorno olhava para a view do CORPO** — com o modo cabeçalho aberto,
///    a seleção existe na view da REGIÃO, e nenhuma alça era desenhada;
/// 3. **a caixa do cabeçalho não abria para edição** — a sessão procurava o
///    nó no documento do corpo, não achava `textBox` e desistia em silêncio.
///
/// Como no resto da pasta: o fake DOM não tem geometria real, então o que se
/// afirma é o MODELO e a estrutura do adorno; pixels ficam para o e2e.
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

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode textBoxNode(String text) => schema.node('textBox', {
        'text': text,
        'width': 2400,
        'height': 900,
        'positionHAlign': 'right',
      });

  PMNode imageNode() => schema.node('image', {
        'src': 'data:image/png;base64,AAAA',
        'width': 1440,
        'height': 720,
      });

  /// O timbre do documento real: brasão e quadro na MESMA linha do cabeçalho.
  PMNode headerRegion() => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              imageNode(),
              schema.text('ESTADO DO RIO DE JANEIRO'),
              textBoxNode('Continuação de Processo'),
            ])),
      ]));

  PMNode body() => schema.node(
      'doc',
      null,
      Fragment.from([
        paragraph('Corpo do documento, com texto suficiente para uma linha.'),
      ]));

  /// Documento do CORPO com uma caixa flutuante — o caso do §1 acima fora do
  /// cabeçalho.
  PMNode bodyWithTextBox() => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.text('âncora'),
              textBoxNode('carimbo'),
            ])),
        paragraph('Depois da caixa.'),
      ]));

  OfficeWordEditor mount({PMNode? document, bool withRegions = false}) {
    final created = OfficeWordEditor.mount(
      host: host,
      adapter: adapter,
      document: document ?? body(),
      schema: schema,
      options: const OfficeWordEditorOptions(),
    );
    editor = created;
    if (withRegions) {
      created.openDocument(
        document ?? body(),
        header: headerRegion(),
        footer: schema.node(
            'doc', null, Fragment.from([paragraph('Rodapé do documento')])),
      );
    }
    return created;
  }

  /// Um evento entregue ao elemento REAL — o fake DOM borbulha, como o
  /// browser, então quem escuta no canvas ou no host recebe.
  void fire(String type, DomElement target) => (target as FakeDomElement)
      .dispatchEvent(type, FakeDomMouseEvent(type: type, target: target));

  double _pxOf(String style, String property) {
    final match =
        RegExp('$property:([-0-9.]+)px').firstMatch(style.replaceAll(' ', ''));
    return match == null ? -1 : double.parse(match.group(1)!);
  }

  group('caixa de texto flutuante no corpo', () {
    test('clicar na caixa seleciona o NÓ (e não um ponto de texto)', () {
      final editor = mount(document: bodyWithTextBox());
      final box = host.querySelector('.dq-office-text-box');
      expect(box, isNotNull, reason: 'a caixa tem de estar projetada');
      expect(box!.getAttribute('data-doc-pos'), isNotNull,
          reason: 'é a âncora que o clique usa; o mapa de posições não '
              'resolve um visual que não vive numa linha');

      fire('pointerdown', box);

      final selection = editor.state.selection;
      expect(selection, isA<NodeSelection>());
      expect((selection as NodeSelection).node.type.name, 'textBox');
    });

    test('a moldura com as oito alças nasce sobre a caixa', () {
      final editor = mount(document: bodyWithTextBox());
      fire('pointerdown', host.querySelector('.dq-office-text-box')!);

      expect(editor.state.selection, isA<NodeSelection>());
      expect(host.querySelectorAll('.dq-office-objframe'), hasLength(1));
      expect(host.querySelectorAll('.dq-office-objhandle'), hasLength(8));
      // As faixas de mover só existem porque a caixa é reposicionável.
      expect(host.querySelectorAll('.dq-office-objmove'), hasLength(4));
    });
  });

  group('objeto dentro do cabeçalho', () {
    /// Entra no modo cabeçalho, como o duplo clique do usuário faz.
    OfficeWordEditor enterHeader() {
      final created = mount(withRegions: true);
      created.headerFooter.enter(header: true, pageIndex: 0);
      expect(created.headerFooter.regionView, isNotNull);
      return created;
    }

    test('clicar na imagem do cabeçalho seleciona o nó NA REGIÃO', () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;
      final image = surface.querySelector('.dq-office-image');
      expect(image, isNotNull, reason: 'a região projeta o brasão');

      fire('pointerdown', image!);

      final region = editor.headerFooter.regionView!;
      expect(region.state.selection, isA<NodeSelection>());
      expect((region.state.selection as NodeSelection).node.type.name, 'image');
      // O corpo NÃO foi tocado: a seleção dele continua onde estava.
      expect(editor.view.state.selection, isNot(isA<NodeSelection>()));
    });

    test('a moldura e as alças aparecem para o objeto do cabeçalho', () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;
      fire('pointerdown', surface.querySelector('.dq-office-image')!);

      expect(editor.headerFooter.regionView!.state.selection,
          isA<NodeSelection>());
      expect(host.querySelectorAll('.dq-office-objframe'), hasLength(1),
          reason: 'o adorno segue a view ATIVA, não a do corpo');
      expect(host.querySelectorAll('.dq-office-objhandle'), hasLength(8));
    });

    test('redimensionar a imagem do cabeçalho grava NO documento da região',
        () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;
      fire('pointerdown', surface.querySelector('.dq-office-image')!);

      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject();
      expect(target, isNotNull);
      adorner.resizeTo(target!.pos, target.node,
          widthPx: 2880 * editor.pxPerTwip, heightPx: 1440 * editor.pxPerTwip);

      final region = editor.headerFooter.regionView!;
      var found = 0;
      region.state.doc.descendants((node, pos, parent, index) {
        if (node.type.name == 'image') {
          found++;
          expect(node.attrs['width'], 2880);
          expect(node.attrs['height'], 1440);
        }
        return true;
      });
      expect(found, 1);
    });

    test('duplo clique na caixa do cabeçalho abre a edição in-place', () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;
      final box = surface.querySelector('.dq-office-text-box');
      expect(box, isNotNull);

      fire('dblclick', box!);

      expect(editor.textBoxSession.isActive, isTrue,
          reason: 'a caixa do cabeçalho é editável como a do corpo');
      expect(editor.textBoxSession.ownerView, same(editor.headerFooter.regionView),
          reason: 'a caixa vive no documento da REGIÃO; gravar no corpo '
              'escreveria por cima de outro nó');
      expect(host.querySelectorAll('.dq-office-tb-surface'), hasLength(1));
      // A sessão da região continua aberta: entrar na caixa não pode fechar o
      // cabeçalho que a contém.
      expect(editor.headerFooter.isActive, isTrue);
    });

    test('o que é digitado na caixa do cabeçalho volta para a região', () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;
      fire('dblclick', surface.querySelector('.dq-office-text-box')!);

      final boxView = editor.textBoxSession.boxView!;
      boxView.dispatch(boxView.state.tr..insertText('X', 1));
      editor.textBoxSession.exit();

      final region = editor.headerFooter.regionView!;
      var text = '';
      region.state.doc.descendants((node, pos, parent, index) {
        if (node.type.name == 'textBox') text = '${node.attrs['text']}';
        return true;
      });
      expect(text, startsWith('X'),
          reason: 'a gravação tem de voltar para a view DONA da caixa');
      expect(editor.isDirty, isTrue);
    });

    test('duplo clique dentro da região não FECHA o modo cabeçalho', () {
      final editor = enterHeader();
      final surface = host.querySelector('.dq-office-hf-surface')!;

      fire('dblclick', surface);

      expect(editor.headerFooter.isActive, isTrue,
          reason: 'sair é o gesto do duplo clique NO CORPO, e só nele');
    });
  });

  group('moldura da região', () {
    test('a área do cabeçalho vai da BORDA da folha até a linha divisória',
        () {
      final editor = mount(withRegions: true);
      editor.headerFooter.enter(header: true, pageIndex: 0);

      final frame = host.querySelector('.dq-office-hf-frame')!;
      final surface = host.querySelector('.dq-office-hf-surface')!;
      final frameStyle = frame.getAttribute('style')!;
      final surfaceStyle = surface.getAttribute('style')!;

      final frameTop = _pxOf(frameStyle, 'top');
      final surfaceTop = _pxOf(surfaceStyle, 'top');
      // A superfície EDITÁVEL começa onde o conteúdo é composto (a distância
      // do cabeçalho); a moldura começa no topo do papel — era exatamente
      // esta faixa que ficava de fora do tracejado.
      expect(surfaceTop, greaterThan(frameTop));
      expect(frameTop, 0.0);
      expect(
        _pxOf(frameStyle, 'height'),
        closeTo(_pxOf(surfaceStyle, 'height') + surfaceTop - frameTop, 0.2),
      );
    });

    test('a área do rodapé vai da linha divisória até a borda de baixo', () {
      final editor = mount(withRegions: true);
      editor.headerFooter.enter(header: false, pageIndex: 0);

      final frame = host.querySelector('.dq-office-hf-frame')!;
      final surface = host.querySelector('.dq-office-hf-surface')!;
      final frameStyle = frame.getAttribute('style')!;
      final pageHeightPx =
          editor.pageSetup.heightTwips * editor.pxPerTwip;

      expect(_pxOf(frameStyle, 'top'),
          closeTo(_pxOf(surface.getAttribute('style')!, 'top'), 0.2));
      expect(_pxOf(frameStyle, 'top') + _pxOf(frameStyle, 'height'),
          closeTo(pageHeightPx, 0.2));
    });
  });
}
