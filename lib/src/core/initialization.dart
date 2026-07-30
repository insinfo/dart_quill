import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/inline.dart';
import '../blots/text.dart';
import '../formats/abstract/attributor.dart';
import '../formats/align.dart';
import '../formats/background.dart';
import '../formats/bold.dart';
import '../formats/color.dart';
import '../formats/direction.dart';
import '../formats/font.dart';
import '../formats/indent.dart';
import '../formats/size.dart';
import '../formats/blockquote.dart';
import '../formats/code.dart';
import '../formats/formula.dart';
import '../formats/header.dart';
import '../formats/image.dart';
import '../formats/italic.dart';
import '../formats/link.dart';
import '../formats/list.dart';
import '../formats/script.dart';
import '../formats/strike.dart';
import '../formats/underline.dart';
import '../formats/table.dart';
import '../formats/video.dart';
import '../modules/clipboard.dart';
import '../modules/history.dart';
import '../modules/keyboard.dart';
import '../modules/input.dart';
import '../modules/image_resize.dart';
import '../modules/syntax.dart';
import '../modules/table.dart';
import '../modules/table_embed.dart';
import '../modules/ui_node.dart';
import '../modules/uploader.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import '../themes/bubble.dart';
import '../themes/snow.dart';
import 'quill.dart';

bool _initialized = false;

/// Registers default formats, modules, and themes so the editor
/// behaves similarly to the upstream Quill.js defaults.
void initializeQuill() {
  if (_initialized) {
    return;
  }
  _initialized = true;

  _registerModules();
  _registerThemes();
  _registerFormats();
}

void _registerModules() {
  Quill.registerModule('keyboard', (quill, options) {
    final resolved = _resolveKeyboardOptions(options);
    return Keyboard(quill, resolved);
  });

  Quill.registerModule('history', (quill, options) {
    final resolved = _resolveHistoryOptions(options);
    return History(quill, resolved);
  });

  Quill.registerModule('clipboard', (quill, options) {
    final resolved = _resolveClipboardOptions(options);
    return Clipboard(quill, resolved);
  });

  Quill.registerModule('input', (quill, options) {
    final resolved = _resolveInputOptions(options);
    return Input(quill, resolved);
  });

  Quill.registerModule('uploader', (quill, options) {
    final resolved = options is UploaderOptions
        ? options
        : UploaderOptions.fromConfig(options);
    return Uploader(quill, resolved);
  });

  Quill.registerModule('imageResize', (quill, options) {
    final resolved = options is ImageResizeOptions
        ? options
        : ImageResizeOptions.fromConfig(options);
    return ImageResize(quill, resolved);
  });

  Quill.registerModule('table', (quill, options) {
    final resolved =
        options is TableOptions ? options : TableOptions.fromConfig(options);
    return Table(quill, resolved);
  });

  Quill.registerModule('syntax', (quill, options) {
    final resolved =
        options is SyntaxOptions ? options : SyntaxOptions.fromConfig(options);
    return Syntax(quill, resolved);
  });

  Quill.registerModule('uiNode', (quill, options) {
    return UINode(quill, const {});
  });

  // Opt-in module (parity: upstream ships modules/tableEmbed outside the
  // default bundle). Enabling it installs the 'table-embed' Delta handler.
  Quill.registerModule('tableEmbed', (quill, options) {
    TableEmbed.register();
    return TableEmbed(quill, options);
  });
}

void _registerThemes() {
  Quill.registerTheme(
      'bubble', (quill, options) => BubbleTheme(quill, options));
  Quill.registerTheme('snow', (quill, options) => SnowTheme(quill, options));
}

