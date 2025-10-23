import '../dependencies/dart_quill_delta/dart_quill_delta.dart';

import '../blots/scroll.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';

import '../platform/dom.dart';
import 'keyboard.dart';

class History extends Module<HistoryOptions> {
  late final Stack stack;
  late int lastRecorded;
  late bool ignoreChange;

  History(Quill quill, HistoryOptions options) : super(quill, options) {
    stack = Stack(undo: [], redo: []);
    lastRecorded = 0;
    ignoreChange = false;

    quill.on(EmitterEvents.EDITOR_CHANGE, _handleEditorChange);

    quill.keyboard.addBinding(
      BindingObject(key: 'Z', shortKey: true),
      handler: (_, __) => undo(),
    );
    quill.keyboard.addBinding(
      BindingObject(key: 'Y', shortKey: true),
      handler: (_, __) => redo(),
    );
    quill.keyboard.addBinding(
      BindingObject(key: 'Z', shortKey: true, shiftKey: true),
      handler: (_, __) => redo(),
    );
    // if (isMac()) {
    //   quill.keyboard.addBinding(
    //     {'key': 'z', 'shortKey': true, 'shiftKey': true},
    //     (range, context) => redo(),
    //   );
    // } else {
    //   quill.keyboard.addBinding(
    //     {'key': 'y', 'shortKey': true},
    //     (range, context) => redo(),
    //   );
    // }

    quill.root.addEventListener('beforeinput', (event) {
      if (event is! DomInputEvent) return;
      if (event.inputType == 'historyUndo') {
        undo();
        event.preventDefault();
      } else if (event.inputType == 'historyRedo') {
        redo();
        event.preventDefault();
      }
    });
  }

  void _handleEditorChange(
    String eventName,
    dynamic delta,
    dynamic oldDelta,
    String source,
  ) {
    if (ignoreChange) return;
    if (eventName == EmitterEvents.TEXT_CHANGE) {
      if (!options.userOnly || source == EmitterSource.USER) {
        record(delta as Delta, oldDelta as Delta);
      } else {
        transform(delta as Delta);
      }
    }
  }

  void change(String source, String dest) {
    final sourceStack = source == 'undo' ? stack.undo : stack.redo;
    final destStack = dest == 'undo' ? stack.undo : stack.redo;

    if (sourceStack.isEmpty) {
      return;
    }

    final delta = sourceStack.removeLast();
    final base = quill.getContents();
    final inverse = delta.invert(base);
    destStack.add(inverse);

    lastRecorded = 0;
    ignoreChange = true;
    quill.updateContents(delta, source: EmitterSource.USER);
    ignoreChange = false;

    final index =
        getLastChangeIndex(quill.scroll, delta);
    quill.setSelection(Range(index, 0), source: EmitterSource.SILENT);
  }

  void clear() {
    stack.undo.clear();
    stack.redo.clear();
  }

  void cutoff() {
    lastRecorded = 0;
  }

  void record(Delta change, Delta before) {
    if (change.operations.isEmpty) return;

    stack.redo.clear();
    var undoDelta = change.invert(before);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (lastRecorded + options.delay > timestamp && stack.undo.isNotEmpty) {
      final last = stack.undo.removeLast();
      undoDelta = undoDelta.compose(last);
    } else {
      lastRecorded = timestamp;
    }

    if (undoDelta.operations.isEmpty) return;

    stack.undo.add(undoDelta);

    if (stack.undo.length > options.maxStack) {
      stack.undo.removeAt(0);
    }
  }

  void redo() {
    change('redo', 'undo');
  }

  void transform(Delta delta) {
    for (var i = 0; i < stack.undo.length; i++) {
      stack.undo[i] = delta.transform(stack.undo[i], true);
    }
    for (var i = 0; i < stack.redo.length; i++) {
      stack.redo[i] = delta.transform(stack.redo[i], true);
    }
  }

  void undo() {
    change('undo', 'redo');
  }
}

class HistoryOptions {
  final int delay;
  final int maxStack;
  final bool userOnly;

  HistoryOptions({
    this.delay = 1000,
    this.maxStack = 100,
    this.userOnly = false,
  });
}

class Stack {
  final List<Delta> undo;
  final List<Delta> redo;

  Stack({required this.undo, required this.redo});
}

int getLastChangeIndex(Scroll scroll, Delta delta) {
  final lastOp = delta.operations.last;
  if (lastOp.key == 'delete') {
    return delta.length;
  }
  if (lastOp.key == 'retain' && lastOp.data == null) {
    return delta.length;
  }
  return delta.length - (lastOp.data as String).length;
}
