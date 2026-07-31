@TestOn('vm')
library;

/// O parser de caminhos e o renderizador de SVG, terminando no **brasão real**
/// (`document_header.svg`, exportado do CorelDRAW) que o SALI põe no topo de
/// todo despacho.
///
/// A gramática do atributo `d` é folgada de um jeito que só aparece em arquivo
/// de editor gráfico: vírgula e espaço são intercambiáveis, o sinal serve de
/// separador (`10-5` são dois números), `.5.5` são dois, e um comando repetido
/// omite a letra. Cada uma dessas licenças tem caso aqui.
import 'dart:io';

import 'package:dart_quill/src/office/document/pdf/svg/svg_path.dart';
import 'package:dart_quill/src/office/document/pdf/svg/svg_renderer.dart';
import 'package:test/test.dart';

late final String _brasao =
    File('test/assets/svg/document_header.svg').readAsStringSync();

void main() {
  group('parser do atributo d', () {
    test('comandos absolutos básicos', () {
      final segments = parseSvgPath('M 10 20 L 30 40 Z');
      expect(segments, hasLength(3));
      expect(segments[0], isA<SvgMoveTo>());
      expect((segments[0] as SvgMoveTo).x, 10);
      expect((segments[1] as SvgLineTo).y, 40);
      expect(segments[2], isA<SvgClosePath>());
    });

    test('comandos relativos acumulam a posição', () {
      final segments = parseSvgPath('m 10 10 l 5 5 l 5 5');
      expect((segments[1] as SvgLineTo).x, 15);
      expect((segments[2] as SvgLineTo).x, 20);
    });

    test('vírgula e espaço são intercambiáveis', () {
      expect(parseSvgPath('M10,20L30,40'), hasLength(2));
      expect(parseSvgPath('M 10 20 L 30 40'), hasLength(2));
    });

    test('o sinal separa números sem espaço', () {
      final segments = parseSvgPath('M10-5L-3-4');
      expect((segments[0] as SvgMoveTo).y, -5);
      expect((segments[1] as SvgLineTo).x, -3);
      expect((segments[1] as SvgLineTo).y, -4);
    });

    test('o ponto decimal separa números colados', () {
      // `.5.5` são 0.5 e 0.5, não "0.55".
      final segments = parseSvgPath('M.5.5');
      expect((segments[0] as SvgMoveTo).x, 0.5);
      expect((segments[0] as SvgMoveTo).y, 0.5);
    });

    test('comando repetido dispensa a letra', () {
      final segments = parseSvgPath('L 1 2 3 4 5 6');
      expect(segments, hasLength(3));
      expect((segments[2] as SvgLineTo).x, 5);
    });

    test('pares depois de M viram L, não M', () {
      // A regra mais esquecida da gramática.
      final segments = parseSvgPath('M 0 0 10 10 20 20');
      expect(segments[0], isA<SvgMoveTo>());
      expect(segments[1], isA<SvgLineTo>());
      expect(segments[2], isA<SvgLineTo>());
    });

    test('H e V mantêm a outra coordenada', () {
      final segments = parseSvgPath('M 10 20 H 50 V 60');
      expect((segments[1] as SvgLineTo).x, 50);
      expect((segments[1] as SvgLineTo).y, 20);
      expect((segments[2] as SvgLineTo).x, 50);
      expect((segments[2] as SvgLineTo).y, 60);
    });

    test('quadrática vira cúbica com os controles a 2/3', () {
      final segments = parseSvgPath('M 0 0 Q 30 0 30 30');
      final cubic = segments[1] as SvgCubicTo;
      expect(cubic.x1, closeTo(20, 0.001));
      expect(cubic.y1, closeTo(0, 0.001));
      expect(cubic.x, 30);
      expect(cubic.y, 30);
    });

    test('S reflete o controle anterior', () {
      final segments = parseSvgPath('M 0 0 C 10 0 20 0 30 0 S 40 10 50 0');
      final smooth = segments[2] as SvgCubicTo;
      // reflexo de (20,0) em torno de (30,0)
      expect(smooth.x1, closeTo(40, 0.001));
    });

    test('arco vira curvas e chega ao ponto final', () {
      final segments = parseSvgPath('M 0 0 A 50 50 0 0 1 100 0');
      expect(segments.length, greaterThan(1));
      final last = segments.last as SvgCubicTo;
      expect(last.x, closeTo(100, 0.5));
      expect(last.y, closeTo(0, 0.5));
    });

    test('arco com raio zero vira reta', () {
      final segments = parseSvgPath('M 0 0 A 0 0 0 0 1 100 0');
      expect(segments[1], isA<SvgLineTo>());
    });

    test('Z volta ao início do subcaminho', () {
      final segments = parseSvgPath('M 10 10 L 20 20 Z l 5 5');
      // depois do Z a posição é (10,10), então o `l 5 5` cai em (15,15)
      final afterClose = segments.last as SvgLineTo;
      expect(afterClose.x, 15);
      expect(afterClose.y, 15);
    });

    test('entrada inválida devolve o que deu, sem lançar', () {
      expect(() => parseSvgPath('M 10'), returnsNormally);
      expect(() => parseSvgPath('lixo'), returnsNormally);
      expect(() => parseSvgPath(''), returnsNormally);
      expect(parseSvgPath(''), isEmpty);
    });
  });

  group('renderizador', () {
    test('lê viewBox, dimensões e um caminho', () {
      final picture = parseSvg('<svg viewBox="0 0 100 50" width="100" '
          'height="50"><path d="M0 0 L10 10" fill="#ff0000"/></svg>');

      expect(picture.viewBox, [0, 0, 100, 50]);
      expect(picture.width, 100);
      expect(picture.shapes, hasLength(1));
      expect(picture.shapes.first.fill, '#ff0000');
    });

    test('herança de fill pelo <g>', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<g fill="#00ff00"><path d="M0 0 L1 1"/></g></svg>');
      expect(picture.shapes.first.fill, '#00ff00');
    });

    test('fill do filho vence o do grupo', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<g fill="#00ff00"><path d="M0 0 L1 1" fill="#0000ff"/></g></svg>');
      expect(picture.shapes.first.fill, '#0000ff');
    });

    test('fill="none" não pinta', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<path d="M0 0 L1 1" fill="none"/></svg>');
      expect(picture.shapes.first.fill, isNull);
    });

    test('cores nomeadas, #rgb e rgb()', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<path d="M0 0" fill="black"/>'
          '<path d="M0 0" fill="#f00"/>'
          '<path d="M0 0" fill="rgb(0, 128, 255)"/></svg>');
      expect(picture.shapes[0].fill, '#000000');
      expect(picture.shapes[1].fill, '#ff0000');
      expect(picture.shapes[2].fill, '#0080ff');
    });

    test('fill-rule evenodd sai como f*', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<path d="M0 0 L1 1 Z" fill="#000" fill-rule="evenodd"/></svg>');
      final result = renderSvgToPdfOperators(picture,
          x: 0, y: 100, width: 100, height: 100);
      expect(result.operators, contains('f*'));
    });

    test('a matriz inverte o eixo Y do SVG', () {
      final picture = parseSvg('<svg viewBox="0 0 100 100">'
          '<path d="M0 0 L1 1" fill="#000"/></svg>');
      final result = renderSvgToPdfOperators(picture,
          x: 0, y: 100, width: 100, height: 100);
      // escala negativa no Y: no SVG o eixo cresce para baixo, no PDF para cima
      expect(result.operators, contains(' 0 0 -'));
      expect(result.operators, startsWith('q\n'));
      expect(result.operators.trimRight(), endsWith('Q'));
    });

    test('a proporção é preservada e o desenho centralizado', () {
      final picture = parseSvg('<svg viewBox="0 0 200 100">'
          '<path d="M0 0 L1 1" fill="#000"/></svg>');
      // Alvo quadrado para um desenho 2:1: a escala tem de ser a do lado
      // limitante (largura), não uma escala por eixo que distorceria.
      final result = renderSvgToPdfOperators(picture,
          x: 0, y: 100, width: 100, height: 100);
      expect(result.operators, contains('0.5 0 0 -0.5'));
    });

    test('recurso não suportado vira aviso, não silêncio', () {
      final picture = parseSvg('<svg viewBox="0 0 10 10">'
          '<path d="M0 0" fill="#000" transform="rotate(45)"/>'
          '<image href="x.png"/>'
          '<text x="1" y="1">oi</text></svg>');

      expect(picture.warnings.any((w) => w.contains('transform')), isTrue);
      expect(picture.warnings.any((w) => w.contains('<image>')), isTrue);
      expect(picture.warnings.any((w) => w.contains('<text>')), isTrue);
    });

    test('raiz que não é <svg> é recusada', () {
      expect(() => parseSvg('<html><body/></html>'),
          throwsA(isA<FormatException>()));
    });
  });

  group('o brasão de verdade', () {
    test('parseia inteiro', () {
      final picture = parseSvg(_brasao);

      expect(picture.viewBox, [0, 0, 1342.93, 287.06]);
      expect(picture.shapes, hasLength(26),
          reason: 'o arquivo tem 26 <path>');
      final segments =
          picture.shapes.fold<int>(0, (sum, s) => sum + s.segments.length);
      expect(segments, greaterThan(5000),
          reason: 'o desenho tem milhares de segmentos: $segments');
    });

    test('as cores do brasão são reconhecidas', () {
      final picture = parseSvg(_brasao);
      final cores = picture.shapes.map((s) => s.fill).toSet();

      expect(cores, isNot(contains(null)),
          reason: 'nenhuma peça pode ficar sem cor');
      for (final cor in cores) {
        expect(cor, matches(RegExp(r'^#[0-9a-f]{6}$')),
            reason: 'cor não normalizada: $cor');
      }
      expect(cores.length, greaterThan(3));
    });

    test('o gradiente é aproximado — e avisado', () {
      final picture = parseSvg(_brasao);
      expect(picture.warnings.any((w) => w.contains('gradiente')), isTrue,
          reason: 'aproximar sem avisar é o que não pode acontecer');
    });

    test('o texto do brasão é reportado como pendente', () {
      // "ESTADO DO RIO DE JANEIRO" e "MUNICÍPIO DE RIO DAS OSTRAS" só saem
      // quando as fontes embutidas entrarem (P1/P7.3).
      final picture = parseSvg(_brasao);
      expect(picture.warnings.any((w) => w.contains('<text>')), isTrue);
    });

    test('gera operadores de PDF válidos', () {
      final picture = parseSvg(_brasao);
      final result = renderSvgToPdfOperators(picture,
          x: 56.7, y: 785, width: 481, height: 103);

      expect(result.operators, startsWith('q\n'));
      expect(result.operators.trimRight(), endsWith('Q'));
      expect(RegExp(r'\bm$', multiLine: true).allMatches(result.operators).length,
          greaterThan(20),
          reason: 'um `m` por subcaminho, no mínimo');
      expect(result.operators, contains(' rg\n'), reason: 'cores');
      expect(result.operators, isNot(contains('e-')),
          reason: 'notação científica não é aceita num content stream');
      expect(result.operators, isNot(contains('NaN')));
    });

    test('a renderização é determinística', () {
      final picture = parseSvg(_brasao);
      String render() => renderSvgToPdfOperators(picture,
              x: 0, y: 800, width: 480, height: 100)
          .operators;
      expect(render(), render());
    });
  });
}
