/// Normalizador estendido de HTML colado do Microsoft Word — o porte
/// genérico do `sali_word_paste.js` (434 linhas, em produção no SALI),
/// rodando ANTES do `normalizeMsWord` nativo. Corrige o que o normalizador
/// do Quill 2.0.3 perde:
///
/// 1. **Numeração literal** (W3): o nativo converte cada parágrafo
///    `mso-list` em `<li>` e descarta o marcador literal; como o Quill
///    renumera de 1, títulos numerados isolados ("2. Descrição…") viravam
///    todos "1.". Itens isolados (ou grupos que não começam em "1.")
///    mantêm o texto do marcador como texto normal.
/// 2. **Tipo de lista pelo marcador** (W3): o nativo depende do regex de
///    `@list` no `<style>`, que falha com frequência e transforma bullets em
///    numeradas; aqui o tipo vem do próprio marcador ("1." → ordered;
///    "·"/"o"/"-" → bullet).
/// 3. **Gate largo** (W4): HTML de Word sem `xmlns:w` (Outlook Web e
///    variantes com `class="Mso…"`/`mso-list`) também é normalizado.
/// 4. **Negrito por classe do `<style>`** (W6): o DOMParser não aplica CSS,
///    então `p.Nivel01 {font-weight:bold}` se perdia.
/// 5. **Espaçamento entre parágrafos** (W7): `margin-bottom` efetivo ≥ 4pt
///    vira um `<p><br></p>` — a única representação de espaço-depois que
///    sobrevive no Delta e no PDF.
library;

import '../../../platform/dom.dart';

final _markerStyleRegexp =
    RegExp(r'mso-list\s*:[^;]*\bignore\b', caseSensitive: false);
final _listStyleRegexp = RegExp(r'\bmso-list\s*:', caseSensitive: false);
final _listIdRegexp =
    RegExp(r'\bmso-list\s*:[^;]*\bl(\d+)\b', caseSensitive: false);
final _listLevelRegexp =
    RegExp(r'\bmso-list\s*:[^;]*\blevel(\d+)\b', caseSensitive: false);

/// "1." "12)" "a." "B)" "iv." "(3)" etc.
final _orderedMarkerRegexp = RegExp(r'^\(?[0-9a-zA-Z]{1,4}[.)]$');

/// Primeiro item de uma sequência que o Quill consegue numerar sozinho.
final _firstMarkerRegexp = RegExp(r'^\(?(1|a|A|i|I)[.)]$');

/// Espaço-depois mínimo (pt) para virar parágrafo em branco.
const double _minSpacingPt = 4;

bool _looksLikeWordDocument(DomDocument doc) {
  final root = doc.documentElement;
  if (root.getAttribute('xmlns:w') == 'urn:schemas-microsoft-com:office:word') {
    return true;
  }
  if (doc.querySelectorAll('[style*=mso-list]').isNotEmpty) {
    return true;
  }
  // `class="MsoNormal"` e afins, sem namespace (Outlook Web e variantes).
  // Seletores um a um: nem todo DOM de teste entende lista com vírgula.
  for (final tag in const ['p', 'div', 'span', 'td']) {
    if (doc
        .querySelectorAll(tag)
        .any((el) => (el.getAttribute('class') ?? '').startsWith('Mso'))) {
      return true;
    }
  }
  return false;
}

String _styleOf(DomElement element) => element.getAttribute('style') ?? '';

class _WordListItem {
  _WordListItem({
    required this.element,
    required this.id,
    required this.level,
    required this.markerText,
  });

  final DomElement element;
  final int id;
  final int level;
  final String markerText;

  bool get isOrdered =>
      markerText.isEmpty || _orderedMarkerRegexp.hasMatch(markerText);
}

DomElement? _nextElementSibling(DomElement element) {
  DomNode? current = element.nextSibling;
  while (current != null) {
    if (current is DomElement) return current;
    current = current.nextSibling;
  }
  return null;
}

DomElement? _findMarkerElement(DomElement item) {
  for (final candidate in item.querySelectorAll('[style]')) {
    if (_markerStyleRegexp.hasMatch(_styleOf(candidate))) return candidate;
  }
  return null;
}

List<_WordListItem> _parseListItems(DomDocument doc) {
  final items = <_WordListItem>[];
  for (final element in doc.querySelectorAll('[style*=mso-list]')) {
    final style = _styleOf(element);
    if (_markerStyleRegexp.hasMatch(style)) {
      continue; // marcador, tratado junto do item pai
    }
    final idMatch = _listIdRegexp.firstMatch(style);
    if (idMatch == null) continue;
    final levelMatch = _listLevelRegexp.firstMatch(style);
    final marker = _findMarkerElement(element);
    final markerText = marker == null
        ? ''
        : (marker.textContent ?? '')
            .replaceAll(RegExp(r'[\s ]+'), ' ')
            .trim();
    marker?.remove();
    items.add(_WordListItem(
      element: element,
      id: int.parse(idMatch.group(1)!),
      level: levelMatch == null ? 1 : int.parse(levelMatch.group(1)!),
      markerText: markerText,
    ));
  }
  return items;
}

