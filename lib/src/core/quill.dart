import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../modules/clipboard.dart';
import '../modules/history.dart';
import '../modules/input.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import 'composition.dart';
import 'editor.dart';
import 'emitter.dart';
import 'instances.dart';
import 'logger.dart' as quill_logger;
import 'selection.dart';
import 'theme.dart';

typedef ThemeBuilder = Theme Function(Quill quill, ThemeOptions options);
typedef ModuleFactory = dynamic Function(Quill quill, dynamic options);

String deltaToSemanticHTML(Delta delta) {
  if (delta.isEmpty) {
    return '<p><br></p>';
  }

  final lines = <_SemanticLine>[];
  var currentLine = _SemanticLine();

  for (final op in delta.operations) {
    if (op.key != Operation.insertKey) {
      continue;
    }
    final attributes = op.attributes ?? const <String, dynamic>{};
    final data = op.data;
    if (data is String) {
      var cursor = 0;
      while (cursor < data.length) {
        final newlineIndex = data.indexOf('\n', cursor);
        final nextIndex = newlineIndex == -1 ? data.length : newlineIndex;
        if (nextIndex > cursor) {
          currentLine.segments.add(
            _SemanticSegment(data.substring(cursor, nextIndex), attributes),
          );
        }
        cursor = nextIndex;
        if (newlineIndex == -1) {
          break;
        }
        currentLine.blockAttributes = Map<String, dynamic>.from(attributes);
        lines.add(currentLine);
        currentLine = _SemanticLine();
        cursor = newlineIndex + 1;
      }
      if (cursor < data.length) {
        // Remaining text without newline
        currentLine.segments.add(
          _SemanticSegment(data.substring(cursor), attributes),
        );
      }
    } else {
      currentLine.segments.add(_SemanticSegment.embed(data, attributes));
    }
  }

  if (currentLine.segments.isNotEmpty ||
      currentLine.blockAttributes.isNotEmpty) {
    lines.add(currentLine);
  }

  return _renderLines(lines);
}

class Quill {
  final DomElement container;
  late final DomElement root;
  late final Scroll scroll;
  final Emitter emitter;
  late final Editor editor;
  late final Selection selection;
  late final Composition composition;
  late final Theme theme;
  late final Keyboard keyboard;
  late final Clipboard clipboard;
  late final History history;
  late final Input input;

  static final Map<String, RegistryEntry> _formatRegistry = {};
  static final Map<String, ModuleFactory> _moduleRegistry = {};
  static final Map<String, ThemeBuilder> _themeRegistry = {
    'default': (quill, options) => Theme(quill, options),
  };
  static final Emitter events = Emitter();
  static const sources = EmitterSource();

  static Iterable<RegistryEntry> get registeredFormats =>
      _formatRegistry.values;

  static void debugMode(quill_logger.DebugLevel? level) {
    quill_logger.setLoggerLevel(level);
  }

  static Quill? find(DomNode node) => quillInstances.get<Quill>(node);

  static void register(dynamic definition, [bool overwrite = false]) {
    if (definition is RegistryEntry) {
      final name = definition.blotName;
      if (!overwrite && _formatRegistry.containsKey(name)) {
        return;
      }
      _formatRegistry[name] = definition;
      return;
    }
    throw ArgumentError(
        'Unsupported registration type: ${definition.runtimeType}');
  }

  static void registerModule(String name, ModuleFactory factory,
      {bool overwrite = false}) {
    if (!overwrite && _moduleRegistry.containsKey(name)) {
      return;
    }
    _moduleRegistry[name] = factory;
  }

  static void registerTheme(String name, ThemeBuilder builder,
      {bool overwrite = false}) {
    if (!overwrite && _themeRegistry.containsKey(name)) {
      return;
    }
    _themeRegistry[name] = builder;
  }

  static dynamic createModule(Quill quill, String name, dynamic options) {
    final factory = _moduleRegistry[name];
    if (factory == null) {
      return null;
    }
    return factory(quill, options);
  }

