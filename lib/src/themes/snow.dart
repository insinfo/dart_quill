import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/theme.dart';
import '../formats/link.dart';
import '../modules/keyboard.dart';
import '../modules/toolbar.dart';
import '../platform/dom.dart';
import '../ui/icons.dart';
import '../ui/tabler_icons.dart';
import 'base.dart';

const TOOLBAR_CONFIG = [
  [
    {
      'header': ['1', '2', '3', false]
    }
  ],
  ['bold', 'italic', 'underline', 'link'],
  [
    {'list': 'ordered'},
    {'list': 'bullet'}
  ],
  [
    {'table': '3x3'},
  ],
  ['clean'],
];

final RegExp _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

/// Parity snow.ts:132-138 — the text of the selection becomes the link
/// preview, prefixed with `mailto:` when it looks like an e-mail address.
String snowLinkPreview(String text) {
  if (_emailPattern.hasMatch(text) && !text.startsWith('mailto:')) {
    return 'mailto:$text';
  }
  return text;
}

class SnowTooltip extends BaseTooltip {
  static final TEMPLATE = [
    '<a class="ql-preview" rel="noopener noreferrer" target="_blank" href="about:blank"></a>',
    '<input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL">',
    '<a class="ql-action"></a>',
    '<a class="ql-remove"></a>',
  ].join('');

  late final DomElement? preview;

  SnowTooltip(Quill quill, DomElement? bounds)
      : super(quill, TEMPLATE, bounds) {
    preview = root.querySelector('a.ql-preview');
    // listen() already ran via the BaseTooltip constructor (virtual
    // dispatch); calling it again here duplicated every listener.
  }

  // linkRange lives on BaseTooltip — shadowing it here broke save(), which
  // read the base field and always saw null (formatting the wrong range).

  @override
  void listen() {
    super.listen();
    root.querySelector('a.ql-action')?.addEventListener('click', (event) {
      if (root.classes.contains('ql-editing')) {
        save();
      } else {
        edit('link', preview?.text);
      }
      event.preventDefault();
      event.stopPropagation();
    });

    root.querySelector('a.ql-remove')?.addEventListener('click', (event) {
      if (linkRange != null) {
        restoreFocus();
        quill.formatText(
          linkRange!.index,
          linkRange!.length,
          'link',
          false,
          source: EmitterSource.USER,
        );
        linkRange = null;
      }
      event.preventDefault();
      event.stopPropagation();
      hide();
    });

    quill.on(EmitterEvents.SELECTION_CHANGE, (range, oldRange, source) {
      if (isEditing) return;
      if (range == null) return;
      if (range.length == 0 && source == EmitterSource.USER) {
        final entry =
            quill.scroll.descendant((blot) => blot is Link, range.index);
        final linkBlot = entry.key as Link?;
        if (linkBlot != null) {
          final linkIndex = quill.scroll.offset(linkBlot);
          final length = linkBlot.length();
          linkRange = Range(linkIndex, length);
          final formats = linkBlot.formats();
          final href = formats[Link.kBlotName] as String?;
          if (href != null) {
            preview?.setAttribute('href', href);
            if (preview != null) {
              preview!.text = href;
            }
          } else {
            preview?.removeAttribute('href');
            if (preview != null) {
              preview!.text = '';
            }
          }
          show();
          final bounds = quill.getBounds(linkIndex, length);
          if (bounds != null) {
            position(bounds);
          }
          return;
        }
      } else {
        linkRange = null;
      }
      hide();
    });
  }

  @override
  void show() {
    super.show();
    root.removeAttribute('data-mode');
  }
}

class SnowTheme extends BaseTheme {
  SnowTheme(Quill quill, ThemeOptions options) : super(quill, options) {
    final existingToolbar = options.modules['toolbar'];
    if (existingToolbar is Map<String, dynamic>) {
      existingToolbar.putIfAbsent('container', () => TOOLBAR_CONFIG);
    } else if (existingToolbar == null) {
      options.modules['toolbar'] = <String, dynamic>{
        'container': TOOLBAR_CONFIG,
      };
    }
    quill.container.classes.add('ql-snow');
    if (options.iconTheme == QuillIconTheme.tabler) {
      quill.container.classes.add('ql-icons-tabler');
    }
  }

  @override
  void extendToolbar(Toolbar toolbar) {
    if (toolbar.container != null) {
      toolbar.container!.classes.add('ql-snow');
      final themeIcons =
          options.iconTheme == QuillIconTheme.tabler ? tablerIcons : icons;
      if (options.iconTheme == QuillIconTheme.tabler) {
        toolbar.container!.classes.add('ql-icons-tabler');
      }
      buildButtons(toolbar.container!.querySelectorAll('button'), themeIcons);
      buildPickers(
          toolbar, toolbar.container!.querySelectorAll('select'), themeIcons);
      // Upstream passes options.bounds through; Tooltip defaults to body.
      // Using quill.container here clipped/re-shifted an already
      // container-relative reference rectangle.
      tooltip = SnowTooltip(quill, options.bounds);
      registerThemeHandlers(toolbar);
      if (toolbar.container!.querySelector('.ql-link') != null) {
        quill.keyboard.addBinding(
          {'key': 'k', 'shortKey': true},
          // Parity snow.ts:114-119 — delegate to the link handler with the
          // negated current state instead of duplicating its logic.
          handler: (Range range, Context context) {
            final hasLink = context.format.containsKey(Link.kBlotName);
            toolbar.handlers['link']?.call(!hasLink);
            return true;
          },
        );
      }
      super.extendToolbar(toolbar);
    }
  }

  /// Parity `SnowTheme.DEFAULTS.modules.toolbar.handlers.link`
  /// (snow.ts:124-149). Registered imperatively because this port has no
  /// theme-level DEFAULTS merging for toolbar handlers; user supplied
  /// handlers still win (see [BaseTheme.overridesHandler]).
  void registerThemeHandlers(Toolbar toolbar) {
    if (overridesHandler(toolbar, 'link')) return;
    toolbar.addHandler('link', (value) {
      if (isFalsyHandlerValue(value)) {
        quill.format(Link.kBlotName, false, source: EmitterSource.USER);
        return;
      }
      final range = quill.getSelection();
      if (range == null || range.length == 0) return;
      final preview = snowLinkPreview(quill.getText(range.index, range.length));
      final currentTooltip = tooltip;
      if (currentTooltip is BaseTooltip) {
        currentTooltip.edit('link', preview);
      }
    });
  }
}
