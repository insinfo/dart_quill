// Tabler Icons webfont markup. Consumers must load tabler-icons.css.
String _ti(String name) => '<i class="ti ti-$name" aria-hidden="true"></i>';

const String tablerPickerIcon =
    '<i class="ti ti-selector" aria-hidden="true"></i>';

final Map<String, dynamic> tablerIcons = {
  'align': {
    '': _ti('align-left'),
    'center': _ti('align-center'),
    'right': _ti('align-right'),
    'justify': _ti('align-justified'),
  },
  'background': _ti('highlight'),
  'blockquote': _ti('blockquote'),
  'bold': _ti('bold'),
  'clean': _ti('clear-formatting'),
  'code': _ti('code'),
  'code-block': _ti('code'),
  'color': _ti('color-picker'),
  'direction': {
    '': _ti('text-direction-ltr'),
    'rtl': _ti('text-direction-rtl'),
  },
  'formula': _ti('math-function'),
  'header': {
    '1': _ti('h-1'),
    '2': _ti('h-2'),
    '3': _ti('h-3'),
    '4': _ti('h-4'),
    '5': _ti('h-5'),
    '6': _ti('h-6'),
  },
  'italic': _ti('italic'),
  'image': _ti('photo'),
  'indent': {
    '+1': _ti('indent-increase'),
    '-1': _ti('indent-decrease'),
  },
  'link': _ti('link'),
  'list': {
    'bullet': _ti('list'),
    'check': _ti('list-check'),
    'ordered': _ti('list-numbers'),
  },
  'script': {
    'sub': _ti('subscript'),
    'super': _ti('superscript'),
  },
  'strike': _ti('strikethrough'),
  'table': _ti('table'),
  'table-row-above': _ti('row-insert-top'),
  'table-row-below': _ti('row-insert-bottom'),
  'table-column-left': _ti('column-insert-left'),
  'table-column-right': _ti('column-insert-right'),
  'table-delete-row': _ti('row-remove'),
  'table-delete-column': _ti('column-remove'),
  'table-delete': _ti('table-off'),
  'underline': _ti('underline'),
  'video': _ti('video'),
};