  static ThemeBuilder _resolveThemeBuilder(String? name) {
    if (name != null && _themeRegistry.containsKey(name)) {
      return _themeRegistry[name]!;
    }
    return _themeRegistry['default']!;
  }

  Quill(this.container, {ThemeOptions? options}) : emitter = Emitter() {
    final doc = container.ownerDocument;
    container.classes.add('ql-container');

    root = doc.createElement('div');
    root.classes.add('ql-editor');
    container.append(root);

    scroll = Scroll(Registry(), root, emitter: emitter);
    for (final entry in _formatRegistry.values) {
      scroll.registry.register(entry);
    }
    editor = Editor(scroll);
    selection = Selection(scroll, emitter);
    composition = Composition(scroll, emitter);

    final mergedOptions = _mergeThemeOptions(options);
    final themeBuilder = _resolveThemeBuilder(mergedOptions.theme);
    theme = themeBuilder(this, mergedOptions);

    final keyboardModule = theme.addModule('keyboard');
    keyboard = (keyboardModule is Keyboard)
        ? keyboardModule
        : Keyboard(this, KeyboardOptions(bindings: {}));
    theme.modules['keyboard'] = keyboard;

    final clipboardModule = theme.addModule('clipboard');
    clipboard = (clipboardModule is Clipboard)
        ? clipboardModule
        : Clipboard(this, ClipboardOptions());
    theme.modules['clipboard'] = clipboard;

    final historyModule = theme.addModule('history');
    history = (historyModule is History)
        ? historyModule
        : History(this, HistoryOptions());
    theme.modules['history'] = history;

    final inputModule = theme.addModule('input');
    input = (inputModule is Input)
        ? inputModule
        : Input(this, const InputOptions());
    theme.modules['input'] = input;

    theme.init();
    quillInstances.register<Quill>(container, this);
  }

  DomElement addContainer(String className, [DomElement? refNode]) {
    final element = container.ownerDocument.createElement('div');
    element.classes.add(className);
    if (refNode != null) {
      container.insertBefore(element, refNode);
    } else {
      container.append(element);
    }
    return element;
  }

  void on(String event, Function handler) {
    emitter.on(event, handler);
  }

  Delta getContents() {
    return editor.getContents();
  }

  dynamic getModule(String name) {
    return theme.modules[name];
  }

  String getSemanticHTML([int index = 0, int length = 0]) {
    final contents = getContents();
    final delta = length <= 0
        ? contents.slice(index)
        : contents.slice(index, index + length);
    return deltaToSemanticHTML(delta);
  }

  String getText([int index = 0, int length = 0]) {
    final contents = getContents();
    final documentLength = _deltaLength(contents);
    final effectiveLength = length <= 0
        ? (documentLength - index).clamp(0, documentLength)
        : length;
    return contents.getPlainText(index, effectiveLength);
  }

  void setContents(Delta delta, {String source = EmitterSource.API}) {
    final before = getContents();
    final currentLength = scroll.length();
    var change = Delta();
    if (currentLength > 0) {
      final deleteDelta = Delta()..delete(currentLength);
      editor.update(deleteDelta, source);
      change = change.concat(deleteDelta);
    }
    if (delta.operations.isNotEmpty) {
      editor.update(delta, source);
      change = change.concat(delta);
    }
    if (change.operations.isEmpty) return;
    emitter.emit(EmitterEvents.TEXT_CHANGE, change, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      change,
      before,
      source,
    );
  }

