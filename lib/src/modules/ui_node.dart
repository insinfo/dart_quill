import '../blots/abstract/blot.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/selection.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

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
  final isMac =
      (domBindings.adapter.platform ?? '').toLowerCase().contains('mac');
  if (isMac && key == 'a' && raw.ctrlKey == true) {
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
      handler: (Range range, Context context) {
        final line = context.line;
        final event = context.event;
        if (line.uiNode == null) {
          return true;
        }

        final isRtl = domBindings.adapter
                .getComputedStyleProperty(line.element, 'direction') ==
            'rtl';
        final raw = event.rawEvent as dynamic;
        final key = event is DomKeyboardEvent ? event.key : raw.key as String?;
        if ((isRtl && key != 'ArrowRight') || (!isRtl && key != 'ArrowLeft')) {
          return true;
        }

        final shiftKey = event is DomKeyboardEvent
            ? event.shiftKey
            : raw.shiftKey as bool? ?? false;
        quill.setSelection(
          Range(
            range.index - 1,
            range.length + (shiftKey ? 1 : 0),
          ),
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

    final document = domBindings.adapter.document;
    late DomEventListener listener;
    listener = (DomEvent event) {
      document.removeEventListener('selectionchange', listener);
      _isListening = false;
      if (DateTime.now().millisecondsSinceEpoch <= _selectionChangeDeadline) {
        _handleSelectionChange();
      }
    };

    document.addEventListener('selectionchange', listener);
  }

  // ---- selection correction ------------------------------------------------

  void _handleSelectionChange() {
    final range = domBindings.adapter.getNativeSelectionRange();
    if (range == null || !range.collapsed || range.startOffset != 0) return;

    final line = quill.scroll.find(range.startContainer, bubble: true).key;
    if (line is! ParentBlot || line.uiNode == null) return;

    final uiNode = line.uiNode!;
    final offset = line.element.childNodes.indexOf(uiNode);
    if (offset < 0) return;
    domBindings.adapter.setSelectionByNodes(
      line.element,
      offset + 1,
      line.element,
      offset + 1,
    );
  }
}
