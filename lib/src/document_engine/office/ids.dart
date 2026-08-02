/// IDs estáveis de nó (Fase 1 do modo avançado).
///
/// A árvore é imutável e os nós não têm identidade própria — o vínculo
/// estável (source map OOXML, assinatura de página do layout incremental,
/// comentários, cache tipográfico por nó) viaja num atributo `id` declarado
/// no spec dos nós de bloco. Este plugin garante o invariante: depois de
/// toda transação que muda o documento, cada nó COM atributo `id` no spec
/// tem um id único no documento — nulos ganham id novo e duplicados (um
/// copiar/colar duplica ids) são re-cunhados na segunda ocorrência.
library;

import '../model/index.dart';
import '../state/index.dart';

/// Nome do atributo de identidade nos specs de nó.
const String officeIdAttribute = 'id';

/// Lê o id estável de um nó, ou null se o spec não declara/não tem.
String? officeNodeId(PMNode node) {
  final value = node.attrs[officeIdAttribute];
  return value is String ? value : null;
}

/// Gerador padrão: prefixo + contador em base36 + entropia do relógio.
/// Determinismo nos testes vem de injetar um gerador próprio.
String Function() defaultOfficeIdGenerator({String prefix = 'n'}) {
  var counter = 0;
  final epoch = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return () => '$prefix-$epoch-${(counter++).toRadixString(36)}';
}

/// Plugin que mantém o invariante de unicidade dos ids.
Plugin<void> officeIdsPlugin({String Function()? generate}) {
  final next = generate ?? defaultOfficeIdGenerator();
  return Plugin<void>(
    PluginSpec<void>(
      key: PluginKey<void>('officeIds'),
      appendTransaction: (transactions, oldState, newState) {
        if (!transactions.any((tr) => tr.docChanged)) return null;
        // Varredura completa: correta por construção (colar, undo e steps
        // estruturais movem subárvores inteiras); a incremental por ranges
        // mapeados entra quando o custo aparecer em medição, não antes.
        final seen = <String>{};
        final fixes = <MapEntry<int, String>>[];
        newState.doc.descendants((node, pos, parent, index) {
          if (!node.type.attrs.containsKey(officeIdAttribute)) {
            return true;
          }
          final id = officeNodeId(node);
          if (id == null || !seen.add(id)) {
            fixes.add(MapEntry(pos, next()));
          }
          return true;
        });
        if (fixes.isEmpty) return null;
        final tr = newState.tr;
        for (final fix in fixes) {
          tr.setNodeAttribute(fix.key, officeIdAttribute, fix.value);
        }
        return tr;
      },
    ),
  );
}
