import 'dart:math';
import '../transform/index.dart';
import '../state/index.dart';

// schedule history compression
const int max_empty_items = 500;
const int DEPTH_OVERFLOW = 20;

final PluginKey historyKey = PluginKey("history");
final PluginKey closeHistoryKey = PluginKey("closeHistory");

class HistoryMeta {
  final bool redo;
  final HistoryState historyState;
  HistoryMeta({required this.redo, required this.historyState});
}

class Item {
  final StepMap map;
  final Step? step;
  final SelectionBookmark? selection;
  final int? mirrorOffset;

  Item(this.map, [this.step, this.selection, this.mirrorOffset]);

  Item? merge(Item other) {
    if (step != null && other.step != null && other.selection == null) {
      final mergedStep = other.step!.merge(step!);
      if (mergedStep != null) {
        return Item(mergedStep.getMap().invert(), mergedStep, selection);
      }
    }
    return null;
  }
}

class Branch {
  final List<Item> items;
  final int eventCount;

  Branch(this.items, this.eventCount);

  static final Branch empty = Branch(const [], 0);

  PopEventResult? popEvent(EditorState state, bool preserveItems) {
    if (eventCount == 0) return null;

    int end = items.length;
    for (;; end--) {
      final next = items[end - 1];
      if (next.selection != null) {
        end--;
        break;
      }
    }

    Mapping? remap;
    int? mapFrom;
    if (preserveItems) {
      remap = remapping(end, items.length);
      mapFrom = remap.maps.length;
    }
    final transform = state.tr;
    SelectionBookmark? selection;
    Branch? remaining;
    final List<Item> addAfter = [];
    final List<Item> addBefore = [];

    for (int i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      final step = item.step;
      if (step == null) {
        if (remap == null) {
          remap = remapping(end, i + 1);
          mapFrom = remap.maps.length;
        }
        mapFrom = mapFrom! - 1;
        addBefore.add(item);
        continue;
      }

      if (remap != null) {
        final mFrom = mapFrom!;
        addBefore.add(Item(item.map));
        final mappedStep = step.map(remap.slice(mFrom));
        StepMap? map;

        if (mappedStep != null) {
          final res = transform.maybeStep(mappedStep);
          if (res.doc != null) {
            map = transform.mapping.maps[transform.mapping.maps.length - 1];
            addAfter.add(Item(map, null, null, addAfter.length + addBefore.length));
          }
        }
        mapFrom = mFrom - 1;
        if (map != null) remap.appendMap(map, mapFrom);
      } else {
        transform.maybeStep(step);
      }


      if (item.selection != null) {
        selection = remap != null ? item.selection!.map(remap.slice(mapFrom!)) : item.selection;
        final slicedItems = items.sublist(0, end);
        final reversedAddBefore = addBefore.reversed.toList();
        final finalItems = [...slicedItems, ...reversedAddBefore, ...addAfter];
        remaining = Branch(finalItems, eventCount - 1);
        break;
      }
    }

    return PopEventResult(remaining: remaining!, transform: transform, selection: selection!);
  }

  Branch addTransform(
    Transform transform,
    SelectionBookmark? selection,
    HistoryOptions histOptions,
    bool preserveItems,
  ) {
    final List<Item> newItems = [];
    int eventCountVal = eventCount;
    List<Item> oldItems = items;
    Item? lastItem = (!preserveItems && oldItems.isNotEmpty) ? oldItems.last : null;

    for (int i = 0; i < transform.steps.length; i++) {
      final step = transform.steps[i].invert(transform.docs[i]);
      var item = Item(transform.mapping.maps[i], step, selection);
      Item? merged;
      if (lastItem != null && (merged = lastItem.merge(item)) != null) {
        item = merged!;
        if (i > 0) {
          newItems.removeLast();
        } else {
          oldItems = oldItems.sublist(0, oldItems.length - 1);
        }
      }
      newItems.add(item);
      if (selection != null) {
        eventCountVal++;
        selection = null;
      }
      if (!preserveItems) lastItem = item;
    }
    
    int overflow = eventCountVal - histOptions.depth;
    if (overflow > DEPTH_OVERFLOW) {
      oldItems = cutOffEvents(oldItems, overflow);
      eventCountVal -= overflow;
    }
    return Branch([...oldItems, ...newItems], eventCountVal);
  }

