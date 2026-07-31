@TestOn('vm')
library;

/// O parser de declarações CSS inline que substituiu o package `csslib`.
///
/// Os casos que importam são os que um "split(';')" ingênuo erra: `rgb(1, 2,
/// 3)` tem vírgulas, `url(...)` pode ter `;`, e valores entre aspas podem ter
/// os dois. Errar aqui não dá erro — dá um estilo silenciosamente truncado.
import 'package:dart_quill/src/converters/html/utils/css_util.dart';
import 'package:test/test.dart';

void main() {
  group('parseInlineStyleToMap', () {
    test('pares simples', () {
      expect(parseInlineStyleToMap('width:120px; color:red'),
          {'width': '120px', 'color': 'red'});
    });

    test('espaços e maiúsculas na propriedade são normalizados', () {
      expect(parseInlineStyleToMap('  Text-Align :  Center  '),
          {'text-align': 'Center'});
    });

    test('ponto e vírgula final não cria declaração vazia', () {
      expect(parseInlineStyleToMap('color:red;'), {'color': 'red'});
    });

    test('string vazia devolve mapa vazio', () {
      expect(parseInlineStyleToMap('   '), isEmpty);
    });

    test('declaração sem valor é descartada', () {
      expect(parseInlineStyleToMap('color:; width:10px'), {'width': '10px'});
    });

    test('declaração sem dois-pontos é descartada', () {
      expect(parseInlineStyleToMap('lixo; width:10px'), {'width': '10px'});
    });

    test('vírgulas dentro de parênteses não quebram o valor', () {
      expect(parseInlineStyleToMap('background-color: rgb(1, 2, 3); width:1px'),
          {'background-color': 'rgb(1, 2, 3)', 'width': '1px'});
    });

    test('ponto e vírgula dentro de parênteses não separa declarações', () {
      final parsed = parseInlineStyleToMap("background: url(a;b.png); color:red");
      expect(parsed['background'], 'url(a;b.png)');
      expect(parsed['color'], 'red');
    });

    test('ponto e vírgula dentro de aspas não separa declarações', () {
      final parsed = parseInlineStyleToMap('content: "a;b"; color:red');
      expect(parsed['content'], '"a;b"');
      expect(parsed['color'], 'red');
    });

    test('o valor mantém dois-pontos internos (ex.: data URI)', () {
      final parsed =
          parseInlineStyleToMap('background: url(data:image/png;base64,AAA)');
      expect(parsed['background'], 'url(data:image/png;base64,AAA)');
    });

    test('a última declaração repetida vence, como no CSS', () {
      expect(parseInlineStyleToMap('color:red; color:blue'), {'color': 'blue'});
    });
  });

  group('stripWidthQuick', () {
    test('remove width', () {
      expect(stripWidthQuick('width: 120px; color:red').trim(),
          startsWith('color'));
    });

    test('NÃO remove max-width', () {
      // Sem a fronteira de palavra na regex, `max-width` iria junto — e a
      // tabela perderia o limite que a mantém dentro da página.
      final result = stripWidthQuick('max-width: 100%; width: 120px');
      expect(result, contains('max-width: 100%'));
      expect(result, isNot(contains('width: 120px')));
    });
  });

  group('sanitizeTableStyle', () {
    test('tira a largura fixa e garante o limite do container', () {
      final style = sanitizeTableStyle('width: 1460px; border: 1px solid');
      final parsed = parseInlineStyleToMap(style);

      expect(parsed['max-width'], '100%');
      expect(parsed['table-layout'], 'fixed');
      expect(parsed['width'], '100%',
          reason: 'a largura medida no editor estoura a página impressa');
      expect(parsed['border'], '1px solid', reason: 'o resto é preservado');
    });

    test('aceita estilo nulo', () {
      expect(() => sanitizeTableStyle(null), returnsNormally);
    });
  });
}
