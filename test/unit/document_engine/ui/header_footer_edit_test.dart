/// F6 — cabeçalho/rodapé editável: duplo clique entra no modo, o corpo fica
/// esmaecido e travado, a região da página ativa é editada por uma SEGUNDA
/// instância da MESMA [OfficeEditorView], e a edição substitui a região no
/// orquestrador.
///
/// Como em `object_selection_test.dart`, o que estes testes protegem é o
/// contrato, não o desenho: o fake DOM não tem geometria (todo elemento mede
/// o mesmo retângulo) nem propaga eventos, então as asserções são sobre o
/// MODELO e sobre a existência/estrutura dos adornos. O evento é entregue
/// direto ao elemento que hospeda o listener, com o `target` que o browser
/// entregaria por bubbling.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/tabs/header_footer_tab.dart';
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

  PMNode region(String text) =>
      schema.node('doc', null, Fragment.from([paragraph(text)]));

  PMNode body() => schema.node(
      'doc',
      null,
      Fragment.from([
        paragraph('Corpo do documento, com texto suficiente para uma linha.'),
      ]));

  /// Monta o editor e abre um documento COM cabeçalho e rodapé — é o estado
  /// de um DOCX real, e o único em que a região existe na projeção.
  OfficeWordEditor mount({
    Map<String, PMNode>? headerVariants,
    bool titlePage = false,
    bool evenAndOddHeaders = false,
  }) {
    final created = OfficeWordEditor.mount(
      host: host,
      adapter: adapter,
      document: body(),
      schema: schema,
      options: const OfficeWordEditorOptions(),
    );
    editor = created;
    created.openDocument(
      body(),
      header: headerVariants?['default'] ?? region('Folha:'),
      footer: region('Rodapé do documento'),
      headerVariants: headerVariants,
      titlePage: titlePage,
      evenAndOddHeaders: evenAndOddHeaders,
    );
    return created;
  }

  /// O duplo clique como o browser o entregaria: o listener vive no canvas,
  /// o `target` é o elemento realmente clicado.
  void doubleClick(DomElement target) {
    final canvas = host.querySelector('.dq-office-canvas')! as FakeDomElement;
    canvas.dispatchEvent(
        'dblclick', FakeDomMouseEvent(type: 'dblclick', target: target));
  }

  DomElement headerElement() => host.querySelector('.dq-office-header')!;
  DomElement footerElement() => host.querySelector('.dq-office-footer')!;

  /// O texto que a região COMPOSTA projeta na primeira página — a prova de
  /// que a edição chegou ao compositor, e não só ao campo do orquestrador.
  String composedHeaderText(OfficeWordEditor editor) {
    final buffer = StringBuffer();
    for (final fragment in editor.pageGraph.pages.first.header) {
      for (final line in fragment.lines) {
        for (final segment in line.segments) {
          buffer.write(segment.text);
        }
      }
    }
    return buffer.toString();
  }

  String textOf(PMNode? doc) {
    if (doc == null) return '';
    final buffer = StringBuffer();
    doc.descendants((node, pos, parent, index) {
      if (node.isText) buffer.write(node.text ?? '');
      return true;
    });
    return buffer.toString();
  }

  group('entrar e sair do modo', () {
    test('duplo clique no cabeçalho entra no modo da região', () {
      final editor = mount();
      expect(editor.headerFooter.isActive, isFalse);

      doubleClick(headerElement());

      expect(editor.headerFooter.isActive, isTrue);
      expect(editor.headerFooter.isHeader, isTrue);
      expect(editor.headerFooter.pageIndex, 0);
    });

    test('duplo clique no rodapé entra na região de rodapé', () {
      final editor = mount();

      doubleClick(footerElement());

      expect(editor.headerFooter.isActive, isTrue);
      expect(editor.headerFooter.isHeader, isFalse);
      expect(
        host
            .querySelector('.dq-office-hf-surface')!
            .getAttribute('data-dq-office-region'),
        'footer',
      );
    });

    test('tracejado e etiqueta são desenhados pelo overlay', () {
      final editor = mount();
      expect(host.querySelectorAll('.dq-office-hf-frame'), isEmpty);

      doubleClick(headerElement());

      final overlay = host.querySelector('.dq-office-overlay')!;
      expect(overlay.querySelectorAll('.dq-office-hf-surface'), hasLength(1));
      expect(overlay.querySelectorAll('.dq-office-hf-frame'), hasLength(1));
      final frame = overlay.querySelector('.dq-office-hf-frame')!;
      expect(frame.classes.contains('dq-office-hf-frame-header'), isTrue);
      expect(frame.querySelector('.dq-office-hf-label')!.text, 'Cabeçalho');
      expect(editor.headerFooter.label, 'Cabeçalho');
    });

    test('o corpo fica esmaecido e SEM contenteditable', () {
      final editor = mount();
      expect(
        host
            .querySelector('.dq-office-page-content')!
            .getAttribute('contenteditable'),
        'true',
      );

      doubleClick(headerElement());

      expect(host.classes.contains('dq-office-app-hf'), isTrue,
          reason: 'a classe de esmaecimento vive no host do editor');
      expect(
        host
            .querySelector('.dq-office-page-content')!
            .getAttribute('contenteditable'),
        isNull,
        reason: 'esmaecer é feedback; o que trava a digitação é o atributo',
      );
      expect(editor.headerFooter.isActive, isTrue);
    });

    test('duplo clique no corpo sai do modo e devolve a edição', () {
      final editor = mount();
      doubleClick(headerElement());
      final content = host.querySelector('.dq-office-page-content')!;

      doubleClick(content);

      expect(editor.headerFooter.isActive, isFalse);
      expect(host.classes.contains('dq-office-app-hf'), isFalse);
      expect(host.querySelectorAll('.dq-office-hf-surface'), isEmpty);
      expect(
        host
            .querySelector('.dq-office-page-content')!
            .getAttribute('contenteditable'),
        'true',
      );
    });

    test('o botão Fechar da aba contextual sai do modo', () {
      final editor = mount();
      doubleClick(headerElement());

      final close = host.querySelector('.dq-office-hf-close')!;
      (close as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: close));

      expect(editor.headerFooter.isActive, isFalse);
    });

    test('entrar e sair sem editar não suja o documento', () {
      final editor = mount();
      expect(editor.isDirty, isFalse);

      doubleClick(headerElement());
      editor.headerFooter.exit();

      expect(editor.isDirty, isFalse,
          reason: 'olhar o cabeçalho não é editá-lo');
    });
  });

  group('a view secundária é a MESMA classe', () {
    test('a região é editada por outra instância de OfficeEditorView', () {
      final editor = mount();
      doubleClick(headerElement());

      final region = editor.headerFooter.regionView;
      expect(region, isA<OfficeEditorView>());
      expect(identical(region, editor.view), isFalse,
          reason: 'outra RAIZ, não outro laço de edição');
      // A raiz da região é a superfície do overlay, fora de `.dq-office-pages`
      // — é o isolamento que impede os dois laços de verem o mesmo evento.
      expect(region!.host.classes.contains('dq-office-hf-surface'), isTrue);
      expect(region.state.doc.textBetween(0, region.state.doc.content.size),
          contains('Folha:'));
    });

    test('a edição vai para a view ATIVA, não para o corpo', () {
      final editor = mount();
      doubleClick(headerElement());

      expect(
          identical(editor.activeView, editor.headerFooter.regionView), isTrue);

      editor.headerFooter.exit();

      expect(identical(editor.activeView, editor.view), isTrue);
    });
  });

  group('a edição da região sobrevive', () {
    test('digitar no cabeçalho substitui a região e suja o documento', () {
      final editor = mount();
      doubleClick(headerElement());
      final region = editor.headerFooter.regionView!;
      final bodyBefore = editor.state.doc;

      region.dispatch(region.state.tr..insertText('X', 1));

      expect(textOf(editor.regionForPage(0, isHeader: true).doc),
          contains('XFolha:'));
      expect(editor.isDirty, isTrue);
      expect(identical(editor.state.doc, bodyBefore), isTrue,
          reason: 'editar o cabeçalho não pode tocar no corpo');
    });

    test('ao fechar, o corpo é recomposto com a região nova', () {
      final editor = mount();
      expect(composedHeaderText(editor), 'Folha:');
      doubleClick(headerElement());
      final region = editor.headerFooter.regionView!;
      region.dispatch(region.state.tr..insertText('X', 1));

      editor.headerFooter.exit();

      expect(composedHeaderText(editor), 'XFolha:',
          reason: 'a repaginação acontece UMA vez, no fechamento');
    });

    test('a edição do rodapé vai para o rodapé, não para o cabeçalho', () {
      final editor = mount();
      doubleClick(footerElement());
      final region = editor.headerFooter.regionView!;

      region.dispatch(region.state.tr..insertText('Z', 1));
      editor.headerFooter.exit();

      expect(textOf(editor.regionForPage(0, isHeader: false).doc),
          contains('ZRodapé'));
      expect(textOf(editor.regionForPage(0, isHeader: true).doc), 'Folha:');
    });

    test('trocar de região grava a anterior', () {
      final editor = mount();
      doubleClick(headerElement());
      final header = editor.headerFooter.regionView!;
      header.dispatch(header.state.tr..insertText('X', 1));

      editor.headerFooter.goTo(header: false);

      expect(editor.headerFooter.isHeader, isFalse);
      expect(textOf(editor.regionForPage(0, isHeader: true).doc),
          contains('XFolha:'));
    });
  });

  group('variantes', () {
    test('com titlePage a página 1 edita a variante first', () {
      final editor = mount(
        headerVariants: {
          'default': region('Padrão'),
          'first': region('Primeira'),
        },
        titlePage: true,
      );

      doubleClick(headerElement());

      expect(editor.headerFooter.regionRef!.variant, 'first');
      expect(editor.headerFooter.label, 'Cabeçalho da Primeira Página');
      final view = editor.headerFooter.regionView!;
      view.dispatch(view.state.tr..insertText('!', 1));
      editor.headerFooter.exit();

      expect(textOf(editor.regionForPage(0, isHeader: true).doc), '!Primeira');
      // A variante `default` continua intacta: uma edição na primeira página
      // não pode reescrever o cabeçalho de todas as outras.
      expect(textOf(editor.regionForPage(1, isHeader: true).doc), 'Padrão');
    });

    test('sem titlePage a página 1 edita a variante default', () {
      final editor = mount(
        headerVariants: {
          'default': region('Padrão'),
          'first': region('Primeira'),
        },
      );

      doubleClick(headerElement());

      expect(editor.headerFooter.regionRef!.variant, 'default');
      expect(editor.headerFooter.label, 'Cabeçalho');
    });
  });

  group('aba contextual', () {
    DomElement? tabNamed(String label) {
      for (final tab in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (tab.text == label) return tab;
      }
      return null;
    }

    test('a aba só existe com o modo aberto e é ativada ao entrar', () {
      final editor = mount();
      final tab = tabNamed('Cabeçalho e Rodapé')!;
      expect(tab.classes.contains('dq-office-ribbon-tab-hidden'), isTrue);

      doubleClick(headerElement());

      expect(tab.classes.contains('dq-office-ribbon-tab-hidden'), isFalse);
      expect(tab.classes.contains('dq-office-ribbon-tab-active'), isTrue);
      expect(editor.headerFooter.isActive, isTrue);
    });

    test('a aba some (e volta para Página Inicial) ao fechar', () {
      final editor = mount();
      doubleClick(headerElement());

      editor.headerFooter.exit();

      final tab = tabNamed('Cabeçalho e Rodapé')!;
      expect(tab.classes.contains('dq-office-ribbon-tab-hidden'), isTrue);
      expect(
          tabNamed('Página Inicial')!
              .classes
              .contains('dq-office-ribbon-tab-active'),
          isTrue);
    });

    test('a aba traz os comandos do Word', () {
      mount();
      doubleClick(headerElement());

      final titles = [
        for (final button in host.querySelectorAll('.dq-office-btn'))
          button.getAttribute('title')
      ];
      expect(
          titles,
          containsAll([
            'Ir para Cabeçalho',
            'Ir para Rodapé',
            'Primeira Página Diferente',
            'Páginas Pares e Ímpares Diferentes',
            'Fechar Cabeçalho e Rodapé',
          ]));
      expect(host.querySelector('.dq-office-hf-header-distance'), isNotNull);
      expect(host.querySelector('.dq-office-hf-footer-distance'), isNotNull);
    });

    test('Primeira Página Diferente liga a flag e repagina', () {
      final editor = mount(
        headerVariants: {
          'default': region('Padrão'),
          'first': region('Primeira'),
        },
      );
      doubleClick(headerElement());
      expect(editor.titlePage, isFalse);

      final toggle = host.querySelector('.dq-office-hf-titlepage')!;
      (toggle as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: toggle));

      expect(editor.titlePage, isTrue);
      expect(composedHeaderText(editor), 'Primeira');
      // A sessão continua aberta e passa a editar a variante que a página
      // realmente projeta agora.
      expect(editor.headerFooter.isActive, isTrue);
      expect(editor.headerFooter.regionRef!.variant, 'first');
    });

    test('Pares e Ímpares Diferentes liga a flag', () {
      final editor = mount();
      doubleClick(headerElement());

      final toggle = host.querySelector('.dq-office-hf-evenodd')!;
      (toggle as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: toggle));

      expect(editor.evenAndOddHeaders, isTrue);
    });

    test('as distâncias gravam no setup de página, preservando o resto', () {
      final editor = mount();
      doubleClick(headerElement());
      final before = editor.pageSetup;

      setRegionDistanceTwips(editor, 1134, isHeader: true);

      expect(editor.pageSetup.headerDistanceTwips, 1134);
      expect(editor.pageSetup.footerDistanceTwips, before.footerDistanceTwips);
      expect(editor.pageSetup.marginTopTwips, before.marginTopTwips);
      expect(editor.pageSetup.widthTwips, before.widthTwips);
      expect(editor.headerFooter.isActive, isTrue,
          reason: 'a repaginação não pode derrubar a sessão');
    });
  });
}
