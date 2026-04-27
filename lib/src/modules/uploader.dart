import 'dart:async';

import '../core/module.dart';
import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/platform.dart';

typedef UploadHandler = FutureOr<void> Function(
  Quill quill,
  Range range,
  List<dynamic> files,
);

class UploaderOptions {
  const UploaderOptions({
    this.mimetypes = const ['image/png', 'image/jpeg'],
    this.handler,
  });

  final List<String> mimetypes;
  final UploadHandler? handler;

  UploaderOptions copyWith({
    List<String>? mimetypes,
    UploadHandler? handler,
  }) {
    return UploaderOptions(
      mimetypes: mimetypes ?? this.mimetypes,
      handler: handler ?? this.handler,
    );
  }

  static UploaderOptions fromConfig(dynamic config) {
    if (config is UploaderOptions) {
      return config;
    }
    if (config is Map) {
      final mimetypes = <String>[];
      final rawMimetypes = config['mimetypes'];
      if (rawMimetypes is Iterable) {
        for (final value in rawMimetypes) {
          if (value != null) {
            mimetypes.add(value.toString());
          }
        }
      }
      final handler = config['handler'];
      return UploaderOptions(
        mimetypes: mimetypes.isEmpty
            ? const ['image/png', 'image/jpeg']
            : List<String>.unmodifiable(mimetypes),
        handler: handler is UploadHandler ? handler : null,
      );
    }
    return const UploaderOptions();
  }
}

class Uploader extends Module<UploaderOptions> {
  Uploader(Quill quill, UploaderOptions options) : super(quill, options);

  FutureOr<void> upload(Range range, Iterable<dynamic> rawFiles) async {
    final accepted = <dynamic>[];
    for (final file in rawFiles) {
      if (options.mimetypes.isEmpty) {
        accepted.add(file);
        continue;
      }
      final type = (file as dynamic)?.type as String?;
      if (type == null || options.mimetypes.contains(type)) {
        accepted.add(file);
      }
    }
    if (accepted.isEmpty) {
      return null;
    }
    final handler = options.handler;
    if (handler != null) {
      return handler(quill, range, accepted);
    }

    if (range.length > 0) {
      quill.updateContents(
        Delta()
          ..retain(range.index)
          ..delete(range.length),
        source: EmitterSource.USER,
      );
    }

    var index = range.index;
    for (final file in accepted) {
      final dataUrl = await domBindings.adapter.readFileAsDataUrl(file);
      if (dataUrl == null || dataUrl.isEmpty) {
        continue;
      }
      quill.insertEmbed(index, 'image', dataUrl, source: EmitterSource.USER);
      index += 1;
    }
    quill.setSelection(Range(index, 0), source: EmitterSource.SILENT);
  }
}
