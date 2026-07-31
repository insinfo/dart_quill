import 'dart:convert';
import 'dart:typed_data';

import 'codecs/zlib/deflate.dart';
import 'codecs/zlib/inflate.dart';
import 'util/crc32.dart';
import 'util/output_memory_stream.dart';

const int _localFileHeaderSignature = 0x04034b50;
const int _centralDirectorySignature = 0x02014b50;
const int _endOfCentralDirectorySignature = 0x06054b50;
const int _dataDescriptorSignature = 0x08074b50;
const int _compressionStored = 0;
const int _compressionDeflate = 8;
const int _utf8Flag = 0x0800;
const int _dataDescriptorFlag = 0x0008;

/// Uma entrada do ZIP.
///
/// Entradas lidas de um arquivo existente guardam o registro local original
/// completo ([_rawLocalRecord]) e o registro do diretório central original
/// ([_rawCentralRecord]). Enquanto a entrada não for modificada, o save
/// re-emite esses bytes **byte a byte** (apenas o offset no diretório central
/// é corrigido) — estratégia de preservação exigida pela decisão D1 do
/// roteiro (round-trip sem corrupção).
class ZipEntry {
  final String name;

  /// Registro local original (header + nome + extra + payload + descriptor).
  Uint8List? _rawLocalRecord;

  /// Registro do diretório central original (sem correção de offset).
  Uint8List? _rawCentralRecord;

  /// Payload comprimido original (view sobre o registro local).
  Uint8List? _rawCompressed;

  int _method = _compressionDeflate;
  int _crc32 = 0;
  int _uncompressedSize = 0;

  /// Conteúdo descomprimido (lazy para entradas originais).
  Uint8List? _content;

  bool _modified;

  ZipEntry._original(this.name) : _modified = false;

  ZipEntry._novo(this.name, Uint8List content)
      : _content = content,
        _modified = true {
    _uncompressedSize = content.length;
  }

  bool get isModified => _modified;

  /// CRC-32 do conteúdo (do diretório central para entradas originais;
  /// recalculado no encode para entradas modificadas).
  int get crc32 => _crc32;

  int get uncompressedSize =>
      _content != null ? _content!.length : _uncompressedSize;

  /// Payload comprimido original, ou `null` se a entrada é nova/modificada.
  Uint8List? get rawCompressed => _modified ? null : _rawCompressed;

  /// Conteúdo descomprimido da entrada (decodifica sob demanda).
  Uint8List get content {
    final cached = _content;
    if (cached != null) return cached;
    final raw = _rawCompressed!;
    final Uint8List decoded;
    if (_method == _compressionStored) {
      decoded = Uint8List.fromList(raw);
    } else if (_method == _compressionDeflate) {
      decoded = Inflate(raw, uncompressedSize: _uncompressedSize).getBytes();
    } else {
      throw UnsupportedError(
          'ZIP compression method $_method is not supported.');
    }
    _content = decoded;
    return decoded;
  }

  set content(Uint8List bytes) {
    _content = bytes;
    _uncompressedSize = bytes.length;
    _modified = true;
    _rawLocalRecord = null;
    _rawCentralRecord = null;
    _rawCompressed = null;
  }
}

/// Container ZIP em Dart puro com preservação byte a byte das entradas
/// intocadas (roteiro_editor_profissional, Fase 1.1 / decisão D1).
class ZipArchive {
  final List<ZipEntry> _entries = [];
  final Map<String, int> _entryIndex = <String, int>{};

  /// Comentário do arquivo (EOCD), preservado no save.
  Uint8List _archiveComment = Uint8List(0);

  ZipArchive();

  List<ZipEntry> get entries => List<ZipEntry>.unmodifiable(_entries);

  List<String> get entryNames =>
      _entries.map((entry) => entry.name).toList(growable: false);

  ZipEntry? findEntry(String name) {
    final index = _entryIndex[name];
    return index == null ? null : _entries[index];
  }

  bool contains(String name) => _entryIndex.containsKey(name);

  /// Conteúdo descomprimido de uma parte, ou `null` se não existe.
  Uint8List? readBytes(String name) => findEntry(name)?.content;

