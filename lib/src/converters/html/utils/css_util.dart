/// Leitura de `style` inline.
///
/// A versão original usava o package `csslib`, que não tem parser "só de
/// declarações": era preciso embrulhar o valor num seletor falso (`.x { … }`),
/// mandar parsear uma folha inteira e caminhar a AST para recuperar pares
/// propriedade/valor — com dois níveis de `try`/`catch` para lidar com
/// mudanças de API entre versões. Para o que o conversor precisa
/// (`width: 120px`, `text-align: center`, `background-color: rgb(1, 2, 3)`) o
/// formato é uma lista de `prop: valor` separada por `;`, e escrever isso são
/// 40 linhas que tiram uma dependência do pacote inteiro.
library;

/// Remove qualquer declaração `width` de uma string de estilo inline.
///
/// Duas armadilhas aqui, ambas silenciosas:
///
/// * Dart **não** aceita a flag inline `(?i)`. A versão original vinha com ela
///   e lançava `FormatException` em toda chamada — o comentário "use apenas
///   como último recurso" é provavelmente a razão de isso nunca ter aparecido.
/// * `\bwidth` **não** protege o `max-width`: o hífen já é fronteira de
///   palavra, então `\b` casa entre `max-` e `width`. A declaração só começa
///   no início da string ou depois de um `;` — e é isso que se ancora aqui.
///   Levar o `max-width` junto tiraria justamente o que segura a tabela
///   dentro da página.
String stripWidthQuick(String s) =>
    s.replaceAllMapped(_widthDeclaration, (m) => m.group(1)!);

final RegExp _widthDeclaration =
    RegExp(r'(^|;)\s*width\s*:\s*[^;]+;?', caseSensitive: false);

/// Converte `"width:120px; margin-left:1cm"` em `{width: 120px, margin-left: 1cm}`.
///
/// Nomes de propriedade vêm em minúsculas; valores preservam a forma original,
/// aparadas as bordas. Declarações sem `:`, com propriedade vazia ou com valor
/// vazio são descartadas — é o que o CSS faz.
Map<String, String> parseInlineStyleToMap(String style) {
  final map = <String, String>{};
  if (style.trim().isEmpty) return map;

  for (final declaration in _splitDeclarations(style)) {
    final colon = declaration.indexOf(':');
    if (colon <= 0) continue;
    final property = declaration.substring(0, colon).trim().toLowerCase();
    final value = declaration.substring(colon + 1).trim();
    if (property.isEmpty || value.isEmpty) continue;
    map[property] = value;
  }
  return map;
}

/// Quebra em `;` respeitando o que não pode ser cortado: os parênteses de
/// `rgb(1, 2, 3)` ou `url(a;b)` e o conteúdo entre aspas.
List<String> _splitDeclarations(String style) {
  final parts = <String>[];
  final current = StringBuffer();
  var depth = 0;
  String? quote;

  for (var i = 0; i < style.length; i++) {
    final char = style[i];
    if (quote != null) {
      current.write(char);
      if (char == quote && (i == 0 || style[i - 1] != r'')) quote = null;
      continue;
    }
    switch (char) {
      case '"':
      case "'":
        quote = char;
        current.write(char);
        break;
      case '(':
        depth++;
        current.write(char);
        break;
      case ')':
        if (depth > 0) depth--;
        current.write(char);
        break;
      case ';':
        if (depth > 0) {
          current.write(char);
        } else {
          parts.add(current.toString());
          current.clear();
        }
        break;
      default:
        current.write(char);
    }
  }
  if (current.isNotEmpty) parts.add(current.toString());
  return parts.where((part) => part.trim().isNotEmpty).toList();
}

/// Recria uma string CSS a partir do Map.
String styleMapToString(Map<String, String> m) {
  if (m.isEmpty) return '';
  final parts = <String>[];
  m.forEach((k, v) {
    parts.add('$k: $v');
  });
  return parts.join('; ') + ';';
}

/// Saneia CSS inline da <table>:
/// - Remove `width` ou substitui por `width:auto`/`max-width:100%`
/// - Pode também forçar `table-layout: fixed` para evitar overflow
String sanitizeTableStyle(String? rawStyle,
    {bool dropWidth = true, bool forceFixedLayout = true}) {
  final style = rawStyle?.trim() ?? '';
  final map = parseInlineStyleToMap(style);

  // 1) Remover ou ajustar `width`
  if (dropWidth) {
    map.remove('width');
  } else {
    map['width'] = 'auto';
    map.putIfAbsent('max-width', () => '100%');
  }

  // 2) Outras garantias úteis
  map.putIfAbsent('max-width', () => '100%');

  if (forceFixedLayout) {
    // Evita que larguras internas "estourem" o container
    map['table-layout'] = 'fixed';
    // width 100% ajuda a respeitar o container
    map['width'] = '100%';
  }

  return styleMapToString(map);
}
