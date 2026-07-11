import 'dart:convert';
import 'dart:typed_data';

import '../zip/codecs/zlib/inflate.dart';
import 'pdf_writer.dart' show zlibEncode;

/// Imagem decodificada pronta para virar XObject em [PdfWriter.addImage].
class PdfImageData {
  PdfImageData({
    required this.width,
    required this.height,
    required this.colorSpace,
    required this.bitsPerComponent,
    required this.filter,
    required this.data,
    this.decodeParms,
    this.smask,
    this.extraEntries,
  });

  final int width;
  final int height;
  final String colorSpace;
  final int bitsPerComponent;
  final String filter;
  final String? decodeParms;
  final Uint8List data;
  final PdfImageData? smask;
  final String? extraEntries;
}

/// Decodifica um data URL (`data:image/...;base64,...`) para [PdfImageData].
/// Retorna `null` quando o formato não é suportado (o chamador pula a imagem).
PdfImageData? decodeDataUrlImage(String dataUrl) {
  if (!dataUrl.startsWith('data:')) return null;
  final int comma = dataUrl.indexOf(',');
  if (comma < 0) return null;
  final String header = dataUrl.substring(5, comma);
  if (!header.contains(';base64')) return null;
  Uint8List bytes;
  try {
    bytes = base64Decode(dataUrl.substring(comma + 1).trim());
  } on FormatException {
    return null;
  }
  return decodeImageBytes(bytes);
}

/// Decodifica bytes JPEG ou PNG.
PdfImageData? decodeImageBytes(Uint8List bytes) {
  if (bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8) {
    return _decodeJpeg(bytes);
  }
  if (bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return _decodePng(bytes);
  }
  return null;
}

// ── JPEG ────────────────────────────────────────────────────────────────

PdfImageData? _decodeJpeg(Uint8List bytes) {
  int offset = 2;
  while (offset + 8 < bytes.length) {
    if (bytes[offset] != 0xff) {
      offset++;
      continue;
    }
    final int marker = bytes[offset + 1];
    offset += 2;
    if (marker == 0xd8 || marker == 0xd9 || (marker >= 0xd0 && marker <= 0xd7)) {
      continue;
    }
    if (offset + 2 > bytes.length) break;
    final int length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) break;
    final bool isSof = (marker >= 0xc0 && marker <= 0xc3) ||
        (marker >= 0xc5 && marker <= 0xc7) ||
        (marker >= 0xc9 && marker <= 0xcb) ||
        (marker >= 0xcd && marker <= 0xcf);
    if (isSof) {
      final int height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      final int width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      final int components = bytes[offset + 7];
      final String colorSpace = components == 1
          ? '/DeviceGray'
          : components == 4
              ? '/DeviceCMYK'
              : '/DeviceRGB';
      return PdfImageData(
        width: width,
        height: height,
        colorSpace: colorSpace,
        bitsPerComponent: 8,
        filter: '/DCTDecode',
        data: bytes,
        // JPEGs CMYK de Adobe são normalmente invertidos.
        extraEntries: components == 4 ? ' /Decode [1 0 1 0 1 0 1 0]' : null,
      );
    }
    offset += length;
  }
  return null;
}

// ── PNG ─────────────────────────────────────────────────────────────────