  void updateContents(Delta delta, {String source = EmitterSource.API}) {
    if (delta.operations.isEmpty) return;
    final before = getContents();
    editor.update(delta, source);
    emitter.emit(EmitterEvents.TEXT_CHANGE, delta, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      delta,
      before,
      source,
    );
  }

  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    return selection.getFormat(index, length);
  }

  Range? getSelection({bool focus = false}) {
    if (focus) {
      this.focus();
    }
    return selection.getRange();
  }

  bool isEnabled() {
    return !root.hasAttribute('disabled');
  }

  void focus({bool preventScroll = false}) {
    final previousScrollTop = preventScroll ? root.scrollTop : null;
    selection.focus();
    if (preventScroll && previousScrollTop != null) {
      root.scrollTop = previousScrollTop;
    }
  }

  bool hasFocus() {
    return selection.hasFocus();
  }

  void format(String name, dynamic value, {String source = EmitterSource.API}) {
    final range = selection.getRange();
    if (range == null) return;
    final before = getContents();
    if (range.length == 0) {
      // Format at cursor position
      scroll.formatAt(range.index, 1, name, value);
    } else {
      // Format selection
      scroll.formatAt(range.index, range.length, name, value);
    }
    final change = Delta()
      ..retain(range.index)
      ..retain(range.length, {name: value});
    editor.update(change, source);
    emitter.emit(EmitterEvents.TEXT_CHANGE, change, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      change,
      before,
      source,
    );
  }

  void setSelection(Range range, {String source = EmitterSource.API}) {
    selection.setSelection(range, source);
  }

  void formatText(int index, int length, String name, dynamic value,
      {String source = EmitterSource.API}) {
    final before = getContents();
    final change = editor.formatText(index, length, name, value);
    emitter.emit(EmitterEvents.TEXT_CHANGE, change, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      change,
      before,
      source,
    );
  }

  void insertEmbed(int index, String embed, dynamic value,
      {String source = EmitterSource.API}) {
    final before = getContents();
    final change = editor.insertEmbed(index, embed, value);
    emitter.emit(EmitterEvents.TEXT_CHANGE, change, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      change,
      before,
      source,
    );
  }

  void insertText(int index, String text,
      {Map<String, dynamic>? formats, String source = EmitterSource.API}) {
    final before = getContents();
    final change = editor.insertText(index, text, formats ?? {});
    emitter.emit(EmitterEvents.TEXT_CHANGE, change, before, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.TEXT_CHANGE,
      change,
      before,
      source,
    );
  }

  Map<String, dynamic>? getBounds(int index, [int length = 0]) {
    final lineEntry = scroll.line(index);
    final line = lineEntry.key;
    if (line == null) {
      return null;
    }

    final lines = scroll.lines();
    final linePosition = lines.indexOf(line);
    if (linePosition == -1) {
      return null;
    }

    const double lineHeight = 20.0;
    final top = linePosition * lineHeight;
    final height = lineHeight;
    final width = root.offsetWidth.toDouble();
    const left = 0.0;

    return {
      'top': top,
      'bottom': top + height,
      'left': left,
      'right': left + width,
      'height': height,
      'width': width,
    };
  }
}

ThemeOptions _mergeThemeOptions(ThemeOptions? options) {
  final modules = <String, dynamic>{
    'keyboard': <String, dynamic>{},
    'history': <String, dynamic>{},
    'clipboard': <String, dynamic>{},
    'input': <String, dynamic>{},
    'uploader': <String, dynamic>{},
  };
  if (options != null) {
    modules.addAll(options.modules);
    return ThemeOptions(
      theme: options.theme,
      bounds: options.bounds,
      modules: modules,
    );
  }
  return ThemeOptions(modules: modules);
}

int _deltaLength(Delta delta) {
  return delta.operations.fold<int>(
    0,
    (length, op) => length + (op.length ?? 0),
  );
}

String _renderSegments(List<_SemanticSegment> segments) {
  final buffer = StringBuffer();
  for (final segment in segments) {
    if (segment.isEmbed) {
      final embedData = segment.embed;
      buffer.write(_renderEmbed(embedData));
      continue;
    }
    if (segment.text.isEmpty) {
      continue;
    }
    buffer.write(_wrapInline(_escapeHtml(segment.text), segment.attributes));
  }
  return buffer.toString();
}

