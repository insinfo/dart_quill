/// Bugs de INTERAÇÃO do chrome que só um browser real reproduz.
///
/// Cada teste aqui nasceu de uma captura de tela do editor com um DOCX de
/// produção aberto, e protege a correção correspondente:
///
/// * ícones da ribbon como blocos pretos — a fonte de ícones não representa
///   `fill-rule="evenodd"`; hoje cada ícone é o SVG como `mask-image`;
/// * menus saindo pela borda da janela — o overlay encaixa o popup na camada;
/// * um CLIQUE parado na divisa da coluna reescrevia a grade da tabela e
///   repaginava o documento; a guia tracejada ficava presa na tela;
/// * a quickbar de tabela nunca aparecia — o `selectionchange` trocava a
///   seleção de células por uma seleção de texto;
/// * zoom 200% dava barra de rolagem ao BODY e empurrava a ribbon para fora;
/// * o caret do rodapé em edição tinha a altura do rodapé inteiro.
///
/// Os testes com o corpus de produção (`resources/`) são pulados na CI, onde
/// os DOCX não existem; os demais rodam sobre o documento de demonstração.
@TestOn('vm')
@Timeout(Duration(minutes: 15))
library;

import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  Future<void> showTab(int index) async {
    await app.page.click('.dq-office-ribbon-tab:nth-child($index)');
  }

  /// Insere uma tabela 3 × 3 pela galeria da aba Inserir e devolve quantas
  /// células foram projetadas.
  Future<int> insertTable() async {
    await showTab(3);
    await app.page.click('button[title="Tabela"]');
    await app.page.waitForSelector('[title="3 × 3"]');
    await app.page.click('[title="3 × 3"]');
    await app.page.waitForSelector('.dq-office-table-cell');
    return app.page.evaluate<int>(
        '() => document.querySelectorAll(".dq-office-table-cell").length');
  }

  Future<Map<String, dynamic>?> rectOf(String selector, {int index = 0}) =>
      app.page.evaluate<Map<String, dynamic>?>('''() => {
        const el = document.querySelectorAll(${_js(selector)})[$index];
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return {left: r.left, top: r.top, right: r.right, bottom: r.bottom,
                width: r.width, height: r.height};
      }''');

  test('os ícones da ribbon são SVGs em máscara, com o desenho do ONLYOFFICE',
      () async {
    await showTab(2);
    final icon = await app.page.evaluate<Map<String, dynamic>>('''() => {
      const el = document.querySelector('.dq-icon-bold');
      const cs = getComputedStyle(el);
      const mask = cs.maskImage && cs.maskImage !== 'none'
          ? cs.maskImage : cs.webkitMaskImage;
      return {
        width: el.getBoundingClientRect().width,
        height: el.getBoundingClientRect().height,
        mask: (mask || '').slice(0, 40),
        fontIcons: [...document.fonts].some(f => f.family.includes('dq-office')),
      };
    }''');
    expect(icon['mask'], startsWith('url("data:image/svg+xml'),
        reason: 'o ícone é o SVG oficial, não um glifo de fonte');
    expect(icon['width'], closeTo(20, 1));
    expect(icon['height'], closeTo(20, 1));
    expect(icon['fontIcons'], isFalse,
        reason: 'a fonte de ícones (que fechava os furos do evenodd) sumiu');
    await app.screenshot('chrome-bugs-ribbon-icons');
  });

  test('o menu de contexto perto da borda fica INTEIRO na janela', () async {
    await showTab(2);
    final canvas = (await rectOf('.dq-office-canvas'))!;
    final x = (canvas['right'] as num) - 12;
    final y = (canvas['bottom'] as num) - 12;
    // O clique direito cai na área cinza ao lado da página: o menu abre do
    // mesmo jeito, e é justamente perto da borda que ele saía da tela.
    await app.page.mouse.click(Point(x.toDouble(), y.toDouble()),
        button: MouseButton.right);
    await app.page.waitForSelector('.dq-office-menu');
    final menu = (await rectOf('.dq-office-popup'))!;
    final viewport = await app.page.evaluate<Map<String, dynamic>>(
        '() => ({w: innerWidth, h: innerHeight})');
    expect(menu['right'], lessThanOrEqualTo(viewport['w']));
    expect(menu['bottom'], lessThanOrEqualTo(viewport['h']));
    expect(menu['left'], greaterThanOrEqualTo(0));
    expect(menu['top'], greaterThanOrEqualTo(0));
    await app.screenshot('chrome-bugs-context-menu-clamped');
    await app.page.keyboard.press(Key.escape);
  });

  test(
      'arrastar entre células mantém a seleção RETANGULAR e abre a quickbar '
      'de tabela; a âncora seleciona a tabela inteira', () async {
    final cells = await insertTable();
    expect(cells, 9);

    final first = (await rectOf('.dq-office-table-cell', index: 0))!;
    final last = (await rectOf('.dq-office-table-cell', index: 4))!;
    final from = Point(
      (first['left'] as num).toDouble() + 12,
      (first['top'] as num).toDouble() + 6,
    );
    final to = Point(
      (last['left'] as num).toDouble() + 12,
      (last['top'] as num).toDouble() + 6,
    );
    await app.page.mouse.move(from);
    await app.page.mouse.down();
    await app.page.mouse.move(
        Point(from.x + 20, from.y + 2), steps: 4);
    await app.page.mouse.move(to, steps: 8);
    await app.page.mouse.up();
    await app.page.waitForSelector('.dq-office-quickbar');

    final state = await app.page.evaluate<Map<String, dynamic>>('''() => ({
      marks: document.querySelectorAll('.dq-office-cellmark').length,
      insert: !!document.querySelector(
          '.dq-office-quickbar button[title="Inserir linhas e colunas"]'),
      merge: !!document.querySelector(
          '.dq-office-quickbar button[title="Mesclar células"]'),
    })''');
    expect(state['marks'], 4, reason: 'retângulo 2×2 realçado');
    expect(state['insert'], isTrue, reason: 'menu Inserir da mini-barra');
    expect(state['merge'], isTrue);
    await app.screenshot('chrome-bugs-table-quickbar');

    // A âncora ⊞: tabela inteira + a mesma barra.
    await app.page.click('.dq-office-tableanchor');
    await app.page.waitForFunction(
        '() => document.querySelectorAll(".dq-office-cellmark").length === 9');
    expect(await app.page.evaluate<bool>(
        '() => !!document.querySelector(".dq-office-quickbar")'), isTrue);
    await app.screenshot('chrome-bugs-table-anchor-selected');
    await app.page.keyboard.press(Key.escape);
  });

  test('um clique PARADO na divisa da coluna não mexe no documento', () async {
    await app.reload();
    await insertTable();
    await app.page.waitForFunction(
        '() => document.querySelector(".dq-office-app")'
        '.getAttribute("data-dq-office-dirty") === "true"');
    // Consome o "sujo" da inserção: o que interessa é o gesto seguinte.
    await app.page.evaluate<void>(
        '() => document.querySelector(".dq-office-app")'
        '.setAttribute("data-dq-office-dirty", "false")');
    final cell = (await rectOf('.dq-office-table-cell', index: 0))!;
    final widthBefore = cell['width'];
    final point = Point(
      (cell['right'] as num).toDouble() - 1,
      (cell['top'] as num).toDouble() + 8,
    );
    await app.page.mouse.move(point);
    final hoverClass = await app.page.evaluate<bool>(
        '() => document.querySelector(".dq-office-app")'
        '.classList.contains("dq-office-app-colresize")');
    expect(hoverClass, isTrue, reason: 'cursor col-resize sobre a divisa');
    await app.page.mouse.down();
    await app.page.mouse.up();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final after = await app.page.evaluate<Map<String, dynamic>>('''() => ({
      dirty: document.querySelector('.dq-office-app')
          .getAttribute('data-dq-office-dirty'),
      guide: document.querySelectorAll('.dq-office-colguide').length,
      width: document.querySelector('.dq-office-table-cell')
          .getBoundingClientRect().width,
    })''');
    expect(after['dirty'], 'false',
        reason: 'clicar sem arrastar não é uma transação');
    expect(after['guide'], 0, reason: 'nenhuma guia presa na tela');
    expect(after['width'], closeTo(widthBefore as num, 0.5));

    // Arrastar DE VERDADE ainda redimensiona.
    await app.page.mouse.move(point);
    await app.page.mouse.down();
    await app.page.mouse.move(Point(point.x + 40, point.y), steps: 6);
    expect(
        await app.page.evaluate<int>(
            '() => document.querySelectorAll(".dq-office-colguide").length'),
        1,
        reason: 'a guia aparece assim que o ponteiro se move');
    await app.page.mouse.up();
    await app.page.waitForFunction(
        '() => document.querySelector(".dq-office-app")'
        '.getAttribute("data-dq-office-dirty") === "true"');
    expect(
        await app.page.evaluate<int>(
            '() => document.querySelectorAll(".dq-office-colguide").length'),
        0);
  });

  test('zoom 200% não dá barra de rolagem ao BODY', () async {
    await app.reload();
    await app.page.evaluate<void>('''() => {
      const slider = document.querySelector('.dq-office-zoom-slider');
      slider.value = '200';
      slider.dispatchEvent(new Event('input', {bubbles: true}));
      slider.dispatchEvent(new Event('change', {bubbles: true}));
    }''');
    await app.page.waitForFunction(
        '() => document.querySelector(".dq-office-zoom-label")'
        '.textContent.includes("200")');
    // Rola o canvas para o meio do documento: era aqui que a réplica dos
    // adornos além da borda estendia o documento hospedeiro.
    await app.page.evaluate<void>('''() => {
      const canvas = document.querySelector('.dq-office-canvas');
      canvas.scrollTop = canvas.scrollHeight / 2;
    }''');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final scroll = await app.page.evaluate<Map<String, dynamic>>('''() => ({
      bodyScrollHeight: document.documentElement.scrollHeight,
      innerHeight: innerHeight,
      bodyScrollTop: document.documentElement.scrollTop || document.body.scrollTop,
      ribbonTop: document.querySelector('.dq-office-ribbon')
          .getBoundingClientRect().top,
    })''');
    expect(scroll['bodyScrollHeight'], lessThanOrEqualTo(scroll['innerHeight']),
        reason: 'o único scroll é o do canvas');
    expect(scroll['bodyScrollTop'], 0);
    expect(scroll['ribbonTop'], greaterThanOrEqualTo(0),
        reason: 'a ribbon continua visível');
    await app.screenshot('chrome-bugs-zoom-200');
  });

  group('corpus de produção (TR)', () {
    final corpus = officeTrCorpus();

    test('rodapé em edição: caret com a altura da LINHA, não do rodapé',
        () async {
      if (skipWithoutCorpus(corpus, 'TR')) return;
      await app.reload();
      await app.importDocx(corpus,
          artifactName: 'chrome-bugs-tr', captureScreenshots: false);
      // O rodapé da primeira página nasce abaixo da janela: rola até ele antes
      // de medir, senão o duplo clique cai no corpo.
      await app.page.evaluate<void>('() => document.querySelector(".dq-office-footer")'
          '.scrollIntoView({block: "center"})');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final footer = (await rectOf('.dq-office-footer'))!;
      await app.page.mouse.click(
        Point(
          (footer['left'] as num).toDouble() + (footer['width'] as num) / 2,
          (footer['top'] as num).toDouble() + 10,
        ),
        clickCount: 2,
      );
      await app.page.waitForSelector('.dq-office-hf-surface');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final caret = await app.page.evaluate<Map<String, dynamic>>('''() => {
        const sel = getSelection();
        if (!sel.rangeCount) return {caret: null};
        const rect = sel.getRangeAt(0).getBoundingClientRect();
        const lines = [...document.querySelectorAll(
            '.dq-office-hf-surface .dq-office-line')]
            .map(l => l.getBoundingClientRect().height);
        const surface = document.querySelector('.dq-office-hf-surface')
            .getBoundingClientRect().height;
        return {caret: rect.height, tallestLine: Math.max(...lines),
                surface};
      }''');
      expect(caret['caret'], isNotNull, reason: 'há um caret no rodapé');
      expect(caret['caret'],
          lessThanOrEqualTo((caret['tallestLine'] as num) + 2),
          reason: 'o caret tem a altura da linha em que está');
      expect(caret['caret'], lessThan((caret['surface'] as num) * 0.8),
          reason: 'e não a da faixa inteira do rodapé');
      await app.screenshot('chrome-bugs-footer-caret');
    });

    test('imagem do cabeçalho: menu de disposição do texto legível e na tela',
        () async {
      if (skipWithoutCorpus(corpus, 'TR')) return;
      // A sessão de rodapé continua aberta do teste anterior: o brasão está
      // no cabeçalho, então entramos nele — depois de trazê-lo de volta à
      // janela, que ficou rolada até o rodapé.
      await app.page.evaluate<void>(
          '() => document.querySelector(".dq-office-header")'
          '.scrollIntoView({block: "center"})');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final header = (await rectOf('.dq-office-header'))!;
      await app.page.mouse.click(
        Point(
          (header['left'] as num).toDouble() + 30,
          (header['top'] as num).toDouble() + (header['height'] as num) / 2,
        ),
        clickCount: 2,
      );
      await app.page.waitForSelector(
          '.dq-office-hf-surface[data-dq-office-region="header"]');
      final image = (await rectOf('.dq-office-hf-surface .dq-office-image'))!;
      await app.page.mouse.click(Point(
        (image['left'] as num).toDouble() + (image['width'] as num) / 2,
        (image['top'] as num).toDouble() + (image['height'] as num) / 2,
      ));
      await app.page.waitForSelector('.dq-office-objanchor');
      await app.page.click('.dq-office-objanchor');
      await app.page.waitForSelector('.dq-office-layout-options');
      final menu = await app.page.evaluate<Map<String, dynamic>>('''() => {
        const popup = document.querySelector('.dq-office-popup');
        const r = popup.getBoundingClientRect();
        return {
          right: r.right, bottom: r.bottom, width: r.width,
          items: document.querySelectorAll('.dq-office-menu-item').length,
          descriptions: document.querySelectorAll(
              '.dq-office-menu-description').length,
          checked: document.querySelector(
              '.dq-office-menu-item-checked .dq-office-menu-label').textContent,
          innerWidth,
          innerHeight,
        };
      }''');
      expect(menu['items'], 7);
      expect(menu['checked'], 'Em linha com o texto');
      expect(menu['descriptions'], 2,
          reason: 'o motivo aparece uma vez, não em cada item');
      expect(menu['width'], lessThan(340));
      expect(menu['right'], lessThanOrEqualTo(menu['innerWidth']));
      expect(menu['bottom'], lessThanOrEqualTo(menu['innerHeight']));
      await app.screenshot('chrome-bugs-header-image-layout-options');
      await app.page.keyboard.press(Key.escape);
    });
  });
}

String _js(String value) => '"${value.replaceAll('"', '\\"')}"';
