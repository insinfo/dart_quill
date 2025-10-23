import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../modules/keyboard.dart';
import '../platform/platform.dart';
import 'editor.dart';
import 'emitter.dart';
import 'selection.dart';
import 'theme.dart';
import '../platform/dom.dart';

String deltaToSemanticHTML(Delta delta) {
  // Placeholder
  return '';
}

class Quill {
  final DomElement container;
  final DomElement root;
  final Scroll scroll;
  final Emitter emitter;
  late final Editor editor;
  late final Selection selection;
  late final Theme theme;
  late final Keyboard keyboard;

  static final Map<String, dynamic> _registry = {};
  static final Emitter events = Emitter();
  static const sources = EmitterSource();

  static void register(dynamic blot, [bool overwrite = false]) {
    final String name = blot.blotName;
    if (!overwrite && _registry.containsKey(name)) {
      throw ArgumentError('Blot $name already registered');
    }
    _registry[name] = blot;
  }

  Quill(this.container)
      : root = domBindings.adapter.document.createElement('div')
          ..classes.add('ql-editor'),
        emitter = Emitter(),
        scroll = Scroll(
            Registry(),
            domBindings.adapter.document.createElement('div')
              ..classes.add('ql-editor'),
            emitter: Emitter()) {
    container.append(root);

    // Initialize dependent components
    editor = Editor(scroll);
    selection = Selection(scroll, emitter);
    theme = Theme(this, {});
    keyboard = Keyboard(this, {});
  }

  void on(String event, Function handler) {
    emitter.on(event, handler);
  }

  Delta getContents() {
    return editor.getContents();
  }

  String getSemanticHTML([int index = 0, int length = 0]) {
    final delta = getContents().slice(index, length);
    return deltaToSemanticHTML(delta);
  }

  String getText([int index = 0, int length = 0]) {
    return getContents().getPlainText(index, length);
  }

  void setContents(Delta delta, {String source = EmitterSource.API}) {
    final change = getContents().diff(delta);
    editor.update(change, source);
  }

  void updateContents(Delta delta, {String source = EmitterSource.API}) {
    editor.update(delta, source);
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
    selection.focus();
    // TODO: Implement scroll prevention if needed
  }

  bool hasFocus() {
    return selection.hasFocus();
  }

  void format(String name, dynamic value, {String source = EmitterSource.API}) {
    final range = selection.getRange();
    if (range == null) return;
    if (range.length == 0) {
      // Format at cursor position
      scroll.formatAt(range.index, 1, name, value);
    } else {
      // Format selection
      scroll.formatAt(range.index, range.length, name, value);
    }
    editor.update(Delta()..retain(range.index)..retain(range.length, {name: value}), source);
  }

  void setSelection(Range range, {String source = EmitterSource.API}) {
    selection.setSelection(range, source);
  }

  void formatText(int index, int length, String name, dynamic value, {String source = EmitterSource.API}) {
    final change = editor.formatText(index, length, name, value);
    emitter.emit(EmitterEvents.TEXT_CHANGE, [change, Delta(), source]);
  }

  void insertEmbed(int index, String embed, dynamic value, {String source = EmitterSource.API}) {
    final change = editor.insertEmbed(index, embed, value);
    emitter.emit(EmitterEvents.TEXT_CHANGE, [change, Delta(), source]);
  }

  void insertText(int index, String text, {Map<String, dynamic>? formats, String source = EmitterSource.API}) {
    final change = editor.insertText(index, text, formats ?? {});
    emitter.emit(EmitterEvents.TEXT_CHANGE, [change, Delta(), source]);
  }

  Map<String, dynamic>? getBounds(int index, [int length = 0]) {
    // Placeholder - This requires DOM measurement which needs platform abstraction
    // For now, return null
    return null;
  }
}