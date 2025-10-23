import '../core/emitter.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/theme.dart';
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

  SnowTooltip(Quill quill, DomElement? bounds) : super(quill, bounds) {
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
        // TODO: Fix formatText signature - needs 4 positional args
        // quill.formatText(linkRange!.index, linkRange!.length, 'link', false);
        linkRange = null;
      }
      event.preventDefault();
      hide();
    });

    quill.on(EmitterEvents.SELECTION_CHANGE, (range, oldRange, source) {
      if (range == null) return;
      if (range.length == 0 && source == EmitterSource.USER) {
        // TODO: Implement LinkBlot detection when format blots are ready
        /*
        final link = quill.scroll.descendant(LinkBlot, range.index);
        if (link != null) {
          linkRange = Range(range.index - link.offset, link.length());
          final previewText = LinkBlot.formats(link.domNode);
          preview?.text = previewText;
          preview?.setAttribute('href', previewText);
          show();
          final bounds = quill.getBounds(linkRange!);
          if (bounds != null) {
            position(bounds);
          }
          return;
        }
        */
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
    if (options.modules['toolbar'] != null &&
        options.modules['toolbar']['container'] == null) {
      options.modules['toolbar']['container'] = TOOLBAR_CONFIG;
    }
    quill.container.classes.add('ql-snow');
  }

  void extendToolbar(Toolbar toolbar) {
    if (toolbar.container != null) {
      toolbar.container!.classes.add('ql-snow');
      buildButtons(toolbar.container!.querySelectorAll('button'), icons);
      buildPickers(toolbar.container!.querySelectorAll('select'), icons);
      tooltip = SnowTooltip(quill, null); // TODO: Get bounds from options
      if (toolbar.container!.querySelector('.ql-link') != null) {
        quill.keyboard.addBinding(
          {'key': 'k', 'shortKey': true},
          handler: (range) {
            // TODO: Get context to check if link is already set
            toolbar.handlers['link']?.call(false);
          },
        );
      }
    }
  }
}
