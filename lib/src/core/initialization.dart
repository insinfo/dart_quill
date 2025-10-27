import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/text.dart';
import '../formats/bold.dart';
import '../formats/code.dart';
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
import '../modules/table.dart';
import '../modules/uploader.dart';
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

  Quill.registerModule('table', (quill, options) {
    final resolved =
        options is TableOptions ? options : TableOptions.fromConfig(options);
    return Table(quill, resolved);
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
      create: ([dynamic _]) {
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
      create: ([dynamic _]) => Break.create(),
    ),
    RegistryEntry(
      blotName: Cursor.kBlotName,
      scope: Cursor.kScope,
      tagNames: const [Cursor.kTagName],
      classNames: const [Cursor.kClassName],
      create: ([dynamic _]) => Cursor.create(),
    ),
    RegistryEntry(
      blotName: TextBlot.kBlotName,
      scope: TextBlot.kScope,
      create: ([dynamic value]) => TextBlot.create(value),
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
      create: ([dynamic _]) => Italic.create(),
    ),
    RegistryEntry(
      blotName: Underline.kBlotName,
      scope: Underline.kScope,
      tagNames: const [Underline.kTagName],
      create: ([dynamic _]) => Underline.create(),
    ),
    RegistryEntry(
      blotName: Strike.kBlotName,
      scope: Strike.kScope,
      tagNames: Strike.kTagNames,
      create: ([dynamic _]) => Strike.create(),
    ),
    RegistryEntry(
      blotName: Link.kBlotName,
      scope: Link.kScope,
      tagNames: const [Link.kTagName],
      create: ([dynamic value]) => Link.create(value?.toString() ?? ''),
    ),
    RegistryEntry(
      blotName: Code.kBlotName,
      scope: Code.kScope,
      tagNames: const [Code.kTagName],
      create: ([dynamic _]) => Code.create(),
    ),
    RegistryEntry(
      blotName: CodeBlockContainer.kBlotName,
      scope: CodeBlockContainer.kScope,
      tagNames: const [CodeBlockContainer.kTagName],
      classNames: const [CodeBlockContainer.kClassName],
      create: ([dynamic _]) => CodeBlockContainer.create(),
    ),
    RegistryEntry(
      blotName: CodeBlock.kBlotName,
      scope: CodeBlock.kScope,
      tagNames: const [CodeBlock.kTagName],
      classNames: const [CodeBlock.kClassName],
      create: ([dynamic _]) => CodeBlock.create(),
    ),
    RegistryEntry(
      blotName: Header.kBlotName,
      scope: Header.kScope,
      tagNames: Header.kTagNames,
      create: ([dynamic value]) {
        final node = Header.create(value);
        final header = Header(node);
        if (header.children.isEmpty) {
          header.appendChild(Break.create());
        }
        return header;
      },
    ),
    RegistryEntry(
      blotName: ListContainer.kBlotName,
      scope: ListContainer.kScope,
      tagNames: const ['OL', 'UL'],
      create: ([dynamic value]) {
        final resolved = value is String ? value : 'bullet';
        return ListContainer.create(resolved);
      },
    ),
    RegistryEntry(
      blotName: ListItem.kBlotName,
      scope: ListItem.kScope,
      tagNames: const [ListItem.kTagName],
      create: ([dynamic value]) {
        final resolved = value is String ? value : 'bullet';
        return ListItem.create(resolved);
      },
    ),
    RegistryEntry(
      blotName: Script.kBlotName,
      scope: Script.kScope,
      tagNames: Script.kTagNames,
      create: ([dynamic value]) => Script.create(value),
    ),
    RegistryEntry(
      blotName: Image.kBlotName,
      scope: Image.kScope,
      tagNames: const [Image.kTagName],
      create: ([dynamic value]) {
        final node = Image.create(value);
        return Image(node);
      },
    ),
    RegistryEntry(
      blotName: TableContainer.kBlotName,
      scope: TableContainer.kScope,
      tagNames: const [TableContainer.kTagName],
      create: ([dynamic value]) => TableContainer.create(value),
    ),
    RegistryEntry(
      blotName: TableBody.kBlotName,
      scope: TableBody.kScope,
      tagNames: const [TableBody.kTagName],
      create: ([dynamic value]) => TableBody.create(value),
    ),
    RegistryEntry(
      blotName: TableRow.kBlotName,
      scope: TableRow.kScope,
      tagNames: const [TableRow.kTagName],
      create: ([dynamic value]) => TableRow.create(value),
    ),
    RegistryEntry(
      blotName: TableCell.kBlotName,
      scope: TableCell.kScope,
      tagNames: const [TableCell.kTagName],
      create: ([dynamic value]) => TableCell.create(value),
    ),
    RegistryEntry(
      blotName: Video.kBlotName,
      scope: Scope.BLOCK_BLOT,
      tagNames: const [Video.kTagName],
      classNames: const [Video.kClassName],
      create: ([dynamic value]) {
        final source = value?.toString() ?? '';
        return Video.create(source);
      },
    ),
  ];

  for (final entry in defaults) {
    Quill.register(entry);
  }
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
