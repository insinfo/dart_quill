/**
 * sali_page_setup.js
 *
 * Registra os formatos de configuracao de pagina do despacho no Quill 2:
 *
 * - `page-orientation` (data-page-orientation): 'portrait' | 'landscape'
 * - `page-margin`      (data-page-margin):      '1cm' | '1.5cm' | '2cm'
 *
 * Sao attributors de BLOCO gravados como atributos data-* na primeira linha
 * do documento, entao a configuracao viaja dentro do proprio Delta do
 * despacho (salvar, reabrir e assinar no backend usam o mesmo Delta — nao
 * precisa de campo novo no banco). Ausencia dos atributos = A4 retrato com
 * margens de 2cm (padrao institucional).
 *
 * O core le esses atributos em `sali_quill_pdf_defaults.dart`
 * (readSaliQuillPageSetup) para montar o PDFPageFormat, e o editor usa os
 * mesmos valores para posicionar a linha-guia "A4".
 *
 * Carregar depois de quill.js e antes de o editor ser criado.
 */
(function () {
  'use strict';

  if (!window.Quill) {
    return;
  }

  var parchment = Quill.import('parchment');

  var orientationAttributor = new parchment.Attributor(
    'page-orientation',
    'data-page-orientation',
    {
      scope: parchment.Scope.BLOCK,
      whitelist: ['portrait', 'landscape']
    }
  );

  // Sem whitelist: aceita qualquer valor "Ncm" (o editor oferece presets mas
  // o core valida/clampa a faixa). Assim as margens sao flexiveis sem exigir
  // uma lista fixa aqui, no editor e no core.
  var marginAttributor = new parchment.Attributor(
    'page-margin',
    'data-page-margin',
    {
      scope: parchment.Scope.BLOCK
    }
  );

  Quill.register(
    {
      'formats/page-orientation': orientationAttributor,
      'formats/page-margin': marginAttributor
    },
    true
  );
})();
