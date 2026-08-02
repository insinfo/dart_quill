import '../model/index.dart';

final Schema testSchema = Schema(SchemaSpec(
  nodes: {
    'doc': NodeSpec(content: 'block+'),
    'paragraph': NodeSpec(content: 'inline*', group: 'block'),
    'blockquote': NodeSpec(content: 'block+', group: 'block', defining: true),
    'heading': NodeSpec(
      attrs: {'level': AttributeSpec(defaultValue: 1)},
      content: 'inline*',
      group: 'block',
      defining: true,
    ),
    'bullet_list': NodeSpec(content: 'list_item+', group: 'block'),
    'ordered_list': NodeSpec(content: 'list_item+', group: 'block'),
    'list_item': NodeSpec(content: 'paragraph block*'),
    'horizontal_rule': NodeSpec(group: 'block'),
    'code_block': NodeSpec(content: 'text*', group: 'block', code: true, defining: true, marks: ''),
    'text': NodeSpec(group: 'inline'),
    'image': NodeSpec(
      inline: true,
      attrs: {
        'src': AttributeSpec(),
        'alt': AttributeSpec(defaultValue: null, hasDefault: true),
        'title': AttributeSpec(defaultValue: null, hasDefault: true)
      },
      group: 'inline',
      draggable: true,
    ),
    'hard_break': NodeSpec(inline: true, group: 'inline', selectable: false)
  },
  marks: {
    'link': MarkSpec(
      attrs: {
        'href': AttributeSpec(),
        'title': AttributeSpec(defaultValue: null, hasDefault: true)
      },
      inclusive: false,
    ),
    'em': MarkSpec(),
    'strong': MarkSpec(),
    'code': MarkSpec()
  }
));