  Mapping remapping(int from, int to) {
    final maps = Mapping();
    for (int i = from; i < to; i++) {
      final item = items[i];
      final mirrorPos = (item.mirrorOffset != null && i - item.mirrorOffset! >= from)
          ? maps.maps.length - item.mirrorOffset!
          : null;
      maps.appendMap(item.map, mirrorPos);
    }
    return maps;
  }

  Branch addMaps(List<StepMap> array) {
    if (eventCount == 0) return this;
    final List<Item> newItems = array.map((map) => Item(map)).toList();
    return Branch([...items, ...newItems], eventCount);
  }

  Branch rebased(Transform rebasedTransform, int rebasedCount) {
    if (eventCount == 0) return this;

    final List<Item> rebasedItems = [];
    final int start = max(0, items.length - rebasedCount);

    final mapping = rebasedTransform.mapping;
    int newUntil = rebasedTransform.steps.length;
    int eventCountVal = eventCount;

    for (int i = start; i < items.length; i++) {
      if (items[i].selection != null) eventCountVal--;
    }

    int iRebased = rebasedCount;
    for (int i = start; i < items.length; i++) {
      final item = items[i];
      iRebased--;
      final pos = mapping.getMirror(iRebased);
      if (pos == null) continue;
      newUntil = min(newUntil, pos);
      final map = mapping.maps[pos];
      if (item.step != null) {
        final step = rebasedTransform.steps[pos].invert(rebasedTransform.docs[pos]);
        final selection = item.selection?.map(mapping.slice(iRebased + 1, pos));
        if (selection != null) eventCountVal++;
        rebasedItems.add(Item(map, step, selection));
      } else {
        rebasedItems.add(Item(map));
      }
    }

    final List<Item> newMaps = [];
    for (int i = rebasedCount; i < newUntil; i++) {
      newMaps.add(Item(mapping.maps[i]));
    }
    
    final slicedItems = items.sublist(0, start);
    final finalItems = [...slicedItems, ...newMaps, ...rebasedItems];
    var branch = Branch(finalItems, eventCountVal);

    if (branch.emptyItemCount() > max_empty_items) {
      branch = branch.compress(items.length - rebasedItems.length);
    }
    return branch;
  }

  int emptyItemCount() {
    int count = 0;
    for (var item in items) {
      if (item.step == null) count++;
    }
    return count;
  }

  Branch compress([int? upto]) {
    final int uptoVal = upto ?? items.length;
    final remap = remapping(0, uptoVal);
    int mapFrom = remap.maps.length;
    final List<Item> compressedItems = [];
    int events = 0;

    for (int i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      if (i >= uptoVal) {
        compressedItems.add(item);
        if (item.selection != null) events++;
      } else if (item.step != null) {
        final step = item.step!.map(remap.slice(mapFrom));
        final map = step?.getMap();
        mapFrom--;
        if (map != null) remap.appendMap(map, mapFrom);
        if (step != null) {
          final selection = item.selection?.map(remap.slice(mapFrom));
          if (selection != null) events++;
          final newItem = Item(map!.invert(), step, selection);
          Item? merged;
          final int last = compressedItems.length - 1;
          if (compressedItems.isNotEmpty && (merged = compressedItems[last].merge(newItem)) != null) {
            compressedItems[last] = merged!;
          } else {
            compressedItems.add(newItem);
          }
        }
      } else {
        mapFrom--;
      }
    }
    return Branch(compressedItems.reversed.toList(), events);
  }
}

class PopEventResult {
  final Branch remaining;
  final Transaction transform;
  final SelectionBookmark selection;

  PopEventResult({
    required this.remaining,
    required this.transform,
    required this.selection,
  });
}

