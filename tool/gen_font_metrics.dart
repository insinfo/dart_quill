/// Gera e opcionalmente anexa um bloco `FontMetrics.fromPacked`.
///
/// Uso:
///   dart run tool/gen_font_metrics.dart <família> <fonte.ttf> [arquivo.dart]
///
/// Sem o terceiro argumento, imprime o bloco. Com ele, insere o registro
/// antes da chave final do `registerEmbeddedFonts` e recusa duplicatas.
///
/// A tabela compatível com Calibri é gerada como família `Carlito` a partir de
/// `Carlito-Regular.ttf` (SIL OFL 1.1). A origem exata e o SHA-256 ficam em
/// `THIRD_PARTY.md`; o binário da fonte não é distribuído pelo pacote.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/src/office/document/fonts/font_metrics.dart';

const _officePunctuation = <int>[
  0x2013,
  0x2014,
  0x2018,
  0x2019,
  0x201c,
  0x201d,
  0x2022,
  0x2026,
  0x2039,
  0x203a,
  0x20ac,
  0x2122,
  0x2212,
];

void main(List<String> arguments) {
  if (arguments.length < 2 || arguments.length > 3) {
    stderr.writeln(
      'Uso: dart run tool/gen_font_metrics.dart '
      '<família> <fonte.ttf> [arquivo.dart]',
    );
    exitCode = 64;
    return;
  }

  final family = arguments[0];
  final font = File(arguments[1]);
  if (!font.existsSync()) {
    stderr.writeln('Fonte inexistente: ${font.path}');
    exitCode = 66;
    return;
  }
  final metrics = parseTtfMetrics(
    Uint8List.fromList(font.readAsBytesSync()),
    extraCodepoints: _officePunctuation,
  );
  // Carlito is horizontally metric-compatible with Calibri. Its hhea vertical
  // box is deliberately generous, though, while Word's "single" layout for
  // these OOXML documents is 1.15 em. Normalize only this compatibility face
  // to a neutral 0.75/0.25/0.15-em box; advances continue to come verbatim
  // from the OFL font. This also makes regeneration independent of a
  // proprietary system-font installation.
  final isCalibriCompatible = family.toLowerCase() == 'carlito';
  final ascent =
      isCalibriCompatible ? (metrics.unitsPerEm * .75).round() : metrics.ascent;
  final descent = isCalibriCompatible
      ? (metrics.unitsPerEm * .25).round()
      : metrics.descent;
  final lineGap = isCalibriCompatible
      ? (metrics.unitsPerEm * 1.15).round() - ascent - descent
      : metrics.lineGap;
  final pairs = metrics.advanceWidths.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final block = StringBuffer()
    ..writeln("  registry.register(")
    ..writeln("      '${family.replaceAll("'", r"\'")}',")
    ..writeln('      FontMetrics.fromPacked(')
    ..writeln('        unitsPerEm: ${metrics.unitsPerEm},')
    ..writeln('        ascent: $ascent,')
    ..writeln('        descent: $descent,')
    ..writeln('        lineGap: $lineGap,')
    ..writeln('        defaultAdvance: ${metrics.defaultAdvance},')
    ..writeln('        packedAdvances: <int>[');
  for (final entry in pairs) {
    block
      ..writeln('          ${entry.key},')
      ..writeln('          ${entry.value},');
  }
  block
    ..writeln('        ],')
    ..writeln('      ));');

  if (arguments.length == 2) {
    stdout.write(block);
    return;
  }

  final output = File(arguments[2]);
  final source = output.readAsStringSync();
  if (source.contains("registry.register(\n      '$family',")) {
    stderr.writeln('Família já registrada: $family');
    exitCode = 65;
    return;
  }
  const endMarker = '\n}\n';
  final insertAt = source.lastIndexOf(endMarker);
  if (insertAt < 0) {
    stderr.writeln('Fim de registerEmbeddedFonts não encontrado');
    exitCode = 65;
    return;
  }
  output.writeAsStringSync(
    '${source.substring(0, insertAt)}${block.toString()}${source.substring(insertAt)}',
  );
  stdout.writeln(
    'Registrada $family: ${pairs.length} codepoints, '
    '${metrics.unitsPerEm} units/em.',
  );
}
