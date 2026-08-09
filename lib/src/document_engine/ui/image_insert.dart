/// Inserir → Imagens: do arquivo escolhido ao nó `image` do documento.
///
/// O tamanho inicial NÃO pode ser um chute. Uma imagem inserida com largura
/// arbitrária obriga o usuário a redimensionar toda vez, e no Word ela entra
/// no tamanho natural (limitado à área útil da página). Por isso lemos as
/// dimensões reais do arquivo — só o cabeçalho, sem decodificar os pixels —
/// e convertemos a 96 dpi, que é a mesma escala que a projeção usa.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../model/index.dart';
import 'controller.dart';

/// Um pixel a 96 dpi em twips (1440 / 96).
const int officeTwipsPerPixel = 15;

/// Extensões que o seletor de arquivo oferece.
const String officeImageAccept = '.png,.jpg,.jpeg,.gif,.bmp,.webp,image/*';

/// Dimensões em PIXELS lidas do cabeçalho do arquivo, ou null quando o
/// formato não é reconhecido (aí o chamador usa um tamanho padrão).
({int width, int height})? imagePixelSize(Uint8List bytes) =>
    _pngSize(bytes) ??
    _jpegSize(bytes) ??
    _gifSize(bytes) ??
    _bmpSize(bytes) ??
    _webpSize(bytes);