  /// Conteúdo de uma parte decodificado como UTF-8 (com tolerância a BOM).
  String? readString(String name) {
    final bytes = readBytes(name);
    if (bytes == null) return null;
    var start = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf) {
      start = 3;
    }
    return utf8.decode(Uint8List.sublistView(bytes, start));
  }

  /// Adiciona ou substitui uma entrada (marca como modificada).
  void setFile(String name, List<int> content) {
    final bytes = content is Uint8List ? content : Uint8List.fromList(content);
    final existingIndex = _entryIndex[name];
    if (existingIndex != null) {
      _entries[existingIndex].content = bytes;
      return;
    }
    _entryIndex[name] = _entries.length;
    _entries.add(ZipEntry._novo(name, bytes));
  }

  bool removeFile(String name) {
    final index = _entryIndex.remove(name);
    if (index == null) return false;
    _entries.removeAt(index);
    for (final entry in _entryIndex.entries.toList()) {
      if (entry.value > index) _entryIndex[entry.key] = entry.value - 1;
    }
    return true;
  }

  factory ZipArchive.decodeBytes(Uint8List bytes) {
    final archive = ZipArchive();
    if (bytes.isEmpty) return archive;

    final eocdOffset = _findEndOfCentralDirectory(bytes);
    if (eocdOffset < 0) {
      throw const FormatException(
          'Invalid ZIP archive: end of central directory not found.');
    }

    final entryCount = _readUint16(bytes, eocdOffset + 10);
    final centralDirectorySize = _readUint32(bytes, eocdOffset + 12);
    final centralDirectoryOffset = _readUint32(bytes, eocdOffset + 16);
    final commentLengthEocd = _readUint16(bytes, eocdOffset + 20);
    archive._archiveComment = Uint8List.fromList(Uint8List.sublistView(
        bytes, eocdOffset + 22, eocdOffset + 22 + commentLengthEocd));
    final centralDirectoryEnd = centralDirectoryOffset + centralDirectorySize;

    var offset = centralDirectoryOffset;
    for (var index = 0;
        index < entryCount && offset < centralDirectoryEnd;
        index++) {
      final signature = _readUint32(bytes, offset);
      if (signature != _centralDirectorySignature) {
        throw const FormatException(
            'Invalid ZIP archive: unexpected central directory header.');
      }

      final flags = _readUint16(bytes, offset + 8);
      final compressionMethod = _readUint16(bytes, offset + 10);
      final crc32 = _readUint32(bytes, offset + 16);
      final compressedSize = _readUint32(bytes, offset + 20);
      final uncompressedSize = _readUint32(bytes, offset + 24);
      final fileNameLength = _readUint16(bytes, offset + 28);
      final extraFieldLength = _readUint16(bytes, offset + 30);
      final commentLength = _readUint16(bytes, offset + 32);
      final localHeaderOffset = _readUint32(bytes, offset + 42);
      final nameStart = offset + 46;
      final nameEnd = nameStart + fileNameLength;
      final centralRecordEnd = nameEnd + extraFieldLength + commentLength;
      final fileName = _decodeName(bytes, nameStart, nameEnd,
          useUtf8: (flags & _utf8Flag) != 0);

      if (compressedSize == 0xffffffff ||
          uncompressedSize == 0xffffffff ||
          localHeaderOffset == 0xffffffff) {
        throw UnsupportedError('ZIP64 archives are not supported.');
      }

      final localSignature = _readUint32(bytes, localHeaderOffset);
      if (localSignature != _localFileHeaderSignature) {
        throw const FormatException(
            'Invalid ZIP archive: local file header not found.');
      }

      final localFileNameLength = _readUint16(bytes, localHeaderOffset + 26);
      final localExtraFieldLength = _readUint16(bytes, localHeaderOffset + 28);
      final dataStart =
          localHeaderOffset + 30 + localFileNameLength + localExtraFieldLength;
      final dataEnd = dataStart + compressedSize;

      // Registro local completo, incluindo data descriptor se presente.
      var localRecordEnd = dataEnd;
      if ((flags & _dataDescriptorFlag) != 0) {
        if (localRecordEnd + 4 <= bytes.length &&
            _readUint32(bytes, localRecordEnd) == _dataDescriptorSignature) {
          localRecordEnd += 16;
        } else {
          localRecordEnd += 12;
        }
      }

      final entry = ZipEntry._original(fileName)
        .._rawLocalRecord =
            Uint8List.sublistView(bytes, localHeaderOffset, localRecordEnd)
        .._rawCentralRecord =
            Uint8List.sublistView(bytes, offset, centralRecordEnd)
        .._rawCompressed = Uint8List.sublistView(bytes, dataStart, dataEnd)
        .._method = compressionMethod
        .._crc32 = crc32
        .._uncompressedSize = uncompressedSize;

      final existingIndex = archive._entryIndex[fileName];
      if (existingIndex != null) {
        archive._entries[existingIndex] = entry;
      } else {
        archive._entryIndex[fileName] = archive._entries.length;
        archive._entries.add(entry);
      }
      offset = centralRecordEnd;
    }

    return archive;
  }

  /// Serializa o arquivo. Entradas intocadas são re-emitidas byte a byte
  /// (registro local e central originais; só o offset do central é corrigido).
  Uint8List encode() {
    final output = OutputMemoryStream();
    final centralDirectory = OutputMemoryStream();

    for (final entry in _entries) {
      final localHeaderOffset = output.length;

      final rawLocal = entry._rawLocalRecord;
      final rawCentral = entry._rawCentralRecord;
      if (!entry._modified && rawLocal != null && rawCentral != null) {
        output.writeBytes(rawLocal);
        final patched = Uint8List.fromList(rawCentral);
        _writeUint32(patched, 42, localHeaderOffset);
        centralDirectory.writeBytes(patched);
        continue;
      }

      final content = entry.content;
      final nameBytes = Uint8List.fromList(utf8.encode(entry.name));
      final compressedBytes = _compress(content);
      final useCompression = compressedBytes.length < content.length;
      final method = useCompression ? _compressionDeflate : _compressionStored;
      final payload = useCompression ? compressedBytes : content;
      final crc32 = getCrc32(content);
      entry._method = method;
      entry._crc32 = crc32;

      output
        ..writeUint32(_localFileHeaderSignature)
        ..writeUint16(20)
        ..writeUint16(_utf8Flag)
        ..writeUint16(method)
        ..writeUint16(0) // dosTime fixo: output determinístico
        ..writeUint16(0x21) // dosDate fixo (1980-01-01): determinístico
        ..writeUint32(crc32)
        ..writeUint32(payload.length)
        ..writeUint32(content.length)
        ..writeUint16(nameBytes.length)
        ..writeUint16(0)
        ..writeBytes(nameBytes)
        ..writeBytes(payload);

      centralDirectory
        ..writeUint32(_centralDirectorySignature)
        ..writeUint16(20)
        ..writeUint16(20)
        ..writeUint16(_utf8Flag)
        ..writeUint16(method)
        ..writeUint16(0)
        ..writeUint16(0x21)
        ..writeUint32(crc32)
        ..writeUint32(payload.length)
        ..writeUint32(content.length)
        ..writeUint16(nameBytes.length)
        ..writeUint16(0)
        ..writeUint16(0)
        ..writeUint16(0)
        ..writeUint16(0)
        ..writeUint32(0)
        ..writeUint32(localHeaderOffset)
        ..writeBytes(nameBytes);
    }

    final centralDirectoryOffset = output.length;
    final centralDirectoryBytes = centralDirectory.getBytes();
    output.writeBytes(centralDirectoryBytes);

    output
      ..writeUint32(_endOfCentralDirectorySignature)
      ..writeUint16(0)
      ..writeUint16(0)
      ..writeUint16(_entries.length)
      ..writeUint16(_entries.length)
      ..writeUint32(centralDirectoryBytes.length)
      ..writeUint32(centralDirectoryOffset)
      ..writeUint16(_archiveComment.length)
      ..writeBytes(_archiveComment);

    return output.getBytes();
  }
}

Uint8List _compress(Uint8List bytes) {
  final output = OutputMemoryStream();
  Deflate(bytes, output: output);
  return output.getBytes();
}

int _findEndOfCentralDirectory(Uint8List bytes) {
  final lowerBound = bytes.length > 0x10016 ? bytes.length - 0x10016 : 0;
  for (var offset = bytes.length - 22; offset >= lowerBound; offset--) {
    if (_readUint32(bytes, offset) == _endOfCentralDirectorySignature) {
      return offset;
    }
  }
  return -1;
}

String _decodeName(Uint8List bytes, int start, int end,
    {required bool useUtf8}) {
  final slice = Uint8List.sublistView(bytes, start, end);
  if (!useUtf8) return latin1.decode(slice);
  try {
    return utf8.decode(slice);
  } catch (_) {
    return latin1.decode(slice);
  }
}

int _readUint16(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _readUint32(Uint8List bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}
