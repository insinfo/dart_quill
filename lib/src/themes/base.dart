import '../core/quill.dart';
import '../core/emitter.dart';
import '../core/theme.dart';
import '../core/selection.dart';
import '../ui/picker.dart'; // Placeholder
import '../ui/tooltip.dart'; // Placeholder
import '../platform/platform.dart';
import '../platform/dom.dart';

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

const List<dynamic> ALIGNS = [false, 'center', 'right', 'justify'];

const List<String> COLORS = [
  '#000000', '#e60000', '#ff9900', '#ffff00', '#008a00', '#0066cc', '#9933ff', '#ffffff',
  '#facccc', '#ffebcc', '#ffffcc', '#cce8cc', '#cce0f5', '#ebd6ff', '#bbbbbb', '#f06666',
  '#ffc266', '#ffff66', '#66b966', '#66a3e0', '#c285ff', '#888888', '#a10000', '#b26b00',
  '#b2b200', '#006100', '#0047b2', '#6b24b2', '#444444', '#5c0000', '#663d00', '#666600',
  '#003700', '#002966', '#3d1466',
];

const List<dynamic> FONTS = [false, 'serif', 'monospace'];

const List<dynamic> HEADERS = ['1', '2', '3', false];

const List<dynamic> SIZES = ['small', false, 'large', 'huge'];

class BaseTheme extends Theme {
  List<Picker>? pickers;
  Tooltip? tooltip;

  BaseTheme(Quill quill, ThemeOptions options) : super(quill, options) {
    final document = domBindings.adapter.document;
    late DomEventListener listener;
    listener = (DomEvent e) {
      if (!document.body.contains(quill.root)) {
        document.body.removeEventListener('click', listener);
        return;
      }
      if (tooltip != null && !tooltip!.root.contains(e.target) && !quill.hasFocus()) {
        tooltip!.hide();
      }
      if (pickers != null) {
        pickers!.forEach((picker) {
          if (!picker.container.contains(e.target)) {
            picker.close();
          }
        });
      }
    };
    document.body.addEventListener('click', listener);
  }

  dynamic addModule(String name) {
    // TODO: Implement module loading system
    // For now, return null as a placeholder
    return null;
  }

  void buildButtons(List<DomElement> buttons, Map<String, dynamic> icons) {
    buttons.forEach((button) {
      final className = button.getAttribute('class') ?? '';
      className.split(RegExp(r'\s+')).forEach((name) {
        if (!name.startsWith('ql-')) return;
        name = name.substring('ql-'.length);
        if (icons[name] == null) return;
        if (name == 'direction') {
          button.innerHTML = '${icons[name]['']} ${icons[name]['rtl']}';
        } else if (icons[name] is String) {
          button.innerHTML = icons[name];
        } else {
          final value = button.getAttribute('value') ?? '';
          if (value.isNotEmpty && icons[name][value] != null) {
            button.innerHTML = icons[name][value];
          }
        }
      });
    });
  }

  void buildPickers(List<DomElement> selects, Map<String, dynamic> icons) {
    pickers = [];
    selects.forEach((select) {
      final selectElement = select;
      if (selectElement.classes.contains('ql-align')) {
        if (selectElement.querySelector('option') == null) {
          fillSelect(selectElement, ALIGNS);
        }
        if (icons['align'] is Map) {
          pickers!.add(IconPicker(selectElement, icons['align'] as Map<String, String>));
        }
      } else if (selectElement.classes.contains('ql-background') || selectElement.classes.contains('ql-color')) {
        final format = selectElement.classes.contains('ql-background') ? 'background': 'color';
        if (selectElement.querySelector('option') == null) {
          fillSelect(selectElement, COLORS, format == 'background');
        }
        pickers!.add(ColorPicker(selectElement, icons[format] as String));
      } else {
        if (selectElement.querySelector('option') == null) {
          if (selectElement.classes.contains('ql-font')) {
            fillSelect(selectElement, FONTS);
          } else if (selectElement.classes.contains('ql-header')) {
            fillSelect(selectElement, HEADERS);
          } else if (selectElement.classes.contains('ql-size')) {
            fillSelect(selectElement, SIZES);
          }
        }
        // Use ColorPicker as generic picker (no icon needed)
        pickers!.add(ColorPicker(selectElement, null));
      }
    });
    final updatePickers = () {
      pickers!.forEach((picker) {
        picker.update();
      });
    };
    quill.emitter.on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) => updatePickers());
  }
}

