/// Port of `quill-table-better/src/modules/toolbar.ts` (v1.2.3).
///
/// Upstream subclasses Quill's Toolbar so `attach` forks: with cells selected
/// a toolbar click formats every selected cell instead of the caret's line.
/// Dart has no `Quill.import('modules/toolbar')` subclassing at registration
/// time, so the same fork is installed by wrapping the live Toolbar's handlers
/// — the observable behaviour, including `setTableFormat`'s `isReplace`
/// semantics and the tri-state `list` handler, is the upstream one.
library;

import '../../blots/abstract/blot.dart';
import '../../blots/block.dart';
import '../../blots/container.dart';
import '../../core/emitter.dart';
import '../../core/quill.dart';
import '../../core/selection.dart';
import '../../modules/toolbar.dart';
import '../formats/header.dart';
import '../formats/list.dart';
import '../formats/table.dart';
import '../ui/cell_selection.dart';

/// TS `class TableToolbar extends Toolbar`.
class TableToolbarRouter {
  TableToolbarRouter(
    this.quill,
    this.selectionProvider, {
    this.onFormatted,
  });

  final Quill quill;
  final CellSelection? Function() selectionProvider;

  /// TS ends `setTableFormat` with `tableMenus.updateMenus()`.
  final void Function()? onFormatted;

  final Map<String, Handler?> _fallbacks = {};
  Toolbar? toolbar;

  /// Formats routed to the selected cells. `header` and `list` have dedicated
  /// upstream handlers; the rest are line formats applied the same way.
  static const routedFormats = <String>{
    'header',
    'list',
    'align',
    'direction',
    'indent',
  };

  void install() {
    final candidate = quill.getModule('toolbar');
    if (candidate is! Toolbar) return;
    toolbar = candidate;
    for (final format in routedFormats) {
      _fallbacks[format] = candidate.handlers[format];
      candidate.addHandler(format, (value) => handle(format, value));
    }
  }

  /// The `attach` fork: cells selected → table path, otherwise the toolbar's
  /// own handler.
  void handle(String format, dynamic value) {
    final selection = selectionProvider();
    if (selection == null || selection.selectedCells.isEmpty) {
      final fallback = _fallbacks[format];
      if (fallback != null) {
        fallback(value);
      } else {
        quill.format(format, value, source: EmitterSource.USER);
      }
      return;
    }
    if (format == 'list') {
      tableHandler(format, listCorrectValue(value, selection), selection);
      return;
    }
    tableHandler(format, value, selection);
  }

  /// TS `getListCorrectValue(format, value, formats)` — `check` toggles
  /// between `unchecked` and off, depending on the current line.
  dynamic listCorrectValue(dynamic value, CellSelection selection) {
    if (value != 'check') return value;
    if (selection.selectedCells.length != 1) return 'unchecked';
    final range = quill.getSelection();
    if (range == null) return 'unchecked';
    final current = quill.getFormat(range.index)['list'];
    return (current == 'checked' || current == 'unchecked')
        ? false
        : 'unchecked';
  }

  /// TS `tablehandler(value, selectedTds, name, lines)`.
  void tableHandler(String name, dynamic value, CellSelection selection) {
    final range = quill.getSelection();
    final cells = selection.selectedCells;
    final lines = <Block>[];
    if (range != null && range.length == 0 && cells.length == 1) {
      final line = quill.getLine(range.index).key;
      if (line is Block) lines.add(line);
    }
    if (lines.isEmpty) {
      for (final cell in cells) {
        lines.addAll(linesOf(cell));
      }
    }
    setTableFormat(range, cells, value, name, lines);
  }

  /// TS `setTableFormat(range, selectedTds, value, name, lines)`.
  void setTableFormat(
    Range? range,
    List<TableCell> cells,
    dynamic value,
    String name,
    List<Block> lines,
  ) {
    final replaceWhole = isReplace(range, cells, lines);
    for (final line in lines) {
      formatLine(line, name, value,
          isReplace: headerReplace(cells, name, line, replaceWhole));
    }
    quill.scroll.optimize([], {'source': EmitterSource.USER});
    if (cells.length < 2 && range != null) {
      quill.setSelection(range, source: EmitterSource.SILENT);
    }
    onFormatted?.call();
  }

  /// TS `isReplace(range, selectedTds, lines)` — true when the format covers
  /// the cell entirely, in which case the cell itself is rebuilt.
  bool isReplace(Range? range, List<TableCell> cells, List<Block> lines) {
    if (cells.length > 1) return true;
    if (cells.length != 1) return false;
    final containerLength = containersOf(cells.first)
        .fold<int>(0, (sum, blot) => sum + blot.length());
    final linesLength = lines.fold<int>(0, (sum, line) => sum + line.length());
    return containerLength == linesLength;
  }

  /// TS `getHeaderReplace(selectedTds, name, line, _isReplace)` — turning a
  /// single header line into a list always rebuilds the cell.
  bool headerReplace(
      List<TableCell> cells, String name, Block line, bool replaceWhole) {
    if (cells.length == 1 && name == 'list' && line is TableHeader) return true;
    return replaceWhole;
  }

  /// TS `containers(blot, index, length)` — the container blots inside a cell.
  List<ContainerBlot> containersOf(TableCell cell) {
    final result = <ContainerBlot>[];
    void walk(ParentBlot blot) {
      for (final child in blot.children) {
        if (child is Container) {
          result.add(child);
          walk(child);
        }
      }
    }

    walk(cell);
    return result;
  }

  /// The formattable lines of a cell (list items come through their
  /// container).
  List<Block> linesOf(TableCell cell) {
    final lines = <Block>[];
    void walk(ParentBlot blot) {
      for (final child in blot.children) {
        if (child is TableListContainer) {
          walk(child);
        } else if (child is TableCellBlock ||
            child is TableHeader ||
            child is TableList) {
          if (child is Block) lines.add(child);
        }
      }
    }

    walk(cell);
    return lines;
  }

  /// Applies one format to one line, forwarding `isReplace` to the blots that
  /// understand it (TS `line.format(name, value, isReplace)`).
  void formatLine(Block line, String name, dynamic value,
      {bool isReplace = false}) {
    if (line is TableHeader) {
      line.format(name, value, isReplace);
      return;
    }
    if (line is TableList) {
      line.format(name, value, isReplace);
      return;
    }
    line.format(name, value);
  }
}
