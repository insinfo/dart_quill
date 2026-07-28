import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import 'keyboard.dart' show deleteRange;

const _insertTypes = {'insertText', 'insertReplacementText'};

class InputOptions {
  final bool? listenCompositionBeforeStart;

  const InputOptions({this.listenCompositionBeforeStart});

  factory InputOptions.fromConfig(dynamic config) {
    if (config is InputOptions) {
      return config;
    }
    if (config is Map<String, dynamic>) {
      final value = config['listenCompositionBeforeStart'];
      if (value is bool) {
        return InputOptions(listenCompositionBeforeStart: value);
      }
    }
    return const InputOptions();
  }
}

class Input extends Module<InputOptions> {
  Input(Quill quill, InputOptions options) : super(quill, options) {
    quill.root.addEventListener('beforeinput', _handleBeforeInput);

    final shouldListen =
        options.listenCompositionBeforeStart ?? !_isAndroidUserAgent;
    if (shouldListen) {
      quill.on(EmitterEvents.COMPOSITION_BEFORE_START,
          _handleCompositionBeforeStart);
    }
  }

  bool get _isAndroidUserAgent {
    final agent = domBindings.adapter.userAgent?.toLowerCase();
    if (agent == null) {
      return false;
    }
    return agent.contains('android');
  }

  void _handleBeforeInput(DomEvent event) {
    if (event is! DomInputEvent) {
      return;
    }
    if (event.defaultPrevented) {
      return;
    }
    final inputType = event.inputType;
    if (inputType == null || !_insertTypes.contains(inputType)) {
      return;
    }
    if (quill.composition.isComposing) {
      return;
    }

    final targetRanges = event.getTargetRanges();
    if (targetRanges.isEmpty || targetRanges.first.collapsed) {
      return;
    }
    final text = _extractText(event);
    if (text == null) {
      return;
    }
    final normalized = quill.selection.normalizeNative(targetRanges.first);
    final range = normalized == null
        ? null
        : quill.selection.normalizedToRange(normalized);
    if (_replaceText(range, text)) {
      event.preventDefault();
    }
  }

  void _handleCompositionBeforeStart(dynamic _) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    _replaceText(range, '');
  }

  String? _extractText(DomInputEvent event) {
    final data = event.data;
    if (data != null) {
      return data;
    }
    final transfer = event.dataTransfer;
    if (transfer != null && transfer.types.contains('text/plain')) {
      return transfer.getData('text/plain') ?? '';
    }
    return null;
  }

  bool _replaceText(Range? range, String text) {
    if (range == null || range.length == 0) return false;

    if (text.isNotEmpty) {
      // Native replacement text inherits the first replaced character's
      // formats, matching contenteditable browser behaviour.
      final formats = quill.getFormat(range.index, 1);
      deleteRange(quill: quill, range: range);
      final delta = Delta()
        ..retain(range.index)
        ..insert(text, formats.isEmpty ? null : formats);
      quill.updateContents(delta, source: EmitterSource.USER);
    } else {
      deleteRange(quill: quill, range: range);
    }

    final cursor = Range(range.index + text.length, 0);
    quill.setSelection(cursor, source: EmitterSource.SILENT);
    return true;
  }
}
