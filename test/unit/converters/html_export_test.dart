@TestOn('vm')
library;

/// `deltaToHtml` — o conversor de Delta para HTML semântico.
///
/// O contrato é: sai HTML que qualquer navegador, e-mail ou impressora
/// entende, **sem** as classes `ql-*` do editor. É o que permite exibir um
/// despacho não assinado fora do Quill.
import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/dart_quill_html.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

Delta _loadDelta(String name) {
  final decoded =
      jsonDecode(File('test/assets/delta/$name').readAsStringSync());
  final ops = decoded is Map ? decoded['ops'] as List : decoded as List;
  return Delta.fromJson(ops);
}

void main() {
  group('formatos inline', () {
    test('negrito, itálico, sublinhado e tachado', () {
      final html = deltaToHtml(Delta()
        ..insert('a', {'bold': true})
        ..insert('b', {'italic': true})
        ..insert('c', {'underline': true})
        ..insert('d', {'strike': true})
        ..insert('\n'));

      expect(html, contains('<strong>a</strong>'));
      expect(html, contains('<em>b</em>'));
      expect(html, contains('<u>c</u>'));
      expect(html, anyOf(contains('<s>d</s>'), contains('<del>d</del>')));
      expect(html, isNot(contains('ql-')),
          reason: 'nenhuma classe do editor pode vazar para o HTML');
    });

    test('link vira uma âncora de verdade', () {
      final html = deltaToHtml(Delta()
        ..insert('portal', {'link': 'https://example.com'})
        ..insert('\n'));

      expect(html, contains('<a'));
      expect(html, contains('href="https://example.com"'));
      expect(html, contains('portal'));
    });

    test('cor e realce saem como style inline', () {
      final html = deltaToHtml(Delta()
        ..insert('x', {'color': '#ff0000'})
        ..insert('y', {'background': '#00ff00'})
        ..insert('\n'));

      expect(html, contains('#ff0000'));
      expect(html, contains('#00ff00'));
      expect(html, contains('style='));
    });
  });

  group('formatos de bloco', () {
    test('cabeçalhos viram h1..h6', () {
      final html = deltaToHtml(Delta()
        ..insert('Título')
        ..insert('\n', {'header': 1})
        ..insert('Sub')
        ..insert('\n', {'header': 2}));

      expect(html, contains('<h1>Título</h1>'));
      expect(html, contains('<h2>Sub</h2>'));
    });

    test('lista com marcador vira ul/li', () {
      final html = deltaToHtml(Delta()
        ..insert('um')
        ..insert('\n', {'list': 'bullet'})
        ..insert('dois')
        ..insert('\n', {'list': 'bullet'}));

      expect(html, contains('<ul>'));
      expect(html, contains('<li>'));
      expect(html, contains('um'));
      expect(html, contains('dois'));
      expect('<li>'.allMatches(html).length, 2);
    });

    test('lista ordenada vira ol/li', () {
      final html = deltaToHtml(Delta()
        ..insert('um')
        ..insert('\n', {'list': 'ordered'}));

      expect(html, contains('<ol>'));
      expect(html, contains('<li>'));
    });

    test('citação vira blockquote', () {
      final html = deltaToHtml(Delta()
        ..insert('citado')
        ..insert('\n', {'blockquote': true}));

      expect(html, contains('<blockquote>'));
      expect(html, contains('citado'));
    });

    test('alinhamento sai como style, não como classe', () {
      final html = deltaToHtml(Delta()
        ..insert('centro')
        ..insert('\n', {'align': 'center'}));

      expect(html, contains('center'));
      expect(html, isNot(contains('ql-align-center')));
    });
  });

  group('escape', () {
    test('markup no texto é escapado por padrão', () {
      final html = deltaToHtml(Delta()..insert('<script>alert(1)</script>\n'));

      expect(html, isNot(contains('<script>')));
      expect(html, contains('&lt;script&gt;'));
    });

    test('E comercial e aspas também', () {
      final html = deltaToHtml(Delta()..insert('a & b\n'));
      expect(html, contains('&amp;'));
    });
  });

  group('wrapper', () {
    test('sem opção, nada é acrescentado', () {
      final html = deltaToHtml(Delta()..insert('x\n'));
      expect(html, isNot(startsWith('<div style=')));
    });

    test('com wrapperStyle, o conteúdo sai dentro do div', () {
      final html = deltaToHtml(
        Delta()..insert('x\n'),
        options: const HtmlConvertOptions(
          wrapperStyle: HtmlConvertOptions.saliDocumentStyle,
        ),
      );

      expect(html, startsWith('<div style="font-size: 12pt;'));
      expect(html, endsWith('</div>'));
      expect(html, contains('x'));
    });
  });

  group('a partir dos ops crus', () {
    test('opsToHtml aceita o que vem do banco, sem construir um Delta', () {
      final ops = jsonDecode('[{"insert":"oi"},{"insert":"\\n"}]') as List;
      expect(opsToHtml(ops), contains('oi'));
    });
  });

  group('documentos reais do SALI', () {
    const fixtures = <String, String>{
      'documento.delta.json': 'documento',
      'ferias.delta.json': 'férias',
      'tabela_colunas_iguais.delta.json': 'tabela com colunas iguais',
      'termo_referencia.delta.json': 'termo de referência (2 MB)',
    };

    fixtures.forEach((file, label) {
      test('$label converte sem perder o texto', () {
        final delta = _loadDelta(file);
        final html = deltaToHtml(delta);

        expect(html, isNotEmpty);
        expect(html, isNot(contains('ql-editor')),
            reason: 'o markup do editor não pode aparecer');

        // Uma amostra do texto do Delta tem de sobreviver à conversão. Sem
        // isto, um conversor que devolvesse "<p></p>" passaria.
        final texto = delta
            .toList()
            .map((op) => op.data)
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.length > 12 && !s.contains('\n'))
            .toList();
        if (texto.isNotEmpty) {
          final amostra = texto.first;
          expect(html, contains(amostra.split('&').first.split('<').first),
              reason: 'trecho ausente no HTML: "$amostra"');
        }
      });
    });

    test('a tabela do documento vira uma tabela HTML', () {
      final html = deltaToHtml(_loadDelta('tabela_colunas_iguais.delta.json'));
      expect(html, contains('<table'));
      expect(html, contains('<tr'));
      expect(html, contains('<td'));
    });

    test('a conversão é determinística', () {
      final delta = _loadDelta('documento.delta.json');
      expect(deltaToHtml(delta), deltaToHtml(delta));
    });
  });
}
