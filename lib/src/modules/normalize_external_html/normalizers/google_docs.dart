import '../../../platform/dom.dart';

final _normalWeightRegexp = RegExp(r'font-weight:\s*normal');
const _blockTagNames = {'P', 'OL', 'UL'};

bool _isBlockElement(DomElement? element) {
  return element != null && _blockTagNames.contains(element.tagName);
}

DomElement? _previousElementSibling(DomElement element) {
  DomNode? current = element.previousSibling;
  while (current != null) {
    if (current is DomElement) {
      return current;
    }
    current = current.previousSibling;
  }
  return null;
}

DomElement? _nextElementSibling(DomElement element) {
  DomNode? current = element.nextSibling;
  while (current != null) {
    if (current is DomElement) {
      return current;
    }
    current = current.nextSibling;
  }
  return null;
}

void _normalizeEmptyLines(DomDocument doc) {
  final brs = doc.querySelectorAll('br');
  for (final br in brs) {
    final previousElement = _previousElementSibling(br);
    final nextElement = _nextElementSibling(br);
    if (_isBlockElement(previousElement) && _isBlockElement(nextElement)) {
      br.remove();
    }
  }
}

void _normalizeFontWeight(DomDocument doc) {
  final nodes = doc.querySelectorAll('b[style*="font-weight"]');
  for (final node in nodes) {
    final style = node.getAttribute('style');
    if (style == null || !_normalWeightRegexp.hasMatch(style)) {
      continue;
    }
    final parent = node.parentNode;
    if (parent == null) {
      continue;
    }
    final children = List<DomNode>.from(node.childNodes);
    for (final child in children) {
      parent.insertBefore(child, node);
    }
    node.remove();
  }
}

void normalizeGoogleDocs(DomDocument doc) {
  if (doc.querySelector('[id^="docs-internal-guid-"]') != null) {
    _normalizeFontWeight(doc);
    _normalizeEmptyLines(doc);
  }
}