List<Item> cutOffEvents(List<Item> items, int n) {
  int? cutPoint;
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.selection != null && (n-- == 0)) {
      cutPoint = i;
      break;
    }
  }
  return cutPoint != null ? items.sublist(cutPoint) : items;
}

class HistoryState {
  final Branch done;
  final Branch undone;
  final List<int>? prevRanges;
  final int prevTime;
  final int prevComposition;

  HistoryState(
    this.done,
    this.undone,
    this.prevRanges,
    this.prevTime,
    this.prevComposition,
  );
}

class HistoryOptions {
  final int depth;
  final int newGroupDelay;

  const HistoryOptions({
    this.depth = 100,
    this.newGroupDelay = 500,
  });
}

bool _cachedPreserveItems = false;
List<Plugin>? _cachedPreserveItemsPlugins;

bool mustPreserveItems(EditorState state) {
  final plugins = state.plugins;
  if (_cachedPreserveItemsPlugins != plugins) {
    _cachedPreserveItems = false;
    _cachedPreserveItemsPlugins = plugins;
    for (int i = 0; i < plugins.length; i++) {
      if (plugins[i].spec.extraProps["historyPreserveItems"] == true) {
        _cachedPreserveItems = true;
        break;
      }
    }
  }
  return _cachedPreserveItems;
}

bool isAdjacentTo(Transform transform, List<int>? prevRanges) {
  if (prevRanges == null) return false;
  if (!transform.docChanged) return true;
  bool adjacent = false;
  transform.mapping.maps[0].forEach((start, end, _ns, _ne) {
    for (int i = 0; i < prevRanges.length; i += 2) {
      if (start <= prevRanges[i + 1] && end >= prevRanges[i]) {
        adjacent = true;
      }
    }
  });
  return adjacent;
}

List<int> rangesFor(List<StepMap> maps) {
  final List<int> result = [];
  for (int i = maps.length - 1; i >= 0 && result.isEmpty; i--) {
    maps[i].forEach((_fs, _fe, from, to) => result.addAll([from, to]));
  }
  return result;
}

List<int>? mapRanges(List<int>? ranges, Mapping mapping) {
  if (ranges == null) return null;
  final List<int> result = [];
  for (int i = 0; i < ranges.length; i += 2) {
    final from = mapping.map(ranges[i], 1);
    final to = mapping.map(ranges[i + 1], -1);
    if (from <= to) {
      result.addAll([from, to]);
    }
  }
  return result;
}

HistoryState applyTransaction(HistoryState history, EditorState state, Transaction tr, HistoryOptions options) {
  final historyTr = tr.getMeta(historyKey) as HistoryMeta?;
  if (historyTr != null) return historyTr.historyState;

  if (tr.getMeta(closeHistoryKey) == true) {
    history = HistoryState(history.done, history.undone, null, 0, -1);
  }

  final appended = tr.getMeta("appendedTransaction") as Transaction?;

  if (tr.steps.isEmpty) {
    return history;
  } else if (appended != null && appended.getMeta(historyKey) != null) {
    final appendedMeta = appended.getMeta(historyKey) as HistoryMeta;
    if (appendedMeta.redo) {
      return HistoryState(
        history.done.addTransform(tr, null, options, mustPreserveItems(state)),
        history.undone,
        rangesFor(tr.mapping.maps),
        history.prevTime,
        history.prevComposition,
      );
    } else {
      return HistoryState(
        history.done,
        history.undone.addTransform(tr, null, options, mustPreserveItems(state)),
        null,
        history.prevTime,
        history.prevComposition,
      );
    }
  } else if (tr.getMeta("addToHistory") != false && !(appended != null && appended.getMeta("addToHistory") == false)) {
    final composition = tr.getMeta("composition") as int?;
    final newGroup = history.prevTime == 0 ||
      (appended == null && history.prevComposition != composition &&
       (history.prevTime < (tr.time) - options.newGroupDelay || !isAdjacentTo(tr, history.prevRanges)));
    final prevRanges = appended != null ? mapRanges(history.prevRanges, tr.mapping) : rangesFor(tr.mapping.maps);
    return HistoryState(
      history.done.addTransform(tr, newGroup ? state.selection.getBookmark() : null, options, mustPreserveItems(state)),
      Branch.empty,
      prevRanges,
      tr.time,
      composition ?? history.prevComposition,
    );
  } else {
    final rebased = tr.getMeta("rebased") as int?;
    if (rebased != null) {
      return HistoryState(
        history.done.rebased(tr, rebased),
        history.undone.rebased(tr, rebased),
        mapRanges(history.prevRanges, tr.mapping),
        history.prevTime,
        history.prevComposition,
      );
    } else {
      return HistoryState(
        history.done.addMaps(tr.mapping.maps),
        history.undone.addMaps(tr.mapping.maps),
        mapRanges(history.prevRanges, tr.mapping),
        history.prevTime,
        history.prevComposition,
      );
    }
  }
}

