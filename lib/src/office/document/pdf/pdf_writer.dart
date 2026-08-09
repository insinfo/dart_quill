import 'dart:convert';
import 'dart:typed_data';

import '../zip/codecs/zlib/deflate.dart';
import '../zip/codecs/zlib/inflate.dart';
import 'pdf_image.dart';

// PDF content streams are generated on the browser main isolate. Level 1
// keeps the files compact while avoiding the disproportionate CPU cost of
// the default level 6 on long, table-heavy documents (the TR corpus has 140
// pages). This changes compression only; the decoded PDF operators are
// byte-for-byte identical.
const int _pdfStreamCompressionLevel = DeflateLevel.bestSpeed;

/// Escritor PDF de baixo nível, Dart puro, orientado a objetos indiretos.
///
/// Produz PDF 1.4 com content streams comprimidos (FlateDecode/zlib),
/// fontes standard-14 com WinAnsiEncoding (texto vetorial selecionável e
/// pesquisável) e imagens JPEG/PNG como XObjects.
class PdfWriter {
  PdfWriter() {
    // Objeto 1: catálogo; objeto 2: árvore de páginas (reservados).
    _catalogId = _reserve();
    _pagesId = _reserve();
  }

  final List<Uint8List?> _objects = <Uint8List?>[null]; // índice 0 não usado
  final List<int> _pageIds = <int>[];
  final Map<String, int> _fontIds = <String, int>{};
  final Map<String, String> _fontResourceNames = <String, String>{};

  /// Fontes registradas por nome de recurso (`TT1`, `TT2`, …), usadas pelas
  /// fontes embutidas. Ficam separadas das standard-14, cujo nome (`/F1`) é
  /// derivado da ordem de registro.
  final Map<String, int> _namedFontIds = <String, int>{};
  late final int _catalogId;
  late final int _pagesId;

  int _reserve() {
    _objects.add(null);
    return _objects.length - 1;
  }

  void _set(int id, List<int> body) {
    _objects[id] = body is Uint8List ? body : Uint8List.fromList(body);
  }

  /// Adiciona um objeto dicionário simples; retorna o número do objeto.
  int addDict(String dict) {
    final int id = _reserve();
    _set(id, ascii.encode(dict));
    return id;
  }

  /// Adiciona um objeto stream. Quando [compress] é verdadeiro os dados são
  /// envolvidos em zlib (FlateDecode). [extraEntries] entra no dicionário do
  /// stream (sem /Length e sem /Filter, que são gerados aqui).
  int addStream(
    List<int> data, {
    String extraEntries = '',
    bool compress = true,
    String? rawFilter,
    String? decodeParms,
  }) {
    List<int> payload = data;
    String filter = rawFilter ?? '';
    if (compress && rawFilter == null) {
      payload = zlibEncode(data);
      filter = '/FlateDecode';
    }
    final BytesBuilder body = BytesBuilder(copy: false);
    final StringBuffer dict = StringBuffer('<< ');
    if (extraEntries.isNotEmpty) dict.write('$extraEntries ');
    if (filter.isNotEmpty) dict.write('/Filter $filter ');
    if (decodeParms != null) dict.write('/DecodeParms $decodeParms ');
    dict.write('/Length ${payload.length} >>\nstream\n');
    body
      ..add(ascii.encode(dict.toString()))
      ..add(payload)
      ..add(ascii.encode('\nendstream'));
    final int id = _reserve();
    _set(id, body.takeBytes());
    return id;
  }

  /// Objeto de fonte standard-14 com WinAnsiEncoding (criado uma única vez).
  int fontId(String baseFont) => _fontIds.putIfAbsent(baseFont, () {
        // Preserve the historical `/F1`, `/F2`, ... assignment from the
        // insertion order of `_fontIds`, but cache it once. Text-heavy PDFs
        // ask for the resource name for every run; rebuilding the key list and
        // searching it there made that hot path O(font count) per run.
        _fontResourceNames[baseFont] = '/F${_fontIds.length + 1}';
        return addDict('<< /Type /Font /Subtype /Type1 /BaseFont /$baseFont '
            '/Encoding /WinAnsiEncoding >>');
      });

