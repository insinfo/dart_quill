@TestOn('vm')
library;

/// Embedding da fonte como CID (`Type0`/`Identity-H`) — o passo que faz o PDF
/// sair na fonte de verdade e que faz `ç`, `ã` e `—` sobreviverem.
///
/// Dois critérios independentes valem aqui:
///
/// 1. **a estrutura** — `Type0` → `CIDFontType2` → `FontDescriptor` →
///    `FontFile2` encadeados como o PDF 32000-1 §9.7 manda; um elo solto faz
///    o leitor ignorar a fonte e cair numa substituta, silenciosamente;
/// 2. **o `/ToUnicode`** — que não muda um pixel do desenho e decide se copiar
///    texto do documento assinado devolve as palavras ou lixo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/src/office/document/fonts/truetype.dart';
import 'package:dart_quill/src/office/document/pdf/pdf_cid_font.dart';
import 'package:dart_quill/src/office/document/pdf/pdf_writer.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

late final Uint8List _interBytes =
    File('test/assets/fonts/Inter-Regular.ttf').readAsBytesSync();

/// Monta um PDF de uma página com [text] escrito na fonte embutida.
Uint8List _pdfWith(String text, {double size = 12}) {
  final writer = PdfWriter();
  final embedded = embedCidFont(
    writer,
    _interBytes,
    usedRunes: text.runes,
    resourceName: '/TT1',
  );
  final content = 'BT ${embedded.resourceName} $size Tf 56 700 Td '
      '${embedded.encodeText(text)} Tj ET';
  writer.addPage(
    widthPt: 595,
    heightPt: 842,
    content: latin1.encode(content),
  );
  return writer.build();
}

