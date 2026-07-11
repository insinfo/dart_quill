import '../../blots/scroll.dart';
import '../../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../../platform/dom.dart';
import '../formats/table.dart';
import 'utils.dart' as utils;

const tableAttributes = <String>['border', 'cellspacing', 'style', 'class'];

Delta applyTableFormat(
  Delta delta,
  dynamic format, [
  dynamic value,
]) {
  if (format is Map) {
    var result = delta;
    for (final entry in format.entries) {
      result = applyTableFormat(result, '${entry.key}', entry.value);
    }
    return result;
  }

  final name = '$format';
  final result = Delta();
  for (final op in delta.operations) {
    final attributes = op.attributes;
    if (attributes != null && attributes[name] != null) {
      result.push(op);
      continue;
    }
    result.insert(op.data, <String, dynamic>{
      name: value,
      ...?attributes,
    });
  }
  return result;
}

DomElement? _parentElement(DomNode? node) {
  final parent = node?.parentNode;
  return parent is DomElement ? parent : null;
}

DomElement? _containingTable(DomNode node) {
  DomElement? current = _parentElement(node);
  while (current != null) {
    if (current.tagName.toUpperCase() == 'TABLE') return current;
    current = _parentElement(current);
  }
  return null;
}

Delta matchTableBetterRow(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) return delta;
  final table = _containingTable(node);
  if (table == null) return delta;
  final compactHtml = (node.innerHTML ?? '').replaceAll(RegExp(r'\s'), '');
  if (compactHtml.isEmpty) return Delta();

  final rows = table.querySelectorAll('tr');
  final row = rows.indexOf(node) + 1;
  if (row <= 0) return delta;
  final blotName = node.querySelectorAll('th').isNotEmpty
      ? TableTh.kBlotName
      : TableCell.kBlotName;
  return applyTableFormat(delta, blotName, row);
}

Delta matchTableBetterCell(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) return delta;
  final tagName = node.tagName.toUpperCase();
  if (tagName != 'TD' && tagName != 'TH') return delta;
  final isTd = tagName == 'TD';
  final blotName = isTd ? TableCell.kBlotName : TableTh.kBlotName;
  final childBlotName =
      isTd ? TableCellBlock.kBlotName : TableThBlock.kBlotName;
  final table = _containingTable(node);
  final rowNode = _parentElement(node);
  if (table == null || rowNode == null) return delta;

  final rows = table.querySelectorAll('tr');
  final cells = rowNode.querySelectorAll(tagName.toLowerCase());
  final row = node.getAttribute('data-row') ?? '${rows.indexOf(rowNode) + 1}';
  final firstElement = node.childNodes.whereType<DomElement>().firstOrNull;
  final cellId =
      firstElement?.getAttribute('data-cell') ?? '${cells.indexOf(node) + 1}';

  var result = delta;
  if (result.length == 0) {
    result.insert('\n', {
      blotName: {'data-row': row}
    });
  }
  final normalized = Delta();
  for (final op in result.operations) {
    final attributes = op.attributes;
    final current = attributes?[blotName];
    var nextAttributes = attributes;
    if (current != null) {
      nextAttributes = <String, dynamic>{
        ...?attributes,
        blotName: <String, dynamic>{
          if (current is Map) ...current.cast<String, dynamic>(),
          'data-row': row,
        },
      };
    }
    var data = op.data;
    if (!isTd && data is String && !data.endsWith('\n')) {
      data = '$data\n';
    }
    normalized.insert(data, nextAttributes);
  }
  return applyTableFormat(normalized, childBlotName, cellId);
}

Delta matchTableBetterCol(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) return delta;
  var span = int.tryParse(node.getAttribute('span') ?? '') ?? 1;
  final width = node.getAttribute('width');
  final prefix = Delta();
  while (span > 1) {
    prefix.insert('\n', {
      TableCol.kBlotName: {'width': width}
    });
    span--;
  }
  return prefix.concat(delta);
}

Delta matchTableTemporary(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) return delta;
  final formats = <String, dynamic>{};
  for (final attribute in tableAttributes) {
    if (!node.hasAttribute(attribute)) continue;
    final raw = node.getAttribute(attribute) ?? '';
    formats[attribute == 'class' ? 'data-class' : attribute] =
        utils.filterWordStyle(raw);
  }
  return (Delta()..insert('\n', {TableTemporary.kBlotName: formats}))
      .concat(delta);
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
