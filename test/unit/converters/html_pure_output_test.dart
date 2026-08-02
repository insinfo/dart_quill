/// H4/H5/H7 — a promessa do conversor é HTML puro, sem dependência de CSS.
///
/// H4: classes de editor (`ql-*`), de Word (`Mso*`) e de framework
/// (`img-responsive`, `list-unstyled`) vazavam na saída — ruído que só faz
/// sentido com o CSS correspondente carregado. H5: `indent`/`direction` de
/// parágrafo não tinham listener e sumiam. H7: um Delta sem `\n` final
/// derrubava a conversão inteira com exceção.
@TestOn('vm')
library;

import 'package:dart_quill/src/converters/html/delta_to_html.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

void main() {
  group('H4 — sem classes de editor/framework', () {
    test('tabela colada do Word não vaza ql-table-better nem Mso*', () {
      final delta = Delta()
        ..insert('\n', {
          'table-temporary': {
            'data-class': 'ql-table-better MsoNormalTable',
            'style': 'border-collapse: collapse;',
          }
        })
        ..insert('célula')
        ..insert('\n', {
          'table-cell-block': 'c1',
          'table-cell': {'data-row': 'r1'},
        })
        ..insert('\n');
      final html = deltaToHtml(delta);
      expect(html, contains('<table'));
      expect(html, isNot(contains('ql-')),
          reason: 'classe do editor só faz sentido dentro do Quill: $html');
      expect(html, isNot(contains('Mso')),
          reason: 'classe do Word é ruído que denuncia a origem: $html');
    });

    test('imagem sai sem classes bootstrap, responsiva por estilo inline', () {
      final delta = Delta()
        ..insert({'image': 'https://exemplo.gov.br/foto.png'})
        ..insert('\n');
      final html = deltaToHtml(delta);
      expect(html, isNot(contains('img-responsive')));
      expect(html, isNot(contains('img-fluid')));
      expect(html, contains('max-width: 100%'),
          reason: 'a responsividade vai inline, sem depender de CSS: $html');
    });

    test('checklist sai sem list-unstyled, com estilo inline', () {
      final delta = Delta()
        ..insert('feito')
        ..insert('\n', {'list': 'checked'})
        ..insert('pendente')
        ..insert('\n', {'list': 'unchecked'});
      final html = deltaToHtml(delta);
      expect(html, isNot(contains('list-unstyled')));
      expect(html, contains('list-style-type: none'),
          reason: 'o marcador some por estilo inline: $html');
    });
  });

  group('H5 — indent e direction de parágrafo', () {
    test('indent vira padding-left proporcional ao nível', () {
      String html(int indent) => deltaToHtml(Delta()
        ..insert('recuado')
        ..insert('\n', {'indent': indent}));
      expect(html(1), contains('padding-left: 3em'));
      expect(html(2), contains('padding-left: 6em'));
    });

    test('direction rtl vira dir="rtl" e recua pela direita', () {
      final html = deltaToHtml(Delta()
        ..insert('عربى')
        ..insert('\n', {'direction': 'rtl', 'indent': 1}));
      expect(html, contains('dir="rtl"'));
      expect(html, contains('padding-right: 3em'));
    });

    test('align e indent na mesma linha compõem um único <p>', () {
      final html = deltaToHtml(Delta()
        ..insert('centrado e recuado')
        ..insert('\n', {'align': 'center', 'indent': 1}));
      expect(html, contains('text-align: center;'));
      expect(html, contains('padding-left: 3em'));
      expect('<p'.allMatches(html).length, 1,
          reason: 'os dois atributos moram no mesmo parágrafo: $html');
    });
  });

  group('H7 — robustez', () {
    test('delta sem newline final converte em vez de lançar', () {
      final delta = Delta()..insert('sem terminador');
      expect(() => deltaToHtml(delta), returnsNormally);
      expect(deltaToHtml(delta), contains('sem terminador'));
    });

    test('delta terminando em embed também converte', () {
      final delta = Delta()
        ..insert('texto\n')
        ..insert({'image': 'https://exemplo.gov.br/x.png'});
      expect(() => deltaToHtml(delta), returnsNormally);
      expect(deltaToHtml(delta), contains('<img'));
    });
  });
}