PdfImageData? _decodePng(Uint8List bytes) {
  int width = 0, height = 0, bitDepth = 0, colorType = -1, interlace = 0;
  Uint8List? palette;
  final BytesBuilder idat = BytesBuilder(copy: false);
  int offset = 8;
  while (offset + 8 <= bytes.length) {
    final int length = _readUint32(bytes, offset);
    final String type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final int dataStart = offset + 8;
    if (dataStart + length > bytes.length) break;
    if (type == 'IHDR') {
      width = _readUint32(bytes, dataStart);
      height = _readUint32(bytes, dataStart + 4);
      bitDepth = bytes[dataStart + 8];
      colorType = bytes[dataStart + 9];
      interlace = bytes[dataStart + 12];
    } else if (type == 'PLTE') {
      palette = bytes.sublist(dataStart, dataStart + length);
    } else if (type == 'IDAT') {
      idat.add(bytes.sublist(dataStart, dataStart + length));
    } else if (type == 'IEND') {
      break;
    }
    offset = dataStart + length + 4; // pula CRC
  }
  if (width <= 0 || height <= 0 || idat.isEmpty) return null;
  if (interlace != 0 || bitDepth > 8) return null; // Adam7/16-bit: sem suporte
  final Uint8List idatBytes = idat.takeBytes();

  switch (colorType) {
    case 0: // grayscale
    case 2: // RGB
      final int colors = colorType == 2 ? 3 : 1;
      return PdfImageData(
        width: width,
        height: height,
        colorSpace: colorType == 2 ? '/DeviceRGB' : '/DeviceGray',
        bitsPerComponent: bitDepth,
        filter: '/FlateDecode',
        decodeParms: '<< /Predictor 15 /Colors $colors '
            '/BitsPerComponent $bitDepth /Columns $width >>',
        data: idatBytes,
      );
    case 3: // paleta
      if (palette == null) return null;
      final String hex = palette
          .map((int b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final int hival = palette.length ~/ 3 - 1;
      return PdfImageData(
        width: width,
        height: height,
        colorSpace: '[/Indexed /DeviceRGB $hival <$hex>]',
        bitsPerComponent: bitDepth,
        filter: '/FlateDecode',
        decodeParms:
            '<< /Predictor 15 /Colors 1 /BitsPerComponent $bitDepth '
            '/Columns $width >>',
        data: idatBytes,
      );
    case 4: // gray + alpha
    case 6: // RGBA
      return _decodePngWithAlpha(
          idatBytes, width, height, colorType == 6 ? 4 : 2);
    default:
      return null;
  }
}

/// Inflaciona o IDAT, remove os filtros de scanline e separa cor/alfa.
PdfImageData? _decodePngWithAlpha(
  Uint8List idat,
  int width,
  int height,
  int channels,
) {
  final Uint8List? raw = _inflateZlib(idat);
  if (raw == null) return null;
  final int stride = width * channels;
  if (raw.length < (stride + 1) * height) return null;
  final Uint8List pixels = _unfilterScanlines(raw, width, height, channels);
  final int colorChannels = channels - 1;
  final Uint8List color = Uint8List(width * height * colorChannels);
  final Uint8List alpha = Uint8List(width * height);
  int c = 0, a = 0, p = 0;
  for (int i = 0; i < width * height; i++) {
    for (int k = 0; k < colorChannels; k++) {
      color[c++] = pixels[p++];
    }
    alpha[a++] = pixels[p++];
  }
  return PdfImageData(
    width: width,
    height: height,
    colorSpace: colorChannels == 3 ? '/DeviceRGB' : '/DeviceGray',
    bitsPerComponent: 8,
    filter: '/FlateDecode',
    data: zlibEncode(color),
    smask: PdfImageData(
      width: width,
      height: height,
      colorSpace: '/DeviceGray',
      bitsPerComponent: 8,
      filter: '/FlateDecode',
      data: zlibEncode(alpha),
    ),
  );
}

Uint8List? _inflateZlib(Uint8List zlib) {
  if (zlib.length < 6) return null;
  if ((zlib[1] & 0x20) != 0) return null; // FDICT não suportado
  try {
    return Inflate(zlib.sublist(2, zlib.length - 4)).getBytes();
  } catch (_) {
    return null;
  }
}

/// Desfaz os filtros PNG (None/Sub/Up/Average/Paeth), bytes de 8 bits.
Uint8List _unfilterScanlines(
  Uint8List raw,
  int width,
  int height,
  int bpp,
) {
  final int stride = width * bpp;
  final Uint8List out = Uint8List(stride * height);
  int inPos = 0;
  for (int row = 0; row < height; row++) {
    final int filter = raw[inPos++];
    final int outRow = row * stride;
    final int prevRow = outRow - stride;
    for (int i = 0; i < stride; i++) {
      final int x = raw[inPos + i];
      final int left = i >= bpp ? out[outRow + i - bpp] : 0;
      final int up = row > 0 ? out[prevRow + i] : 0;
      final int upLeft = (row > 0 && i >= bpp) ? out[prevRow + i - bpp] : 0;
      int value;
      switch (filter) {
        case 1:
          value = x + left;
          break;
        case 2:
          value = x + up;
          break;
        case 3:
          value = x + ((left + up) >> 1);
          break;
        case 4:
          value = x + _paeth(left, up, upLeft);
          break;
        default:
          value = x;
      }
      out[outRow + i] = value & 0xff;
    }
    inPos += stride;
  }
  return out;
}

int _paeth(int a, int b, int c) {
  final int p = a + b - c;
  final int pa = (p - a).abs(), pb = (p - b).abs(), pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  if (pb <= pc) return b;
  return c;
}

int _readUint32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
