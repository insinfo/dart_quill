/// Fase 2 — o laço de edição: beforeinput → modelo → layout → projeção.
///
/// Roda no fake DOM porque é onde uma exceção dentro do handler APARECE:
/// num listener de browser ela some no dispatch e o sintoma vira "nada
/// aconteceu". Os testes de Chrome cobrem o que só o browser sabe dizer
/// (foco, seleção nativa, geometria); a lógica do laço se prova aqui.
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
  OfficeEditorView? view;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    view?.dispose();
    view = null;
    host.remove();
  });

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode opaqueBookmark() => schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:bookmarkStart',
          'officeXml': '<w:bookmarkStart w:id="1" w:name="x"/>',
          'runContent': true,
        }
      });

  PMNode cellWith(List<PMNode> inline) => schema.node(
        'tableCell',
        null,
        Fragment.from([schema.node('paragraph', null, Fragment.from(inline))]),
      );

  PMNode twoCellDocument({
    List<PMNode>? left,
    List<PMNode>? right,
  }) =>
      docOf([
        schema.node(
          'table',
          null,
          Fragment.from([
            schema.node(
              'tableRow',
              null,
              Fragment.from([
                cellWith(left ?? [schema.text('alpha')]),
                cellWith(right ?? [schema.text('beta')]),
              ]),
            ),
          ]),
        ),
      ]);

  List<int> tableCellTextStarts(PMNode doc) {
    final result = <int>[];
    doc.descendants((node, position, parent, index) {
      if (node.type.name != 'tableCell') return true;
      result.add(position + 2);
      return false;
    });
    return result;
  }

  PMNode documentWithRenderedPageBreakHint() {
    final marker = schema.node('opaqueInline', {
      'insert': {
        'qname': 'w:lastRenderedPageBreak',
        'officeXml': '<w:lastRenderedPageBreak/>',
        'runContent': true,
        'renderedPageBreakHint': true,
      }
    });
    return docOf([
      schema.node(
        'paragraph',
        {
          'id': 'hinted',
          'style': const {'lineTwips': 200, 'lineRule': 'exact'},
        },
        Fragment.from([schema.text('antes'), marker, schema.text('depois')]),
      ),
    ]);
  }

  LayoutComposer renderedHintComposer() => LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 5000,
          heightTwips: 1000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      );

  OfficeEditorView mount(PMNode doc) {
    final state = EditorState.create(EditorStateConfig(doc: doc));
    return view = OfficeEditorView(host: host, state: state, adapter: adapter);
  }

  String textOf(OfficeEditorView view) => view.state.doc
      .textBetween(0, view.state.doc.content.size, blockSeparator: ' ');

  group('cache de paginação Word', () {
    test('edição somente de marca invalida hints sem StepMap', () {
      final doc = documentWithRenderedPageBreakHint();
      view = OfficeEditorView(
        host: host,
        state: EditorState.create(EditorStateConfig(doc: doc)),
        adapter: adapter,
        composer: renderedHintComposer(),
      );
      final current = view!;
      final bold = schema.marks['bold']!.create();

      expect(current.pageGraph.pages, hasLength(2));
      expect(current.pageGraph.honoredRenderedPageBreakHints, isTrue);
      expect(current.renderedPageBreakHintsValid, isTrue);

      current.dispatch(current.state.tr..addMark(1, 6, bold));

      expect(current.pageGraph.pages, hasLength(1));
      expect(current.pageGraph.honoredRenderedPageBreakHints, isFalse);
      expect(current.renderedPageBreakHintsValid, isFalse);
      final block = current.pageGraph.pages.single.fragments
          .whereType<BlockFragment>()
          .single;
      expect(block.lines, hasLength(1),
          reason:
              'o marker obsoleto também não pode continuar quebrando linha');
      expect(
        block.lines.single.segments.map((segment) => segment.text).join(),
        'antesdepois',
      );

      current.dispatch(current.state.tr..removeMark(1, 6, bold));
      expect(current.pageGraph.pages, hasLength(1));
      expect(current.pageGraph.honoredRenderedPageBreakHints, isFalse,
          reason: 'uma edição seguinte não reativa o cache descartado');
      expect(current.renderedPageBreakHintsValid, isFalse);
    });
  });

  /// Põe o caret na posição do modelo e dispara o `beforeinput` que o
  /// browser mandaria.
  FakeDomInputEvent input(
      OfficeEditorView view, int modelPosition, String inputType,
      {String? data, int? to, List<DomNativeRange> targetRanges = const []}) {
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, modelPosition)!;
    final end = map.domPositionFor(host, to ?? modelPosition)!;
    adapter.setSelectionByNodes(from.node, from.offset, end.node, end.offset);
    final event = FakeDomInputEvent(
        type: 'beforeinput',
        target: host,
        inputType: inputType,
        data: data,
        targetRanges: targetRanges);
    (host as FakeDomElement).dispatchEvent('beforeinput', event);
    return event;
  }

  FakeDomKeyboardEvent pressTab(OfficeEditorView view, int modelPosition,
      {bool shift = false}) {
    const map = OfficeDomPositionMap();
    final caret = map.domPositionFor(host, modelPosition)!;
    adapter.setSelectionByNodes(
        caret.node, caret.offset, caret.node, caret.offset);
    final event = FakeDomKeyboardEvent(
        type: 'keydown', target: host, key: 'Tab', shiftKey: shift);
    (host as FakeDomElement).dispatchEvent('keydown', event);
    return event;
  }

  group('insertText', () {
    test('digitar no fim do parágrafo entra no modelo', () {
      final view = mount(docOf([paragraph('alpha')]));
      input(view, 1 + 5, 'insertText', data: ' beta');
      expect(textOf(view), contains('alpha beta'));
    });

    test('digitar no meio insere no lugar certo', () {
      final view = mount(docOf([paragraph('aaabbb')]));
      input(view, 1 + 3, 'insertText', data: '-');
      expect(textOf(view), contains('aaa-bbb'));
    });

    test('o caret fica DEPOIS do texto inserido', () {
      final view = mount(docOf([paragraph('abc')]));
      input(view, 1 + 3, 'insertText', data: 'XY');
      expect(view.readNativeSelection()?.from, 1 + 5);
    });

    test('digitar sobre uma seleção substitui o intervalo', () {
      final view = mount(docOf([paragraph('um dois tres')]));
      // "um dois tres": a posição 1 é antes do 'u', então [4,8] é "dois".
      input(view, 1 + 3, 'insertText', data: 'X', to: 1 + 7);
      expect(textOf(view), 'um X tres');
    });

    test('a projeção mostra o novo estado', () {
      final view = mount(docOf([paragraph('antes')]));
      input(view, 1 + 5, 'insertText', data: ' depois');
      expect(host.textContent, contains('antes depois'));
    });

    test('seleção entre células rejeita texto e Enter sem alterar tabela', () {
      final view = mount(twoCellDocument());
      final starts = tableCellTextStarts(view.state.doc);
      final before = view.state.doc;

      input(view, starts.first + 1, 'insertText',
          data: 'X', to: starts.last + 1);
      expect(view.state.doc.eq(before), isTrue);

      input(view, starts.first + 1, 'insertParagraph', to: starts.last + 1);
      expect(view.state.doc.eq(before), isTrue);
      expect(view.state.doc.child(0).child(0).childCount, 2);
    });
  });

  group('atoms opacos e edição visível', () {
    PMNode inlineDocument() => docOf([
          schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.text('A'),
              opaqueBookmark(),
              schema.text('B'),
            ]),
          ),
        ]);

    test('Backspace atravessa bookmark e apaga o caractere anterior', () {
      final view = mount(inlineDocument());

      input(view, 3, 'deleteContentBackward');

      final block = view.state.doc.child(0);
      expect(block.textContent, 'B');
      expect(block.child(0).type.name, 'opaqueInline');
    });

    test('Delete atravessa bookmark e apaga o caractere seguinte', () {
      final view = mount(inlineDocument());

      input(view, 2, 'deleteContentForward');

      final block = view.state.doc.child(0);
      expect(block.textContent, 'A');
      expect(block.lastChild!.type.name, 'opaqueInline');
    });

    test('bookmark também é preservado dentro de célula', () {
      final view = mount(twoCellDocument(left: [
        schema.text('A'),
        opaqueBookmark(),
        schema.text('B'),
      ]));
      final start = tableCellTextStarts(view.state.doc).first;

      input(view, start + 2, 'deleteContentBackward');

      final paragraph = view.state.doc.child(0).child(0).child(0).child(0);
      expect(paragraph.textContent, 'B');
      expect(paragraph.child(0).type.name, 'opaqueInline');
      expect(view.state.doc.child(0).child(0).childCount, 2);
    });
  });

  group('apagar', () {
    test('backspace apaga o caractere anterior', () {
      final view = mount(docOf([paragraph('abcd')]));
      input(view, 1 + 4, 'deleteContentBackward');
      expect(textOf(view), 'abc');
    });

    test('delete apaga o caractere seguinte', () {
      final view = mount(docOf([paragraph('abcd')]));
      input(view, 1 + 1, 'deleteContentForward');
      expect(textOf(view), 'acd');
    });

    test('backspace no início do documento é no-op', () {
      final view = mount(docOf([paragraph('abc')]));
      input(view, 1, 'deleteContentBackward');
      expect(textOf(view), 'abc');
    });

    test('backspace com seleção apaga o intervalo', () {
      final view = mount(docOf([paragraph('um dois tres')]));
      // [3,8] cobre " dois" — o espaço antes de "dois" entra no intervalo.
      input(view, 1 + 2, 'deleteContentBackward', to: 1 + 7);
      expect(textOf(view), 'um tres');
    });

    test('deleteWordBackward respeita palavra portuguesa acentuada', () {
      final view = mount(docOf([paragraph('ação útil')]));
      input(view, 1 + 'ação útil'.length, 'deleteWordBackward');
      expect(textOf(view), 'ação ');

      input(view, 1 + 'ação '.length, 'deleteWordBackward');
      expect(textOf(view), '');
    });

    test('deleteWordBackward prefere o target range nativo', () {
      final view = mount(docOf([paragraph('um-dois')]));
      const map = OfficeDomPositionMap();
      final targetFrom = map.domPositionFor(host, 1 + 3)!;
      final targetTo = map.domPositionFor(host, 1 + 7)!;
      input(
        view,
        1 + 7,
        'deleteWordBackward',
        targetRanges: [
          DomNativeRange(
            startContainer: targetFrom.node,
            startOffset: targetFrom.offset,
            endContainer: targetTo.node,
            endOffset: targetTo.offset,
          ),
        ],
      );
      expect(textOf(view), 'um-');
    });

    test('deleteSoftLineBackward para na quebra manual da linha', () {
      final line = schema.node(
        'paragraph',
        null,
        Fragment.from([
          schema.text('primeira'),
          schema.node('hardBreak', {'breakType': null}, null),
          schema.text('segunda'),
        ]),
      );
      final view = mount(docOf([line]));
      input(view, 1 + 'primeira'.length + 1 + 3, 'deleteSoftLineBackward');
      expect(
        view.state.doc.child(0).textBetween(
              0,
              view.state.doc.child(0).content.size,
              leafText: (node) =>
                  node.type.name == 'hardBreak' ? '\n' : '\u{fffc}',
            ),
        'primeira\nunda',
      );
    });
  });

  group('parágrafo', () {
    test('Enter divide o bloco em dois', () {
      final view = mount(docOf([paragraph('antesdepois')]));
      final blocksBefore = view.state.doc.childCount;
      input(view, 1 + 5, 'insertParagraph');
      expect(view.state.doc.childCount, blocksBefore + 1);
      expect(view.state.doc.child(0).textContent, 'antes');
      expect(view.state.doc.child(1).textContent, 'depois');
    });

    test('Shift+Enter insere hardBreak sem dividir o parágrafo', () {
      final view = mount(docOf([paragraph('antesdepois')]));
      input(view, 1 + 5, 'insertLineBreak');

      expect(view.state.doc.childCount, 1);
      final block = view.state.doc.child(0);
      expect(block.childCount, 3);
      expect(block.child(0).textContent, 'antes');
      expect(block.child(1).type.name, 'hardBreak');
      expect(block.child(2).textContent, 'depois');
      expect(view.state.selection.from, 1 + 5 + 1);
    });
  });

  group('teclado em tabela', () {
    PMNode tableDoc() {
      PMNode cell(String value) => schema.node(
            'tableCell',
            null,
            Fragment.from([paragraph(value)]),
          );
      PMNode row(String left, String right) => schema.node(
            'tableRow',
            null,
            Fragment.from([cell(left), cell(right)]),
          );
      return docOf([
        schema.node(
          'table',
          null,
          Fragment.from([row('A', 'B'), row('C', 'D')]),
        ),
      ]);
    }

    List<int> cellTextStarts(PMNode doc) {
      final result = <int>[];
      doc.descendants((node, position, parent, index) {
        if (node.type.name != 'tableCell') return true;
        result.add(position + 2); // tableCell > paragraph > conteúdo
        return false;
      });
      return result;
    }

    test('Tab e Shift+Tab percorrem células editáveis', () {
      final view = mount(tableDoc());
      final starts = cellTextStarts(view.state.doc);

      final tab = pressTab(view, starts[0]);
      expect(tab.defaultPrevented, isTrue);
      expect(view.state.selection.from, starts[1]);

      final shiftTab = pressTab(view, starts[1], shift: true);
      expect(shiftTab.defaultPrevented, isTrue);
      expect(view.state.selection.from, starts[0]);
    });

    test('Tab na última célula preserva tabela e caret', () {
      final view = mount(tableDoc());
      final starts = cellTextStarts(view.state.doc);
      final before = view.state.doc;

      final event = pressTab(view, starts.last);

      expect(event.defaultPrevented, isTrue);
      expect(view.state.doc.eq(before), isTrue);
      expect(view.state.selection.from, starts.last);
    });

    test('Backspace/Delete nos limites não mesclam células', () {
      final view = mount(tableDoc());
      final starts = cellTextStarts(view.state.doc);
      final before = view.state.doc;

      input(view, starts.first, 'deleteContentBackward');
      expect(view.state.doc.eq(before), isTrue);

      input(view, starts.last + 1, 'deleteContentForward');
      expect(view.state.doc.eq(before), isTrue);
      expect(view.state.doc.child(0).childCount, 2);
      expect(view.state.doc.child(0).child(0).childCount, 2);
    });
  });

  group('o browser nunca escreve na projeção', () {
    test('inputType não suportado é cancelado e não muda o documento', () {
      final view = mount(docOf([paragraph('intacto')]));
      final before = textOf(view);
      input(view, 1 + 7, 'formatBold');
      expect(textOf(view), before);
    });

    test('composição IME é ignorada enquanto não há reconciliação', () {
      final view = mount(docOf([paragraph('base')]));
      const map = OfficeDomPositionMap();
      final position = map.domPositionFor(host, 1 + 4)!;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);
      (host as FakeDomElement).dispatchEvent(
          'beforeinput',
          FakeDomInputEvent(
              type: 'beforeinput',
              target: host,
              inputType: 'insertText',
              data: 'ç',
              isComposing: true));
      expect(textOf(view), 'base',
          reason: 'fingir suporte a IME corromperia o documento');
    });
  });

  group('ciclo completo', () {
    test('dispatch programático recompõe o grafo e reprojeta', () {
      final view = mount(docOf([paragraph('inicial')]));
      view.dispatch(view.state.tr..insertText(' extra', 1 + 7));
      expect(textOf(view), contains('inicial extra'));
      expect(host.textContent, contains('inicial extra'));
      expect(view.pageGraph.pages, isNotEmpty);
    });

    test('onStateChange avisa a aplicação a cada transação', () {
      var changes = 0;
      final state =
          EditorState.create(EditorStateConfig(doc: docOf([paragraph('x')])));
      view = OfficeEditorView(
        host: host,
        state: state,
        adapter: adapter,
        onStateChange: (_) => changes++,
      );
      input(view!, 1 + 1, 'insertText', data: 'y');
      expect(changes, 1);
    });

    test('digitar várias vezes acumula no documento', () {
      // Parágrafo VAZIO é um bloco sem filhos — um nó de texto vazio é
      // inválido no schema (e é o estado inicial real de um documento novo).
      final view =
          mount(docOf([schema.node('paragraph', null, Fragment.empty)]));
      for (final letter in ['a', 'b', 'c']) {
        final at = view.state.doc.content.size - 1;
        input(view, at, 'insertText', data: letter);
      }
      expect(textOf(view), 'abc');
    });

    test('dispose solta o listener', () {
      final view = mount(docOf([paragraph('final')]));
      view.dispose();
      input(view, 1 + 5, 'insertText', data: 'ZZZ');
      expect(textOf(view), 'final');
    });
  });
}
