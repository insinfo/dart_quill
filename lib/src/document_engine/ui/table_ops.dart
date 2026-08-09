/// Operações estruturais de tabela — funções PURAS sobre o estado.
///
/// Separadas da UI de propósito: a aba contextual e uma futura quickbar
/// flutuante chamam as MESMAS funções, e elas são testáveis sem montar
/// chrome nenhum.
library;

import '../model/index.dart';
import '../state/index.dart';

/// A profundidade da tabela que contém a seleção, ou null.
int? tableDepthOf(EditorState state) {
  final resolved = state.selection.fromRes;
  for (var depth = resolved.depth; depth > 0; depth--) {
    if (resolved.node(depth).type.name == 'table') return depth;
  }
  return null;
}

PMNode _emptyCell(Schema schema) =>
    schema.node('tableCell', null, Fragment.from([schema.node('paragraph')]));

/// Insere uma linha acima/abaixo da linha da seleção.
void tableInsertRow(
  EditorState state,
  void Function(Transaction) dispatch,
  Schema schema, {
  required bool above,
}) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final row = resolved.node(depth + 1);
  final newRow = schema.node(
      'tableRow',
      null,
      Fragment.from(
          [for (var c = 0; c < row.childCount; c++) _emptyCell(schema)]));
  final pos = above ? resolved.before(depth + 1) : resolved.after(depth + 1);
  dispatch(state.tr..insert(pos, newRow));
}

/// Exclui a linha da seleção; a última linha exclui a tabela inteira.
void tableDeleteRow(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  if (resolved.node(depth).childCount <= 1) {
    tableDelete(state, dispatch);
    return;
  }
  dispatch(
      state.tr..delete(resolved.before(depth + 1), resolved.after(depth + 1)));
}

/// Insere uma coluna à esquerda/direita da coluna da seleção, em TODAS as
/// linhas.
///
/// As posições são calculadas no documento ATUAL e aplicadas em ordem
/// DECRESCENTE: cada inserção anterior não desloca as seguintes.
void tableInsertColumn(
  EditorState state,
  void Function(Transaction) dispatch,
  Schema schema, {
  required bool before,
}) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final table = resolved.node(depth);
  final colIndex = resolved.index(depth + 1);
  final tableStart = resolved.start(depth);

  final insertions = <int>[];
  var rowOffset = tableStart;
  for (var r = 0; r < table.childCount; r++) {
    final row = table.child(r);
    var cellOffset = rowOffset + 1;
    for (var c = 0; c < row.childCount; c++) {
      if (c == colIndex) {
        insertions
            .add(before ? cellOffset : cellOffset + row.child(c).nodeSize);
        break;
      }
      cellOffset += row.child(c).nodeSize;
    }
    rowOffset += row.nodeSize;
  }
  final tr = state.tr;
  for (final pos in insertions.reversed) {
    tr.insert(pos, _emptyCell(schema));
  }
  dispatch(tr);
}

/// Exclui a coluna da seleção; a última coluna exclui a tabela inteira.
void tableDeleteColumn(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final table = resolved.node(depth);
  if (table.child(0).childCount <= 1) {
    tableDelete(state, dispatch);
    return;
  }
  final colIndex = resolved.index(depth + 1);
  final tableStart = resolved.start(depth);

  final ranges = <(int, int)>[];
  var rowOffset = tableStart;
  for (var r = 0; r < table.childCount; r++) {
    final row = table.child(r);
    var cellOffset = rowOffset + 1;
    for (var c = 0; c < row.childCount; c++) {
      final size = row.child(c).nodeSize;
      if (c == colIndex) {
        ranges.add((cellOffset, cellOffset + size));
        break;
      }
      cellOffset += size;
    }
    rowOffset += row.nodeSize;
  }
  final tr = state.tr;
  for (final (start, end) in ranges.reversed) {
    tr.delete(start, end);
  }
  dispatch(tr);
}

/// Exclui a tabela inteira.
void tableDelete(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  dispatch(state.tr..delete(resolved.before(depth), resolved.after(depth)));
}
