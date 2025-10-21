import '../blots/block.dart';
import '../blots/container.dart';
import '../blots/abstract/blot.dart';
import 'dart:html';

class TableCell extends Block {
  TableCell(HtmlElement domNode) : super(domNode);

  static const String blotName = 'table';
  static const String tagName = 'TD';

  static HtmlElement create(String? value) {
    final node = HtmlElement.td();
    if (value != null) {
      node.setAttribute('data-row', value);
    } else {
      node.setAttribute('data-row', tableId());
    }
    return node;
  }

  static String? formats(HtmlElement domNode) {
    if (domNode.hasAttribute('data-row')) {
      return domNode.getAttribute('data-row');
    }
    return null;
  }

  int cellOffset() {
    if (parent != null) {
      return parent!.children.indexOf(this);
    }
    return -1;
  }

  @override
  void format(String name, dynamic value) {
    if (name == TableCell.blotName && value != null) {
      domNode.setAttribute('data-row', value.toString());
    } else {
      super.format(name, value);
    }
  }

  TableRow row() {
    return parent as TableRow;
  }

  int rowOffset() {
    if (row() != null) {
      return row().rowOffset();
    }
    return -1;
  }

  TableContainer? table() {
    return row().parent?.parent as TableContainer?;
  }

  @override
  Blot clone() => TableCell(domNode.clone(true) as HtmlElement);
}

class TableRow extends Container {
  TableRow(HtmlElement domNode) : super(domNode);

  static const String blotName = 'table-row';
  static const String tagName = 'TR';
  static List<Type> allowedChildren = [TableCell];
  static Type requiredContainer = TableBody; // Placeholder for TableBody

  bool checkMerge() {
    // Placeholder for super.checkMerge() and children.head/tail
    return false;
  }

  @override
  void optimize([dynamic context]) {
    super.optimize(context);
    // Placeholder for children.forEach and splitAfter
  }

  int rowOffset() {
    if (parent != null) {
      return parent!.children.indexOf(this);
    }
    return -1;
  }

  TableContainer? table() {
    return parent?.parent as TableContainer?;
  }

  @override
  Blot clone() => TableRow(domNode.clone(true) as HtmlElement);
}

class TableBody extends Container {
  TableBody(HtmlElement domNode) : super(domNode);

  static const String blotName = 'table-body';
  static const String tagName = 'TBODY';
  static List<Type> allowedChildren = [TableRow];
  static Type requiredContainer = TableContainer; // Placeholder for TableContainer

  @override
  Blot clone() => TableBody(domNode.clone(true) as HtmlElement);
}

class TableContainer extends Container {
  TableContainer(HtmlElement domNode) : super(domNode);

  static const String blotName = 'table-container';
  static const String tagName = 'TABLE';
  static List<Type> allowedChildren = [TableBody];

  void balanceCells() {
    // Placeholder for descendants and children.forEach
  }

  List<TableCell?> cells(int column) {
    return rows().map((row) => row.children[column] as TableCell?).toList();
  }

  void deleteColumn(int index) {
    // Placeholder for descendant and children.forEach
  }

  void insertColumn(int index) {
    // Placeholder for descendant and children.forEach
  }

  void insertRow(int index) {
    // Placeholder for descendant and children.forEach
  }

  List<TableRow> rows() {
    final body = children.first as TableBody?;
    if (body == null) return [];
    return body.children.map((row) => row as TableRow).toList();
  }

  @override
  Blot clone() => TableContainer(domNode.clone(true) as HtmlElement);
}

String tableId() {
  return 'row-${(DateTime.now().millisecondsSinceEpoch % 100000).toString()}'; // Simple ID generation
}
