import 'dart:math' as math;

import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../formats/abstract/attributor.dart';
import '../modules/clipboard.dart';
import '../modules/history.dart';
import '../modules/input.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import 'composition.dart';
import 'editor.dart';
import 'emitter.dart';
import 'instances.dart';
import 'logger.dart' as quill_logger;
import 'selection.dart';
import 'theme.dart';
import 'utils/scroll_rect_into_view.dart' as scrolling;

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
  static final Map<String, Attributor> _attributorRegistry = {};
  static final Map<String, dynamic> _imports = {};
  static final Map<String, ModuleFactory> _moduleRegistry = {};
  static final Map<String, ThemeBuilder> _themeRegistry = {
    'default': (quill, options) => Theme(quill, options),
  };
  static final Emitter events = Emitter();
  static const sources = EmitterSource();

  static Iterable<RegistryEntry> get registeredFormats =>
      _formatRegistry.values;

  /// Registered definitions keyed by Quill-compatible paths such as
  /// `formats/bold` and `attributors/style/color`.
  static Map<String, dynamic> get registeredDefinitions =>
      Map<String, dynamic>.unmodifiable(_imports);

  /// Dart equivalent of `Quill.import(path)` (`import` is a language keyword).
  static dynamic importDefinition(String path) => _imports[path];

  static void debugMode(quill_logger.DebugLevel? level) {
    quill_logger.setLoggerLevel(level);
  }

  static Quill? find(DomNode node) => quillInstances.get<Quill>(node);

  static void register(dynamic definition, [bool overwrite = false]) {
    if (definition is RegistryEntry) {
      final name = definition.blotName;
      registerPath('formats/$name', definition, overwrite: overwrite);
      return;
    }
    if (definition is Attributor) {
      final name = definition.attrName;
      registerPath('formats/$name', definition, overwrite: overwrite);
      return;
    }
    throw ArgumentError(
        'Unsupported registration type: ${definition.runtimeType}');
  }

  /// Register a definition under an exact Quill import path.
  ///
  /// Attributor namespace entries intentionally do not become the active
  /// format for an editor. Only `formats/*` aliases are installed into its
  /// Parchment registry, matching upstream Quill's registration semantics.
  static void registerPath(
    String path,
    dynamic definition, {
    bool overwrite = false,
  }) {
    if (!overwrite && _imports.containsKey(path)) return;
    _imports[path] = definition;

    if (!path.startsWith('formats/')) return;
    if (definition is RegistryEntry) {
      _formatRegistry[definition.blotName] = definition;
    } else if (definition is Attributor) {
      _attributorRegistry[definition.attrName] = definition;
    }
  }

  static void registerModule(String name, ModuleFactory factory,
      {bool overwrite = false}) {
    if (!overwrite && _moduleRegistry.containsKey(name)) {
      return;
    }
    _moduleRegistry[name] = factory;
    _imports['modules/$name'] = factory;
  }

  static void registerTheme(String name, ThemeBuilder builder,
      {bool overwrite = false}) {
    if (!overwrite && _themeRegistry.containsKey(name)) {
      return;
    }
    _themeRegistry[name] = builder;
    _imports['themes/$name'] = builder;
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
    root.addEventListener('mousedown', (_) => domBindings.adapter.focus(root));
    root.addEventListener('mouseup', (_) => _syncNativeSelection());
    root.addEventListener('keyup', (_) => _syncNativeSelection());

    scroll = Scroll(Registry(), root, emitter: emitter);
    // Editable by default (parity quill.ts, which relies on the
    // contenteditable attribute for isEnabled()).
    scroll.enable();
    for (final entry in _formatRegistry.values) {
      scroll.registry.register(entry);
    }
    for (final attributor in _attributorRegistry.values) {
      scroll.registry.registerAttributor(attributor);
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
    ensureGlobalDomEventBridge();
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

  void off(String event, [Function? handler]) => emitter.off(event, handler);

  void once(String event, Function handler) => emitter.once(event, handler);

  /// When true, USER-sourced edits are accepted even while the editor is
  /// disabled (parity quill.ts `allowReadOnlyEdits`, toggled by
  /// [editReadOnly]).
  bool allowReadOnlyEdits = false;

  /// Parity quill.ts:881-917 — the single funnel for every document
  /// mutation: honours readOnly, captures the old delta, shifts and
  /// re-applies the selection silently, and emits change events only when
  /// something actually changed (TEXT_CHANGE is suppressed for SILENT).
  ///
  /// [index] `null` leaves the selection untouched; [indexFromRange] mirrors
  /// the TS `index === true`. [shift] `null` shifts the range through the
  /// change delta, `0` re-applies it unchanged, other values shift by length.
  Delta modify(
    Delta Function() modifier, {
    String source = EmitterSource.API,
    int? index,
    bool indexFromRange = false,
    int? shift,
  }) {
    if (!isEnabled() && source == EmitterSource.USER && !allowReadOnlyEdits) {
      return Delta();
    }
    final tracksSelection = index != null || indexFromRange;
    var range = tracksSelection ? selection.getRange() : null;
    final oldDelta = editor.getContents();
    final change = modifier();
    if (range != null) {
      final effectiveIndex = indexFromRange ? range.index : index!;
      if (shift == null) {
        range = shiftRangeByDelta(range, change, source);
      } else if (shift != 0) {
        range = shiftRangeByLength(range, effectiveIndex, shift, source);
      }
      setSelection(range, source: EmitterSource.SILENT);
    }
    if (change.operations.isNotEmpty) {
      if (source != EmitterSource.SILENT) {
        emitter.emit(EmitterEvents.TEXT_CHANGE, change, oldDelta, source);
      }
      emitter.emit(
        EmitterEvents.EDITOR_CHANGE,
        EmitterEvents.TEXT_CHANGE,
        change,
        oldDelta,
        source,
      );
    }
    return change;
  }

  /// Parity quill.ts — runs [modifier] with read-only edits temporarily
  /// permitted.
  T editReadOnly<T>(T Function() modifier) {
    allowReadOnlyEdits = true;
    try {
      return modifier();
    } finally {
      allowReadOnlyEdits = false;
    }
  }

  void enable([bool enabled = true]) {
    scroll.enable(enabled);
    if (enabled) {
      container.classes.remove('ql-disabled');
      root.removeAttribute('disabled');
    } else {
      container.classes.add('ql-disabled');
      root.setAttribute('disabled', 'true');
    }
  }

  void disable() => enable(false);

  void blur() {
    selection.clear();
    domBindings.adapter.blur(root);
  }

  int getLength() => scroll.length();

  /// Lines intersecting the range (parity quill.ts `getLines`).
  List<Blot> getLines([int index = 0, int length = 0x7fffffff]) =>
      scroll.lines(index, length);

  /// Drains pending DOM mutations into the model (parity quill.ts `update`).
  void update([String source = EmitterSource.USER]) {
    scroll.update(null, {'source': source});
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
    // Applying a delta that ends in '\n' onto the mandatory empty document
    // leaves an extra trailing line; remove it (quill.ts setContents).
    final newLength = scroll.length();
    if (newLength > 1) {
      final trailingDelete = Delta()
        ..retain(newLength - 1)
        ..delete(1);
      editor.update(trailingDelete, source);
      change = change.concat(trailingDelete);
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

  Delta updateContents(Delta delta, {String source = EmitterSource.API}) {
    if (delta.operations.isEmpty) return Delta();
    return modify(() {
      editor.update(delta, source);
      return delta;
    }, source: source, indexFromRange: true);
  }

  MapEntry<Blot?, int> getLine(int index) {
    return scroll.line(index);
  }

  MapEntry<LeafBlot?, int> getLeaf(int index) {
    return scroll.leaf(index);
  }

  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    return selection.getFormat(index, length);
  }

  Range? getSelection({bool focus = false}) {
    if (focus) {
      this.focus();
    }
    final nativeRange = _syncNativeSelection();
    return nativeRange ?? selection.getRange();
  }

  /// Parity quill.ts — driven by the root's contenteditable state.
  bool isEnabled() => scroll.isEnabled();

  /// Maps a document index to a native (DOM node, offset) pair, mirroring
  /// `Selection.rangeToNative` in quill's selection.ts: the index is clamped
  /// to the last document position and resolved through `scroll.leaf` +
  /// `LeafBlot.position`. [inclusive] is false for range starts and true for
  /// range ends.
  MapEntry<DomNode, int>? _domPosition(int index, {bool inclusive = false}) {
    final scrollLength = scroll.length();
    final clamped = math.min(scrollLength - 1, index);
    final leafEntry = scroll.leaf(clamped);
    final leaf = leafEntry.key;
    if (leaf == null) {
      return null;
    }
    return leaf.position(leafEntry.value, inclusive);
  }

  void focus({bool preventScroll = false}) {
    final previousScrollTop = preventScroll ? root.scrollTop : null;
    domBindings.adapter.focus(root);
    selection.focus();
    final range = selection.getRange() ?? selection.savedRange;
    if (range != null) {
      final start = _domPosition(range.index);
      final end = _domPosition(range.index + range.length, inclusive: true);
      if (start != null && end != null) {
        domBindings.adapter
            .setSelectionByNodes(start.key, start.value, end.key, end.value);
      }
    }
    if (preventScroll && previousScrollTop != null) {
      root.scrollTop = previousScrollTop;
    }
  }

  bool hasFocus() {
    return selection.hasFocus();
  }

  void format(String name, dynamic value, {String source = EmitterSource.API}) {
    // Toolbar actions restore the saved range before calling this method. Use
    // that canonical range instead of re-reading the browser selection, which
    // may already have collapsed onto the first line after the toolbar click.
    final range = selection.getRange();
    if (range == null) return;
    if (scroll.registry.query(name, Scope.BLOCK) != null ||
        scroll.registry.queryAttributor(name, Scope.BLOCK_ATTRIBUTE) != null) {
      formatLine(range.index, range.length, name, value, source: source);
    } else if (range.length == 0) {
      selection.format(name, value);
    } else {
      formatText(range.index, range.length, name, value, source: source);
    }
  }

  /// Removes inline and block formats from the selected range.
  ///
  /// Observable parity with Quill 2's `removeFormat` (block attributes,
  /// including lists and alignment, are cleared along with inline styles),
  /// but implemented by clearing each format by name instead of by the TS
  /// diff-against-plain-text route.
  ///
  /// NOTE: [Editor.removeFormat] IS the faithful diff-based port; switching
  /// this over requires the faithful `applyDelta` (G1.10 pendency) — the
  /// current bespoke `Editor.update` does not apply the `{list: null}`
  /// retain that the diff produces, so lists survive the clean.
  void removeFormat(int index, int length,
      {String source = EmitterSource.API}) {
    if (length <= 0) return;
    final names = <String>{};
    for (final operation
        in getContents().slice(index, index + length).operations) {
      names.addAll(operation.attributes?.keys ?? const <String>[]);
    }
    for (final line in scroll.lines(index, length)) {
      names.addAll(line.formats().keys);
    }
    for (final name in names) {
      if (scroll.registry.query(name, Scope.BLOCK) != null ||
          scroll.registry.queryAttributor(name, Scope.BLOCK_ATTRIBUTE) !=
              null) {
        formatLine(index, length, name, false, source: source);
      } else {
        formatText(index, length, name, false, source: source);
      }
    }
  }

  void setSelection(Range range, {String source = EmitterSource.API}) {
    selection.setSelection(range, source);
    final start = _domPosition(range.index);
    final end = _domPosition(range.index + range.length, inclusive: true);
    if (start != null && end != null) {
      domBindings.adapter
          .setSelectionByNodes(start.key, start.value, end.key, end.value);
    }
    if (source != EmitterSource.SILENT) {
      scrollSelectionIntoView();
    }
  }

  void scrollRectIntoView(
    scrolling.Rect rect, [
    scrolling.ScrollRectIntoViewOptions options =
        const scrolling.ScrollRectIntoViewOptions(),
  ]) {
    scrolling.scrollRectIntoView(root, rect, options);
  }

  /// Scroll the current or last saved selection into the visible viewport.
  void scrollSelectionIntoView([
    scrolling.ScrollRectIntoViewOptions options =
        const scrolling.ScrollRectIntoViewOptions(),
  ]) {
    final range = selection.getRange() ?? selection.savedRange;
    if (range == null) return;
    final bounds = getBounds(range.index, range.length);
    if (bounds != null) {
      scrollRectIntoView(scrolling.Rect.fromMap(bounds), options);
    }
  }

  @Deprecated('Use scrollSelectionIntoView instead.')
  void scrollIntoView() => scrollSelectionIntoView();

  Delta formatLine(int index, int length, String name, dynamic value,
      {String source = EmitterSource.API}) {
    return modify(() => editor.formatLine(index, length, {name: value}),
        source: source, index: index, shift: 0);
  }

  Delta formatText(int index, int length, String name, dynamic value,
      {String source = EmitterSource.API}) {
    return modify(() => editor.formatText(index, length, name, value),
        source: source, index: index, shift: 0);
  }

  Delta insertEmbed(int index, String embed, dynamic value,
      {String source = EmitterSource.API}) {
    return modify(() => editor.insertEmbed(index, embed, value),
        source: source, index: index);
  }

  Delta insertText(int index, String text,
      {Map<String, dynamic>? formats, String source = EmitterSource.API}) {
    return modify(() => editor.insertText(index, text, formats ?? {}),
        source: source, index: index, shift: text.length);
  }

  Delta deleteText(int index, int length, {String source = EmitterSource.API}) {
    return modify(() {
      editor.deleteText(index, length);
      return Delta()
        ..retain(index)
        ..delete(length);
    }, source: source, index: index, shift: -length);
  }

  Range? _syncNativeSelection({String source = EmitterSource.USER}) {
    final nativeRange = domBindings.adapter.getSelectionRange(root);
    if (nativeRange == null) {
      return null;
    }
    final documentLength = scroll.length();
    final normalizedIndex = nativeRange.index.clamp(0, documentLength);
    final normalizedLength =
        nativeRange.length.clamp(0, documentLength - normalizedIndex);
    final range = Range(normalizedIndex, normalizedLength);
    selection.setSelection(range, source);
    return range;
  }

  Map<String, dynamic>? getBounds(int index, [int length = 0]) {
    final start = _domPosition(index);
    final end = _domPosition(index + length, inclusive: true);
    if (start != null && end != null) {
      final nativeBounds = domBindings.adapter.getRangeBounds(
        start.key,
        start.value,
        end.key,
        end.value,
      );
      if (nativeBounds != null) return nativeBounds;
    }

    // Offset-based fallback for non-browser adapters.
    final platformBounds = domBindings.adapter.getBounds(root, index, length);
    if (platformBounds != null) {
      return platformBounds;
    }

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
    'imageResize': <String, dynamic>{},
    'table': <String, dynamic>{},
  };
  if (options != null) {
    modules.addAll(options.modules);
    return ThemeOptions(
      theme: options.theme,
      iconTheme: options.iconTheme,
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

  final dataAttributes = <String>[];
  final codeLanguage = attrs['code-block'];
  if (codeLanguage is String && codeLanguage.isNotEmpty) {
    dataAttributes.add('data-language="${_escapeAttribute(codeLanguage)}"');
  }

  final buffer = StringBuffer();
  if (classes.isNotEmpty) {
    buffer.write(' class="${classes.join(' ')}"');
  }
  if (styles.isNotEmpty) {
    buffer.write(' style="${styles.join('; ')}"');
  }
  if (dataAttributes.isNotEmpty) {
    buffer.write(' ${dataAttributes.join(' ')}');
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
