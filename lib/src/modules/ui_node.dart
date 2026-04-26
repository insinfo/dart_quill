import '../blots/abstract/blot.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/selection.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';

/// How long (in milliseconds) a navigation-key-triggered selection change
/// remains valid. Matches upstream `TTL_FOR_VALID_SELECTION_CHANGE = 100`.
const int kUiNodeSelectionChangeTtl = 100;

/// Returns true when [event] is a navigation shortcut that could move the
/// cursor to the very beginning of a block line (before a `.ql-ui` node).
bool _canMoveCaretBeforeUiNode(DomEvent event) {
  final raw = event.rawEvent as dynamic;
  final key = raw.key as String?;
  if (key == 'ArrowLeft' ||
      key == 'ArrowRight' ||
      key == 'ArrowUp' ||
      key == 'ArrowDown' ||
      key == 'Home') {
    return true;
  }
  // macOS Ctrl+A (move to line start)
  if (key == 'a' && raw.ctrlKey == true) {
    return true;
  }
  return false;
}

/// Port of `quilljs/src/modules/uiNode.ts`.
///
/// Corrects cursor positioning when the caret would land before a `.ql-ui`
/// element (e.g. the bullet / checkbox indicator prepended to list items).
///
/// Browser behaviour:  `[CARET]<div class="ql-ui"></div>[CONTENT]`  →
/// corrected to:       `<div class="ql-ui"></div>[CARET][CONTENT]`
class UINode extends Module<Map<String, Never>> {
  UINode(super.quill, super.options) {
    _handleArrowKeys();
    _handleNavigationShortcuts();
  }

  bool _isListening = false;
  int _selectionChangeDeadline = 0;

  // ---- keyboard bindings --------------------------------------------------

  void _handleArrowKeys() {
    quill.keyboard.addBinding(
      BindingObject(
        key: ['ArrowLeft', 'ArrowRight'],
        offset: 0,
        shiftKey: null,
      ),
      handler: (dynamic range, [dynamic ctx]) {
        // ctx is a Context-like map with 'line' and 'event' entries when the
        // keyboard module is fully implemented.
        if (ctx is! Map) return true;
        final line = ctx['line'];
        final event = ctx['event'] as DomEvent?;
        if (line is! ParentBlot || line.uiNode == null || event == null) {
          return true;
        }

        final raw = event.rawEvent as dynamic;
        final isRtl =
            (line.element.getAttribute('dir') ?? '') == 'rtl';
        final key = raw.key as String?;
        if ((isRtl && key != 'ArrowRight') ||
            (!isRtl && key != 'ArrowLeft')) {
          return true;
        }

        final r = range as Range;
        final shiftKey = raw.shiftKey as bool? ?? false;
        quill.setSelection(
          Range(r.index - 1, r.length + (shiftKey ? 1 : 0)),
          source: EmitterSource.USER,
        );
        return false;
      },
    );
  }

  // ---- navigation shortcut listener ----------------------------------------

  void _handleNavigationShortcuts() {
    quill.root.addEventListener('keydown', (event) {
      if (!event.defaultPrevented && _canMoveCaretBeforeUiNode(event)) {
        _ensureListeningToSelectionChange();
      }
    });
  }

  /// Sets up a one-shot Quill `SELECTION_CHANGE` listener that will correct
  /// the selection if it lands before a `.ql-ui` node.
  ///
  /// We mirror the upstream TTL approach: we only act if the selection change
  /// arrives within [kUiNodeSelectionChangeTtl] ms of the keydown.
  void _ensureListeningToSelectionChange() {
    _selectionChangeDeadline =
        DateTime.now().millisecondsSinceEpoch + kUiNodeSelectionChangeTtl;

    if (_isListening) return;
    _isListening = true;

    void listener([dynamic range, dynamic oldRange, dynamic source]) {
      _isListening = false;
      if (DateTime.now().millisecondsSinceEpoch <=
          _selectionChangeDeadline) {
        _handleSelectionChange();
      }
    }

    quill.emitter.once(EmitterEvents.SELECTION_CHANGE, listener);
  }

  // ---- selection correction ------------------------------------------------

  void _handleSelectionChange() {
    final range = quill.getSelection();
    if (range == null) return;
    // Only act on collapsed cursor at offset 0 within its line.
    if (range.length != 0) return;

    final lineEntry = quill.scroll.line(range.index);
    final line = lineEntry.key;
    if (line is! ParentBlot || line.uiNode == null) return;

    final offsetInLine = lineEntry.value;
    // If the caret is at the very start of the line (before any content).
    if (offsetInLine != 0) return;

    // Advance cursor past the uiNode – in Quill delta terms that means
    // keeping the same absolute index (uiNode has no length in the delta)
    // but we nudge it so the visual cursor appears after the uiNode.
    quill.setSelection(
      Range(range.index, 0),
      source: EmitterSource.SILENT,
    );
  }
}
