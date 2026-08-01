/// Tabelas no PDF: larguras, colspan e rowspan.
///
/// A suíte de PDF não tinha NENHUM caso de tabela — uma tabela perdida ou
/// deformada passava verde. O renderizador percorria as células em sequência
/// e ignorava `rowspan`: as colunas escorregavam para a esquerda a cada linha
/// e a célula mesclada saía com a altura de uma linha só.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  /// Retângulos desenhados (`x y w h re`) — as bordas das células.
  List<List<double>> rects(Uint8List pdf) {
    final streams = PdfReader(pdf).decodedStreams.join('\n');
    return RegExp(r'([-\d.]+) ([-\d.]+) ([-\d.]+) ([-\d.]+) re')
        .allMatches(streams)
        .map((m) => [
              double.parse(m.group(1)!),
              double.parse(m.group(2)!),
              double.parse(m.group(3)!),
              double.parse(m.group(4)!),
            ])
        .toList();
  }

  Map<String, dynamic> cellAttrs(String row, String id,
          {String? rowspan, String? colspan}) =>
      {
        'table-cell-block': id,
        'table-cell': {
          'data-row': row,
          if (rowspan != null) 'rowspan': rowspan,
          if (colspan != null) 'colspan': colspan,
        },
      };

  Delta mergedTable() => Delta()
    ..insert('\n', {
      'table-temporary': {'data-class': 'ql-table-better'}
    })
    ..insert('\n', {
      'table-col': {'width': '100'}
    })
    ..insert('\n', {
      'table-col': {'width': '100'}
    })
    ..insert('\n', {
      'table-col': {'width': '100'}
    })
    ..insert('alto')
    ..insert('\n', cellAttrs('r1', 'c1', rowspan: '2'))
    ..insert('b')
    ..insert('\n', cellAttrs('r1', 'c2'))
    ..insert('c')
    ..insert('\n', cellAttrs('r1', 'c3'))
    ..insert('d')
    ..insert('\n', cellAttrs('r2', 'c4'))
    ..insert('e')
    ..insert('\n', cellAttrs('r2', 'c5'))
    ..insert('\n');

  test('a célula com rowspan é desenhada com a altura das duas linhas', () {
    final boxes = rects(deltaToPdf(mergedTable()));
    expect(boxes, isNotEmpty, reason: 'as bordas das células são retângulos');
    final heights = boxes.map((b) => b[3]).toList()..sort();
    expect(heights.last, greaterThan(heights.first * 1.8),
        reason: 'a mesclada tem de ser ~2x a altura de uma linha ($heights)');
  });

  test('as colunas não escorregam na linha seguinte à mesclagem', () {
    final boxes = rects(deltaToPdf(mergedTable()));
    final xs = boxes.map((b) => b[0].round()).toSet().toList()..sort();
    // Três colunas => no máximo três x distintos. Com o rowspan ignorado a
    // segunda linha começava na coluna 1 e surgia um quarto x.
    expect(xs.length, lessThanOrEqualTo(3), reason: 'x distintos: $xs');
  });

  test('colspan soma as larguras das colunas cobertas', () {
    final delta = Delta()
      ..insert('\n', {
        'table-temporary': {'data-class': 'ql-table-better'}
      })
      ..insert('\n', {
        'table-col': {'width': '100'}
      })
      ..insert('\n', {
        'table-col': {'width': '100'}
      })
      ..insert('largo')
      ..insert('\n', cellAttrs('r1', 'c1', colspan: '2'))
      ..insert('\n');
    final widths = rects(deltaToPdf(delta)).map((b) => b[2]).toList();
    expect(widths.any((w) => w > 130), isTrue,
        reason: 'a célula de colspan 2 ocupa as duas colunas ($widths)');
  });

  test('a tabela do DOCX real chega ao PDF com seu texto', () {
    final delta =
        docxToDelta(File('test/assets/docx/etp_corpus.docx').readAsBytesSync());
    final pdf = deltaToPdf(delta);
    final text = PdfReader(pdf).extractText();
    expect(text, contains('Severidade'),
        reason: 'o cabeçalho da tabela precisa aparecer no PDF');
    expect(text, contains('14.669.612,33'),
        reason: 'o total da tabela de TCO precisa sobreviver');
    expect(PdfReader(pdf).endsWithEof, isTrue);
  });

  test('cada nível de lista recua mais que o anterior', () {
    List<double> offsets(Delta delta) {
      final streams = PdfReader(deltaToPdf(delta)).decodedStreams.join(' ');
      return RegExp(r'([\d.]+) [\d.]+ Td')
          .allMatches(streams)
          .map((m) => double.parse(m.group(1)!))
          .toList();
    }

    final raso = offsets(Delta()
      ..insert('item')
      ..insert('\n', {'list': 'bullet'}));
    final fundo = offsets(Delta()
      ..insert('item')
      ..insert('\n', {'list': 'bullet', 'indent': 2}));
    expect(fundo.last, greaterThan(raso.last + 20),
        reason: 'indent 2 recua dois níveis (raso=$raso fundo=$fundo)');
  });
}
