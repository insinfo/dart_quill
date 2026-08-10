@TestOn('browser')
library office_spellcheck_test;

/// O corretor ortográfico NATIVO em Chrome REAL.
///
/// O fake DOM guarda strings: ele confirma que escrevemos `spellcheck`, não
/// que o browser LIGOU o corretor. Quem decide isso é a propriedade
/// `HTMLElement.spellcheck` depois do parsing — é ela que faz o Chrome
/// pintar o sublinhado, e é ela que este arquivo mede.
///
/// O sublinhado em si não tem API: nenhum browser expõe as marcas do
/// corretor ao script (é justamente a barreira que impede uma página de ler
/// o dicionário do usuário). O que dá para provar automaticamente é o
/// contrato que o produz — a propriedade ligada — e a metade que importa
/// para este projeto: a projeção continua sendo escrita pelo MODELO.
import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final schema = officeQuillSchema();
  final adapter = domBindings.adapter;

  late DomElement host;
  OfficeWordEditor? editor;

  setUp(() {
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  OfficeWordEditor mount({required bool spellcheck}) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node('paragraph', null,
                  Fragment.from([schema.text('texot do documento')])),
            ])),
        schema: schema,
        options: OfficeWordEditorOptions(spellcheck: spellcheck),
      );

  /// As caixas de conteúdo editável projetadas. Só há um editor montado por
  /// teste, então a busca global é a mesma coisa que buscar no host.
  List<web.HTMLElement> contentBoxes() {
    final nodes = web.document.querySelectorAll('.dq-office-page-content');
    return [
      for (var i = 0; i < nodes.length; i++) nodes.item(i)! as web.HTMLElement,
    ];
  }

  test('o Chrome LIGA o corretor quando o hospedeiro pede', () {
    mount(spellcheck: true);
    final boxes = contentBoxes();
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      // A propriedade, não o atributo: é ela que o Chrome consulta para
      // pintar o sublinhado.
      expect(box.spellcheck, isTrue);
      expect(box.isContentEditable, isTrue);
    }
  });

  test('sem a opção o corretor fica desligado mesmo com a página ligada', () {
    // O padrão de `spellcheck` num contenteditable é HERDAR. Ligar no body é
    // o cenário que faz um editor "ganhar" o corretor sem pedir.
    web.document.body!.spellcheck = true;
    try {
      mount(spellcheck: false);
      for (final box in contentBoxes()) {
        expect(box.spellcheck, isFalse,
            reason: 'a decisão é do editor, não da página hospedeira');
      }
    } finally {
      web.document.body!.spellcheck = false;
    }
  });

  test('com o corretor ligado a projeção continua vindo do MODELO', () {
    final e = mount(spellcheck: true);
    final before = contentBoxes().first.textContent;
    expect(before, contains('texot'));

    e.view.dispatch(e.state.tr..insertText(' extra', 1 + 18));

    expect(
        contentBoxes().first.textContent, contains('texot do documento extra'));
    expect(e.state.doc.textContent, 'texot do documento extra',
        reason: 'modelo e projeção têm de continuar dizendo a mesma coisa');
  });
}
