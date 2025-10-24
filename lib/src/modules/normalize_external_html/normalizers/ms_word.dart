import '../../../platform/dom.dart';

final _ignoreRegexp = RegExp(r'\bmso-list:[^;]*ignore', caseSensitive: false);
final _idRegexp = RegExp(r'\bmso-list:[^;]*\bl(\d+)', caseSensitive: false);
final _indentRegexp = RegExp(r'\bmso-list:[^;]*\blevel(\d+)', caseSensitive: false);

class _ParsedListItem {
  _ParsedListItem({
    required this.id,
    required this.indent,
    required this.type,
    required this.element,
  });

  final int id;
  final int indent;
  final String type;
  final DomElement element;
}

_ParsedListItem? _parseListItem(DomElement element, String html) {
  final style = element.getAttribute('style');
  final idMatch = style == null ? null : _idRegexp.firstMatch(style);
  if (idMatch == null) {
    return null;
  }

  final id = int.tryParse(idMatch.group(1) ?? '');
  if (id == null) {
    return null;
  }

  final indentMatch = style == null ? null : _indentRegexp.firstMatch(style);
  final indent = indentMatch == null
      ? 1
      : (int.tryParse(indentMatch.group(1) ?? '') ?? 1);

  final typeRegexp = RegExp(
    '@list l$id:level$indent\\s*\\{[^\\}]*mso-level-number-format:\\s*([\\w-]+)',
    caseSensitive: false,
  );
  final typeMatch = typeRegexp.firstMatch(html);
  final type =
      typeMatch != null && typeMatch.group(1)?.toLowerCase() == 'bullet'
          ? 'bullet'
          : 'ordered';

  return _ParsedListItem(
    id: id,
    indent: indent,
    type: type,
    element: element,
  );
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

void _normalizeListItem(DomDocument doc) {
  final nodes = doc.querySelectorAll('[style*=mso-list]');
  final ignored = <DomElement>[];
  final others = <DomElement>[];

  for (final node in nodes) {
    final style = node.getAttribute('style') ?? '';
    if (_ignoreRegexp.hasMatch(style)) {
      ignored.add(node);
    } else {
      others.add(node);
    }
  }

  for (final node in ignored) {
    node.remove();
  }

  final html = doc.documentElement.innerHTML ?? '';
  final pending = <_ParsedListItem>[];
  for (final element in others) {
    final parsed = _parseListItem(element, html);
    if (parsed != null) {
      pending.add(parsed);
    }
  }

  while (pending.isNotEmpty) {
    final childListItems = <_ParsedListItem>[];
    var current = pending.removeAt(0);

    while (true) {
      childListItems.add(current);
      if (pending.isEmpty) {
        break;
      }
      final next = pending.first;
    final nextSibling = _nextElementSibling(current.element);
    if (nextSibling != null && next.element == nextSibling &&
      next.id == current.id) {
        current = pending.removeAt(0);
        continue;
      }
      break;
    }

    final listElement = doc.createElement('ul');
    for (final item in childListItems) {
      final li = doc.createElement('li');
      li.setAttribute('data-list', item.type);
      if (item.indent > 1) {
        li.setAttribute('class', 'ql-indent-${item.indent - 1}');
      }
      li.innerHTML = item.element.innerHTML;
      listElement.append(li);
    }

    final firstElement = childListItems.first.element;
    final parentNode = firstElement.parentNode;
    if (parentNode != null) {
      parentNode.insertBefore(listElement, firstElement);
    }
    for (final item in childListItems) {
      item.element.remove();
    }
  }
}

void normalizeMsWord(DomDocument doc) {
  final root = doc.documentElement;
  if (root.getAttribute('xmlns:w') ==
      'urn:schemas-microsoft-com:office:word') {
    _normalizeListItem(doc);
  }
}
