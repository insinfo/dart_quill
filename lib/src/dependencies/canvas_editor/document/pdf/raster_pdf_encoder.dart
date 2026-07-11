import 'dart:convert';
import 'dart:typed_data';

/// Codificador PDF multipágina para páginas rasterizadas em JPEG.
///
/// O editor já compõe com fidelidade tabelas, imagens, shapes, cabeçalhos e
/// rodapés no canvas. Este codificador encapsula cada canvas como uma página
/// PDF sem reamostrar os bytes JPEG.
class RasterPdfEncoder {
  RasterPdfEncoder._();

  static Uint8List encode(
    List<Uint8List> jpegPages, {
    String title = 'Documento',
    String producer = 'canvas_text_editor',
  }) {
    if (jpegPages.isEmpty) {
      throw ArgumentError.value(jpegPages, 'jpegPages', 'não pode ser vazio');
    }

    final List<_JpegSize> sizes = jpegPages.map(_jpegSize).toList();
    final int infoObject = 3 + jpegPages.length * 3;
    final int objectCount = infoObject;
    final List<int> offsets = List<int>.filled(objectCount + 1, 0);
    final BytesBuilder output = BytesBuilder(copy: false);

    void writeAscii(String value) => output.add(ascii.encode(value));
    void object(int number, void Function() writeBody) {
      offsets[number] = output.length;
      writeAscii('$number 0 obj\n');
      writeBody();
      writeAscii('\nendobj\n');
    }

    writeAscii('%PDF-1.4\n');
    output.add(const <int>[0x25, 0xe2, 0xe3, 0xcf, 0xd3, 0x0a]);
    object(1, () => writeAscii('<< /Type /Catalog /Pages 2 0 R >>'));

    final List<int> pageObjects = <int>[
      for (int i = 0; i < jpegPages.length; i++) 5 + i * 3,
    ];
    object(2, () {
      writeAscii('<< /Type /Pages /Count ${pageObjects.length} /Kids [');
      for (final int page in pageObjects) {
        writeAscii(' $page 0 R');
      }
      writeAscii(' ] >>');
    });

    for (int i = 0; i < jpegPages.length; i++) {
      final Uint8List jpeg = jpegPages[i];
      final _JpegSize size = sizes[i];
      final int imageObject = 3 + i * 3;
      final int contentObject = imageObject + 1;
      final int pageObject = imageObject + 2;
      final double widthPt = size.width * 72 / 96;
      final double heightPt = size.height * 72 / 96;
      final String width = _number(widthPt);
      final String height = _number(heightPt);

      object(imageObject, () {
        writeAscii('<< /Type /XObject /Subtype /Image /Width ${size.width} '
            '/Height ${size.height} /ColorSpace /DeviceRGB '
            '/BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} '
            '>>\nstream\n');
        output.add(jpeg);
        writeAscii('\nendstream');
      });

      final Uint8List commands = Uint8List.fromList(
          ascii.encode('q\n$width 0 0 $height 0 0 cm\n/Im${i + 1} Do\nQ\n'));
      object(contentObject, () {
        writeAscii('<< /Length ${commands.length} >>\nstream\n');
        output.add(commands);
        writeAscii('endstream');
      });

      object(pageObject, () {
        writeAscii('<< /Type /Page /Parent 2 0 R '
            '/MediaBox [0 0 $width $height] '
            '/Resources << /XObject << /Im${i + 1} $imageObject 0 R >> >> '
            '/Contents $contentObject 0 R >>');
      });
    }

    object(
        infoObject,
        () => writeAscii('<< /Title (${_pdfString(title)}) '
            '/Producer (${_pdfString(producer)}) >>'));

    final int xrefOffset = output.length;
    writeAscii('xref\n0 ${objectCount + 1}\n');
    writeAscii('0000000000 65535 f \n');
    for (int i = 1; i <= objectCount; i++) {
      writeAscii('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }
    writeAscii('trailer\n<< /Size ${objectCount + 1} /Root 1 0 R '
        '/Info $infoObject 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');
    return output.takeBytes();
  }

  static _JpegSize _jpegSize(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const FormatException('Página PDF não é um JPEG válido.');
    }
    int offset = 2;
    while (offset + 8 < bytes.length) {
      if (bytes[offset] != 0xff) {
        offset++;
        continue;
      }
      final int marker = bytes[offset + 1];
      offset += 2;
      if (marker == 0xd8 || marker == 0xd9) continue;
      if (offset + 2 > bytes.length) break;
      final int length = (bytes[offset] << 8) | bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) break;
      if ((marker >= 0xc0 && marker <= 0xc3) ||
          (marker >= 0xc5 && marker <= 0xc7) ||
          (marker >= 0xc9 && marker <= 0xcb) ||
          (marker >= 0xcd && marker <= 0xcf)) {
        final int height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final int width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        return _JpegSize(width, height);
      }
      offset += length;
    }
    throw const FormatException('Dimensões do JPEG não encontradas.');
  }

  static String _number(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(3);

  static String _pdfString(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('(', '\\(')
      .replaceAll(')', '\\)')
      .replaceAll(RegExp(r'[\r\n]+'), ' ');
}

class _JpegSize {
  const _JpegSize(this.width, this.height);

  final int width;
  final int height;
}
