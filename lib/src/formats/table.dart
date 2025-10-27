import 'dart:math' as math;

import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/container.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

String tableId() {
  final random = math.Random();
  final value = random.nextInt(0x100000);
  return 'row-${value.toRadixString(36)}';
}

class TableContainer extends Container {
  TableContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-container';
  static const String kTagName = 'TABLE';
  static const int kScope = Scope.BLOCK_BLOT;
  static const List<Type> allowedChildren = [TableBody];

  static TableContainer create([dynamic value]) {
    if (value is DomElement) {
      return TableContainer(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    return TableContainer(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  TableBody? _tableBody() {
    for (final child in children) {
      if (child is TableBody) {
        return child;
      }
    }
    return null;
  }

  List<TableRow> rows() {
    final body = _tableBody();
    if (body == null) {
      return const <TableRow>[];
    }
    return body.children.whereType<TableRow>().toList(growable: false);
  }

  void balanceCells() {
    final tableRows = descendants<TableRow>().toList(growable: false);
    if (tableRows.isEmpty) {
      return;
    }
    final maxColumns = tableRows.fold<int>(0, (max, row) {
      return row.children.length > max ? row.children.length : max;
    });
    for (final row in tableRows) {
      final missing = maxColumns - row.children.length;
      if (missing <= 0) {
        continue;
      }
      String? referenceValue;
      if (row.children.isNotEmpty && row.children.first is TableCell) {
        referenceValue = (row.children.first as TableCell).rowId;
      }
      for (var i = 0; i < missing; i++) {
        final cell = TableCell.create(referenceValue);
        row.appendChild(cell);
        cell.optimize();
      }
    }
  }

  List<TableCell?> cells(int column) {
    return rows()
        .map((row) =>
            column >= 0 && column < row.children.length &&
                    row.children[column] is TableCell
                ? row.children[column] as TableCell
                : null)
        .toList(growable: false);
  }

  void deleteColumn(int index) {
    for (final row in rows()) {
      if (index >= 0 && index < row.children.length) {
        row.children[index].remove();
      }
    }
  }

  void insertColumn(int index) {
    for (final row in rows()) {
      final value = row.children.isNotEmpty && row.children.first is TableCell
          ? (row.children.first as TableCell).rowId
          : tableId();
      final cell = TableCell.create(value);
      final ref = (index >= 0 && index < row.children.length)
          ? row.children[index]
          : null;
      row.insertBefore(cell, ref);
    }
  }

  void insertRow(int index) {
    final body = _tableBody();
    if (body == null) {
      return;
    }
    final id = tableId();
    final row = TableRow.create();
    final templateRow = body.children.isNotEmpty &&
            body.children.first is TableRow
        ? body.children.first as TableRow
        : null;
    final columnCount = templateRow?.children.length ?? 0;
    for (var i = 0; i < columnCount; i++) {
      row.appendChild(TableCell.create(id));
    }
    final ref = (index >= 0 && index < body.children.length)
        ? body.children[index]
        : null;
    body.insertBefore(row, ref);
  }

  @override
  TableContainer clone() => TableContainer(element.cloneNode(deep: false));
}

class TableBody extends Container {
  TableBody(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-body';
  static const String kTagName = 'TBODY';
  static const int kScope = Scope.BLOCK_BLOT;
  static const List<Type> allowedChildren = [TableRow];
  static const Type requiredContainer = TableContainer;

  static TableBody create([dynamic value]) {
    if (value is DomElement) {
      return TableBody(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    return TableBody(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableBody clone() => TableBody(element.cloneNode(deep: false));
}

class TableRow extends Container {
  TableRow(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-row';
  static const String kTagName = 'TR';
  static const int kScope = Scope.BLOCK_BLOT;
  static const List<Type> allowedChildren = [TableCell];
  static const Type requiredContainer = TableBody;

  static TableRow create([dynamic value]) {
    if (value is DomElement) {
      return TableRow(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    return TableRow(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  int rowOffset() {
    final parentBlot = parent;
    if (parentBlot == null) {
      return -1;
    }
    return parentBlot.childOffset(this);
  }

  TableContainer? table() {
    final tableParent = parent?.parent;
    return tableParent is TableContainer ? tableParent : null;
  }

  @override
  TableRow clone() => TableRow(element.cloneNode(deep: false));
}

class TableCell extends Block {
  TableCell(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table';
  static const String kTagName = 'TD';
  static const int kScope = Scope.BLOCK_BLOT;
  static const Type requiredContainer = TableRow;

  static TableCell create([dynamic value]) {
    if (value is DomElement) {
      return TableCell(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    final resolved = value?.toString();
    if (resolved != null && resolved.isNotEmpty) {
      node.setAttribute('data-row', resolved);
    } else {
      node.setAttribute('data-row', tableId());
    }
    return TableCell(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  String? get rowId => element.getAttribute('data-row');

  int cellOffset() => parent?.childOffset(this) ?? -1;

  TableRow? row() => parent is TableRow ? parent as TableRow : null;

  int rowOffset() => row()?.rowOffset() ?? -1;

  TableContainer? table() => row()?.table();

  @override
  Map<String, dynamic> formats() {
    final formats = super.formats();
    final rowValue = rowId;
    if (rowValue != null && rowValue.isNotEmpty) {
      return {
        ...formats,
        'table': rowValue,
      };
    }
    return formats;
  }

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName) {
      if (value == null || value == false) {
        element.removeAttribute('data-row');
      } else {
        element.setAttribute('data-row', value.toString());
      }
      return;
    }
    super.format(name, value);
  }

  @override
  TableCell clone() => TableCell(element.cloneNode(deep: true));
}


