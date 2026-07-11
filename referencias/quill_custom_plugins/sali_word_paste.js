/**
 * sali_word_paste.js
 *
 * Normaliza HTML colado do Microsoft Word antes de o Quill converte-lo em
 * Delta, corrigindo perdas de formatacao do normalizador nativo do Quill
 * 2.0.3 (src/modules/normalizeExternalHTML/normalizers/msWord.ts):
 *
 * 1. Numeracao literal preservada: o normalizador nativo converte TODO
 *    paragrafo `mso-list` em `<li data-list="ordered|bullet">` e descarta o
 *    marcador literal (span `mso-list:Ignore`). Como o Quill reinicia a
 *    contagem por lista, titulos numerados isolados ("2. Descricao...") e
 *    numeracoes de celulas de tabela viravam todos "1.". Aqui, itens
 *    isolados (ou grupos que nao comecam em "1.") mantem o texto do
 *    marcador ("2.", "8.", "a)") como texto normal do paragrafo.
 * 2. Bullets detectados pelo texto do marcador: o nativo depende do regex
 *    `@list lN:levelM {mso-level-number-format:bullet}` no <style>, que
 *    falha com frequencia e transforma bullets em listas numeradas. Aqui, o
 *    tipo vem do proprio marcador (ex.: "1." => ordered; "·"/"o"/"-" =>
 *    bullet).
 * 3. Negrito definido por classe: o Word poe `font-weight:bold` em classes
 *    do <style> (ex.: `p.Nivel01 {...font-weight:bold}`). O DOMParser nao
 *    aplica CSS, entao o negrito de titulos se perdia. Aqui as classes bold
 *    sao detectadas no <style> e o conteudo do paragrafo e envolvido em <b>.
 * 4. Espacamento entre paragrafos: o Quill nao tem margem de paragrafo, entao
 *    o espaco-depois do Word ("space after") sumia e o texto colava tudo.
 *    Paragrafos cujo margin-bottom efetivo (inline ou da classe no <style>)
 *    e >= 4pt ganham um paragrafo vazio (<p><br></p>) logo apos — a unica
 *    representacao de espacamento que sobrevive no Delta e no PDF.
 *
 * Depuracao / fixtures de teste:
 * - O ultimo HTML colado fica em `window.SALI_LAST_PASTE_HTML` e a versao
 *   normalizada em `window.SALI_LAST_PASTE_HTML_NORMALIZED`.
 *   No DevTools: copy(SALI_LAST_PASTE_HTML) e cole num arquivo .html para
 *   virar fixture de teste (mesmo fluxo do SALI_LAST_PDF_ERROR_DELTA).
 *
 * Carregar DEPOIS de quill.js e register_table_better.js: o patch e feito no
 * prototype do modulo 'modules/clipboard' registrado no momento do load
 * (o TableClipboard do quill-table-better herda `convert` do Clipboard base,
 * entao o patch cobre os dois fluxos).
 */