/// Agrupa itens contíguos (irmãos consecutivos) com o mesmo id de lista.
List<List<_WordListItem>> _groupItems(List<_WordListItem> items) {
  final groups = <List<_WordListItem>>[];
  List<_WordListItem>? current;
  for (final item in items) {
    final previous = current?.last;
    if (previous != null &&
        previous.id == item.id &&
        _nextElementSibling(previous.element)?.identityKey ==
            item.element.identityKey) {
      current!.add(item);
    } else {
      current = <_WordListItem>[item];
      groups.add(current);
    }
  }
  return groups;
}

bool _groupBecomesQlList(List<_WordListItem> group) {
  if (group.length < 2) return false;
  final allBullet = group.every((item) => !item.isOrdered);
  if (allBullet) return true;
  final allOrdered = group.every((item) => item.isOrdered);
  // Lista numerada: só deixa o Quill numerar quando a sequência começa do
  // início ("1.", "a.", "i."); continuações ("8.") mantêm o número literal.
  return allOrdered && _firstMarkerRegexp.hasMatch(group.first.markerText);
}

void _convertGroupToQlList(DomDocument doc, List<_WordListItem> group) {
  final ul = doc.createElement('ul');
  for (final item in group) {
    final li = doc.createElement('li');
    li.setAttribute('data-list', item.isOrdered ? 'ordered' : 'bullet');
    if (item.level > 1) {
      li.setAttribute('class', 'ql-indent-${item.level - 1}');
    }
    li.innerHTML = item.element.innerHTML;
    ul.append(li);
  }
  final first = group.first.element;
  first.parentNode?.insertBefore(ul, first);
  for (final item in group) {
    item.element.remove();
  }
}

void _removeMsoListStyle(DomElement element) {
  final style = _styleOf(element);
  if (!_listStyleRegexp.hasMatch(style)) return;
  element.setAttribute(
      'style',
      style.replaceAll(
          RegExp(r'(^|;)\s*mso-list\s*:[^;]*', caseSensitive: false), r'$1'));
}

void _keepGroupAsLiteralParagraphs(DomDocument doc, List<_WordListItem> group) {
  for (final item in group) {
    if (item.markerText.isNotEmpty) {
      item.element.insertBefore(
          doc.createTextNode('${item.markerText} '), item.element.firstChild);
    }
    // Sem isto o normalizador nativo reprocessa o parágrafo e descarta o
    // número literal que acabamos de preservar.
    _removeMsoListStyle(item.element);
  }
}

// ---------------------------------------------------------------------------
// <style> do Word: classes bold e margens por classe.
// ---------------------------------------------------------------------------

final _cssRuleRegexp = RegExp(r'([^{}]+)\{([^{}]*)\}');
final _classSelectorRegexp = RegExp(r'^\s*(?:p|li|div|h[1-6])\.([\w-]+)\s*$');

Set<String> _collectBoldClasses(String styleText) {
  final classes = <String>{};
  for (final rule in _cssRuleRegexp.allMatches(styleText)) {
    if (!RegExp(r'font-weight\s*:\s*bold', caseSensitive: false)
        .hasMatch(rule.group(2)!)) {
      continue;
    }
    for (final selector in rule.group(1)!.split(',')) {
      final match = _classSelectorRegexp.firstMatch(selector);
      if (match != null) classes.add(match.group(1)!);
    }
  }
  return classes;
}

double _marginValueToPt(String raw) {
  final match = RegExp(r'^(-?[\d.]+)\s*(pt|cm|in|px|mm)?$', caseSensitive: false)
      .firstMatch(raw.trim());
  if (match == null) return 0;
  final value = double.tryParse(match.group(1)!) ?? 0;
  switch ((match.group(2) ?? 'pt').toLowerCase()) {
    case 'cm':
      return value * 28.35;
    case 'mm':
      return value * 2.835;
    case 'in':
      return value * 72;
    case 'px':
      return value * 0.75;
    default:
      return value;
  }
}

