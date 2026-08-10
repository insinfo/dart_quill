/// F9 — Inserir → Caixa de Texto.
///
/// Inserir o nó é a parte fácil e a menos interessante. O que estes testes
/// protegem é a caixa nova ser TRATADA como caixa pelo resto do editor: ser
/// composta e projetada (senão o usuário clica no botão e não vê nada), abrir
/// para digitação na hora (é onde o Word põe o cursor) e nascer SEM `word` —
/// o atributo de carimbo, cuja ausência é o que faz a exportação gerar a
/// forma a partir do modelo em vez de devolver um XML velho.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
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

  PMNode paragraphOf(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node(
            'doc', null, Fragment.from([paragraphOf('corpo do documento')])),
        schema: schema,
      );

  PMNode? boxAt(OfficeWordEditor e, int? pos) =>
      pos == null ? null : e.state.doc.nodeAt(pos);

  test('inserir cria um nó textBox no cursor', () {
    final e = mount();
    final pos = insertTextBox(e, enterEditing: false);

    expect(pos, isNotNull);
    expect(boxAt(e, pos)?.type.name, 'textBox');
  });

  test('a caixa nova é COMPOSTA e PROJETADA', () {
    final e = mount();
    insertTextBox(e, enterEditing: false);

    final drawn = host.querySelectorAll('.dq-office-text-box');
    expect(drawn, hasLength(1),
        reason: 'um botão que insere um nó que ninguém desenha é um botão '
            'que não faz nada');
    // A âncora de posição é o que o duplo clique e o adorno de seleção usam.
    expect(drawn.first.getAttribute('data-doc-pos'), isNotNull);
  });

  test(
      'a caixa nasce SEM `word` — é o que manda gerar a forma na '
      'exportação', () {
    final e = mount();
    final pos = insertTextBox(e, enterEditing: false);

    expect(boxAt(e, pos)!.attrs['word'], isNull);
  });

  test('a caixa nova é redimensionável pelo mesmo adorno da importada', () {
    final e = mount();
    final pos = insertTextBox(e, enterEditing: false);

    expect(officeResizableNodeTypes, contains(boxAt(e, pos)!.type.name));
  });

  test(
      'inserir ABRE a caixa para digitação (o cursor do Word nasce '
      'dentro dela)', () {
    final e = mount();
    final pos = insertTextBox(e);

    expect(e.textBoxSession.isActive, isTrue);
    expect(e.textBoxSession.boxRef?.pos, pos);
    expect(e.activeView, same(e.textBoxSession.boxView));
    expect(host.querySelectorAll('.dq-office-tb-surface'), hasLength(1));
  });

  test('o que é digitado na caixa recém-criada é gravado no nó', () {
    final e = mount();
    final pos = insertTextBox(e);

    final view = e.textBoxSession.boxView!;
    view.dispatch(view.state.tr
      ..replaceWith(1, view.state.doc.content.size - 1,
          Fragment.from([schema.text('escrito agora')])));
    e.textBoxSession.exit();

    final box = boxAt(e, pos)!;
    expect(box.attrs['text'], 'escrito agora');
    expect(PMNode.fromJSON(schema, box.attrs['textBoxDoc'] as Map).textContent,
        'escrito agora');
  });

  test('a geometria padrão é a da "Caixa de Texto Simples" do Word', () {
    final e = mount();
    final box = boxAt(e, insertTextBox(e, enterEditing: false))!;

    expect(box.attrs['width'], officeDefaultTextBoxWidthTwips);
    expect(box.attrs['height'], officeDefaultTextBoxHeightTwips);
    // Os mesmos recuos que a importação assume quando `wps:bodyPr` os omite:
    // caixa nova e caixa importada medem o texto interno com a mesma régua.
    expect(box.attrs['insetLeft'], officeDefaultTextBoxInsetXTwips);
    expect(box.attrs['insetTop'], officeDefaultTextBoxInsetYTwips);
  });

  test('inserir é UM passo de undo', () {
    final e = mount();
    final before = e.state.doc;
    insertTextBox(e, enterEditing: false);

    e.runCommand('undo');

    expect(e.state.doc.eq(before), isTrue);
    expect(host.querySelectorAll('.dq-office-text-box'), isEmpty);
  });
}