void _registerFormats() {
  final defaults = <RegistryEntry>[
    RegistryEntry(
      blotName: Block.kBlotName,
      scope: Block.kScope,
      tagNames: const [Block.tagName],
      create: ([dynamic value]) {
        if (value is DomElement) return Block(value);
        final node = domBindings.adapter.document.createElement(Block.tagName);
        final block = Block(node);
        if (block.children.isEmpty) {
          block.appendChild(Break.create());
        }
        return block;
      },
    ),
    RegistryEntry(
      blotName: Break.kBlotName,
      scope: Break.kScope,
      tagNames: const [Break.tagName],
      create: ([dynamic value]) =>
          value is DomElement ? Break(value) : Break.create(),
    ),
    RegistryEntry(
      blotName: Cursor.kBlotName,
      scope: Cursor.kScope,
      tagNames: const [Cursor.kTagName],
      classNames: const [Cursor.kClassName],
      create: ([dynamic value]) =>
          value is DomElement ? Cursor(value) : Cursor.create(),
    ),
    RegistryEntry(
      blotName: TextBlot.kBlotName,
      scope: TextBlot.kScope,
      create: ([dynamic value]) => TextBlot.create(value),
    ),
    RegistryEntry(
      blotName: Inline.kBlotName,
      scope: Inline.kScope,
      tagNames: const [Inline.kTagName],
      create: ([dynamic value]) =>
          value is DomElement ? Inline(value) : Inline.create(),
    ),
    RegistryEntry(
      blotName: Bold.kBlotName,
      scope: Bold.kScope,
      tagNames: Bold.kTagNames,
      create: Bold.create,
    ),
    RegistryEntry(
      blotName: Italic.kBlotName,
      scope: Italic.kScope,
      tagNames: Italic.kTagNames,
      create: ([dynamic value]) =>
          value is DomElement ? Italic(value) : Italic.create(),
    ),
    RegistryEntry(
      blotName: Underline.kBlotName,
      scope: Underline.kScope,
      tagNames: const [Underline.kTagName],
      create: ([dynamic value]) =>
          value is DomElement ? Underline(value) : Underline.create(),
    ),
    RegistryEntry(
      blotName: Strike.kBlotName,
      scope: Strike.kScope,
      tagNames: Strike.kTagNames,
      create: ([dynamic value]) =>
          value is DomElement ? Strike(value) : Strike.create(),
    ),
    RegistryEntry(
      blotName: Link.kBlotName,
      scope: Link.kScope,
      tagNames: const [Link.kTagName],
      staticFormats: Link.getFormat,
      create: ([dynamic value]) => value is DomElement
          ? Link(value)
          : Link.create(value?.toString() ?? ''),
    ),
    RegistryEntry(
      blotName: Code.kBlotName,
      scope: Code.kScope,
      tagNames: const [Code.kTagName],
      create: ([dynamic value]) =>
          value is DomElement ? Code(value) : Code.create(),
    ),
    RegistryEntry(
      blotName: CodeBlockContainer.kBlotName,
      scope: CodeBlockContainer.kScope,
      tagNames: const [CodeBlockContainer.kTagName],
      classNames: const [CodeBlockContainer.kClassName],
      create: ([dynamic value]) => value is DomElement
          ? CodeBlockContainer(value)
          : CodeBlockContainer.create(),
    ),
    RegistryEntry(
      blotName: CodeBlock.kBlotName,
      scope: CodeBlock.kScope,
      tagNames: const [CodeBlock.kTagName],
      classNames: const [CodeBlock.kClassName],
      requiredContainerBlotName: CodeBlockContainer.kBlotName,
      // Parity syntax.ts — the code block reports its language; `true` when
      // the syntax module never wrote one.
      staticFormats: (node) => node.getAttribute('data-language') ?? true,
      create: ([dynamic value]) =>
          value is DomElement ? CodeBlock(value) : CodeBlock.create(),
    ),
    RegistryEntry(
      blotName: Blockquote.kBlotName,
      scope: Blockquote.kScope,
      tagNames: const [Blockquote.kTagName],
      staticFormats: (node) => true,
      create: ([dynamic value]) {
        if (value is DomElement) return Blockquote(value);
        final blockquote = Blockquote.create();
        if (blockquote.children.isEmpty) {
          blockquote.appendChild(Break.create());
        }
        return blockquote;
      },
    ),
    RegistryEntry(
      blotName: Header.kBlotName,
      scope: Header.kScope,
      tagNames: Header.kTagNames,
      staticFormats: (node) {
        final level = Header.getLevel(node);
        return level > 0 ? level : null;
      },
      create: ([dynamic value]) {
        if (value is DomElement) return Header(value);
        final node = Header.create(value);
        final header = Header(node);
        if (header.children.isEmpty) {
          header.appendChild(Break.create());
        }
        return header;
      },
    ),
    // Parity list.ts: the container is always an OL and carries no value —
    // the list kind lives in each <li>'s data-list attribute. A pasted <ul>
    // never reaches the registry; the clipboard's matchList converts it.
    RegistryEntry(
      blotName: ListContainer.kBlotName,
      scope: ListContainer.kScope,
      tagNames: const [ListContainer.kTagName],
      create: ListContainer.create,
    ),
    RegistryEntry(
      blotName: ListItem.kBlotName,
      scope: ListItem.kScope,
      tagNames: const [ListItem.kTagName],
      requiredContainerBlotName: ListContainer.kBlotName,
      // Parity list.ts:18-20 — the `<li>` carries its own list style.
      staticFormats: (node) => node.getAttribute('data-list'),
      create: ListItem.create,
    ),
    RegistryEntry(
      blotName: Script.kBlotName,
      scope: Script.kScope,
      tagNames: Script.kTagNames,
      staticFormats: Script.getFormat,
      create: ([dynamic value]) =>
          value is DomElement ? Script(value) : Script.create(value),
    ),
    RegistryEntry(
      blotName: Image.kBlotName,
      scope: Image.kScope,
      tagNames: const [Image.kTagName],
      isEmbed: true,
      staticValue: Image.getValue,
      staticFormats: (node) => Image.getAttributes(node)
        ..removeWhere((_, value) => value == null || value.isEmpty),
      create: ([dynamic value]) {
        if (value is DomElement) return Image(value);
        final node = Image.create(value);
        return Image(node);
      },
    ),
    RegistryEntry(
      blotName: Formula.kBlotName,
      scope: Formula.kScope,
      tagNames: const [Formula.kTagName],
      classNames: const [Formula.kClassName],
      isEmbed: true,
      staticValue: Formula.getValue,
      create: ([dynamic value]) => value is DomElement
          ? Formula(value)
          : Formula(Formula.create(value?.toString() ?? '')),
    ),
    ...tableRegistryEntries(),
    RegistryEntry(
      blotName: Video.kBlotName,
      scope: Scope.BLOCK_BLOT,
      tagNames: const [Video.kTagName],
      classNames: const [Video.kClassName],
      isEmbed: true,
      staticValue: Video.valueDom,
      staticFormats: (node) => Video.formatsDom(node)
        ..removeWhere((_, value) => value == null || value.isEmpty),
      create: ([dynamic value]) {
        if (value is DomElement) return Video(value);
        final source = value?.toString() ?? '';
        return Video.create(source);
      },
    ),
  ];

  for (final entry in defaults) {
    Quill.register(entry);
  }

  // Parity quill.ts: registering `modules/syntax` at load invokes
  // `Syntax.register()` (Quill.register calls a module's static register —
  // quill.ts:175), which overwrites 'code-block' with SyntaxCodeBlock in the
  // GLOBAL registry, syntax module on or off. That is why a standard Quill
  // reports the code block's language (`data-language`, default "plain")
  // instead of `true` — proven by the G10 goldens.
  Syntax.register();

  // Named attributor variants. These exact paths coexist even when multiple
  // variants share the same attrName (e.g. align class/style).
  final attributorNamespaces = <String, Attributor>{
    'attributors/attribute/direction': DirectionAttribute.instance,
    'attributors/class/align': AlignClass.instance,
    'attributors/class/background': BackgroundClass.instance,
    'attributors/class/color': ColorClass.instance,
    'attributors/class/direction': DirectionClass.instance,
    'attributors/class/font': FontClass.instance,
    'attributors/class/size': SizeClass.instance,
    'attributors/style/align': AlignStyle.instance,
    'attributors/style/background': BackgroundStyle.instance,
    'attributors/style/color': ColorStyle.instance,
    'attributors/style/direction': DirectionStyle.instance,
    'attributors/style/font': FontStyleAttributor.instance,
    'attributors/style/size': SizeStyle.instance,
  };
  for (final entry in attributorNamespaces.entries) {
    Quill.registerPath(entry.key, entry.value, overwrite: true);
  }

  // Active default formats, mirroring the second registration map in
  // quill.ts. These are the variants installed into each editor registry.
  Quill.register(AlignClass.instance);
  Quill.register(DirectionClass.instance);
  Quill.register(IndentClass);
  Quill.register(ColorStyle.instance);
  Quill.register(BackgroundStyle.instance);
  Quill.register(FontClass.instance);
  Quill.register(SizeClass.instance);
}

