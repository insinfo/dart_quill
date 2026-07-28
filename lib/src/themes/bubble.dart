import 'dart:async';
import 'dart:math' as math;

import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/theme.dart';
import '../modules/toolbar.dart';
import '../platform/dom.dart';
import '../ui/icons.dart';
import '../ui/tabler_icons.dart';
import 'base.dart';

const TOOLBAR_CONFIG = <List<dynamic>>[
  ['bold', 'italic', 'link'],
  [
    {'header': 1},
    {'header': 2},
    'blockquote'
  ],
];

class BubbleTooltip extends BaseTooltip {
  static const String TEMPLATE =
      '<span class="ql-tooltip-arrow"></span><div class="ql-tooltip-editor"><input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL"><a class="ql-close"></a></div>';

  BubbleTooltip(Quill quill, [DomElement? bounds])
      : super(quill, TEMPLATE, bounds) {
    quill.on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) {
      if (type != EmitterEvents.SELECTION_CHANGE) return;
      if (range != null && range.length > 0 && source == EmitterSource.USER) {
        show();
        // Lock our width so we will expand beyond our offsetParent boundaries
        root.style?.left = '0px';
        root.style?.width = '';
        root.style?.width = '${root.offsetWidth}px';
        // Parity bubble.ts:42-59 — `quill.getLines` does not exist in this
        // port; `scroll.lines(index, length)` is its implementation.
        final int rangeIndex = range.index as int;
        final int rangeLength = range.length as int;
        final lines = quill.scroll.lines(rangeIndex, rangeLength);
        if (lines.length <= 1) {
          final bounds = quill.getBounds(rangeIndex, rangeLength);
          if (bounds != null) {
            position(bounds);
          }
        } else {
          final lastLine = lines.last;
          // `quill.getIndex(blot)` is `scroll.offset(blot)` here.
          final index = quill.scroll.offset(lastLine);
          final length = math.min(
            lastLine.length() - 1,
            rangeIndex + rangeLength - index,
          );
          final indexBounds = quill.getBounds(index, length);
          if (indexBounds != null) {
            position(indexBounds);
          }
        }
      } else if (quill.hasFocus()) {
        // TS checks `document.activeElement !== this.textbox`; the platform
        // DOM abstraction exposes no activeElement, so the tooltip's own
        // editing flag stands in for "focus is inside the textbox".
        if (!isEditing) {
          hide();
        }
      }
    });
  }

  @override
  void listen() {
    super.listen();
    root.querySelector('a.ql-close')?.addEventListener('click', (e) {
      root.classes.remove('ql-editing');
    });
    quill.on(EmitterEvents.SCROLL_OPTIMIZE, (mutations, context) {
      // Let selection be restored by toolbar handlers before repositioning
      Timer(Duration(milliseconds: 1), () {
        if (root.classes.contains('ql-hidden')) return;
        final range = quill.getSelection();
        if (range != null) {
          final bounds = quill.getBounds(range.index, range.length);
          if (bounds != null) {
            position(bounds);
          }
        }
      });
    });
  }

  @override
  void cancel() {
    show();
  }

  /// Parity `bubble.ts:95-105` — the arrow compensates the horizontal shift
  /// applied by [Tooltip.position] so it keeps pointing at the selection.
  @override
  double position(Map<String, dynamic> bounds) {
    final shift = super.position(bounds);
    final arrow = root.querySelector('.ql-tooltip-arrow');
    if (arrow != null) {
      arrow.style?.marginLeft = '';
      if (shift != 0) {
        arrow.style?.marginLeft = '${-1 * shift - arrow.offsetWidth / 2}px';
      }
    }
    return shift;
  }
}

class BubbleTheme extends BaseTheme {
  BubbleTheme(Quill quill, ThemeOptions options) : super(quill, options) {
    final toolbarModule = options.modules['toolbar'];
    if (toolbarModule is Map<String, dynamic>) {
      toolbarModule.putIfAbsent('container', () => TOOLBAR_CONFIG);
    } else if (toolbarModule == null) {
      options.modules['toolbar'] = <String, dynamic>{
        'container': TOOLBAR_CONFIG,
      };
    }
    quill.container.classes.add('ql-bubble');
    if (options.iconTheme == QuillIconTheme.tabler) {
      quill.container.classes.add('ql-icons-tabler');
    }
  }

  @override
  void extendToolbar(Toolbar toolbar) {
    final bubbleTooltip =
        BubbleTooltip(quill, options.bounds ?? quill.container);
    tooltip = bubbleTooltip;
    if (toolbar.container != null) {
      bubbleTooltip.root.append(toolbar.container!);
      final themeIcons =
          options.iconTheme == QuillIconTheme.tabler ? tablerIcons : icons;
      if (options.iconTheme == QuillIconTheme.tabler) {
        toolbar.container!.classes.add('ql-icons-tabler');
      }
      buildButtons(toolbar.container!.querySelectorAll('button'), themeIcons);
      buildPickers(
          toolbar, toolbar.container!.querySelectorAll('select'), themeIcons);
    }
    registerThemeHandlers(toolbar);
    super.extendToolbar(toolbar);
  }

  /// Parity `BubbleTheme.DEFAULTS.modules.toolbar.handlers.link`
  /// (bubble.ts:132-147). Registered imperatively because this port has no
  /// theme-level DEFAULTS merging for toolbar handlers; user supplied
  /// handlers still win (see [BaseTheme.overridesHandler]).
  void registerThemeHandlers(Toolbar toolbar) {
    if (overridesHandler(toolbar, 'link')) return;
    toolbar.addHandler('link', (value) {
      if (isFalsyHandlerValue(value)) {
        quill.format('link', false, source: EmitterSource.USER);
      } else {
        final currentTooltip = tooltip;
        if (currentTooltip is BaseTooltip) {
          currentTooltip.edit();
        }
      }
    });
  }
}
