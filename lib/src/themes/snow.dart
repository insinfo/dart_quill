import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/theme.dart';
import '../formats/link.dart';
import '../modules/keyboard.dart';
import '../modules/toolbar.dart';
import '../platform/dom.dart';
import '../ui/icons.dart';
import 'base.dart';

const TOOLBAR_CONFIG = [
  [
    {'header': ['1', '2', '3', false]}
  ],
  ['bold', 'italic', 'underline', 'link'],
  [
    {'list': 'ordered'}, 
    {'list': 'bullet'}
  ],
  ['clean'],
];

class SnowTooltip extends BaseTooltip {
  static final TEMPLATE = [
    '<a class="ql-preview" rel="noopener noreferrer" target="_blank" href="about:blank"></a>',
    '<input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL">',
    '<a class="ql-action"></a>',
    '<a class="ql-remove"></a>',
  ].join('');

  late final DomElement? preview;
  Range? linkRange;

  SnowTooltip(Quill quill, DomElement? bounds)
      : super(quill, TEMPLATE, bounds) {
    preview = root.querySelector('a.ql-preview');
    listen();
  }

  void listen() {
    super.listen();
    root.querySelector('a.ql-action')?.addEventListener('click', (event) {
      if (root.classes.contains('ql-editing')) {
        save();
      } else {
        edit('link', preview?.text);
      }
      event.preventDefault();
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
      hide();
    });

    quill.on(EmitterEvents.SELECTION_CHANGE, (range, oldRange, source) {
      if (range == null) return;
      if (range.length == 0 && source == EmitterSource.USER) {
        final entry = quill.scroll.descendant((blot) => blot is Link, range.index);
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
  }

  @override
  void extendToolbar(Toolbar toolbar) {
    if (toolbar.container != null) {
      toolbar.container!.classes.add('ql-snow');
      buildButtons(toolbar.container!.querySelectorAll('button'), icons);
  buildPickers(toolbar, toolbar.container!.querySelectorAll('select'), icons);
      tooltip = SnowTooltip(quill, options.bounds ?? quill.container);
      if (toolbar.container!.querySelector('.ql-link') != null) {
        quill.keyboard.addBinding(
          {'key': 'k', 'shortKey': true},
          handler: (Range range, Context _) {
            final formats = quill.getFormat(range.index, range.length);
            final hasLink = formats.containsKey(Link.kBlotName);
            if (hasLink) {
              quill.format(Link.kBlotName, false, source: EmitterSource.USER);
            } else {
              toolbar.handlers['link']?.call(null);
            }
            return true;
          },
        );
      }
      super.extendToolbar(toolbar);
    }
  }
}
