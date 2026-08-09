/// A mini-UI contextual num CHROME de verdade.
///
/// O fake DOM prova que os controles existem e agem sobre o modelo; ele não
/// pode provar o que só o browser tem: geometria de seleção (a barra nasce
/// ACIMA do texto), `contextmenu` cancelado de fato, e — o requisito que
/// mais quebra na prática — a seleção continuar viva enquanto o usuário
/// interage com a barra.
///
/// Tudo mira o CORPO da página (`.dq-office-page-content`): cabeçalho e
/// rodapé são projeções inertes com `user-select: none`, então uma seleção
/// ali nem chega a existir.
@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  /// Seleciona as primeiras letras do primeiro parágrafo do CORPO e devolve
  /// a geometria do que ficou selecionado + o estado da quickbar.
  Future<Map<String, dynamic>> selectInBody() =>
      app.page.evaluate<Map<String, dynamic>>('''async () => {
        const run = document.querySelector(
            '.dq-office-page-content .dq-office-run');
        const text = run.firstChild;
        const range = document.createRange();
        range.setStart(text, 0);
        range.setEnd(text, Math.min(8, text.length));
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);

        const rect = range.getBoundingClientRect();
        const canvas = document.querySelector('.dq-office-canvas');
        canvas.dispatchEvent(new MouseEvent('mouseup', {
          bubbles: true,
          clientX: rect.left + 4,
          clientY: rect.top + 4,
        }));
        await new Promise((resolve) => setTimeout(resolve, 250));

        const bar = document.querySelector('.dq-office-quickbar');
        const barRect = bar ? bar.getBoundingClientRect() : null;
        return {
          text: selection.toString(),
          selTop: rect.top,
          selLeft: rect.left,
          hasBar: !!bar,
          barTop: barRect ? barRect.top : null,
          barLeft: barRect ? barRect.left : null,
          barBottom: barRect ? barRect.bottom : null,
        };
      }''');

  test('a quickbar nasce acima da seleção e a preserva ao formatar', () async {
    await app.reload();
    final opened = await selectInBody();

    expect(opened['text'], isNotEmpty,
        reason: 'a seleção no corpo tem de existir');
    expect(opened['hasBar'], isTrue,
        reason: 'terminar a seleção abre a mini toolbar');
    expect(
        opened['barBottom'] as num, lessThanOrEqualTo(opened['selTop'] as num),
        reason: 'a barra fica ACIMA do texto, sem cobrir o que se formata');

    // Clicar no N da quickbar não pode tirar a seleção: é o teste que o
    // `preventDefault` no mousedown existe para passar.
    final result =
        await app.page.evaluate<Map<String, dynamic>>('''async () => {
      const bar = document.querySelector('.dq-office-quickbar');
      const bold = [...bar.querySelectorAll('.dq-office-btn')]
          .find((b) => (b.getAttribute('title') || '').startsWith('Negrito'));
      const before = window.getSelection().toString();
      const rect = bold.getBoundingClientRect();
      bold.dispatchEvent(new MouseEvent('mousedown', {
        bubbles: true,
        cancelable: true,
        clientX: rect.left + 2,
        clientY: rect.top + 2,
      }));
      const afterMouseDown = window.getSelection().toString();
      bold.click();
      await new Promise((resolve) => setTimeout(resolve, 200));
      const bolded = document.querySelectorAll(
          '.dq-office-page-content .dq-office-run-bold, '
          + '.dq-office-page-content b, .dq-office-page-content strong').length;
      const styleBold = [...document.querySelectorAll(
          '.dq-office-page-content .dq-office-run')]
          .filter((run) => /font-weight:\\s*(bold|[6-9]00)/
              .test(run.getAttribute('style') || '')).length;
      return {before, afterMouseDown, bolded, styleBold};
    }''');

    expect(result['afterMouseDown'], result['before'],
        reason: 'a seleção sobrevive ao clique no controle da barra');
    expect((result['bolded'] as num) + (result['styleBold'] as num),
        greaterThan(0),
        reason: 'o negrito da mini toolbar chega ao documento projetado');
  });

  test('o botão direito abre o menu do editor, não o do browser', () async {
    await app.reload();
    final menu = await app.page.evaluate<Map<String, dynamic>>('''async () => {
      const run = document.querySelector(
          '.dq-office-page-content .dq-office-run');
      const rect = run.getBoundingClientRect();
      const event = new MouseEvent('contextmenu', {
        bubbles: true,
        cancelable: true,
        clientX: rect.left + 20,
        clientY: rect.top + 5,
      });
      run.dispatchEvent(event);
      await new Promise((resolve) => setTimeout(resolve, 150));
      const items = [...document.querySelectorAll('.dq-office-menu-label')]
          .map((item) => item.textContent);
      const popup = document.querySelector('.dq-office-menu');
      const popupRect = popup
          ? popup.parentElement.getBoundingClientRect()
          : null;
      return {
        prevented: event.defaultPrevented,
        items,
        left: popupRect ? popupRect.left : null,
        top: popupRect ? popupRect.top : null,
        anchorX: rect.left + 20,
        anchorY: rect.top + 5,
      };
    }''');

    expect(menu['prevented'], isTrue,
        reason: 'sem preventDefault o menu do browser aparece por cima');
    expect((menu['items'] as List).cast<String>(),
        containsAll(['Recortar', 'Copiar', 'Colar']));
    // Abre ONDE se clicou (tolerância de alguns pixels pela borda do popup).
    expect((menu['left'] as num) - (menu['anchorX'] as num), closeTo(0, 6));
    expect((menu['top'] as num) - (menu['anchorY'] as num), closeTo(0, 6));

    // Esc fecha, como todo popup do editor.
    final closed = await app.page.evaluate<bool>('''async () => {
      document.dispatchEvent(
          new KeyboardEvent('keydown', {key: 'Escape', bubbles: true}));
      await new Promise((resolve) => setTimeout(resolve, 120));
      return !document.querySelector('.dq-office-menu');
    }''');
    expect(closed, isTrue);
  });

  test('o combobox mostra a fonte efetiva e aceita tamanho digitado', () async {
    await app.reload();
    final initial = await app.page.evaluate<Map<String, dynamic>>('''() => ({
      family: document.querySelector('.dq-office-font-family').value,
      size: document.querySelector('.dq-office-font-size').value,
    })''');
    // O documento do exemplo não tem formatação direta: o combobox mostra a
    // fonte com que o layout DESENHOU o texto, não um campo vazio.
    expect(initial['family'], isNotEmpty);
    expect(initial['size'], isNotEmpty);

    await selectInBody();
    final typed = await app.page.evaluate<Map<String, dynamic>>('''async () => {
      const input = document.querySelector('.dq-office-font-size');
      input.value = '10,5';
      input.dispatchEvent(new Event('change', {bubbles: true}));
      await new Promise((resolve) => setTimeout(resolve, 250));
      const sizes = [...document.querySelectorAll(
          '.dq-office-page-content .dq-office-run')]
          .map((run) => (run.getAttribute('style') || '')
              .match(/font-size:([0-9.]+)px/))
          .filter(Boolean)
          .map((match) => Number(match[1]));
      return {value: input.value, sizes};
    }''');

    expect(typed['value'], '10.5',
        reason: 'vírgula decimal é aceita e normalizada, como no Word pt-BR');
    // 10,5 pt = 14 px a 96 dpi: a projeção recebeu o tamanho digitado.
    expect((typed['sizes'] as List).cast<num>(), contains(closeTo(14, 0.3)));
  });
}