  /// Nome de recurso da fonte na página (ex.: `/F3`), estável por BaseFont.
  String fontResourceName(String baseFont) {
    fontId(baseFont);
    return _fontResourceNames[baseFont]!;
  }

  /// Associa um nome de recurso (`TT1`) ao objeto de uma fonte já montada.
  ///
  /// É por aqui que uma fonte embutida entra nos `/Resources` da página; o
  /// [fontId] cuida apenas das 14 padrão.
  void registerFontResource(String resourceName, int objectId) {
    final name =
        resourceName.startsWith('/') ? resourceName.substring(1) : resourceName;
    _namedFontIds[name] = objectId;
  }

  /// Registra uma imagem decodificada como XObject; retorna o id do objeto.
  int addImage(PdfImageData image) {
    int? smaskId;
    final PdfImageData? smask = image.smask;
    if (smask != null) {
      smaskId = addStream(
        smask.data,
        extraEntries: '/Type /XObject /Subtype /Image '
            '/Width ${smask.width} /Height ${smask.height} '
            '/ColorSpace /DeviceGray /BitsPerComponent ${smask.bitsPerComponent}',
        compress: false,
        rawFilter: smask.filter,
        decodeParms: smask.decodeParms,
      );
    }
    return addStream(
      image.data,
      extraEntries: '/Type /XObject /Subtype /Image '
          '/Width ${image.width} /Height ${image.height} '
          '/ColorSpace ${image.colorSpace} '
          '/BitsPerComponent ${image.bitsPerComponent}'
          '${smaskId != null ? ' /SMask $smaskId 0 R' : ''}'
          '${image.extraEntries ?? ''}',
      compress: false,
      rawFilter: image.filter,
      decodeParms: image.decodeParms,
    );
  }

  /// Anotação de link URI sobre [rect] (coordenadas PDF, pontos).
  int addLinkAnnotation(List<double> rect, String uri) {
    final String r = rect.map(pdfFormatNumber).join(' ');
    return addDict('<< /Type /Annot /Subtype /Link /Rect [$r] '
        '/Border [0 0 0] /A << /S /URI /URI (${escapePdfString(uri)}) >> >>');
  }

  /// Adiciona uma página. [content] é o content stream (não comprimido);
  /// [xObjects] mapeia nome de recurso (`Im1`) → id do objeto de imagem.
  void addPage({
    required double widthPt,
    required double heightPt,
    required List<int> content,
    Map<String, int> xObjects = const <String, int>{},
    List<int> annotationIds = const <int>[],
  }) {
    final int contentId = addStream(content);
    final StringBuffer resources = StringBuffer('<< ');
    if (_fontIds.isNotEmpty || _namedFontIds.isNotEmpty) {
      resources.write('/Font << ');
      int index = 1;
      for (final int id in _fontIds.values) {
        resources.write('/F$index $id 0 R ');
        index++;
      }
      _namedFontIds.forEach((String name, int id) {
        resources.write('/$name $id 0 R ');
      });
      resources.write('>> ');
    }
    if (xObjects.isNotEmpty) {
      resources.write('/XObject << ');
      xObjects.forEach((String name, int id) {
        resources.write('/$name $id 0 R ');
      });
      resources.write('>> ');
    }
    resources.write('>>');
    final String annots = annotationIds.isEmpty
        ? ''
        : ' /Annots [${annotationIds.map((int id) => '$id 0 R').join(' ')}]';
    final int pageId = addDict('<< /Type /Page /Parent $_pagesId 0 R '
        '/MediaBox [0 0 ${pdfFormatNumber(widthPt)} ${pdfFormatNumber(heightPt)}] '
        '/Resources $resources /Contents $contentId 0 R$annots >>');
    _pageIds.add(pageId);
  }

