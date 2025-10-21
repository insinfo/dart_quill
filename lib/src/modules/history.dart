import '../core/module.dart'; // Placeholder for Module
import '../core/quill.dart'; // Placeholder for Quill
import '../core/selection.dart';
import 'dart:html';
import 'package:quill_delta/quill_delta.dart';

// Placeholder for Quill.events and Quill.sources
class Quill {
  static final events = _QuillEvents();
  static final sources = _QuillSources();
  late Scroll scroll;
  late Keyboard keyboard;
  void on(String eventName, Function handler) {}
  Delta getContents() => Delta();
  void updateContents(Delta delta, String source) {}
  void setSelection(dynamic index, [dynamic lengthOrSource, String? source]) {}
}

class _QuillEvents {
  final String EDITOR_CHANGE = 'editor-change';
  final String SELECTION_CHANGE = 'selection-change';
  final String TEXT_CHANGE = 'text-change';
}

class _QuillSources {
  final String USER = 'user';
  final String API = 'api';
  final String SILENT = 'silent';
}

// Placeholder for Module
class Module<T> {
  late Quill quill;
  late T options;
  Module(this.quill, this.options);
}

// Placeholder for Keyboard
class Keyboard {
  void addBinding(dynamic binding, [dynamic context, dynamic handler]) {}
}

class HistoryOptions {
  final bool userOnly;
  final int delay;
  final int maxStack;

  HistoryOptions({
    this.userOnly = false,
    this.delay = 1000,
    this.maxStack = 100,
  });
}

class StackItem {
  final Delta delta;
  final Range? range;

  StackItem({
    required this.delta,
    this.range,
  });
}

class Stack {
  List<StackItem> undo;
  List<StackItem> redo;

  Stack({
    required this.undo,
    required this.redo,
  });
}

class History extends Module<HistoryOptions> {
  static final DEFAULTS = HistoryOptions();

  int lastRecorded = 0;
  bool ignoreChange = false;
  Stack stack = Stack(undo: [], redo: []);
  Range? currentRange;

  History(Quill quill, HistoryOptions options) : super(quill, options) {
    quill.on(
      Quill.events.EDITOR_CHANGE,
      (String eventName, dynamic value, dynamic oldValue, String source) {
        if (eventName == Quill.events.SELECTION_CHANGE) {
          if (value != null && source != Quill.sources.SILENT) {
            currentRange = value as Range;
          }
        } else if (eventName == Quill.events.TEXT_CHANGE) {
          if (!ignoreChange) {
            if (!options.userOnly || source == Quill.sources.USER) {
              record(value as Delta, oldValue as Delta);
            } else {
              transform(value as Delta);
            }
          }

          currentRange = transformRange(currentRange, value as Delta);
        }
      },
    );

    quill.keyboard.addBinding(
      {'key': 'z', 'shortKey': true},
      (_) => undo(),
    );
    quill.keyboard.addBinding(
      {'key': ['z', 'Z'], 'shortKey': true, 'shiftKey': true},
      (_) => redo(),
    );
    if (window.navigator.platform!.contains(RegExp(r'Win', caseSensitive: false))) {
      quill.keyboard.addBinding(
        {'key': 'y', 'shortKey': true},
        (_) => redo(),
      );
    }

    quill.root.addEventListener('beforeinput', (event) {
      final inputEvent = event as InputEvent;
      if (inputEvent.inputType == 'historyUndo') {
        undo();
        event.preventDefault();
      } else if (inputEvent.inputType == 'historyRedo') {
        redo();
        event.preventDefault();
      }
    });
  }

  void change(String source, String dest) {
    if (stack.undo.isEmpty) return; // Simplified, should check source stack
    final item = stack.undo.removeLast(); // Simplified, should remove from source stack
    if (item == null) return;
    final base = quill.getContents();
    final inverseDelta = item.delta.invert(base);
    stack.redo.add(StackItem(delta: inverseDelta, range: transformRange(item.range, inverseDelta))); // Simplified, should add to dest stack
    lastRecorded = 0;
    ignoreChange = true;
    quill.updateContents(item.delta, Quill.sources.USER);
    ignoreChange = false;

    restoreSelection(item);
  }

  void clear() {
    stack = Stack(undo: [], redo: []);
  }

  void cutoff() {
    lastRecorded = 0;
  }

  void record(Delta changeDelta, Delta oldDelta) {
    if (changeDelta.ops.isEmpty) return;
    stack.redo = [];
    var undoDelta = changeDelta.invert(oldDelta);
    var undoRange = currentRange;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (lastRecorded + options.delay > timestamp && stack.undo.isNotEmpty) {
      final item = stack.undo.removeLast();
      undoDelta = undoDelta.compose(item.delta);
      undoRange = item.range;
    } else {
      lastRecorded = timestamp;
    }
    if (undoDelta.length() == 0) return;
    stack.undo.add(StackItem(delta: undoDelta, range: undoRange));
    if (stack.undo.length > options.maxStack) {
      stack.undo.removeAt(0);
    }
  }

  void redo() {
    change('redo', 'undo');
  }

  void transform(Delta delta) {
    transformStack(stack.undo, delta);
    transformStack(stack.redo, delta);
  }

  void undo() {
    change('undo', 'redo');
  }

  void restoreSelection(StackItem stackItem) {
    if (stackItem.range != null) {
      quill.setSelection(stackItem.range, Quill.sources.USER);
    } else {
      final index = getLastChangeIndex(quill.scroll, stackItem.delta);
      quill.setSelection(index, Quill.sources.USER);
    }
  }
}

void transformStack(List<StackItem> stack, Delta delta) {
  var remoteDelta = delta;
  for (int i = stack.length - 1; i >= 0; i -= 1) {
    final oldItem = stack[i];
    stack[i] = StackItem(
      delta: remoteDelta.transform(oldItem.delta, true),
      range: oldItem.range != null ? transformRange(oldItem.range, remoteDelta) : null,
    );
    remoteDelta = oldItem.delta.transform(remoteDelta);
    if (stack[i].delta.length() == 0) {
      stack.removeAt(i);
    }
  }
}

bool endsWithNewlineChange(Scroll scroll, Delta delta) {
  final lastOp = delta.ops.isNotEmpty ? delta.ops.last : null;
  if (lastOp == null) return false;
  if (lastOp.insert != null) {
    return lastOp.insert is String && (lastOp.insert as String).endsWith('\n');
  }
  if (lastOp.attributes != null) {
    // Placeholder for scroll.query
    // return lastOp.attributes!.keys.any((attr) => scroll.query(attr, Scope.BLOCK) != null);
  }
  return false;
}

int getLastChangeIndex(Scroll scroll, Delta delta) {
  final deleteLength = delta.ops.fold<int>(0, (sum, op) => sum + (op.length ?? 0));
  var changeIndex = delta.length() - deleteLength;
  if (endsWithNewlineChange(scroll, delta)) {
    changeIndex -= 1;
  }
  return changeIndex;
}

Range? transformRange(Range? range, Delta delta) {
  if (range == null) return null;
  final start = delta.transformPosition(range.index);
  final end = delta.transformPosition(range.index + range.length);
  return Range(start, end - start);
}
