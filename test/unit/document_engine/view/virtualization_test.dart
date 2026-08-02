/// Fase 7 — virtualização: só a janela de páginas fica montada.
///
/// A ordem do §7.9 é o que torna isto seguro: posição modelo↔DOM, índice de
/// página e placeholders exatos já existem. O risco que sobra é o caret
/// sumir numa página desmontada — e é isso que os testes de fixação cobrem.
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

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  PMNode longDoc(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar a linha '
              'inteira e forçar a composição a produzir várias páginas.')
      ]));

  OfficeEditorView mount(PMNode doc, {OfficeVirtualization? virtualization}) =>
      view = OfficeEditorView.withExtensions(
          host: host,
          doc: doc,
          adapter: adapter,
          extensions: officeDefaultExtensions(schema),
          virtualization: virtualization);

  int mountedPages() => host.querySelectorAll('.dq-office-page').length;
  int placeholders() =>
      host.querySelectorAll('.dq-office-page-placeholder').length;

  test('sem política, o documento inteiro fica montado', () {
    final view = mount(longDoc(300));
    expect(view.mountedWindow, isNull);
    expect(mountedPages(), view.pageGraph.pages.length);
    expect(placeholders(), 0);
  });

  test('com política, só a janela fica montada', () {
    final view = mount(longDoc(400),
        virtualization: const OfficeVirtualization(radius: 1));
    final total = view.pageGraph.pages.length;
    expect(total, greaterThan(4), reason: 'precisa de páginas para virtualizar');

    expect(mountedPages(), lessThan(total));
    expect(mountedPages() + placeholders(), total,
        reason: 'toda página tem de existir: montada ou como placeholder');
  });

  test('a janela começa no início e cobre o raio pedido', () {
    final view = mount(longDoc(400),
        virtualization: const OfficeVirtualization(radius: 2));
    expect(view.mountedWindow!.firstPage, 0);
    expect(view.mountedWindow!.lastPage, 2);
  });

  test('a página da SELEÇÃO nunca fica desmontada', () {
    final view = mount(longDoc(400),
        virtualization: const OfficeVirtualization(radius: 1));
    final total = view.pageGraph.pages.length;
    final lastPageEntry = view.pageGraph.positionMap.entries
        .lastWhere((entry) => entry.pageIndex == total - 1);

    view.dispatch(view.state.tr
      ..setSelection(TextSelection.create(
          view.state.doc, lastPageEntry.docPosStart)));

    expect(view.mountedWindow!.contains(total - 1), isTrue,
        reason: 'desmontar a página do caret faria o cursor sumir');
    // E o mapa de posições consegue resolver a posição — a prova de que a
    // página está mesmo no DOM.
    expect(
        const OfficeDomPositionMap()
            .domPositionFor(host, lastPageEntry.docPosStart),
        isNotNull);
  });

  test('rolar troca a janela', () {
    final view = mount(longDoc(600),
        virtualization: const OfficeVirtualization(radius: 1));
    final before = view.mountedWindow!;

    final pageHeightPx =
        view.pageGraph.pages.first.setup.heightTwips / 20.0 * (96 / 72);
    host.scrollTop = (pageHeightPx * 3).round();
    (host as FakeDomElement).dispatchEvent('scroll', FakeDomEvent('scroll', host));

    final after = view.mountedWindow!;
    expect(after, isNot(before));
    expect(after.contains(3), isTrue);
    expect(after.firstPage, greaterThan(before.firstPage));
  });

  test('a janela não muda enquanto o scroll fica na mesma página', () {
    final view = mount(longDoc(600),
        virtualization: const OfficeVirtualization(radius: 2));
    final before = view.mountedWindow;
    host.scrollTop = 5;
    (host as FakeDomElement).dispatchEvent('scroll', FakeDomEvent('scroll', host));
    expect(view.mountedWindow, before,
        reason: 'reprojetar a cada pixel de scroll seria pior que não '
            'virtualizar');
  });

  test('scroll durante composição IME NÃO remonta', () {
    final view = mount(longDoc(600),
        virtualization: const OfficeVirtualization(radius: 1));
    (host as FakeDomElement)
        .dispatchEvent('compositionstart', FakeDomEvent('compositionstart', host));
    final before = view.mountedWindow;

    final pageHeightPx =
        view.pageGraph.pages.first.setup.heightTwips / 20.0 * (96 / 72);
    host.scrollTop = (pageHeightPx * 4).round();
    (host as FakeDomElement).dispatchEvent('scroll', FakeDomEvent('scroll', host));

    expect(view.mountedWindow, before,
        reason: 'remontar no meio da composição destruiria o estado do IME');
  });

  test('placeholders têm a altura EXATA da página', () {
    mount(longDoc(400),
        virtualization: const OfficeVirtualization(radius: 1));
    final placeholder =
        host.querySelectorAll('.dq-office-page-placeholder').first;
    final page = host.querySelectorAll('.dq-office-page').first;
    final heightOf = RegExp(r'height:([0-9.]+)px');
    expect(heightOf.firstMatch(placeholder.getAttribute('style')!)!.group(1),
        heightOf.firstMatch(page.getAttribute('style')!)!.group(1),
        reason: 'altura diferente faria o scroll pular ao trocar a janela');
  });

  test('digitar continua funcionando com a janela ativa', () {
    final view = mount(longDoc(400),
        virtualization: const OfficeVirtualization(radius: 2));
    final position = const OfficeDomPositionMap().domPositionFor(host, 1)!;
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);
    (host as FakeDomElement).dispatchEvent(
        'beforeinput',
        FakeDomInputEvent(
            type: 'beforeinput',
            target: host,
            inputType: 'insertText',
            data: 'X'));
    expect(view.state.doc.child(0).textContent, startsWith('X'));
  });

  test('dispose solta o listener de scroll', () {
    final view = mount(longDoc(600),
        virtualization: const OfficeVirtualization(radius: 1));
    view.dispose();
    final before = view.mountedWindow;
    host.scrollTop = 100000;
    (host as FakeDomElement).dispatchEvent('scroll', FakeDomEvent('scroll', host));
    expect(view.mountedWindow, before);
  });
}
