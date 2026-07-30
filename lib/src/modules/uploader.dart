import 'dart:async';

import '../blots/abstract/blot.dart';
import '../core/module.dart';
import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

typedef UploadHandler = FutureOr<void> Function(
  Quill quill,
  Range range,
  List<dynamic> files,
);

/// Parity uploader.ts:55-81 — reads every file as a data URL and inserts all
/// of them with a single `updateContents`, so a multi-file drop/paste is one
/// undo step.
Future<void> defaultUploadHandler(
  Quill quill,
  Range range,
  List<dynamic> files,
) async {
  if (quill.scroll.query('image', Scope.ANY) == null) {
    return;
  }
  final images = <String>[];
  for (final file in files) {
    final dataUrl = await domBindings.adapter.readFileAsDataUrl(file);
    if (dataUrl != null && dataUrl.isNotEmpty) {
      images.add(dataUrl);
    }
  }
  if (images.isEmpty) {
    return;
  }
  final update = Delta()
    ..retain(range.index)
    ..delete(range.length);
  for (final image in images) {
    update.insert({'image': image});
  }
  quill.updateContents(update, source: EmitterSource.USER);
  quill.setSelection(
    Range(range.index + images.length, 0),
    source: EmitterSource.SILENT,
  );
}

class UploaderOptions {
  const UploaderOptions({
    this.mimetypes = const ['image/png', 'image/jpeg'],
    this.handler,
  });

  final List<String> mimetypes;

  /// Custom upload handler; [defaultUploadHandler] is used when null.
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
  Uploader(Quill quill, UploaderOptions options) : super(quill, options) {
    // Parity uploader.ts:17-38.
    quill.root.addEventListener('drop', _handleDrop);
  }

  static const UploaderOptions DEFAULTS = UploaderOptions();

  void _handleDrop(DomEvent event) {
    event.preventDefault();
    final files = _filesFromEvent(event);
    if (files.isEmpty) {
      return;
    }
    // Parity uploader.ts:19-38 — the files land where the pointer dropped
    // them, not at whatever was selected before.
    final range = _dropRange(event) ??
        quill.getSelection(focus: true) ??
        quill.selection.savedRange ??
        Range(quill.getLength() - 1, 0);
    upload(range, files);
  }

  /// The editor range under the drop point, or null when the platform has no
  /// caret-from-point API or the point falls outside the editor.
  Range? _dropRange(DomEvent event) {
    if (event is! DomMouseEvent) return null;
    final native = domBindings.adapter
        .caretRangeFromPoint(event.clientX, event.clientY);
    if (native == null) return null;
    final normalized = quill.selection.normalizeNative(native);
    if (normalized == null) return null;
    return quill.selection.normalizedToRange(normalized);
  }

  List<dynamic> _filesFromEvent(DomEvent event) {
    if (event is DomInputEvent) {
      return event.dataTransfer?.files ?? const <DomFile>[];
    }
    if (event is DomClipboardEvent) {
      return event.clipboardData?.files ?? const <DomFile>[];
    }
    // A drop is a DragEvent, which the platform layer wraps as a mouse event.
    if (event is DomMouseEvent) {
      return event.dataTransfer?.files ?? const <DomFile>[];
    }
    // Last resort for adapters that hand over an unwrapped event.
    try {
      final transfer = (event.rawEvent as dynamic)?.dataTransfer;
      if (transfer is DomDataTransfer) {
        return transfer.files;
      }
      final files = transfer?.files;
      if (files is List) {
        return files;
      }
    } catch (_) {
      // Raw event does not expose a data transfer: nothing to upload.
    }
    return const <dynamic>[];
  }

  String? _mimetypeOf(dynamic file) {
    if (file is DomFile) {
      return file.type;
    }
    try {
      return (file as dynamic).type as String?;
    } catch (_) {
      return null;
    }
  }

  FutureOr<void> upload(Range range, Iterable<dynamic> rawFiles) {
    // Parity uploader.ts:41-52 — only whitelisted mimetypes are uploaded.
    final uploads = <dynamic>[];
    for (final file in rawFiles) {
      if (file == null) {
        continue;
      }
      final type = _mimetypeOf(file);
      if (type != null && options.mimetypes.contains(type)) {
        uploads.add(file);
      }
    }
    if (uploads.isEmpty) {
      return null;
    }
    final handler = options.handler ?? defaultUploadHandler;
    return handler(quill, range, uploads);
  }
}
