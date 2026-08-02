/// Blocos especiais no PDF: blockquote, code-block e checklist (P10).
///
/// O exportador tratava os três como parágrafo comum: a citação perdia a
/// marca visual, o código saía na fonte do tema sem fundo, e a checklist
/// virava bullet — ☑/☐ não existem no WinAnsi e sairiam como `?`, então a
/// caixa precisa ser DESENHADA, não digitada.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  String streams(Uint8List pdf) => PdfReader(pdf).decodedStreams.join('\n');

  test('code-block sai em Courier sobre fundo cinza-claro', () {
    final delta = Delta()
      ..insert('final x = 1;')
      ..insert('\n', {'code-block': true});
    final pdf = deltaToPdf(delta);
    // O nome da fonte mora no dicionário do objeto (não no stream).
    expect(latin1.decode(pdf), contains('/BaseFont /Courier'),
        reason: 'o texto do bloco de código deve trocar para Courier');
    final content = streams(pdf);
    // #F0F0F0 → 0.941 em cada canal.
    expect(content, contains('0.941 0.941 0.941 rg'),
        reason: 'o fundo cinza-claro do código deve ser preenchido');
  });

  test('blockquote desenha a barra vertical cinza', () {
    final delta = Delta()
      ..insert('Uma citação qualquer.')
      ..insert('\n', {'blockquote': true});
    final content = streams(deltaToPdf(delta));
    // #CCCCCC → 0.8; a barra tem 3 pt de largura.
    final bar = RegExp(r'0\.8 0\.8 0\.8 rg\n[-\d.]+ [-\d.]+ 3 [-\d.]+ re f');
    expect(bar.hasMatch(content), isTrue,
        reason: 'a barra de 3pt em #CCC deve existir: $content');
  });

  test('checklist desenha caixa vetorial; marcada ganha o traço do check', () {
    Uint8List pdf(String state) => deltaToPdf(Delta()
      ..insert('item')
      ..insert('\n', {'list': state}));
    final unchecked = streams(pdf('unchecked'));
    final checked = streams(pdf('checked'));

    // Nenhum marcador de texto: a caixa é um `re S` (stroke), não um glifo.
    expect(unchecked, isNot(contains('(•')),
        reason: 'checklist não pode cair no bullet');
    final box = RegExp(r'(?:[-\d.]+ ){4}re S');
    expect(box.hasMatch(unchecked), isTrue,
        reason: 'a caixa deve ser um retângulo contornado');
    expect(box.hasMatch(checked), isTrue);

    // O check são dois segmentos a mais no estado marcado.
    int strokes(String c) => RegExp(r' l S').allMatches(c).length;
    expect(strokes(checked), strokes(unchecked) + 2,
        reason: 'o estado marcado desenha os dois traços do check');
  });

  test('checklist respeita o nível de indentação', () {
    Uint8List pdf(int? indent) => deltaToPdf(Delta()
      ..insert('item')
      ..insert('\n', {'list': 'unchecked', if (indent != null) 'indent': indent}));
    double boxX(String c) {
      final m = RegExp(r'([-\d.]+) [-\d.]+ [-\d.]+ [-\d.]+ re S').firstMatch(c)!;
      return double.parse(m.group(1)!);
    }

    expect(boxX(streams(pdf(1))), greaterThan(boxX(streams(pdf(null)))),
        reason: 'um nível a mais empurra a caixa para a direita');
  });
}
