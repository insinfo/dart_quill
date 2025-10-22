import 'dart:html';

import 'package:quill_delta/quill_delta.dart';

import '../../core/quill.dart';
import '../blots/link.dart';
import '../core/selection.dart';
import '../modules/toolbar.dart';
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

  late final HtmlElement preview;
  late final Range linkRange;

  SnowTooltip(Quill quill, Bounds bounds) : super(quill, bounds) {
    preview = root.querySelector('a.ql-preview') as HtmlElement;
    listen();
  }

  void listen() {
    super.listen();
    (root.querySelector('a.ql-action') as HtmlElement).onClick.listen((event) {
      if (root.classes.contains('ql-editing')) {
        save();
      } else {
        edit('link', preview.text);
      }
      event.preventDefault();
    });

    (root.querySelector('a.ql-remove') as HtmlElement).onClick.listen((event) {
      if (linkRange != null) {
        final range = linkRange;
        restoreFocus();
        quill.formatText(range.index, range.length, 'link', false, Quill.sources.USER);
        // delete this.linkRange;
      }
      event.preventDefault();
      hide();
    });

    quill.on(Quill.events.SELECTION_CHANGE, (range, oldRange, source) {
      if (range == null) return;
      if (range.length == 0 && source == Quill.sources.USER) {
        final link = quill.scroll.descendant(LinkBlot, range.index);
        if (link != null) {
          linkRange = Range(range.index - link.offset, link.length());
          final previewText = LinkBlot.formats(link.domNode);
          preview.text = previewText;
          preview.setAttribute('href', previewText);
          show();
          final bounds = quill.getBounds(linkRange);
          if (bounds != null) {
            position(bounds);
          }
          return;
        }
      } else {
        // delete this.linkRange;
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

  @override
  void extendToolbar(Toolbar toolbar) {
    if (toolbar.container != null) {
      toolbar.container!.classes.add('ql-snow');
      buildButtons(toolbar.container!.querySelectorAll('button'), icons);
      buildPickers(toolbar.container!.querySelectorAll('select'), icons);
      tooltip = SnowTooltip(quill, options.bounds);
      if (toolbar.container!.querySelector('.ql-link') != null) {
        quill.keyboard.addBinding(
          {'key': 'k', 'shortKey': true},
          (range, context) {
            toolbar.handlers['link'](!context.format.link);
          },
        );
      }
    }
  }
}
