import '../dependencies/dart_quill_delta/dart_quill_delta.dart';

import '../blots/abstract/blot.dart';
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
  Range? currentRange;

  History(Quill quill, HistoryOptions options) : super(quill, options) {
    stack = Stack(undo: <StackItem>[], redo: <StackItem>[]);
    lastRecorded = 0;
    ignoreChange = false;
    currentRange = null;

    quill.on(
      EmitterEvents.SELECTION_CHANGE,
      (dynamic range, dynamic _oldRange, dynamic source) {
        if (source == EmitterSource.SILENT) {
          return;
        }
        if (range is Range) {
          currentRange = range;
        }
      },
    );

    quill.on(
      EmitterEvents.TEXT_CHANGE,
      (dynamic delta, dynamic oldDelta, dynamic source) {
        final change = delta as Delta;
        final previous = oldDelta as Delta;
        if (!ignoreChange) {
          if (!options.userOnly || source == EmitterSource.USER) {
            record(change, previous);
          } else {
            transform(change);
          }
        }
        currentRange = transformRange(currentRange, change);
      },
    );

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

  void change(String source, String dest) {
    final sourceStack = source == 'undo' ? stack.undo : stack.redo;
    final destStack = dest == 'undo' ? stack.undo : stack.redo;

    if (sourceStack.isEmpty) {
      return;
    }

    final item = sourceStack.removeLast();
    final delta = item.delta;
    final base = quill.getContents();
    final inverse = delta.invert(base);
    destStack.add(
      StackItem(
        delta: inverse,
        range: transformRange(item.range, inverse),
      ),
    );

    lastRecorded = 0;
    ignoreChange = true;
    quill.updateContents(delta, source: EmitterSource.USER);
    ignoreChange = false;

    _restoreSelection(item);
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
    var undoRange = currentRange;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (lastRecorded + options.delay > timestamp && stack.undo.isNotEmpty) {
      final last = stack.undo.removeLast();
      undoDelta = undoDelta.compose(last.delta);
      undoRange = last.range;
    } else {
      lastRecorded = timestamp;
    }

    if (undoDelta.operations.isEmpty) return;

    stack.undo.add(StackItem(delta: undoDelta, range: undoRange));

    if (stack.undo.length > options.maxStack) {
      stack.undo.removeAt(0);
    }
  }

  void redo() {
    change('redo', 'undo');
  }

  void transform(Delta delta) {
    _transformStack(stack.undo, delta);
    _transformStack(stack.redo, delta);
  }

  void undo() {
    change('undo', 'redo');
  }

  void _restoreSelection(StackItem stackItem) {
    final range = stackItem.range;
    if (range != null) {
      quill.setSelection(range, source: EmitterSource.USER);
      return;
    }
    final index = getLastChangeIndex(quill.scroll, stackItem.delta);
    quill.setSelection(Range(index, 0), source: EmitterSource.USER);
  }
}

class HistoryOptions {
  int delay;
  int maxStack;
  bool userOnly;

  HistoryOptions({
    this.delay = 1000,
    this.maxStack = 100,
    this.userOnly = false,
  });
}

class Stack {
  Stack({required this.undo, required this.redo});

  final List<StackItem> undo;
  final List<StackItem> redo;
}

class StackItem {
  StackItem({required this.delta, this.range});

  final Delta delta;
  final Range? range;
}

int getLastChangeIndex(Scroll scroll, Delta delta) {
  if (delta.operations.isEmpty) return 0;
  final deleteLength = delta.operations.fold<int>(
    0,
    (length, op) => length + (op.isDelete ? (op.length ?? 0) : 0),
  );
  var changeIndex = _deltaLength(delta) - deleteLength;
  if (_endsWithNewlineChange(scroll, delta)) {
    changeIndex -= 1;
  }
  return changeIndex < 0 ? 0 : changeIndex;
}

void _transformStack(List<StackItem> stack, Delta delta) {
  var remoteDelta = delta;
  for (var i = stack.length - 1; i >= 0; i--) {
    final item = stack[i];
    final transformedDelta = remoteDelta.transform(item.delta, true);
    final transformedRange = transformRange(item.range, remoteDelta);
    remoteDelta = item.delta.transform(remoteDelta, false);
    if (transformedDelta.operations.isEmpty) {
      stack.removeAt(i);
      continue;
    }
    stack[i] = StackItem(delta: transformedDelta, range: transformedRange);
  }
}

int _deltaLength(Delta delta) {
  return delta.operations.fold<int>(
    0,
    (length, op) => length + (op.length ?? 0),
  );
}

bool _endsWithNewlineChange(Scroll scroll, Delta delta) {
  if (delta.operations.isEmpty) return false;
  final lastOp = delta.operations.last;
  if (lastOp.isInsert) {
    final data = lastOp.data;
    if (data is String) {
      return data.endsWith('\n');
    }
  }
  final attributes = lastOp.attributes;
  if (attributes == null || attributes.isEmpty) {
    return false;
  }
  for (final name in attributes.keys) {
    if (scroll.query(name, Scope.BLOCK) != null ||
        scroll.query(name, Scope.BLOCK_ATTRIBUTE) != null ||
        _knownBlockAttributes.contains(name)) {
      return true;
    }
  }
  return false;
}

Range? transformRange(Range? range, Delta delta) {
  if (range == null) return null;
  final start = delta.transformPosition(range.index);
  final end = delta.transformPosition(range.index + range.length);
  return Range(start, end - start);
}

const Set<String> _knownBlockAttributes = <String>{
  'align',
  'direction',
  'indent',
  'list',
  'header',
  'blockquote',
  'code-block',
  'table',
};