KeyboardOptions _resolveKeyboardOptions(dynamic options) {
  if (options is KeyboardOptions) {
    return options;
  }
  if (options is Map) {
    final rawBindings = options['bindings'];
    if (rawBindings is Map) {
      return KeyboardOptions(
        bindings: Map<String, dynamic>.from(rawBindings),
      );
    }
  }
  return KeyboardOptions(bindings: const <String, dynamic>{});
}

HistoryOptions _resolveHistoryOptions(dynamic options) {
  if (options is HistoryOptions) {
    return options;
  }
  if (options is Map) {
    final defaults = HistoryOptions();
    final delay = options['delay'];
    final maxStack = options['maxStack'];
    final userOnly = options['userOnly'];
    return HistoryOptions(
      delay: delay is int ? delay : defaults.delay,
      maxStack: maxStack is int ? maxStack : defaults.maxStack,
      userOnly: userOnly is bool ? userOnly : defaults.userOnly,
    );
  }
  return HistoryOptions();
}

ClipboardOptions _resolveClipboardOptions(dynamic options) {
  if (options is ClipboardOptions) {
    return options;
  }
  if (options is Map) {
    final matchers = options['matchers'];
    if (matchers is List) {
      return ClipboardOptions(matchers: List<dynamic>.from(matchers));
    }
  }
  return ClipboardOptions();
}

InputOptions _resolveInputOptions(dynamic options) {
  if (options is InputOptions) {
    return options;
  }
  return InputOptions.fromConfig(options);
}