/// margin-bottom (em pt) declarado num corpo de regra/atributo style.
double? _marginBottomFromCss(String cssText) {
  if (cssText.isEmpty) return null;
  final direct =
      RegExp(r'(?:^|;)\s*margin-bottom\s*:\s*([^;}]+)', caseSensitive: false)
          .firstMatch(cssText);
  if (direct != null) return _marginValueToPt(direct.group(1)!);
  final shorthand =
      RegExp(r'(?:^|;)\s*margin\s*:\s*([^;}]+)', caseSensitive: false)
          .firstMatch(cssText);
  if (shorthand != null) {
    final parts = shorthand.group(1)!.trim().split(RegExp(r'\s+'));
    // margin: [top] [right] [bottom] [left] (1 a 4 valores)
    final bottom = parts.length >= 3 ? parts[2] : parts.first;
    return _marginValueToPt(bottom);
  }
  return null;
}

Map<String, double> _collectClassMarginBottom(String styleText) {
  final margins = <String, double>{};
  for (final rule in _cssRuleRegexp.allMatches(styleText)) {
    final value = _marginBottomFromCss(rule.group(2)!);
    if (value == null) continue;
    for (final selector in rule.group(1)!.split(',')) {
      final match = _classSelectorRegexp.firstMatch(selector);
      if (match != null) margins[match.group(1)!] = value;
    }
  }
  return margins;
}

bool _isBlankBlock(DomElement? element) {
  if (element == null) return false;
  return (element.textContent ?? '')
      .replaceAll(RegExp(r'[\s ]+'), '')
      .isEmpty;
}

bool _isInsideTableCell(DomElement element) {
  DomNode? current = element.parentNode;
  while (current != null) {
    if (current is DomElement) {
      final tag = current.tagName.toLowerCase();
      if (tag == 'td' || tag == 'th') return true;
    }
    current = current.parentNode;
  }
  return false;
}

void _applyBoldClasses(DomDocument doc, Set<String> boldClasses) {
  if (boldClasses.isEmpty) return;
  final blocks = <DomElement>[
    for (final tag in const ['p', 'li', 'div'])
      ...doc.body.querySelectorAll(tag),
  ];
  for (final element in blocks) {
    final classAttr = element.getAttribute('class');
    if (classAttr == null) continue;
    final isBold =
        classAttr.split(RegExp(r'\s+')).any(boldClasses.contains);
    if (!isBold || (element.textContent ?? '').trim().isEmpty) continue;
    if (element.querySelector('b') != null ||
        element.querySelector('strong') != null) {
      continue; // já tem negrito explícito
    }
    element.innerHTML = '<b>${element.innerHTML}</b>';
  }
}

/// Insere `<p><br></p>` após parágrafos com espaço-depois relevante.
void _applyParagraphSpacing(DomDocument doc, Map<String, double> classMargins) {
  for (final element in doc.body.querySelectorAll('p')) {
    if (_isBlankBlock(element)) continue;
    if (_isInsideTableCell(element)) {
      continue; // não inflar linhas de tabela com espaçadores
    }
    final next = _nextElementSibling(element);
    if (next == null) continue; // último bloco do pai
    if (next.tagName.toLowerCase() == 'p' && _isBlankBlock(next)) {
      continue; // o Word já colocou um parágrafo vazio de espaçamento
    }

    double? margin = _marginBottomFromCss(_styleOf(element));
    if (margin == null) {
      final classAttr = element.getAttribute('class');
      if (classAttr != null) {
        for (final name in classAttr.split(RegExp(r'\s+'))) {
          final fromClass = classMargins[name];
          if (fromClass != null) {
            margin = fromClass;
            break;
          }
        }
      }
    }
    if (margin == null || margin < _minSpacingPt) continue;

    final spacer = doc.createElement('p');
    spacer.append(doc.createElement('br'));
    element.parentNode?.insertBefore(spacer, element.nextSibling);
  }
}

/// O normalizador estendido. Roda ANTES do `normalizeMsWord` nativo: os
/// grupos convertidos aqui saem do alcance dele, e os itens mantidos como
/// texto literal perdem o `mso-list` para ele não os reprocessar.
void normalizeWordPaste(DomDocument doc) {
  if (!_looksLikeWordDocument(doc)) return;

  final styleText = doc
      .querySelectorAll('style')
      .map((tag) => tag.textContent ?? '')
      .join('\n');

  final groups = _groupItems(_parseListItems(doc));
  for (final group in groups) {
    if (_groupBecomesQlList(group)) {
      _convertGroupToQlList(doc, group);
    } else {
      _keepGroupAsLiteralParagraphs(doc, group);
    }
  }
  // Marcadores órfãos (fora de itens com id) também não podem virar texto.
  for (final element in doc.querySelectorAll('[style*=mso-list]')) {
    if (_markerStyleRegexp.hasMatch(_styleOf(element))) element.remove();
  }

  _applyBoldClasses(doc, _collectBoldClasses(styleText));
  _applyParagraphSpacing(doc, _collectClassMarginBottom(styleText));
}
