/// Localizar/Substituir (F10): a conversão índice-de-texto → posição-do-
/// modelo e o contrato de UMA transação no Substituir Tudo.
///
/// O caso que estes testes existem para travar é o documento com uma IMAGEM
/// no meio do parágrafo: o átomo ocupa posição e não tem texto, então quem
/// somar comprimentos de string seleciona a palavra errada — e só descobre
/// isso num documento de usuário.
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

  PMNode paragraph(List<PMNode> content) =>
      schema.node('paragraph', null, Fragment.from(content));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode textDoc(List<String> paragraphs) => docOf([
        for (final text in paragraphs)
          paragraph(text.isEmpty ? const [] : [schema.text(text)]),
      ]);

  PMNode image() => schema.node('image', {
        'src': 'data:image/png;base64,AA',
        'width': 1440,
        'height': 1440,
      });

  OfficeWordEditor mount(PMNode document) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document,
        schema: schema,
      );

  void click(DomElement element) => (element as FakeDomElement).dispatchEvent(
      'click', FakeDomMouseEvent(type: 'click', target: element));

  /// Escrever no campo não dispara `input` sozinho no fake DOM (ele não
  /// simula o browser): o teste emite o evento que o usuário emitiria.
  void type(DomElement field, String value) {
    field.value = value;
    (field as FakeDomElement)
        .dispatchEvent('input', FakeDomEvent('input', field));
  }

  DomElement field(String key) {
    for (final input in host.querySelectorAll('.dq-office-find-input')) {
      if (input.getAttribute('data-field') == key) return input;
    }
    for (final input in host.querySelectorAll('.dq-office-find-checkbox')) {
      if (input.getAttribute('data-field') == key) return input;
    }
    throw StateError('campo não encontrado: $key');
  }

  DomElement button(String label) {
    for (final element in [
      ...host.querySelectorAll('.dq-office-find-action'),
      ...host.querySelectorAll('.dq-office-find-step'),
    ]) {
      if ((element.textContent ?? '') == label) return element;
    }
    throw StateError('botão não encontrado: $label');
  }

  String counter() =>
      host.querySelector('.dq-office-find-count')?.textContent ?? '';

  group('varredura', () {
    test('ignora a caixa por padrão e a respeita quando pedido', () {
      final doc = textDoc(['Word word WORD']);

      expect(officeFindAll(doc, 'word'), hasLength(3));
      expect(
        officeFindAll(doc, 'word',
            options: const OfficeSearchOptions(matchCase: true)),
        hasLength(1),
      );
    });

    test('acento é significativo e a caixa alta acentuada também dobra', () {
      final doc = textDoc(['coração CORAÇÃO coracao']);

      final withAccent = officeFindAll(doc, 'coração');
      expect(withAccent, hasLength(2),
          reason: 'dobrar a caixa não pode perder o acento nem o alinhamento');
      expect(officeFindAll(doc, 'coracao'), hasLength(1));

      // A posição continua exata depois de um caractere acentuado.
      final second = withAccent[1];
      expect(doc.textBetween(second.from, second.to), 'CORAÇÃO');
    });

    test('palavra inteira exige fronteira dos dois lados', () {
      final doc = textDoc(['casa casamento descasa casa-nova']);
      const whole = OfficeSearchOptions(wholeWord: true);

      final matches = officeFindAll(doc, 'casa', options: whole);
      expect(matches, hasLength(2),
          reason: '"casamento" e "descasa" têm letra colada');
      expect(doc.textBetween(matches[0].from, matches[0].to), 'casa');
      // O hífen NÃO é letra: "casa-nova" começa com a palavra "casa".
      expect(matches[1].from, greaterThan(matches[0].from));
    });

    test('uma ocorrência atravessa runs com formatação diferente', () {
      final bold = schema.marks['bold']!;
      final doc = docOf([
        paragraph([
          schema.text('ne', [bold.create()]),
          schema.text('grito'),
        ]),
      ]);

      final matches = officeFindAll(doc, 'negrito');
      expect(matches, hasLength(1));
      expect(matches.single.from, 1);
      expect(matches.single.to, 8);
    });

    test('não atravessa parágrafo', () {
      expect(officeFindAll(textDoc(['fim', 'inicio']), 'fiminicio'), isEmpty);
    });

    group('com IMAGEM no meio do parágrafo', () {
      // 'antes ' ocupa 1..6, a imagem ocupa a posição 7 (átomo, sem texto),
      // ' alvo depois' recomeça em 8 — então "alvo" está em 9.
      final doc = docOf([
        paragraph([
          schema.text('antes '),
          schema.node('image', {
            'src': 'data:image/png;base64,AA',
            'width': 1440,
            'height': 1440,
          }),
          schema.text(' alvo depois'),
        ]),
      ]);

      test('a posição é a do MODELO, não o índice do texto', () {
        final match = officeFindAll(doc, 'alvo').single;

        expect(match.from, 9);
        expect(match.to, 13);
        expect(doc.textBetween(match.from, match.to), 'alvo');

        // O erro clássico: usar o índice dentro de textBetween. Ele daria 7,
        // que é a POSIÇÃO DA IMAGEM.
        final naive = doc.textBetween(0, doc.content.size).indexOf('alvo') + 1;
        expect(naive, isNot(match.from),
            reason: 'o teste perde o valor se os dois caminhos coincidirem');
      });

      test('nenhuma ocorrência atravessa o átomo', () {
        expect(officeFindAll(doc, 'antes  alvo'), isEmpty,
            reason: 'a imagem é uma cerca, como o ^g do Word');
      });
    });

    test('consulta vazia não acha nada', () {
      expect(officeFindAll(textDoc(['qualquer coisa']), ''), isEmpty);
    });
  });

  group('Substituir Tudo', () {
    test('é UMA transação: o undo devolve o documento inteiro', () {
      final editor = mount(textDoc([
        'alfa beta alfa',
        'gama alfa',
      ]));

      final count = officeReplaceAll(editor, 'alfa', 'ômega');

      expect(count, 3);
      expect(editor.state.doc.child(0).textContent, 'ômega beta ômega');
      expect(editor.state.doc.child(1).textContent, 'gama ômega');

      editor.runCommand('undo');

      expect(editor.state.doc.child(0).textContent, 'alfa beta alfa',
          reason: 'um Ctrl+Z, não três');
      expect(editor.state.doc.child(1).textContent, 'gama alfa');
    });

    test('substitui de trás para frente sem embaralhar posições', () {
      // Substituto MAIOR que o procurado: aplicado do começo para o fim, o
      // deslocamento acumulado faria a segunda troca cair no lugar errado.
      final editor = mount(textDoc(['x a y a z']));

      officeReplaceAll(editor, 'a', 'LONGO');

      expect(editor.state.doc.child(0).textContent, 'x LONGO y LONGO z');
    });

    test('preserva a formatação do texto trocado', () {
      final bold = schema.marks['bold']!;
      final editor = mount(docOf([
        paragraph([
          schema.text('normal '),
          schema.text('alvo', [bold.create()]),
        ]),
      ]));

      officeReplaceAll(editor, 'alvo', 'novo');

      final last = editor.state.doc.child(0).lastChild!;
      expect(last.text, 'novo');
      expect(last.marks.map((mark) => mark.type.name), contains('bold'));
    });

    test('respeita as opções da busca', () {
      final editor = mount(textDoc(['Casa casa casamento']));

      final count = officeReplaceAll(editor, 'casa', 'lar',
          options: const OfficeSearchOptions(matchCase: true, wholeWord: true));

      expect(count, 1);
      expect(editor.state.doc.child(0).textContent, 'Casa lar casamento');
    });

    test('atravessa a imagem sem tocar nela', () {
      final editor = mount(docOf([
        paragraph([
          schema.text('antes '),
          image(),
          schema.text(' alvo depois'),
        ]),
      ]));

      officeReplaceAll(editor, 'alvo', 'X');

      final block = editor.state.doc.child(0);
      expect(block.child(1).type.name, 'image',
          reason: 'a imagem continua no lugar, com o mesmo nó');
      expect(block.textContent, 'antes  X depois');
    });
  });

  group('painel', () {
    test('abre no overlay com contador, navegação e opções', () {
      final editor = mount(textDoc(['um dois um dois um']));

      officeFindPanel(editor).open();

      expect(host.querySelectorAll('.dq-office-find'), hasLength(1));
      type(field('find'), 'um');

      expect(counter(), '1 de 3');
      expect(editor.state.selection.from, 1);
      expect(editor.state.selection.to, 3);
    });

    test('Próximo e Anterior circulam e SELECIONAM a ocorrência', () {
      final editor = mount(textDoc(['um dois um dois um']));
      officeFindPanel(editor).open();
      type(field('find'), 'um');

      click(button('›'));
      expect(counter(), '2 de 3');
      expect(
          editor.state.doc.textBetween(
              editor.state.selection.from, editor.state.selection.to),
          'um');
      expect(editor.state.selection.from, 9);

      click(button('›'));
      expect(counter(), '3 de 3');
      click(button('›'));
      expect(counter(), '1 de 3', reason: 'o Word volta ao começo');

      click(button('‹'));
      expect(counter(), '3 de 3');
    });

    test('a seleção cai no lugar certo com imagem antes da ocorrência', () {
      final editor = mount(docOf([
        paragraph([schema.text('antes '), image(), schema.text(' alvo')]),
      ]));

      officeFindPanel(editor).open();
      type(field('find'), 'alvo');

      expect(editor.state.selection.from, 9);
      expect(
          editor.state.doc.textBetween(
              editor.state.selection.from, editor.state.selection.to),
          'alvo');
    });

    test('sem resultado o contador diz isso, e nada é selecionado', () {
      final editor = mount(textDoc(['nada aqui']));
      officeFindPanel(editor).open();

      type(field('find'), 'zzz');

      expect(counter(), 'Nenhum resultado');
      expect(officeFindPanel(editor).currentIndex, -1);
    });

    test('as opções refazem a busca ao serem marcadas', () {
      final editor = mount(textDoc(['Casa casa']));
      officeFindPanel(editor).open();
      type(field('find'), 'casa');
      expect(counter(), '1 de 2');

      final matchCase = field('matchCase') as FakeDomElement;
      matchCase.dispatchEvent('change', FakeDomEvent('change', matchCase));

      expect(matchCase.value, 'true');
      expect(counter(), '1 de 1');
    });

    test('Substituir troca a ocorrência corrente e segue para a próxima', () {
      final editor = mount(textDoc(['alfa beta alfa']));
      officeFindPanel(editor).open(withReplace: true);
      type(field('find'), 'alfa');
      field('replace').value = 'X';

      click(button('Substituir'));

      expect(editor.state.doc.child(0).textContent, 'X beta alfa');
      expect(counter(), '1 de 1',
          reason: 'sobrou uma ocorrência, e ela vira a corrente');
    });

    test('Substituir Tudo anuncia quantas trocou', () {
      final editor = mount(textDoc(['alfa beta alfa']));
      officeFindPanel(editor).open(withReplace: true);
      type(field('find'), 'alfa');
      field('replace').value = 'X';

      click(button('Substituir Tudo'));

      expect(editor.state.doc.child(0).textContent, 'X beta X');
      expect(counter(), '2 substituídas');
    });

    test('Ctrl+H abre o painel com a linha de substituição', () {
      final editor = mount(textDoc(['texto']));

      (host as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: host, key: 'h', ctrlKey: true));

      expect(officeFindPanel(editor).isOpen, isTrue);
      expect(officeFindPanel(editor).isReplaceVisible, isTrue);

      // Ctrl+F reaproveita o MESMO painel (o texto digitado não se perde) e
      // apenas esconde a linha de substituição.
      (host as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: host, key: 'f', ctrlKey: true));

      expect(host.querySelectorAll('.dq-office-find'), hasLength(1));
      expect(officeFindPanel(editor).isReplaceVisible, isFalse);
    });

    test('a seleção do documento alimenta a busca ao abrir', () {
      final editor = mount(textDoc(['procure isto aqui, isto mesmo']));
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 9, 13)));

      officeFindPanel(editor).open();

      expect(field('find').value, 'isto');
      expect(counter(), '1 de 2');
    });

    test('rolar o documento NÃO fecha o painel', () {
      // A rolagem fecha os popups ANCORADOS (eles perderiam o âncora), mas
      // quem rolou aqui pode ter sido o próprio "Próximo" indo até a
      // ocorrência: fechar seria reagir ao efeito do próprio comando.
      final editor = mount(textDoc(['um dois um']));
      officeFindPanel(editor).open();
      type(field('find'), 'um');

      final canvas = host.querySelector('.dq-office-canvas') as FakeDomElement;
      canvas.dispatchEvent('scroll', FakeDomEvent('scroll', canvas));

      expect(host.querySelectorAll('.dq-office-find'), hasLength(1));
    });

    test('reabrir preserva a consulta e as opções', () {
      final editor = mount(textDoc(['Casa casa']));
      officeFindPanel(editor).open();
      type(field('find'), 'zzz');
      final matchCase = field('matchCase') as FakeDomElement;
      matchCase.dispatchEvent('change', FakeDomEvent('change', matchCase));

      officeFindPanel(editor).close();
      officeFindPanel(editor).open();

      expect(field('find').value, 'zzz');
      expect(field('matchCase').value, 'true');
    });

    test('fechar tira o painel do overlay', () {
      final editor = mount(textDoc(['texto']));
      officeFindPanel(editor).open();
      expect(host.querySelectorAll('.dq-office-find'), hasLength(1));

      officeFindPanel(editor).close();

      expect(host.querySelectorAll('.dq-office-find'), isEmpty);
    });
  });
}
