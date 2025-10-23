import 'dart:async';
import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/theme.dart';
import '../modules/toolbar.dart';
import '../platform/dom.dart';
import 'base.dart';

// Utility functions (simplified for now)
Map<String, dynamic> merge(Map<String, dynamic> a, Map<String, dynamic> b) {
  final result = Map<String, dynamic>.from(a);
  b.forEach((key, value) {
    if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
      result[key] = merge(result[key], value);
    } else {
      result[key] = value;
    }
  });
  return result;
}

const TOOLBAR_CONFIG = <List<dynamic>>[
  ['bold', 'italic', 'link'],
  [{'header': 1}, {'header': 2}, 'blockquote'],
];

class BubbleTooltip extends BaseTooltip {
  static const String TEMPLATE = '<span class="ql-tooltip-arrow"></span><div class="ql-tooltip-editor"><input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL"><a class="ql-close"></a></div>';

  BubbleTooltip(Quill quill, [DomElement? bounds]) : super(quill, bounds) {
    quill.on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) {
      if (type != EmitterEvents.SELECTION_CHANGE) return;
      if (range != null && range.length > 0 && source == EmitterSource.USER) {
        show();
        root.style.left = '0px';
        root.style.width = '';
        root.style.width = '${root.offsetWidth}px';
        // Placeholder for quill.getLines and quill.getBounds
        // final lines = quill.getLines(range.index, range.length);
        // if (lines.length == 1) {
        //   final bounds = quill.getBounds(range);
        //   if (bounds != null) {
        //     position(bounds);
        //   }
        // } else {
        //   final lastLine = lines.last;
        //   final index = quill.getIndex(lastLine);
        //   final length = math.min(lastLine.length() - 1, range.index + range.length - index);
        //   final indexBounds = quill.getBounds(Range(index, length));
        //   if (indexBounds != null) {
        //     position(indexBounds);
        //   }
        // }
      } else if (quill.hasFocus()) {
        // TODO: Check if textbox has focus using platform abstraction
        hide();
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

  @override
  void position(Map<String, dynamic> bounds) {
    super.position(bounds);
    // TODO: Calculate shift based on bounds and viewport
    final shift = 0; // Placeholder
    final arrow = root.querySelector('.ql-tooltip-arrow');
    if (arrow != null) {
      final style = arrow.style as dynamic;
      style.marginLeft = '';
      if (shift != 0) {
        style.marginLeft = '${-1 * shift - arrow.offsetWidth / 2}px';
      }
    }
  }
}

class BubbleTheme extends BaseTheme {
  BubbleTheme(Quill quill, ThemeOptions options) : super(quill, options) {
    if (options.modules['toolbar'] != null && options.modules['toolbar']['container'] == null) {
      options.modules['toolbar']['container'] = TOOLBAR_CONFIG;
    }
    quill.container.classes.add('ql-bubble');
  }

  void extendToolbar(Toolbar toolbar) {
    // TODO: Get bounds container from options or use default
    final bubbleTooltip = BubbleTooltip(quill, null);
    tooltip = bubbleTooltip;
    if (toolbar.container != null) {
      bubbleTooltip.root.append(toolbar.container!);
      // Placeholder for buildButtons and buildPickers
      // buildButtons(toolbar.container!.querySelectorAll('button'), icons);
      // buildPickers(toolbar.container!.querySelectorAll('select'), icons);
    }
  }

  // TODO: Implement DEFAULTS properly - cannot access instance in static initializer
  static final DEFAULTS = <String, dynamic>{
    'toolbar': <String, dynamic>{
      'handlers': <String, dynamic>{
        // Handlers need to be created at runtime, not in static context
      },
    },
  };
}