  /// Serializa o documento completo.
  Uint8List build({
    String title = 'Documento',
    String producer = 'canvas_text_editor',
  }) {
    _set(_catalogId, ascii.encode('<< /Type /Catalog /Pages $_pagesId 0 R >>'));
    _set(
      _pagesId,
      ascii.encode('<< /Type /Pages /Count ${_pageIds.length} '
          '/Kids [${_pageIds.map((int id) => '$id 0 R').join(' ')}] >>'),
    );
    final int infoId = addDict('<< /Title (${escapePdfString(title)}) '
        '/Producer (${escapePdfString(producer)}) >>');

    final BytesBuilder output = BytesBuilder(copy: false);
    void writeAscii(String value) => output.add(ascii.encode(value));
    writeAscii('%PDF-1.4\n');
    output.add(const <int>[0x25, 0xe2, 0xe3, 0xcf, 0xd3, 0x0a]);

    final int count = _objects.length - 1;
    final List<int> offsets = List<int>.filled(count + 1, 0);
    for (int id = 1; id <= count; id++) {
      final Uint8List? body = _objects[id];
      if (body == null) {
        throw StateError('Objeto PDF $id não foi preenchido.');
      }
      offsets[id] = output.length;
      writeAscii('$id 0 obj\n');
      output.add(body);
      writeAscii('\nendobj\n');
    }

    final int xrefOffset = output.length;
    writeAscii('xref\n0 ${count + 1}\n0000000000 65535 f \n');
    for (int id = 1; id <= count; id++) {
      writeAscii('${offsets[id].toString().padLeft(10, '0')} 00000 n \n');
    }
    writeAscii('trailer\n<< /Size ${count + 1} /Root $_catalogId 0 R '
        '/Info $infoId 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');
    return output.takeBytes();
  }
}

/// Número PDF compacto (sem notação científica, até 3 casas).
String pdfFormatNumber(double value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  String text = value.toStringAsFixed(3);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  return text;
}

/// Escapa uma string de texto para literal PDF `(...)` (bytes já WinAnsi ou
/// ASCII). Caracteres fora do intervalo imprimível saem em octal.
String escapePdfString(String value) {
  final StringBuffer out = StringBuffer();
  for (final int unit in value.codeUnits) {
    final int byte = unit & 0xff;
    if (byte == 0x5c) {
      out.write(r'\\');
    } else if (byte == 0x28) {
      out.write(r'\(');
    } else if (byte == 0x29) {
      out.write(r'\)');
    } else if (byte < 0x20 || byte > 0x7e) {
      out.write('\\${byte.toRadixString(8).padLeft(3, '0')}');
    } else {
      out.writeCharCode(byte);
    }
  }
  return out.toString();
}

/// Desfaz [zlibEncode]: valida o header zlib (RFC 1950), descarta o Adler-32
/// e devolve os bytes originais.
///
/// Existe para fechar o par com [zlibEncode]. Sem ele, quem precisa reler um
/// stream `/FlateDecode` (um teste, um inspetor de PDF) descobre do jeito
/// difícil que o [Inflate] embutido consome **deflate cru**, sem header — e
/// alimentá-lo com o payload inteiro devolve zero bytes, em silêncio.
Uint8List zlibDecode(List<int> data) {
  final List<int> bytes = data is Uint8List ? data : Uint8List.fromList(data);
  // CMF/FLG: os 4 bits baixos do CMF são o método de compressão (8 = deflate).
  final bool hasHeader = bytes.length > 6 && (bytes[0] & 0x0f) == 0x08;
  final List<int> deflated = hasHeader
      ? Uint8List.sublistView(bytes as Uint8List, 2, bytes.length - 4)
      : bytes;
  return Inflate(deflated).getBytes();
}

/// Envolve [raw] em zlib (RFC 1950): header + deflate + Adler-32.
Uint8List zlibEncode(List<int> raw) {
  final Uint8List deflated =
      Deflate(raw, level: _pdfStreamCompressionLevel).getBytes();
  final BytesBuilder builder = BytesBuilder(copy: false)
    ..add(const <int>[0x78, 0x9c])
    ..add(deflated);
  final int checksum = adler32(raw);
  builder.add(<int>[
    (checksum >> 24) & 0xff,
    (checksum >> 16) & 0xff,
    (checksum >> 8) & 0xff,
    checksum & 0xff,
  ]);
  return builder.takeBytes();
}

/// Adler-32 (RFC 1950) sobre [data].
int adler32(List<int> data) {
  int a = 1, b = 0;
  for (int i = 0; i < data.length; i++) {
    a += data[i] & 0xff;
    if (a >= 65521) a -= 65521;
    b += a;
    b %= 65521;
  }
  return ((b << 16) | a) & 0xffffffff;
}
