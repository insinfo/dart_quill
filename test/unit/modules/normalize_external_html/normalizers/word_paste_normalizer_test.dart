/// W3/W4/W6/W7/W10 — o normalizador estendido de colar do Word
/// (`normalizeWordPaste`, porte do `sali_word_paste.js` em produção).
///
/// A fixture `word_paste_sample.html` reproduz a estrutura real que o Word
/// põe no clipboard: `mso-list` com marcador em `mso-list:Ignore`, classes
/// de estilo no `<style>` (negrito e margens) e namespace `xmlns:w`.
import 'dart:io';

import 'package:test/test.dart';

import 'package:dart_quill/src/modules/normalize_external_html/index.dart';
import 'package:dart_quill/src/modules/normalize_external_html/normalizers/word_paste.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../../support/fake_dom.dart';

void main() {
  FakeDomDocument load() => FakeDomDocument.fromHtml(
      File('test/assets/html/word_paste_sample.html').readAsStringSync());

  group('normalizeWordPaste — fixture real do Word', () {
    late FakeDomDocument doc;
    late List<DomElement> blocks;

    setUp(() {
      doc = load();
      normalizeWordPaste(doc);
      blocks = doc.body.childNodes.whereType<DomElement>().toList();
    });

    test('título numerado isolado mantém o número literal (W3)', () {
      final title = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('DESCRIÇÃO'));
      expect(title.tagName, 'P',
          reason: 'item isolado não pode virar <li> renumerado');
      expect((title.textContent ?? '').trim(), startsWith('2.'),
          reason: 'o marcador literal "2." tem de sobreviver');
      expect(_styleOf(title), isNot(contains('mso-list')),
          reason: 'sem limpar o mso-list o normalizador nativo reprocessa');
    });

    test('bullets são detectados pelo marcador, não pelo @list (W3)', () {
      final ul = blocks.firstWhere((el) =>
          el.tagName == 'UL' &&
          (el.textContent ?? '').contains('Primeiro bullet'));
      final items = ul.childNodes.whereType<DomElement>().toList();
      expect(items, hasLength(2));
      for (final li in items) {
        expect(li.getAttribute('data-list'), 'bullet');
      }
    });

    test('sequência que começa em "1." vira lista do Quill (W3)', () {
      final ul = blocks.firstWhere((el) =>
          el.tagName == 'UL' &&
          (el.textContent ?? '').contains('Item numerado um'));
      final items = ul.childNodes.whereType<DomElement>().toList();
      expect(items, hasLength(2));
      for (final li in items) {
        expect(li.getAttribute('data-list'), 'ordered');
      }
    });

    test('continuação ("8.", "9.") mantém os números literais (W3)', () {
      final eight = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('Continuação oito'));
      expect(eight.tagName, 'P');
      expect((eight.textContent ?? '').trim(), startsWith('8.'));
      final nine = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('Continuação nove'));
      expect((nine.textContent ?? '').trim(), startsWith('9.'));
    });

    test('classe bold do <style> vira <b> (W6)', () {
      final title = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('DESCRIÇÃO'));
      expect(title.querySelector('b'), isNotNull,
          reason: 'p.Nivel01 {font-weight:bold} tem de virar <b>');
    });

    test('margin-bottom da classe vira parágrafo em branco (W7)', () {
      final body = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('espaço-depois'));
      final next = _nextElement(body);
      expect(next, isNotNull);
      expect(next!.tagName, 'P');
      expect((next.textContent ?? '').trim(), isEmpty,
          reason: 'p.Corpo {margin-bottom:8pt} pede o espaçador');
    });

    test('parágrafo sem espaçamento não ganha espaçador (W7)', () {
      final plain = blocks.firstWhere(
          (el) => (el.textContent ?? '').contains('Parágrafo comum'));
      final next = _nextElement(plain);
      // O próximo é a UL dos bullets, não um <p> vazio.
      expect(next?.tagName, 'UL');
    });
  });

  test('gate largo: variante Outlook sem xmlns:w é normalizada (W4)', () {
    const html = '''
      <html><body>
        <p class="MsoListParagraph" style="mso-list:l0 level1 lfo1">
          <span style="mso-list:Ignore">·&nbsp;</span>alpha</p>
        <p class="MsoListParagraph" style="mso-list:l0 level1 lfo1">
          <span style="mso-list:Ignore">·&nbsp;</span>beta</p>
      </body></html>
    ''';
    final doc = FakeDomDocument.fromHtml(html);
    normalizeWordPaste(doc);
    final ul = doc.body.childNodes
        .whereType<DomElement>()
        .firstWhere((el) => el.tagName == 'UL');
    final items = ul.childNodes.whereType<DomElement>().toList();
    expect(items, hasLength(2));
    expect(items.first.getAttribute('data-list'), 'bullet');
  });

  test('HTML que não é do Word passa intacto (W4)', () {
    const html = '<html><body><p style="margin-bottom:20pt">solto</p>'
        '<p>seguinte</p></body></html>';
    final doc = FakeDomDocument.fromHtml(html);
    normalizeWordPaste(doc);
    final blocks = doc.body.childNodes.whereType<DomElement>().toList();
    expect(blocks, hasLength(2),
        reason: 'sem cara de Word, nada de espaçadores nem listas');
  });

  test('um normalizador que lança não derruba o paste (W9)', () {
    final pipeline = NormalizeExternalHTML(normalizers: [
      (doc) => throw StateError('boom'),
      normalizeWordPaste,
    ]);
    final doc = load();
    expect(() => pipeline.normalize(doc), returnsNormally);
    // O segundo normalizador ainda rodou.
    expect(
        doc.body.childNodes
            .whereType<DomElement>()
            .any((el) => el.tagName == 'UL'),
        isTrue);
  });
}

String _styleOf(DomElement el) => el.getAttribute('style') ?? '';

DomElement? _nextElement(DomElement element) {
  DomNode? current = element.nextSibling;
  while (current != null) {
    if (current is DomElement) return current;
    current = current.nextSibling;
  }
  return null;
}
