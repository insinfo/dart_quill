import '../../blots/block.dart';
import '../../core/emitter.dart';
import '../../core/quill.dart';
import '../../modules/toolbar.dart';
import '../../platform/dom.dart';
import '../formats/header.dart';
import '../formats/list.dart';
import '../formats/table.dart';
import '../ui/cell_selection.dart';

/// Routes toolbar block formats to every selected table-better cell.
class TableToolbarRouter {
  TableToolbarRouter(this.quill, this.selectionProvider);

  final Quill quill;
  final CellSelection? Function() selectionProvider;
  final Map<String, Handler?> _fallbacks = {};
  Toolbar? toolbar;

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
    for (final cell in selection.selectedCells) {
      final lines = cell.children
          .expand(_tableLines)
          .whereType<Block>()
          .toList(growable: false);
      for (final line in lines) {
        _formatLine(line, format, value);
      }
    }
    quill.scroll.optimize([], {'source': EmitterSource.USER});
  }

  Iterable<dynamic> _tableLines(dynamic blot) sync* {
    if (blot is TableCellBlock || blot is TableHeader || blot is TableList) {
      yield blot;
      return;
    }
    if (blot is TableListContainer) {
      yield* blot.children;
    }
  }

  void _formatLine(Block line, String format, dynamic value) {
    if (format == 'header') {
      if (line is TableHeader) {
        line.format('header', value);
      } else if (value == null || value == false) {
        if (line is! TableCellBlock) {
          replaceBlotWith(line, TableCellBlock.kBlotName, _cellId(line));
        }
      } else {
        replaceBlotWith(line, TableHeader.kBlotName, {
          'cellId': _cellId(line),
          'value': value,
        });
      }
      return;
    }
    if (format == 'list') {
      if (line is TableList) {
        line.format('list', value);
      } else if (value == null || value == false) {
        if (line is! TableCellBlock) {
          replaceBlotWith(line, TableCellBlock.kBlotName, _cellId(line));
        }
      } else {
        final replacement = replaceBlotWith(line, TableList.kBlotName, value);
        if (replacement.domNode is DomElement) {
          (replacement.domNode as DomElement)
              .setAttribute('data-cell', _cellId(line));
        }
        replacement.optimize([], {'source': EmitterSource.USER});
      }
      return;
    }
    line.format(format, value);
  }

  String _cellId(Block line) {
    final direct = line.element.getAttribute('data-cell');
    if (direct != null && direct.isNotEmpty) return direct;
    if (line.parent is TableListContainer) {
      return (line.parent as TableListContainer)
              .element
              .getAttribute('data-cell') ??
          cellId();
    }
    return cellId();
  }
}
