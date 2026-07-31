/// A minimal PDF reader, for tests only.
///
/// The exporter is asserted by reading its output back — page count, xref
/// integrity, extracted text, annotations — instead of comparing bytes. A
/// golden of PDF bytes breaks on any unrelated change and, when it breaks,
/// says nothing about what went wrong; this says "the text is missing" or
/// "the xref points past EOF".
///
/// It understands only what this package writes: PDF 1.4, a classic
/// cross-reference table, and content streams compressed with FlateDecode.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_quill/src/office/document/pdf/pdf_writer.dart'
    show zlibDecode;

class PdfReader {
  PdfReader(this.bytes) : rawLatin1 = latin1.decode(bytes, allowInvalid: true);

  final Uint8List bytes;

  /// The whole file as latin1, for coarse "does it contain X" checks.
  final String rawLatin1;

  String get header => rawLatin1.substring(0, 8);

  bool get endsWithEof => rawLatin1.trimRight().endsWith('%%EOF');

  bool get hasTrailerRoot {
    final trailer = rawLatin1.lastIndexOf('trailer');
    return trailer >= 0 && rawLatin1.substring(trailer).contains('/Root');
  }

  /// Number of page objects, taken from the page tree's `/Count`, falling back
  /// to counting `/Type /Page` objects.
  int get pageCount {
    final count = RegExp(r'/Type\s*/Pages\b[^>]*?/Count\s+(\d+)', dotAll: true)
        .firstMatch(rawLatin1);
    if (count != null) return int.parse(count.group(1)!);
    return RegExp(r'/Type\s*/Page[^s]').allMatches(rawLatin1).length;
  }

  /// Byte offsets listed in the cross-reference table (the free entry `f` is
  /// skipped: it is object 0 and points nowhere).
  List<int> get xrefOffsets {
    final start = rawLatin1.lastIndexOf('\nxref');
    if (start < 0) return const [];
    final end = rawLatin1.indexOf('trailer', start);
    final table = rawLatin1.substring(start, end < 0 ? rawLatin1.length : end);
    return RegExp(r'^(\d{10}) \d{5} n', multiLine: true)
        .allMatches(table)
        .map((m) => int.parse(m.group(1)!))
        .where((offset) => offset > 0)
        .toList();
  }

  /// `"12 0 obj"` when [offset] lands on an indirect object header, else null.
  String? objectHeaderAt(int offset) {
    if (offset < 0 || offset >= rawLatin1.length) return null;
    final slice =
        rawLatin1.substring(offset, (offset + 32).clamp(0, rawLatin1.length));
    final match = RegExp(r'^(\d+ \d+ obj)').firstMatch(slice);
    return match?.group(1);
  }

  /// `[x0, y0, x1, y1]` of the first `/MediaBox`, or null.
  List<double>? get firstMediaBox {
    final match =
        RegExp(r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)')
            .firstMatch(rawLatin1);
    if (match == null) return null;
    return [
      for (var i = 1; i <= 4; i++) double.parse(match.group(i)!),
    ];
  }

  /// Text of every content stream, concatenated.
  ///
  /// Only the operators this exporter emits are handled: `Tj` and `TJ` inside
  /// `BT`/`ET`, with WinAnsi (cp1252) bytes.
  String extractText() {
    final buffer = StringBuffer();
    for (final stream in _streams()) {
      buffer.write(_textOfContentStream(stream));
    }
    return buffer.toString();
  }

  /// Decoded payload of every stream object in the file.
  List<String> _streams() {
    final result = <String>[];
    // Offsets are byte-based, and latin1 is 1 byte per char, so string indices
    // and byte indices coincide.
    var from = 0;
    while (true) {
      final start = rawLatin1.indexOf('stream', from);
      if (start < 0) break;
      var dataStart = start + 'stream'.length;
      if (dataStart < bytes.length && bytes[dataStart] == 0x0d) dataStart++;
      if (dataStart < bytes.length && bytes[dataStart] == 0x0a) dataStart++;
      final end = rawLatin1.indexOf('endstream', dataStart);
      if (end < 0) break;
      from = end + 'endstream'.length;

      final dictionary = _dictionaryBefore(start);
      if (dictionary.contains('/Image')) continue; // not text
      final payload = bytes.sublist(dataStart, end);
      if (dictionary.contains('FlateDecode')) {
        try {
          result.add(latin1.decode(zlibDecode(payload), allowInvalid: true));
        } catch (_) {
          // A stream this reader cannot inflate is not text worth asserting.
        }
      } else {
        result.add(latin1.decode(payload, allowInvalid: true));
      }
    }
    return result;
  }

  String _dictionaryBefore(int streamKeyword) {
    final open = rawLatin1.lastIndexOf('<<', streamKeyword);
    if (open < 0) return '';
    return rawLatin1.substring(open, streamKeyword);
  }

  static String _textOfContentStream(String content) {
    final buffer = StringBuffer();
    // `(text) Tj` and `[(a) -10 (b)] TJ`.
    for (final match
        in RegExp(r'\((?:\\.|[^\\()])*\)', dotAll: true).allMatches(content)) {
      buffer.write(_unescapePdfString(match.group(0)!));
    }
    return buffer.toString();
  }

  /// `(a\(b\)c)` -> `a(b)c`, decoding the octal escapes cp1252 needs.
  static String _unescapePdfString(String literal) {
    final body = literal.substring(1, literal.length - 1);
    final out = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final char = body[i];
      if (char != r'\') {
        out.write(char);
        continue;
      }
      if (i + 1 >= body.length) break;
      final next = body[++i];
      switch (next) {
        case 'n':
          out.write('\n');
          break;
        case 'r':
          out.write('\r');
          break;
        case 't':
          out.write('\t');
          break;
        case '(':
        case ')':
        case r'\':
          out.write(next);
          break;
        default:
          if (RegExp(r'[0-7]').hasMatch(next)) {
            var octal = next;
            while (octal.length < 3 &&
                i + 1 < body.length &&
                RegExp(r'[0-7]').hasMatch(body[i + 1])) {
              octal += body[++i];
            }
            out.writeCharCode(_winAnsiToUnicode(int.parse(octal, radix: 8)));
          } else {
            out.write(next);
          }
      }
    }
    return out.toString();
  }

  /// cp1252 differs from latin1 only in 0x80–0x9F.
  static int _winAnsiToUnicode(int byte) {
    const high = <int>[
      0x20AC, 0x81, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
      0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x8D, 0x017D, 0x8F,
      0x90, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
      0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x9D, 0x017E, 0x0178,
    ];
    if (byte >= 0x80 && byte <= 0x9F) return high[byte - 0x80];
    return byte;
  }
}