/// O MIME do arquivo, pelo conteúdo (assinatura) e não pela extensão — um
/// `.jpg` que na verdade é PNG continua abrindo.
String imageMimeType(Uint8List bytes, {String? fileName}) {
  if (_startsWith(bytes, const [0x89, 0x50, 0x4e, 0x47])) return 'image/png';
  if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (_startsWith(bytes, const [0x47, 0x49, 0x46])) return 'image/gif';
  if (_startsWith(bytes, const [0x42, 0x4d])) return 'image/bmp';
  if (bytes.length > 12 &&
      _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  final extension = (fileName ?? '').toLowerCase();
  if (extension.endsWith('.svg')) return 'image/svg+xml';
  return 'application/octet-stream';
}

/// Insere a imagem no cursor, no tamanho natural limitado à área útil.
///
/// O `src` é um data URL: o editor não tem servidor de assets, e o DOCX
/// exportado carrega os bytes de qualquer forma. Devolve a largura/altura em
/// twips efetivamente aplicadas (os testes conferem o encolhimento).
({int widthTwips, int heightTwips}) insertImage(
  OfficeWordController c,
  Uint8List bytes, {
  String? fileName,
}) {
  final size = imagePixelSize(bytes);
  // Sem cabeçalho legível, 4 cm — grande o bastante para se ver e pequeno o
  // bastante para não estourar a página.
  var widthTwips = size == null ? 2268 : size.width * officeTwipsPerPixel;
  var heightTwips = size == null ? 2268 : size.height * officeTwipsPerPixel;
  if (widthTwips <= 0 || heightTwips <= 0) {
    widthTwips = 2268;
    heightTwips = 2268;
  }

  // Limitar à área útil, preservando a proporção: uma foto de câmera tem
  // milhares de pixels e entraria com metros de largura.
  final maximum = c.pageSetup.contentWidthTwips;
  if (maximum > 0 && widthTwips > maximum) {
    heightTwips = (heightTwips * maximum / widthTwips).round();
    widthTwips = maximum;
  }

  final mime = imageMimeType(bytes, fileName: fileName);
  final src = 'data:$mime;base64,${base64Encode(bytes)}';
  final type = c.schema.nodes['image'];
  if (type == null) return (widthTwips: widthTwips, heightTwips: heightTwips);

  c.syncSelection();
  final state = c.view.state;
  final tr = state.tr
    ..replaceSelectionWith(type.create({
      'src': src,
      'width': widthTwips,
      'height': heightTwips,
    }));
  c.dispatch(tr);
  return (widthTwips: widthTwips, heightTwips: heightTwips);
}

/// Abre o seletor de arquivo e insere o que for escolhido.
void pickAndInsertImage(OfficeWordController c) {
  c.adapter.pickFile(officeImageAccept, (name, bytes) {
    insertImage(c, bytes, fileName: name);
  });
}

// -- leitura de cabeçalho ----------------------------------------------------

bool _startsWith(Uint8List bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}

int _uint32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

int _uint32le(Uint8List bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

/// PNG: o IHDR é sempre o primeiro chunk, em offset fixo.
({int width, int height})? _pngSize(Uint8List bytes) {
  if (!_startsWith(bytes, const [0x89, 0x50, 0x4e, 0x47]) ||
      bytes.length < 24) {
    return null;
  }
  return (width: _uint32(bytes, 16), height: _uint32(bytes, 20));
}

/// JPEG: percorre os marcadores até um SOFn (que não seja de tabela).
///
/// Trata as duas irregularidades que aparecem em arquivos reais: sequências
/// de `0xff` como preenchimento entre marcadores, e marcadores SEM segmento
/// de comprimento (SOI, EOI, RSTn), que não podem ser pulados por tamanho.
({int width, int height})? _jpegSize(Uint8List bytes) {
  if (!_startsWith(bytes, const [0xff, 0xd8])) return null;
  var offset = 2;
  while (offset + 1 < bytes.length) {
    if (bytes[offset] != 0xff) {
      offset++;
      continue;
    }
    final marker = bytes[offset + 1];
    if (marker == 0xff) {
      offset++; // byte de preenchimento
      continue;
    }
    // Marcadores autônomos: sem segmento, portanto sem comprimento.
    if (marker == 0xd8 ||
        marker == 0x01 ||
        (marker >= 0xd0 && marker <= 0xd7)) {
      offset += 2;
      continue;
    }
    if (marker == 0xd9) return null; // EOI sem SOF
    if (offset + 3 >= bytes.length) return null;
    final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
    // SOF0..SOF15, exceto DHT (c4), JPG (c8) e DAC (cc).
    final isStartOfFrame = marker >= 0xc0 &&
        marker <= 0xcf &&
        marker != 0xc4 &&
        marker != 0xc8 &&
        marker != 0xcc;
    if (isStartOfFrame) {
      if (offset + 8 >= bytes.length) return null;
      return (
        height: (bytes[offset + 5] << 8) | bytes[offset + 6],
        width: (bytes[offset + 7] << 8) | bytes[offset + 8],
      );
    }
    if (length < 2) return null;
    offset += 2 + length;
  }
  return null;
}

({int width, int height})? _gifSize(Uint8List bytes) {
  if (!_startsWith(bytes, const [0x47, 0x49, 0x46]) || bytes.length < 10) {
    return null;
  }
  return (
    width: bytes[6] | (bytes[7] << 8),
    height: bytes[8] | (bytes[9] << 8),
  );
}

({int width, int height})? _bmpSize(Uint8List bytes) {
  if (!_startsWith(bytes, const [0x42, 0x4d]) || bytes.length < 26) return null;
  final width = _uint32le(bytes, 18);
  final height = _uint32le(bytes, 22);
  // A altura é assinada: negativa significa top-down.
  final signedHeight = height > 0x7fffffff ? 0x100000000 - height : height;
  if (width <= 0 || signedHeight <= 0) return null;
  return (width: width, height: signedHeight);
}

/// WebP: só o formato simples (VP8/VP8L/VP8X), que cobre o que um usuário
/// arrasta para dentro de um documento.
({int width, int height})? _webpSize(Uint8List bytes) {
  if (bytes.length < 30 ||
      !_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46])) {
    return null;
  }
  final chunk = String.fromCharCodes(bytes.sublist(12, 16));
  if (chunk == 'VP8X') {
    final width = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
    final height = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
    return (width: width, height: height);
  }
  if (chunk == 'VP8 ') {
    return (
      width: (bytes[26] | (bytes[27] << 8)) & 0x3fff,
      height: (bytes[28] | (bytes[29] << 8)) & 0x3fff,
    );
  }
  if (chunk == 'VP8L') {
    final bits =
        bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
    return (
      width: (bits & 0x3fff) + 1,
      height: ((bits >> 14) & 0x3fff) + 1,
    );
  }
  return null;
}

/// Um nó `image` avulso (útil para testes e para consumidores que já têm o
/// data URL pronto).
PMNode officeImageNode(
  OfficeWordController c, {
  required String src,
  required int widthTwips,
  required int heightTwips,
}) =>
    c.schema.node('image', {
      'src': src,
      'width': widthTwips,
      'height': heightTwips,
    });