String _resolveBlockTag(Map<String, dynamic> attrs) {
  if (attrs.containsKey('header')) {
    final level = attrs['header'];
    final normalized = (level is int) ? level : int.tryParse('$level') ?? 1;
    return 'h${normalized.clamp(1, 6)}';
  }
  if (attrs.containsKey('blockquote')) {
    return 'blockquote';
  }
  if (attrs.containsKey('code-block')) {
    return 'pre';
  }
  if (attrs.containsKey('align')) {
    return 'div';
  }
  return 'p';
}

String _wrapInline(String text, Map<String, dynamic> attrs) {
  var result = text;
  if (attrs.containsKey('code')) {
    result = '<code>$result</code>';
  }
  if (attrs['bold'] == true) {
    result = '<strong>$result</strong>';
  }
  if (attrs['italic'] == true) {
    result = '<em>$result</em>';
  }
  if (attrs['underline'] == true) {
    result = '<u>$result</u>';
  }
  if (attrs['strike'] == true) {
    result = '<s>$result</s>';
  }
  if (attrs['script'] == 'super') {
    result = '<sup>$result</sup>';
  } else if (attrs['script'] == 'sub') {
    result = '<sub>$result</sub>';
  }
  if (attrs.containsKey('link')) {
    final href = _escapeAttribute('${attrs['link']}');
    result = '<a href="$href">$result</a>';
  }
  final styles = <String>[];
  if (attrs.containsKey('color')) {
    styles.add('color: ${_escapeAttribute('${attrs['color']}')}');
  }
  if (attrs.containsKey('background')) {
    styles
        .add('background-color: ${_escapeAttribute('${attrs['background']}')}');
  }
  if (attrs.containsKey('font')) {
    styles.add('font-family: ${_escapeAttribute('${attrs['font']}')}');
  }
  if (attrs.containsKey('size')) {
    styles.add('font-size: ${_escapeAttribute('${attrs['size']}')}');
  }
  if (styles.isNotEmpty) {
    result = '<span style="${styles.join('; ')}">$result</span>';
  }
  return result;
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _escapeAttribute(String value) {
  return _escapeHtml(value).replaceAll('`', '&#96;');
}

class _SemanticLine {
  final List<_SemanticSegment> segments = [];
  Map<String, dynamic> blockAttributes = <String, dynamic>{};
}

class _SemanticSegment {
  _SemanticSegment(this.text, Map<String, dynamic> attrs)
      : attributes = Map<String, dynamic>.from(attrs),
        embed = null,
        isEmbed = false;

  _SemanticSegment.embed(this.embed, Map<String, dynamic> attrs)
      : attributes = Map<String, dynamic>.from(attrs),
        text = '',
        isEmbed = true;

  final String text;
  final dynamic embed;
  final Map<String, dynamic> attributes;
  final bool isEmbed;
}

String _renderLines(List<_SemanticLine> lines) {
  final buffer = StringBuffer();
  if (lines.isEmpty) {
    return '<p><br></p>';
  }

  final listStack = <_ListState>[];

  for (final line in lines) {
    final blockAttrs = line.blockAttributes;
    final listType = blockAttrs['list'];
    final indent = _parseIndent(blockAttrs['indent']);

    if (listType != null) {
      _adjustListStack(buffer, listStack, '$listType', indent);
      final listItemAttrs =
          _collectBlockAttributes(blockAttrs, forListItem: true);
      buffer.write('<li$listItemAttrs>');
      if (listType == 'checked' || listType == 'unchecked') {
        final checkedAttr = listType == 'checked' ? ' checked="checked"' : '';
        buffer.write('<input type="checkbox" disabled="disabled"$checkedAttr>');
      }
      final rendered = _renderSegments(line.segments);
      if (rendered.isEmpty) {
        buffer.write('<br>');
      } else {
        buffer.write(rendered);
      }
      buffer.write('</li>');
      continue;
    }

    _closeListStack(buffer, listStack);

    final tag = _resolveBlockTag(blockAttrs);
    final blockAttributes = _collectBlockAttributes(blockAttrs);
    buffer.write('<$tag$blockAttributes>');
    final rendered = _renderSegments(line.segments);
    if (blockAttrs.containsKey('code-block')) {
      buffer.write('<code>$rendered</code>');
    } else if (rendered.isEmpty) {
      buffer.write('<br>');
    } else {
      buffer.write(rendered);
    }
    buffer.write('</$tag>');
  }

  _closeListStack(buffer, listStack);
  return buffer.toString();
}

void _adjustListStack(
    StringBuffer buffer, List<_ListState> stack, String listType, int indent) {
  while (stack.length > indent + 1) {
    final closed = stack.removeLast();
    buffer.write('</${closed.tag}>');
  }

  if (stack.isEmpty || stack.length <= indent) {
    for (int level = stack.length; level <= indent; level++) {
      final tag = _listTag(listType);
      final className = _listClass(listType);
      buffer.write('<$tag');
      if (className != null) {
        buffer.write(' class="$className"');
      }
      buffer.write('>');
      stack.add(_ListState(tag, listType, level));
    }
  } else {
    final current = stack.last;
    if (current.type != listType) {
      final closed = stack.removeLast();
      buffer.write('</${closed.tag}>');
      final tag = _listTag(listType);
      final className = _listClass(listType);
      buffer.write('<$tag');
      if (className != null) {
        buffer.write(' class="$className"');
      }
      buffer.write('>');
      stack.add(_ListState(tag, listType, current.indent));
    }
  }
}

void _closeListStack(StringBuffer buffer, List<_ListState> stack) {
  while (stack.isNotEmpty) {
    final closed = stack.removeLast();
    buffer.write('</${closed.tag}>');
  }
}

String _listTag(String listType) {
  switch (listType) {
    case 'ordered':
      return 'ol';
    case 'bullet':
    case 'checked':
    case 'unchecked':
    default:
      return 'ul';
  }
}

String? _listClass(String listType) {
  if (listType == 'checked' || listType == 'unchecked') {
    return 'ql-checklist';
  }
  return null;
}

int _parseIndent(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse('$value') ?? 0;
}

String _collectBlockAttributes(Map<String, dynamic> attrs,
    {bool forListItem = false}) {
  final classes = <String>[];
  final styles = <String>[];

  if (attrs.containsKey('align')) {
    styles.add('text-align: ${_escapeAttribute('${attrs['align']}')}');
  }

  final indent = _parseIndent(attrs['indent']);
  if (indent > 0 && !forListItem) {
    styles.add('margin-left: ${indent * 1.5}em');
  }

  if (attrs.containsKey('direction')) {
    classes.add('ql-direction-${_escapeAttribute('${attrs['direction']}')}');
  }

  if (attrs.containsKey('list')) {
    classes.add('ql-list-${_escapeAttribute('${attrs['list']}')}');
  }

  final buffer = StringBuffer();
  if (classes.isNotEmpty) {
    buffer.write(' class="${classes.join(' ')}"');
  }
  if (styles.isNotEmpty) {
    buffer.write(' style="${styles.join('; ')}"');
  }
  return buffer.toString();
}

String _renderEmbed(dynamic embedData) {
  if (embedData is Map && embedData.isNotEmpty) {
    final entry = embedData.entries.first;
    final type = entry.key;
    final value = entry.value;
    final escapedValue = _escapeAttribute('$value');
    switch (type) {
      case 'image':
        return '<img src="$escapedValue" alt="">';
      case 'video':
        return '<iframe src="$escapedValue" frameborder="0" allowfullscreen="true"></iframe>';
      case 'formula':
        return '<span class="ql-formula" data-value="$escapedValue"></span>';
      default:
        return '<span data-embed="${_escapeAttribute(type)}" data-value="$escapedValue"></span>';
    }
  }
  return '<span data-embed="embed"></span>';
}

class _ListState {
  _ListState(this.tag, this.type, this.indent);

  final String tag;
  final String type;
  final int indent;
}