void main() {
  group('estrutura da fonte', () {
    test('a cadeia Type0 → CIDFontType2 → descritor → FontFile2 existe', () {
      final pdf = PdfReader(_pdfWith('Despacho'));

      expect(pdf.rawLatin1, contains('/Subtype /Type0'));
      expect(pdf.rawLatin1, contains('/Encoding /Identity-H'));
      expect(pdf.rawLatin1, contains('/Subtype /CIDFontType2'));
      expect(pdf.rawLatin1, contains('/Type /FontDescriptor'));
      expect(pdf.rawLatin1, contains('/FontFile2'));
      expect(pdf.rawLatin1, contains('/CIDToGIDMap /Identity'),
          reason: 'sem Identity o CID não é o glifo e o texto sai embaralhado');
    });

    test('o /Length1 do programa da fonte é declarado', () {
      // Alguns leitores exigem o tamanho descomprimido para TrueType.
      expect(PdfReader(_pdfWith('x')).rawLatin1, contains('/Length1 '));
    });

    test('o nome carrega o prefixo de subconjunto', () {
      final pdf = PdfReader(_pdfWith('abc'));
      expect(pdf.rawLatin1, matches(RegExp(r'/BaseFont /[A-Z]{6}\+Inter')));
    });

    test('o prefixo é derivado dos glifos, não aleatório', () {
      // Um prefixo aleatório mudaria os bytes a cada execução e quebraria o
      // hash SHA-256 do documento assinado.
      String tagOf(String text) =>
          RegExp(r'/BaseFont /([A-Z]{6})\+').firstMatch(
              PdfReader(_pdfWith(text)).rawLatin1)!.group(1)!;

      expect(tagOf('mesmo texto'), tagOf('mesmo texto'));
      expect(tagOf('abc'), isNot(tagOf('xyz')),
          reason: 'conjuntos diferentes têm de ter prefixos diferentes');
    });

    test('o descritor traz as métricas da fonte, em milésimos de em', () {
      final pdf = PdfReader(_pdfWith('M'));
      final ascent =
          RegExp(r'/Ascent (-?\d+)').firstMatch(pdf.rawLatin1)!.group(1)!;
      final descent =
          RegExp(r'/Descent (-?\d+)').firstMatch(pdf.rawLatin1)!.group(1)!;

      expect(int.parse(ascent), inInclusiveRange(600, 1200));
      expect(int.parse(descent), lessThan(0));
      expect(pdf.rawLatin1, contains('/FontBBox ['));
      expect(pdf.rawLatin1, contains('/CapHeight '));
    });

    test('a fonte entra nos /Resources da página', () {
      expect(PdfReader(_pdfWith('x')).rawLatin1, contains('/TT1 '));
    });

    test('as larguras (/W) cobrem os glifos usados', () {
      final pdf = PdfReader(_pdfWith('ab'));
      expect(pdf.rawLatin1, contains('/W ['));
      expect(pdf.rawLatin1, contains('/DW 1000'));
    });
  });

  group('/ToUnicode', () {
    test('a CMap é emitida e bem formada', () {
      final cmap = _toUnicodeOf(_pdfWith('Ação'));

      expect(cmap, contains('begincmap'));
      expect(cmap, contains('endcmap'));
      expect(cmap, contains('/CMapName /Adobe-Identity-UCS'));
      expect(cmap, contains('begincodespacerange'));
      expect(cmap, contains('beginbfchar'));
    });

    test('cada caractere aparece com o seu ponto de código', () {
      const texto = 'Ação — 42';
      final cmap = _toUnicodeOf(_pdfWith(texto));
      final font = TrueTypeFont.parse(_interBytes);

      for (final rune in texto.runes) {
        final glyph = font.glyphIdFor(rune);
        if (glyph == 0) continue;
        final entrada = '<${glyph.toRadixString(16).padLeft(4, '0')}> '
            '<${rune.toRadixString(16).padLeft(4, '0')}>';
        expect(cmap.toLowerCase(), contains(entrada.toLowerCase()),
            reason: 'sem esta entrada, copiar "${String.fromCharCode(rune)}" '
                'do PDF devolve lixo');
      }
    });

    test('os blocos respeitam o limite de 100 entradas do formato', () {
      const muitos =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
          'áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ.,;:!?()[]{}@#\$%&*+-=/\\|<>"\'';
      final cmap = _toUnicodeOf(_pdfWith(muitos));

      for (final match in RegExp(r'(\d+) beginbfchar').allMatches(cmap)) {
        expect(int.parse(match.group(1)!), lessThanOrEqualTo(100));
      }
    });
  });

  group('codificação do texto', () {
    test('encodeText produz CIDs de 2 bytes em hexadecimal', () {
      final writer = PdfWriter();
      final font = embedCidFont(writer, _interBytes,
          usedRunes: 'AB'.runes, resourceName: '/TT1');

      final encoded = font.encodeText('AB');
      expect(encoded, matches(RegExp(r'^<[0-9a-f]{8}>$')),
          reason: 'dois caracteres = 4 bytes = 8 dígitos');
    });

    test('caractere sem glifo vira .notdef, não some', () {
      final writer = PdfWriter();
      final font = embedCidFont(writer, _interBytes,
          usedRunes: 'a'.runes, resourceName: '/TT1');

      // '中' não existe na Inter: tem de virar 0000 (caixa vazia), o que é
      // honesto — sumir seria pior, e quebrar o desenho, pior ainda.
      expect(font.encodeText('中'), '<0000>');
    });

    test('a medição usa a métrica real da fonte', () {
      final writer = PdfWriter();
      final font = embedCidFont(writer, _interBytes,
          usedRunes: 'mi'.runes, resourceName: '/TT1');

      expect(font.measure('m', 12), greaterThan(font.measure('i', 12)));
      expect(font.measure('mm', 12), closeTo(font.measure('m', 12) * 2, 0.001));
      expect(font.measure('', 12), 0);
    });
  });

  group('o documento resultante', () {
    test('é um PDF válido e legível', () {
      final pdf = PdfReader(_pdfWith('Despacho nº 42'));

      expect(pdf.header, startsWith('%PDF-1.'));
      expect(pdf.hasTrailerRoot, isTrue);
      expect(pdf.pageCount, 1);
      for (final offset in pdf.xrefOffsets) {
        expect(pdf.objectHeaderAt(offset), isNotNull);
      }
    });

    test('embute a fonte recortada, não a fonte inteira', () {
      final bytes = _pdfWith('Despacho');
      expect(bytes.length, lessThan(_interBytes.length ~/ 2),
          reason: 'PDF de ${bytes.length} bytes para uma fonte de '
              '${_interBytes.length} indica que o subset não entrou');
    });

    test('o mesmo texto gera os mesmos bytes', () {
      expect(_pdfWith('determinismo'), equals(_pdfWith('determinismo')));
    });

    test('uma fonte que proíbe embutir é recusada com mensagem clara', () {
      // Falsifica o fsType da OS/2 para o bit 1 (restricted).
      final bytes = Uint8List.fromList(_interBytes);
      final font = TrueTypeFont.parse(bytes);
      if (!font.hasTable('OS/2')) return;

      final os2 = _tableOffset(bytes, 'OS/2');
      ByteData.sublistView(bytes).setUint16(os2 + 8, 0x0002);

      expect(
        () => embedCidFont(PdfWriter(), bytes,
            usedRunes: 'a'.runes, resourceName: '/TT1'),
        throwsA(isA<TrueTypeException>().having(
            (e) => e.message, 'mensagem', contains('não pode ser embutida'))),
      );
    });
  });
}

/// Conteúdo da CMap `/ToUnicode` do PDF.
String _toUnicodeOf(Uint8List pdf) {
  final reader = PdfReader(pdf);
  for (final stream in reader.decodedStreams) {
    if (stream.contains('begincmap')) return stream;
  }
  fail('nenhum stream contém a CMap /ToUnicode');
}

int _tableOffset(Uint8List font, String tag) {
  final view = ByteData.sublistView(font);
  final numTables = view.getUint16(4);
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    if (String.fromCharCodes(font, record, record + 4) == tag) {
      return view.getUint32(record + 8);
    }
  }
  throw StateError('tabela $tag ausente');
}
