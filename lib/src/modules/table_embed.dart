import '../core/module.dart';
import '../core/quill.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';

Map<String, dynamic> _normalizeTableData(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Map<String, dynamic>.from(data);
  }
  if (data is Map) {
    return data.map((dynamic key, dynamic value) =>
        MapEntry(key is String ? key : key.toString(), value));
  }
  return <String, dynamic>{};
}

Delta _deltaFrom(dynamic value) {
  if (value is Delta) {
    return Delta.from(value);
  }
  if (value is List) {
    return Delta.fromJson(value);
  }
  return Delta();
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((dynamic key, dynamic val) =>
        MapEntry(key is String ? key : key.toString(), val));
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? _mapFromDynamic(dynamic value) {
  if (value == null) {
    return null;
  }
  final map = _asStringMap(value);
  return map.isEmpty ? null : map;
}

dynamic _cloneData(dynamic value) {
  if (value is Delta) {
    return Delta.from(value);
  }
  if (value is List) {
    return value.map(_cloneData).toList();
  }
  if (value is Map) {
    return value.map((dynamic key, dynamic val) =>
        MapEntry(key is String ? key : key.toString(), _cloneData(val)));
  }
  return value;
}

Map<String, dynamic>? _compactCellData(
  Delta content,
  Map<String, dynamic>? attributes,
) {
  final data = <String, dynamic>{};
  if (content.isNotEmpty) {
    data['content'] = content.toJson();
  }
  if (attributes != null && attributes.isNotEmpty) {
    data['attributes'] = attributes;
  }
  return data.isEmpty ? null : data;
}

Map<String, dynamic> _compactTableData(
  Delta rows,
  Delta columns,
  Map<String, Map<String, dynamic>> cells,
) {
  final data = <String, dynamic>{};
  if (rows.isNotEmpty) {
    data['rows'] = rows.toJson();
  }
  if (columns.isNotEmpty) {
    data['columns'] = columns.toJson();
  }
  if (cells.isNotEmpty) {
    data['cells'] = cells.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }
  return data;
}

({int row, int column}) _parseCellIdentity(String identity) {
  final parts = identity.split(':');
  final row = int.parse(parts[0]) - 1;
  final column = int.parse(parts[1]) - 1;
  return (row: row, column: column);
}

String _stringifyCellIdentity(int row, int column) => '${row + 1}:${column + 1}';

int? _composePosition(Delta delta, int index) {
  var newIndex = index;
  final iterator = DeltaIterator(delta);
  var offset = 0;
  while (iterator.hasNext && offset <= newIndex) {
    final length = iterator.peekLength();
    final op = iterator.next();
    if (op.isDelete) {
      if (length > newIndex - offset) {
        return null;
      }
      newIndex -= length;
    } else if (op.isInsert) {
      newIndex += length;
      offset += length;
    } else {
      offset += length;
    }
  }
  return newIndex;
}

Map<String, Map<String, dynamic>> _reindexCellIdentities(
  dynamic cells, {
  required Delta rows,
  required Delta columns,
}) {
  final source = _asStringMap(cells);
  final result = <String, Map<String, dynamic>>{};
  source.forEach((identity, value) {
    if (value is! Map) {
      return;
    }
    final position = _parseCellIdentity(identity);
    final rowPosition = _composePosition(rows, position.row);
    final columnPosition = _composePosition(columns, position.column);
    if (rowPosition == null || columnPosition == null) {
      return;
    }
    final newIdentity = _stringifyCellIdentity(rowPosition, columnPosition);
    result[newIdentity] = _asStringMap(value).map(
      (key, dynamic val) => MapEntry(key, _cloneData(val)),
    );
  });
  return result;
}

Map<String, dynamic> _composeTableData(
  dynamic baseRaw,
  dynamic changeRaw, {
  bool keepNull = false,
}) {
  final base = _normalizeTableData(baseRaw);
  final change = _normalizeTableData(changeRaw);
  final rows = _deltaFrom(base['rows']).compose(_deltaFrom(change['rows']));
  final columns =
      _deltaFrom(base['columns']).compose(_deltaFrom(change['columns']));
  final cells = _reindexCellIdentities(
    base['cells'],
    rows: _deltaFrom(change['rows']),
    columns: _deltaFrom(change['columns']),
  );
  final changeCells = _asStringMap(change['cells']);
  changeCells.forEach((identity, value) {
    final existing = cells[identity] ?? <String, dynamic>{};
    final baseMap = _asStringMap(existing);
    final changeMap = _asStringMap(value);
    final content = _deltaFrom(baseMap['content']).compose(
      _deltaFrom(changeMap['content']),
    );
    final attributes = Delta.composeAttributes(
      _mapFromDynamic(baseMap['attributes']),
      _mapFromDynamic(changeMap['attributes']),
      keepNull: keepNull,
    );
    final cell = _compactCellData(content, attributes);
    if (cell != null) {
      cells[identity] = cell;
    } else {
      cells.remove(identity);
    }
  });
  return _compactTableData(rows, columns, cells);
}

Map<String, dynamic> _transformTableData(
  dynamic aRaw,
  dynamic bRaw,
  bool priority,
) {
  final a = _normalizeTableData(aRaw);
  final b = _normalizeTableData(bRaw);
  final aRows = _deltaFrom(a['rows']);
  final aColumns = _deltaFrom(a['columns']);
  final bRows = _deltaFrom(b['rows']);
  final bColumns = _deltaFrom(b['columns']);

  final rows = aRows.transform(bRows, priority);
  final columns = aColumns.transform(bColumns, priority);

  final cells = _reindexCellIdentities(
    b['cells'],
    rows: bRows.transform(aRows, !priority),
    columns: bColumns.transform(aColumns, !priority),
  );

  final aCells = _asStringMap(a['cells']);
  final keys = List<String>.from(aCells.keys);
  for (final identity in keys) {
    final value = aCells[identity];
    final position = _parseCellIdentity(identity);
    final rowPosition = _composePosition(rows, position.row);
    final columnPosition = _composePosition(columns, position.column);
    if (rowPosition == null || columnPosition == null) {
      continue;
    }
    final newIdentity = _stringifyCellIdentity(rowPosition, columnPosition);
    final target = cells[newIdentity];
    if (target == null) {
      continue;
    }
    final valueMap = _asStringMap(value);
    final targetMap = _asStringMap(target);
    final content = _deltaFrom(valueMap['content']).transform(
      _deltaFrom(targetMap['content']),
      priority,
    );
    final attributes = Delta.transformAttributes(
      _mapFromDynamic(valueMap['attributes']),
      _mapFromDynamic(targetMap['attributes']),
      priority,
    );
    final cell = _compactCellData(content, attributes);
    if (cell != null) {
      cells[newIdentity] = cell;
    } else {
      cells.remove(newIdentity);
    }
  }

  return _compactTableData(rows, columns, cells);
}

Map<String, dynamic> _invertTableData(
  dynamic changeRaw,
  dynamic baseRaw,
) {
  final change = _normalizeTableData(changeRaw);
  final base = _normalizeTableData(baseRaw);
  final changeRows = _deltaFrom(change['rows']);
  final baseRows = _deltaFrom(base['rows']);
  final changeColumns = _deltaFrom(change['columns']);
  final baseColumns = _deltaFrom(base['columns']);

  final rows = changeRows.invert(baseRows);
  final columns = changeColumns.invert(baseColumns);

  final cells = _reindexCellIdentities(
    change['cells'],
    rows: rows,
    columns: columns,
  );

  final keys = List<String>.from(cells.keys);
  for (final identity in keys) {
    final changeCell = cells[identity];
    if (changeCell == null) {
      continue;
    }
    final changeMap = _asStringMap(changeCell);
    final baseCell = (base['cells'] as Map?)?.cast<String, dynamic>()[identity];
    final baseMap = _asStringMap(baseCell);
    final content = _deltaFrom(changeMap['content']).invert(
      _deltaFrom(baseMap['content']),
    );
    final attributes = Delta.invertAttributes(
      _mapFromDynamic(changeMap['attributes']),
      _mapFromDynamic(baseMap['attributes']),
    );
    final cell = _compactCellData(content, attributes);
    if (cell != null) {
      cells[identity] = cell;
    } else {
      cells.remove(identity);
    }
  }

  final baseCells = _asStringMap(base['cells']);
  baseCells.forEach((identity, value) {
    final position = _parseCellIdentity(identity);
    final rowPosition = _composePosition(changeRows, position.row);
    final columnPosition = _composePosition(changeColumns, position.column);
    if (rowPosition == null || columnPosition == null) {
      cells[identity] = _asStringMap(value).map(
        (key, dynamic val) => MapEntry(key, _cloneData(val)),
      );
    }
  });

  return _compactTableData(rows, columns, cells);
}

final EmbedHandler tableHandler = EmbedHandler(
  compose: (dynamic a, dynamic b, {bool keepNull = false}) =>
      _composeTableData(a, b, keepNull: keepNull),
  transform: (dynamic a, dynamic b, bool priority) =>
      _transformTableData(a, b, priority),
  invert: (dynamic change, dynamic base) =>
      _invertTableData(change, base),
);

class TableEmbed extends Module<dynamic> {
  TableEmbed(Quill quill, dynamic options) : super(quill, options);

  static void register() {
    Delta.registerEmbed('table-embed', tableHandler);
  }

  static void unregister() {
    Delta.unregisterEmbed('table-embed');
  }
}
