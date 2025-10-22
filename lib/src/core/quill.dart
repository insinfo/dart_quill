import 'dart:html';

import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import 'editor.dart';
import 'emitter.dart';
import 'selection.dart';
import 'theme.dart';

class Quill {
  final HtmlElement container;
  final DivElement root;
  final Scroll scroll;
  final Emitter emitter;
  late final Editor editor;
  late final Selection selection;
  late final Theme theme;
  
  static final Map<String, dynamic> _registry = {};

  static void register(dynamic blot, [bool overwrite = false]) {
    final String name = blot.blotName;
    if (!overwrite && _registry.containsKey(name)) {
      throw ArgumentError('Blot $name already registered');
    }
    _registry[name] = blot;
  }

  Quill(this.container) :
    root = DivElement()..classes.add('ql-editor'),
    emitter = Emitter(),
    scroll = Scroll(Registry(), DivElement()..classes.add('ql-editor'), emitter: Emitter()) {
      
    container.append(root);
    
    // Initialize dependent components
    editor = Editor(scroll);
    selection = Selection(scroll, emitter);
    theme = Theme(this, {});
  }
}