Transaction? histTransaction(HistoryState history, EditorState state, bool redo) {
  final bool preserveItems = mustPreserveItems(state);
  final histPlugin = historyKey.get(state);
  final histOptions = (histPlugin?.spec.extraProps["config"] as HistoryOptions?) ?? const HistoryOptions();
  final pop = (redo ? history.undone : history.done).popEvent(state, preserveItems);
  if (pop == null) return null;

  final selection = pop.selection.resolve(pop.transform.doc);
  final added = (redo ? history.done : history.undone).addTransform(
    pop.transform,
    state.selection.getBookmark(),
    histOptions,
    preserveItems,
  );

  final newHist = HistoryState(
    redo ? added : pop.remaining,
    redo ? pop.remaining : added,
    null,
    0,
    -1,
  );
  
  final tr = pop.transform;
  tr.setSelection(selection);
  tr.setMeta(historyKey, HistoryMeta(redo: redo, historyState: newHist));
  return tr;
}

Transaction closeHistory(Transaction tr) {
  return tr.setMeta(closeHistoryKey, true);
}

Plugin history([HistoryOptions config = const HistoryOptions()]) {
  return Plugin(PluginSpec(
    key: historyKey,
    state: StateField(
      init: (configObj, instance) {
        return HistoryState(Branch.empty, Branch.empty, null, 0, -1);
      },
      apply: (tr, hist, oldState, newState) {
        return applyTransaction(hist as HistoryState, oldState, tr, config);
      },
    ),
    extraProps: {
      "config": config,
    },
    props: {
      "handleDOMEvents": {
        "beforeinput": (dynamic view, dynamic e) {
          try {
            final inputType = e.inputType as String;
            final Command? command = inputType == "historyUndo" ? undo : inputType == "historyRedo" ? redo : null;
            if (command == null || view.editable == false) return false;
            e.preventDefault();
            return command(view.state as EditorState, view.dispatch as void Function(Transaction));
          } catch (_) {}
          return false;
        }
      }
    }
  ));
}

Command buildCommand(bool redoVal, bool scroll) {
  return (state, [dispatch, view]) {
    final hist = historyKey.getState(state) as HistoryState?;
    if (hist == null || (redoVal ? hist.undone : hist.done).eventCount == 0) return false;
    if (dispatch != null) {
      final tr = histTransaction(hist, state, redoVal);
      if (tr != null) {
        dispatch(scroll ? tr.scrollIntoView() : tr);
      }
    }
    return true;
  };
}

final Command undo = buildCommand(false, true);
final Command redo = buildCommand(true, true);
final Command undoNoScroll = buildCommand(false, false);
final Command redoNoScroll = buildCommand(true, false);

int undoDepth(EditorState state) {
  final hist = historyKey.getState(state) as HistoryState?;
  return hist != null ? hist.done.eventCount : 0;
}

int redoDepth(EditorState state) {
  final hist = historyKey.getState(state) as HistoryState?;
  return hist != null ? hist.undone.eventCount : 0;
}

bool isHistoryTransaction(Transaction tr) {
  return tr.getMeta(historyKey) != null;
}
