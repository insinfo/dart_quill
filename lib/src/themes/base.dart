import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/theme.dart';
import '../modules/clipboard.dart';
import '../modules/history.dart';
import '../modules/keyboard.dart';
import '../modules/toolbar.dart';
import '../modules/uploader.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import '../ui/picker.dart';
import '../ui/tooltip.dart';

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

  @override
  dynamic addModule(String name) {
    if (modules.containsKey(name)) {
      return modules[name];
    }

    final config = options.modules[name];
    switch (name) {
      case 'toolbar':
        final toolbarOptions = _normalizeToolbarOptions(config);
        final toolbar = Toolbar(quill, toolbarOptions);
        modules[name] = toolbar;
        extendToolbar(toolbar);
        _registerToolbarHandlers(toolbar);
        return toolbar;
      case 'keyboard':
        options.modules[name] = _normalizeKeyboardOptions(config);
        break;
      case 'history':
        options.modules[name] = _normalizeHistoryOptions(config);
        break;
      case 'clipboard':
        options.modules[name] = _normalizeClipboardOptions(config);
        break;
      case 'uploader':
        options.modules[name] = _normalizeUploaderOptions(config);
        break;
      default:
        break;
    }
    final module = super.addModule(name);
    return module;
  }

  void extendToolbar(Toolbar toolbar) {}

  void _registerToolbarHandlers(Toolbar toolbar) {
    if (!toolbar.handlers.containsKey('formula')) {
      toolbar.addHandler('formula', (_) {
        final currentTooltip = tooltip;
        if (currentTooltip is BaseTooltip) {
          currentTooltip.edit('formula');
        }
      });
    }
    if (!toolbar.handlers.containsKey('video')) {
      toolbar.addHandler('video', (_) {
        final currentTooltip = tooltip;
        if (currentTooltip is BaseTooltip) {
          currentTooltip.edit('video');
        }
      });
    }
    if (!toolbar.handlers.containsKey('image')) {
      toolbar.addHandler('image', (_) {
        final container = toolbar.container;
        if (container == null) {
          return;
        }

        final uploader = _ensureUploaderModule();
        if (uploader == null) {
          return;
        }

        DomElement? fileInput =
            container.querySelector('input.ql-image[type="file"]');
        if (fileInput == null) {
          final document = container.ownerDocument;
          fileInput = document.createElement('input');
          fileInput.setAttribute('type', 'file');
          fileInput.classes.add('ql-image');
          if (uploader.options.mimetypes.isNotEmpty) {
            fileInput.setAttribute(
              'accept',
              uploader.options.mimetypes.join(', '),
            );
          }
          final style = fileInput.style as dynamic;
          style.display = 'none';
          container.append(fileInput);

          final capturedInput = fileInput;
          fileInput.addEventListener('change', (event) {
            final range = quill.getSelection(focus: true);
            if (range == null) {
              return;
            }

            final currentUploader = _ensureUploaderModule();
            if (currentUploader == null) {
              return;
            }

            final rawEvent = event.rawEvent;
            dynamic fileList;
            if (rawEvent != null) {
              try {
                fileList = (rawEvent as dynamic).target?.files;
              } catch (_) {
                fileList = null;
              }
            }

            final files = <dynamic>[];
            if (fileList is Iterable) {
              for (final file in fileList) {
                files.add(file);
              }
            } else if (fileList != null) {
              files.add(fileList);
            }

            currentUploader.upload(range, files);

            try {
              (rawEvent as dynamic).target?.value = '';
            } catch (_) {
              capturedInput.setAttribute('value', '');
            }
          });
        }

        try {
          final dynamic nativeInput = fileInput;
          nativeInput.click();
        } catch (_) {
          // Ignore environments where programmatic click is unavailable.
        }
      });
    }
  }

  Uploader? _ensureUploaderModule() {
    final existing = modules['uploader'];
    if (existing is Uploader) {
      return existing;
    }
    final uploaderOptions = _normalizeUploaderOptions(options.modules['uploader']);
    final uploader = Uploader(quill, uploaderOptions);
    modules['uploader'] = uploader;
    options.modules['uploader'] = uploaderOptions;
    return uploader;
  }

  ToolbarProps _normalizeToolbarOptions(dynamic config) {
    if (config is ToolbarProps) {
      return config;
    }

    dynamic container;
    Map<String, Handler>? handlers;

    if (config is ToolbarConfig) {
      container = config;
    } else if (config is List) {
      container = ToolbarConfig(
        config
            .map<List<dynamic>>((group) => List<dynamic>.from(group as Iterable))
            .toList(),
      );
    } else if (config is Map) {
      if (config.containsKey('container')) {
        container = config['container'];
      }
      final rawHandlers = config['handlers'];
      if (rawHandlers is Map) {
        handlers = rawHandlers.map((key, value) {
          if (value is Handler) {
            return MapEntry(key as String, value);
          }
          throw ArgumentError('Toolbar handler for "$key" must be a Handler');
        });
      }
    } else if (config != null) {
      container = config;
    }

    if (container is List) {
      container = ToolbarConfig(
        container
            .map<List<dynamic>>((group) => List<dynamic>.from(group as Iterable))
            .toList(),
      );
    }

    return ToolbarProps(
      container: container,
      handlers: handlers,
    );
  }

  KeyboardOptions _normalizeKeyboardOptions(dynamic config) {
    if (config is KeyboardOptions) {
      return config;
    }
    if (config is Map<String, dynamic>) {
      return KeyboardOptions(
        bindings: Map<String, dynamic>.from(
          config['bindings'] is Map<String, dynamic>
              ? config['bindings'] as Map<String, dynamic>
              : const {},
        ),
      );
    }
    return KeyboardOptions(bindings: {});
  }

  HistoryOptions _normalizeHistoryOptions(dynamic config) {
    if (config is HistoryOptions) {
      return config;
    }
    if (config is Map) {
      return HistoryOptions(
        delay: (config['delay'] as int?) ?? HistoryOptions().delay,
        maxStack: (config['maxStack'] as int?) ?? HistoryOptions().maxStack,
        userOnly: (config['userOnly'] as bool?) ?? HistoryOptions().userOnly,
      );
    }
    return HistoryOptions();
  }

  ClipboardOptions _normalizeClipboardOptions(dynamic config) {
    if (config is ClipboardOptions) {
      return config;
    }
    if (config is Map) {
      final matchers = config['matchers'];
      return ClipboardOptions(
        matchers: matchers is List ? List<dynamic>.from(matchers) : const [],
      );
    }
    return ClipboardOptions();
  }

  UploaderOptions _normalizeUploaderOptions(dynamic config) {
    return UploaderOptions.fromConfig(config);
  }

  String? _detectFormat(DomElement element) {
    for (final className in element.classes.values) {
      if (className.startsWith('ql-')) {
        return className.substring('ql-'.length);
      }
    }
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

  void buildPickers(
      Toolbar toolbar, List<DomElement> selects, Map<String, dynamic> icons) {
    pickers = [];
    selects.forEach((select) {
      final format = _detectFormat(select);
      if (format == null) {
        return;
      }

      Picker picker;
      if (select.classes.contains('ql-align')) {
        if (select.querySelector('option') == null) {
          fillSelect(select, ALIGNS);
        }
        picker = IconPicker(select, icons['align'] as Map<String, String>? ?? {});
      } else if (select.classes.contains('ql-background') || select.classes.contains('ql-color')) {
        final pickerFormat = select.classes.contains('ql-background') ? 'background' : 'color';
        if (select.querySelector('option') == null) {
          fillSelect(select, COLORS, pickerFormat == 'background');
        }
        picker = ColorPicker(select, icons[pickerFormat] as String?);
      } else {
        if (select.querySelector('option') == null) {
          if (select.classes.contains('ql-font')) {
            fillSelect(select, FONTS);
          } else if (select.classes.contains('ql-header')) {
            fillSelect(select, HEADERS);
          } else if (select.classes.contains('ql-size')) {
            fillSelect(select, SIZES);
          }
        }
        picker = Picker(select);
      }

      picker.onSelected = (value) {
        toolbar.applyFromPicker(select, format, value);
      };
      pickers!.add(picker);
    });

    final updatePickers = () {
      pickers!.forEach((picker) {
        picker.update();
      });
    };
    quill.emitter
        .on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) => updatePickers());
  }
}

class BaseTooltip extends Tooltip {
  DomElement? textbox;
  Range? linkRange;
  bool _editing = false;

  BaseTooltip(Quill quill, String template, [DomElement? boundsContainer])
      : super(quill, boundsContainer, template) {
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
    show();
    root.classes.add('ql-editing');
    _editing = true;
    if (textbox == null) return;

    if (preview != null) {
      textbox!.setAttribute('value', preview);
    } else if (mode != root.getAttribute('data-mode')) {
      textbox!.setAttribute('value', '');
    }
    textbox!.select();
    final savedRange = quill.selection.savedRange;
    if (savedRange != null) {
      final bounds = quill.getBounds(savedRange.index, savedRange.length);
      if (bounds != null) {
        position(bounds);
      }
    }
    textbox!.setAttribute('placeholder', textbox!.getAttribute('data-$mode') ?? '');
    root.setAttribute('data-mode', mode);
  }

  void restoreFocus() {
    quill.focus(preventScroll: true);
  }

  bool get isEditing => _editing;

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

  @override
  void hide() {
    _editing = false;
    super.hide();
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
