/// F9 — edição in-place de caixa de texto.
///
/// O que estes testes protegem é a ponta que faltava: a caixa era desenhada e
/// preservada byte a byte, mas não editável. Editar in-place tem duas metades
/// que precisam casar — o que aparece na tela (a superfície montada sobre a
/// caixa) e o que vai para o arquivo (o `w:txbxContent` regerado). Uma sem a
/// outra é pior que nenhuma: o usuário digita, vê o texto novo, salva e
/// reabre com o antigo.
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

  PMNode paragraphOf(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  /// O documento interno da caixa, no formato em que o codec o importa.
  PMNode innerDoc(List<String> lines) => schema.node('doc', null,
      Fragment.from([for (final line in lines) paragraphOf(line)]));

  PMNode textBoxNode({PMNode? inner, String text = 'na caixa'}) =>
      schema.node('textBox', {
        'text': text,
        'textBoxDoc': inner?.toJSON(),
        'width': 2880,
        'height': 1440,
        'insetLeft': 144,
        'insetTop': 72,
        'insetRight': 144,
        'insetBottom': 72,
      });

  OfficeWordEditor mount({PMNode? box}) {
    final node = box ?? textBoxNode(inner: innerDoc(['na caixa']));
    return editor = OfficeWordEditor.mount(
      host: host,
      adapter: adapter,
      document: schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null, Fragment.from([node])),
            paragraphOf('corpo do documento'),
          ])),
      schema: schema,
    );
  }

  /// O elemento projetado da caixa.
  DomElement boxElement(OfficeWordEditor e) {
    final elements = host.querySelectorAll('.dq-office-text-box');
    expect(elements, isNotEmpty, reason: 'a caixa tem de estar projetada');
    return elements.first;
  }

  /// O duplo clique como o browser o entregaria: o listener vive no canvas,
  /// o `target` é o elemento realmente clicado.
  void doubleClickOn(DomElement target) {
    final canvas = host.querySelector('.dq-office-canvas')! as FakeDomElement;
    canvas.dispatchEvent(
        'dblclick', FakeDomMouseEvent(type: 'dblclick', target: target));
  }

  group('entrar e sair', () {
    test('a caixa projetada carrega a posição do NÓ no modelo', () {
      final e = mount();
      final pos = boxElement(e).getAttribute('data-doc-pos');
      expect(pos, isNotNull,
          reason: 'sem esta âncora o duplo clique não sabe qual caixa abrir');
      final node = e.state.doc.nodeAt(int.parse(pos!));
      expect(node?.type.name, 'textBox');
    });

    test('duplo clique na caixa entra e monta uma view sobre ela', () {
      final e = mount();
      expect(e.textBoxSession.isActive, isFalse);

      doubleClickOn(boxElement(e));

      expect(e.textBoxSession.isActive, isTrue);
      expect(e.textBoxSession.boxView, isNotNull);
      // É a MESMA classe do corpo, montada em outra raiz — não um segundo
      // laço de edição.
      expect(e.textBoxSession.boxView, isNot(same(e.view)));
      expect(host.querySelectorAll('.dq-office-tb-surface'), hasLength(1));
      expect(host.querySelectorAll('.dq-office-tb-frame'), hasLength(1));
    });

    test('a view da caixa edita o textBoxDoc, não o corpo', () {
      final e = mount(box: textBoxNode(inner: innerDoc(['linha um'])));
      doubleClickOn(boxElement(e));

      expect(e.textBoxSession.boxView!.state.doc.textContent, 'linha um');
    });

    test('as ações de formatação passam a agir DENTRO da caixa', () {
      final e = mount();
      doubleClickOn(boxElement(e));

      expect(e.activeView, same(e.textBoxSession.boxView));
    });

    test('entrar trava a edição do corpo', () {
      final e = mount();
      doubleClickOn(boxElement(e));

      final content = host.querySelector('.dq-office-page-content')!;
      expect(content.getAttribute('contenteditable'), isNull,
          reason: 'esmaecer é o aviso; o atributo é o que impede a digitação');
    });

    test('duplo clique FORA sai e devolve a edição ao corpo', () {
      final e = mount();
      doubleClickOn(boxElement(e));
      expect(e.textBoxSession.isActive, isTrue);

      doubleClickOn(host.querySelector('.dq-office-page-content')!);

      expect(e.textBoxSession.isActive, isFalse);
      expect(host.querySelectorAll('.dq-office-tb-surface'), isEmpty);
      expect(e.activeView, same(e.view));
    });

    test('caixa sem textBoxDoc ainda abre, a partir do texto plano', () {
      final e = mount(box: textBoxNode(text: 'só texto\nem duas linhas'));
      doubleClickOn(boxElement(e));

      expect(e.textBoxSession.isActive, isTrue);
      expect(e.textBoxSession.boxView!.state.doc.childCount, 2);
      expect(e.textBoxSession.boxView!.state.doc.textContent,
          'só textoem duas linhas');
    });
  });

  group('gravação', () {
    /// Digita [text] na view da caixa, como o usuário faria.
    void typeInBox(OfficeWordEditor e, String text) {
      final view = e.textBoxSession.boxView!;
      final state = view.state;
      view.dispatch(state.tr
        ..replaceWith(
            1, state.doc.content.size - 1, Fragment.from([schema.text(text)])));
    }

    test('sair grava textBoxDoc E text no nó', () {
      final e = mount(box: textBoxNode(inner: innerDoc(['antigo'])));
      doubleClickOn(boxElement(e));
      typeInBox(e, 'novo conteúdo');

      doubleClickOn(host.querySelector('.dq-office-page-content')!);

      final node = e.state.doc.child(0).child(0);
      expect(node.type.name, 'textBox');
      final stored = PMNode.fromJSON(schema, node.attrs['textBoxDoc'] as Map);
      expect(stored.textContent, 'novo conteúdo');
      // `text` é o fallback visual de renderers antigos e o que a busca
      // enxerga: deixá-lo velho faria a caixa mostrar uma coisa e ser
      // encontrada por outra.
      expect(node.attrs['text'], 'novo conteúdo');
    });

    test('entrar, olhar e sair NÃO altera o documento', () {
      final e = mount(box: textBoxNode(inner: innerDoc(['intocado'])));
      final before = e.state.doc;

      doubleClickOn(boxElement(e));
      doubleClickOn(host.querySelector('.dq-office-page-content')!);

      expect(identical(e.state.doc, before), isTrue,
          reason: 'abrir uma caixa não é editá-la');
    });

    test('a sessão inteira é UM passo de undo', () {
      final e = mount(box: textBoxNode(inner: innerDoc(['antigo'])));
      doubleClickOn(boxElement(e));
      typeInBox(e, 'um');
      typeInBox(e, 'dois');
      doubleClickOn(host.querySelector('.dq-office-page-content')!);

      e.runCommand('undo');

      final node = e.state.doc.child(0).child(0);
      final stored = PMNode.fromJSON(schema, node.attrs['textBoxDoc'] as Map);
      expect(stored.textContent, 'antigo');
    });

    test('a projeção do corpo mostra o texto novo depois de sair', () {
      final e = mount(box: textBoxNode(inner: innerDoc(['antigo'])));
      doubleClickOn(boxElement(e));
      typeInBox(e, 'texto novo');
      doubleClickOn(host.querySelector('.dq-office-page-content')!);

      expect(boxElement(e).textContent, contains('texto novo'));
    });
  });
}
