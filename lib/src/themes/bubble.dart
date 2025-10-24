import 'dart:async';
import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/theme.dart';
import '../modules/toolbar.dart';
import '../platform/dom.dart';
import '../ui/icons.dart';
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

  BubbleTooltip(Quill quill, [DomElement? bounds])
      : super(quill, TEMPLATE, bounds) {
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
  double position(Map<String, dynamic> bounds) {
  final baseShift = super.position(bounds);
  final container = boundsContainer;
    final containerWidth = container.offsetWidth.toDouble();
  final tooltipWidth = root.offsetWidth.toDouble();
  final left = _extract(bounds['left']);
  final rawWidth = _extract(bounds['width']);
  final effectiveWidth = rawWidth == 0 ? tooltipWidth : rawWidth;
  final center = left + effectiveWidth / 2;
    final idealLeft = center - tooltipWidth / 2;
    final maxLeft = containerWidth > tooltipWidth
        ? containerWidth - tooltipWidth
        : 0;
    final clampedLeft = idealLeft.clamp(0, maxLeft.toDouble());
    final style = root.style as dynamic;
    style.left = '${clampedLeft}px';

    final arrowShift = idealLeft - clampedLeft;
    final arrow = root.querySelector('.ql-tooltip-arrow');
    if (arrow != null) {
      final style = arrow.style as dynamic;
      style.marginLeft = '';
      if (baseShift != 0 || arrowShift != 0) {
        final totalShift = baseShift + arrowShift;
        style.marginLeft = '${-totalShift - arrow.offsetWidth / 2}px';
      }
    }

    return baseShift;
  }

  double _extract(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
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
  }

  @override
  void extendToolbar(Toolbar toolbar) {
    final bubbleTooltip = BubbleTooltip(quill, options.bounds ?? quill.container);
    tooltip = bubbleTooltip;
    if (toolbar.container != null) {
      bubbleTooltip.root.append(toolbar.container!);
      buildButtons(toolbar.container!.querySelectorAll('button'), icons);
      buildPickers(toolbar, toolbar.container!.querySelectorAll('select'), icons);
    }
    super.extendToolbar(toolbar);
  }

  static Map<String, dynamic> defaults() => {
        'toolbar': Toolbar.DEFAULTS,
      };
}