class BaseTooltip extends Tooltip {
  DomElement? textbox;
  Range? linkRange;

  BaseTooltip(Quill quill, [DomElement? boundsContainer]) : super(quill, boundsContainer) {
    textbox = root.querySelector('input[type="text"]');
    listen();
  }

  void listen() {
    textbox?.addEventListener('keydown', (event) {
      // Check for key by getting the rawEvent property
      final key = (event.rawEvent as dynamic).key as String?;
      if (key == 'Enter') {
        save();
        event.preventDefault();
      } else if (key == 'Escape') {
        cancel();
        event.preventDefault();
      }
    });
  }

  void cancel() {
    hide();
    restoreFocus();
  }

  void edit([String mode = 'link', String? preview]) {
    root.classes.remove('ql-hidden');
    root.classes.add('ql-editing');
    if (textbox == null) return;

    if (preview != null) {
      textbox!.setAttribute('value', preview);
    } else if (mode != root.getAttribute('data-mode')) {
      textbox!.setAttribute('value', '');
    }
    final savedRange = quill.selection.savedRange;
    if (savedRange != null) {
      final bounds = quill.getBounds(savedRange.index, savedRange.length);
      if (bounds != null) {
        position(bounds);
      }
    }
    // TODO: Add select() method to DomElement interface for text inputs
    textbox!.setAttribute('placeholder', textbox!.getAttribute('data-$mode') ?? '');
    root.setAttribute('data-mode', mode);
  }

  void restoreFocus() {
    quill.focus(preventScroll: true);
  }

  void save() {
    var value = textbox?.getAttribute('value') ?? '';
    switch (root.getAttribute('data-mode')) {
      case 'link':
        final scrollTop = quill.root.scrollTop;
        if (linkRange != null) {
          quill.formatText(linkRange!.index, linkRange!.length, 'link', value, source: EmitterSource.USER);
          linkRange = null;
        } else {
          restoreFocus();
          quill.format('link', value, source: EmitterSource.USER);
        }
        quill.root.scrollTop = scrollTop;
        break;
      case 'video':
        value = extractVideoUrl(value);
        // Fallthrough
        continue _formulaCase;
      _formulaCase:
      case 'formula':
        if (value.isEmpty) break;
        final range = quill.getSelection(focus: true);
        if (range != null) {
          final index = range.index + range.length;
          quill.insertEmbed(index, root.getAttribute('data-mode')!, value, source: EmitterSource.USER);
          if (root.getAttribute('data-mode') == 'formula') {
            quill.insertText(index + 1, ' ', source: EmitterSource.USER);
          }
          quill.setSelection(Range(index + 2, 0), source: EmitterSource.USER);
        }
        break;
      default:
    }
    textbox!.setAttribute('value', '');
    hide();
  }
}

String extractVideoUrl(String url) {
  var match =
      RegExp(r'^(?:(https?):\/\/)?(?:(?:www|m)\.)?youtube\.com\/watch.*v=([a-zA-Z0-9_-]+)').firstMatch(url) ??
          RegExp(r'^(?:(https?):\/\/)?(?:(?:www|m)\.)?youtu\.be\/([a-zA-Z0-9_-]+)').firstMatch(url);
  if (match != null) {
    return '${match.group(1) ?? 'https'}://www.youtube.com/embed/${match.group(2)}?showinfo=0';
  }
  match = RegExp(r'^(?:(https?):\/\/)?(?:www\.)?vimeo\.com\/(\d+)').firstMatch(url);
  if (match != null) {
    return '${match.group(1) ?? 'https'}://player.vimeo.com/video/${match.group(2)}/';
  }
  return url;
}

void fillSelect(DomElement select, List<dynamic> values, [dynamic defaultValue = false]) {
  final document = domBindings.adapter.document;
  values.forEach((value) {
    final option = document.createElement('option');
    if (value == defaultValue) {
      option.setAttribute('selected', 'selected');
    } else {
      option.setAttribute('value', value.toString());
    }
    select.append(option);
  });
}
