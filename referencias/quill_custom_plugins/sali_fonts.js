/**
 * sali_fonts.js
 *
 * Habilita o formato `font` no Quill 2 com a politica de familias do SALI:
 * inter (padrao do sistema), arial e calibri.
 *
 * - Attributor de ESTILO (`style="font-family: ..."`), nao de classe, para o
 *   HTML salvo do despacho renderizar igual fora do editor.
 * - `value()` normaliza o CSS recebido (ex.: `"Arial", sans-serif` colado do
 *   Word) para o token canonico ('arial'), entao colar texto em Arial ou
 *   Calibri preserva a fonte automaticamente; familias fora da whitelist sao
 *   descartadas e caem na fonte padrao (Inter).
 * - A mesma whitelist/normalizacao existe no core
 *   (`quill_pdf_sanitizer.dart` / `sali_pdf_font_families.dart`), que carrega
 *   os TTFs sob demanda na conversao para PDF.
 *
 * Carregar depois de quill.js e antes de o editor ser criado.
 */
(function () {
  'use strict';

  if (!window.Quill) {
    return;
  }

  var WHITELIST = ['inter', 'arial', 'calibri'];
  var ALIASES = {
    arimo: 'arial',
    helvetica: 'arial',
    'arial mt': 'arial',
    'calibri light': 'calibri'
  };

  function normalizeFamily(raw) {
    if (!raw) {
      return '';
    }
    var first = String(raw)
      .split(',')[0]
      .replace(/["']/g, '')
      .trim()
      .toLowerCase();
    return ALIASES[first] || first;
  }

  var parchment = Quill.import('parchment');

  class SaliFontAttributor extends parchment.StyleAttributor {
    value(node) {
      var normalized = normalizeFamily(node.style.fontFamily);
      // O whitelist do parchment e aplicado via canAdd dentro do value();
      // sem esta checagem qualquer familia colada passaria (ex.: Times).
      return this.canAdd(node, normalized) ? normalized : '';
    }
  }

  var saliFontAttributor = new SaliFontAttributor('font', 'font-family', {
    scope: parchment.Scope.INLINE,
    whitelist: WHITELIST
  });

  Quill.register({ 'formats/font': saliFontAttributor }, true);
})();