(function () {
  'use strict';

  if (!window.Quill) {
    return;
  }

  var MARKER_STYLE_RE = /mso-list\s*:[^;"']*\bignore\b/i;
  var LIST_STYLE_RE = /\bmso-list\s*:/i;
  var LIST_ID_RE = /\bmso-list\s*:[^;"']*\bl(\d+)\b/i;
  var LIST_LEVEL_RE = /\bmso-list\s*:[^;"']*\blevel(\d+)\b/i;
  // "1." "12)" "a." "B)" "iv." "(3)" etc.
  var ORDERED_MARKER_RE = /^\(?[0-9a-zA-Z]{1,4}[.)]$/;
  // Primeiro item de uma sequencia que o Quill consegue numerar sozinho.
  var FIRST_MARKER_RE = /^\(?(1|a|A|i|I)[.)]$/;

  function looksLikeWordHtml(html) {
    return (
      html.indexOf('urn:schemas-microsoft-com:office:word') !== -1 ||
      html.indexOf('mso-list') !== -1 ||
      html.indexOf('class="Mso') !== -1 ||
      html.indexOf('class=Mso') !== -1
    );
  }

  function styleOf(el) {
    return el.getAttribute && (el.getAttribute('style') || '');
  }

  /**
   * Classes que o <style> do Word define com font-weight:bold
   * (ex.: `p.Nivel01, li.Nivel01, div.Nivel01 {...font-weight:bold;}`).
   */
  function collectBoldClasses(styleText) {
    var classes = {};
    var ruleRe = /([^{}]+)\{([^{}]*)\}/g;
    var match;
    while ((match = ruleRe.exec(styleText)) !== null) {
      var body = match[2];
      if (!/font-weight\s*:\s*bold/i.test(body)) {
        continue;
      }
      var selectors = match[1].split(',');
      for (var i = 0; i < selectors.length; i++) {
        var sel = /^\s*(?:p|li|div|h[1-6])\.([\w-]+)\s*$/.exec(selectors[i]);
        if (sel) {
          classes[sel[1]] = true;
        }
      }
    }
    return classes;
  }

  function findMarkerElement(item) {
    var candidates = item.querySelectorAll('[style]');
    for (var i = 0; i < candidates.length; i++) {
      if (MARKER_STYLE_RE.test(styleOf(candidates[i]))) {
        return candidates[i];
      }
    }
    return null;
  }

  function classifyMarker(markerText) {
    if (!markerText) {
      return 'ordered';
    }
    return ORDERED_MARKER_RE.test(markerText) ? 'ordered' : 'bullet';
  }

  function removeMsoListStyle(el) {
    var style = styleOf(el);
    if (!style || !LIST_STYLE_RE.test(style)) {
      return;
    }
    var cleaned = style.replace(/(^|;)\s*mso-list\s*:[^;]*/gi, '$1');
    el.setAttribute('style', cleaned);
  }

  function parseListItems(doc) {
    var all = doc.querySelectorAll('[style*="mso-list"]');
    var items = [];
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var style = styleOf(el);
      if (MARKER_STYLE_RE.test(style)) {
        continue; // marcador, tratado junto do item pai
      }
      var idMatch = LIST_ID_RE.exec(style);
      if (!idMatch) {
        continue;
      }
      var levelMatch = LIST_LEVEL_RE.exec(style);
      var markerEl = findMarkerElement(el);
      var markerText = markerEl
        ? markerEl.textContent.replace(/[ \s]+/g, ' ').trim()
        : '';
      if (markerEl && markerEl.parentNode) {
        markerEl.parentNode.removeChild(markerEl);
      }
      items.push({
        el: el,
        id: Number(idMatch[1]),
        level: levelMatch ? Number(levelMatch[1]) : 1,
        markerText: markerText,
        type: classifyMarker(markerText)
      });
    }
    return items;
  }

  /** Agrupa itens contiguos (irmaos consecutivos) com o mesmo id de lista. */
  function groupItems(items) {
    var groups = [];
    var current = null;
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var previous = current && current[current.length - 1];
      if (
        previous &&
        previous.id === item.id &&
        previous.el.nextElementSibling === item.el
      ) {
        current.push(item);
      } else {
        current = [item];
        groups.push(current);
      }
    }
    return groups;
  }

  function groupBecomesQlList(group) {
    if (group.length < 2) {
      return false;
    }
    var allBullet = true;
    var allOrdered = true;
    for (var i = 0; i < group.length; i++) {
      if (group[i].type === 'bullet') {
        allOrdered = false;
      } else {
        allBullet = false;
      }
    }
    if (allBullet) {
      return true;
    }
    // Lista numerada: so deixa o Quill numerar quando a sequencia comeca do
    // inicio ("1.", "a.", "i."); continuacoes ("8.") mantem o numero literal.
    return allOrdered && FIRST_MARKER_RE.test(group[0].markerText);
  }

  function convertGroupToQlList(doc, group) {
    var ul = doc.createElement('ul');
    for (var i = 0; i < group.length; i++) {
      var item = group[i];
      var li = doc.createElement('li');
      li.setAttribute('data-list', item.type);
      if (item.level > 1) {
        li.setAttribute('class', 'ql-indent-' + (item.level - 1));
      }
      li.innerHTML = item.el.innerHTML;
      ul.appendChild(li);
    }
    var first = group[0].el;
    first.parentNode.replaceChild(ul, first);
    for (var j = 1; j < group.length; j++) {
      var el = group[j].el;
      if (el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }
  }

  function keepGroupAsLiteralParagraphs(doc, group) {
    for (var i = 0; i < group.length; i++) {
      var item = group[i];
      if (item.markerText) {
        item.el.insertBefore(
          doc.createTextNode(item.markerText + ' '),
          item.el.firstChild
        );
      }
      // Sem isso o normalizador nativo do Quill reprocessa o paragrafo e
      // descarta o numero literal que acabamos de preservar.
      removeMsoListStyle(item.el);
    }
  }

  var MIN_SPACING_PT = 4;

  function marginValueToPt(raw) {
    var match = /^(-?[\d.]+)\s*(pt|cm|in|px|mm)?$/i.exec(raw.trim());
    if (!match) {
      return 0;
    }
    var value = parseFloat(match[1]);
    if (isNaN(value)) {
      return 0;
    }
    switch ((match[2] || 'pt').toLowerCase()) {
      case 'cm':
        return value * 28.35;
      case 'mm':
        return value * 2.835;
      case 'in':
        return value * 72;
      case 'px':
        return value * 0.75;
      default:
        return value;
    }
  }

  /** margin-bottom (em pt) declarado num corpo de regra/atributo style. */
  function marginBottomFromCss(cssText) {
    if (!cssText) {
      return null;
    }
    var direct = /(?:^|;)\s*margin-bottom\s*:\s*([^;}"']+)/i.exec(cssText);
    if (direct) {
      return marginValueToPt(direct[1]);
    }
    var shorthand = /(?:^|;)\s*margin\s*:\s*([^;}"']+)/i.exec(cssText);
    if (shorthand) {
      var parts = shorthand[1].trim().split(/\s+/);
      // margin: [top] [right] [bottom] [left] (1 a 4 valores)
      var bottom =
        parts.length >= 3 ? parts[2] : parts.length === 2 ? parts[0] : parts[0];
      return marginValueToPt(bottom);
    }
    return null;
  }

  /** Classes de paragrafo do <style> do Word => margin-bottom em pt. */
  function collectClassMarginBottom(styleText) {
    var margins = {};
    var ruleRe = /([^{}]+)\{([^{}]*)\}/g;
    var match;
    while ((match = ruleRe.exec(styleText)) !== null) {
      var value = marginBottomFromCss(match[2]);
      if (value === null) {
        continue;
      }
      var selectors = match[1].split(',');
      for (var i = 0; i < selectors.length; i++) {
        var sel = /^\s*(?:p|li|div|h[1-6])\.([\w-]+)\s*$/.exec(selectors[i]);
        if (sel) {
          margins[sel[1]] = value;
        }
      }
    }
    return margins;
  }

  function isBlankBlock(el) {
    if (!el) {
      return false;
    }
    var text = (el.textContent || '').replace(/[\s ]+/g, '');
    return text === '';
  }

  /**
   * Insere <p><br></p> apos paragrafos com espaco-depois relevante no Word,
   * para o espacamento sobreviver no modelo do Quill (editor e PDF).
   */
  function applyParagraphSpacing(doc, classMargins) {
    if (!doc.body) {
      return;
    }
    var paragraphs = doc.body.querySelectorAll('p');
    for (var i = 0; i < paragraphs.length; i++) {
      var el = paragraphs[i];
      if (isBlankBlock(el)) {
        continue;
      }
      if (el.closest && el.closest('td, th')) {
        continue; // nao inflar linhas de tabela com espacadores
      }
      if (!el.nextElementSibling) {
        continue; // ultimo bloco do pai
      }
      if (
        isBlankBlock(el.nextElementSibling) &&
        el.nextElementSibling.tagName === 'P'
      ) {
        continue; // o Word ja colocou um paragrafo vazio de espacamento
      }

      var margin = marginBottomFromCss(styleOf(el));
      if (margin === null) {
        var classAttr = el.getAttribute('class');
        var names = classAttr ? classAttr.split(/\s+/) : [];
        for (var j = 0; j < names.length; j++) {
          if (classMargins[names[j]] !== undefined) {
            margin = classMargins[names[j]];
            break;
          }
        }
      }
      if (margin === null || margin < MIN_SPACING_PT) {
        continue;
      }

      var spacer = doc.createElement('p');
      spacer.appendChild(doc.createElement('br'));
      el.parentNode.insertBefore(spacer, el.nextSibling);
    }
  }

  function applyBoldClasses(doc, boldClasses) {
    var blocks = doc.body ? doc.body.querySelectorAll('p, li, div') : [];
    for (var i = 0; i < blocks.length; i++) {
      var el = blocks[i];
      var classAttr = el.getAttribute('class');
      if (!classAttr) {
        continue;
      }
      var names = classAttr.split(/\s+/);
      var isBold = false;
      for (var j = 0; j < names.length; j++) {
        if (boldClasses[names[j]]) {
          isBold = true;
          break;
        }
      }
      if (!isBold || !el.textContent || !el.textContent.trim()) {
        continue;
      }
      if (el.querySelector('b, strong')) {
        continue; // ja tem negrito explicito
      }
      el.innerHTML = '<b>' + el.innerHTML + '</b>';
    }
  }

  function normalizeWordHtml(html) {
    var doc = new DOMParser().parseFromString(html, 'text/html');
    var styleTags = doc.querySelectorAll('style');
    var styleText = '';
    for (var i = 0; i < styleTags.length; i++) {
      styleText += styleTags[i].textContent + '\n';
    }

    var items = parseListItems(doc);
    var groups = groupItems(items);
    for (var g = 0; g < groups.length; g++) {
      if (groupBecomesQlList(groups[g])) {
        convertGroupToQlList(doc, groups[g]);
      } else {
        keepGroupAsLiteralParagraphs(doc, groups[g]);
      }
    }

    applyBoldClasses(doc, collectBoldClasses(styleText));
    applyParagraphSpacing(doc, collectClassMarginBottom(styleText));

    return doc.documentElement.outerHTML;
  }

  var ClipboardModule = Quill.import('modules/clipboard');
  if (!ClipboardModule || !ClipboardModule.prototype) {
    return;
  }
  var originalConvert = ClipboardModule.prototype.convert;
  ClipboardModule.prototype.convert = function (payload, formats) {
    var normalizedPayload = payload || {};
    try {
      if (
        typeof normalizedPayload.html === 'string' &&
        normalizedPayload.html
      ) {
        window.SALI_LAST_PASTE_HTML = normalizedPayload.html;
        if (looksLikeWordHtml(normalizedPayload.html)) {
          var normalized = normalizeWordHtml(normalizedPayload.html);
          window.SALI_LAST_PASTE_HTML_NORMALIZED = normalized;
          normalizedPayload = Object.assign({}, normalizedPayload, {
            html: normalized
          });
        }
      }
    } catch (error) {
      if (window.console && console.error) {
        console.error(
          '[sali_word_paste] Falha ao normalizar HTML do Word; usando o HTML original.',
          error
        );
      }
    }
    return originalConvert.call(this, normalizedPayload, formats);
  };
})();
