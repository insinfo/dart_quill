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

  /// Drains pending DOM mutations into the model and reconciles the cached
  /// document delta with the resulting tree (parity quill.ts `update` plus the
  /// SCROLL_UPDATE → `editor.update(null, mutations)` listener).
  ///
  /// Returns the change delta, which is empty whenever the model already
  /// matched the snapshot.
  Delta update([String source = EmitterSource.USER]) {
    scroll.update(null, {'source': source});
    return modify(() => editor.syncFromDocument(), source: source);
  }

  Delta getContents() {
    return editor.getContents();
  }

  dynamic getModule(String name) {
    return theme.modules[name];
  }

  /// Parity quill.ts `getSemanticHTML(index, length)` (543-552): serializes
  /// the blot tree through editor.ts `convertHTML`, not a bespoke
  /// delta-to-HTML pass. Length defaults to the rest of the document.
  String getSemanticHTML([int index = 0, int? length]) {
    final resolved = length ?? (getLength() - index);
    return editor.getHTML(index, resolved);
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

  /// Removes inline and block formats from the range (parity quill.ts).
  ///
  /// Delegates to the faithful [Editor.removeFormat], which diffs the range
  /// against its plain text plus the untouched suffix of the closing line.
  /// The clear-each-format-by-name version that used to live here existed
  /// because that diff could not be applied — it produced a
  /// `retain {list: null}` the bespoke `Editor.update` ignored. With the
  /// faithful `applyDelta` in place, the upstream route works.
  Delta removeFormat(int index, int length,
      {String source = EmitterSource.API}) {
    return modify(
      () => editor.removeFormat(index, length),
      source: source,
      index: index,
      shift: length,
    );
  }

  void setSelection(Range range, {String source = EmitterSource.API}) {
    // Parity selection.ts rangeToNative: both endpoints are clamped to
    // scroll.length() - 1 — the caret can never sit past the final newline.
    // Upstream stores the clamped value too (setNativeRange → update reads
    // the native selection back), so the logical range must match.
    final maxIndex = math.max(0, scroll.length() - 1);
    final clampedIndex = math.max(0, math.min(range.index, maxIndex));
    final clampedEnd =
        math.max(clampedIndex, math.min(range.index + range.length, maxIndex));
    if (clampedIndex != range.index ||
        clampedEnd - clampedIndex != range.length) {
      range = Range(clampedIndex, clampedEnd - clampedIndex);
    }
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

