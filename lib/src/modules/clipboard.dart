import 'dart:math' as math;

import '../dependencies/dart_quill_delta/dart_quill_delta.dart';

import '../blots/scroll.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/embed.dart';
import '../formats/code.dart';
import '../formats/table.dart';
import '../modules/keyboard.dart';
import '../formats/abstract/attributor.dart';
import '../platform/dom.dart';

// Placeholder for normalizeExternalHTML
class NormalizeExternalHTML {
  void normalize(DomDocument doc) {}
}

final normalizeExternalHTML = NormalizeExternalHTML();

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Type definitions
typedef Selector = dynamic; // String | DomNode.TEXT_NODE | DomNode.ELEMENT_NODE
typedef Matcher = Delta Function(DomNode node, Delta delta, Scroll scroll);

class ClipboardOptions {
  final List<dynamic> matchers;

  ClipboardOptions({
    this.matchers = const [],
  });
}

final CLIPBOARD_CONFIG = <List<dynamic>>[
  [DomNode.TEXT_NODE, matchText],
  [DomNode.TEXT_NODE, matchNewline],
  ['br', matchBreak],
  [DomNode.ELEMENT_NODE, matchNewline],
  [DomNode.ELEMENT_NODE, matchBlot],
  [DomNode.ELEMENT_NODE, matchAttributor],
  [DomNode.ELEMENT_NODE, matchStyles],
  ['li', matchIndent],
  ['ol, ul', matchList],
  ['pre', matchCodeBlock],
  ['tr', matchTable],
  ['b', createMatchAlias('bold')],
  ['i', createMatchAlias('italic')],
  ['strike', createMatchAlias('strike')],
  ['style', matchIgnore],
];

final ATTRIBUTE_ATTRIBUTORS = <String, Attributor>{}; // Placeholder
final STYLE_ATTRIBUTORS = <String, Attributor>{}; // Placeholder

class Clipboard extends Module<ClipboardOptions> {
  static final DEFAULTS = ClipboardOptions();

  final List<List<dynamic>> matchers = [];

  Clipboard(Quill quill, ClipboardOptions options) : super(quill, options) {
    quill.root.addEventListener('copy', (e) => onCaptureCopy(e as DomClipboardEvent, false));
    quill.root.addEventListener('cut', (e) => onCaptureCopy(e as DomClipboardEvent, true));
    quill.root.addEventListener('paste', (e) => onCapturePaste(e as DomClipboardEvent));

    CLIPBOARD_CONFIG.forEach((pair) {
      addMatcher(pair[0], pair[1] as Matcher);
    });
    options.matchers.forEach((pair) {
      addMatcher(pair[0], pair[1] as Matcher);
    });
  }

  void addMatcher(Selector selector, Matcher matcher) {
    matchers.add([selector, matcher]);
  }

  Delta convert({String? html, String? text, Map<String, dynamic> formats = const {}}) {
    if (formats[CodeBlock.kBlotName] != null) {
      return Delta()..insert(text ?? '', {CodeBlock.kBlotName: formats[CodeBlock.kBlotName]});
    }
    if (html == null) {
      return Delta()..insert(text ?? '', formats);
    }
    final delta = convertHTML(html);
    if (deltaEndsWith(delta, '\n') && (delta.operations.last.attributes == null || formats['table'] != null)) {
      return delta.compose(Delta()..retain(delta.length - 1)..delete(1));
    }
    return delta;
  }

  void normalizeHTML(DomDocument doc) {
    normalizeExternalHTML.normalize(doc);
  }

  Delta convertHTML(String html) {
    final doc = quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
    normalizeHTML(doc);
    final container = doc.body;
    final nodeMatches = Expando<List<Matcher>>();
    final prepared = prepareMatching(container, nodeMatches);
    final elementMatchers = prepared[0] as List<Matcher>;
    final textMatchers = prepared[1] as List<Matcher>;
    return traverse(quill.scroll, container, elementMatchers, textMatchers, nodeMatches);
  }

  void dangerouslyPasteHTML(dynamic indexOrHtml, [String? html, String source = EmitterSource.API]) {
    if (indexOrHtml is String) {
      final delta = convert(html: indexOrHtml, text: '');
      final resolvedSource = html ?? source;
      quill.setContents(delta, source: resolvedSource);
      quill.setSelection(Range(0, 0), source: EmitterSource.SILENT);
    } else if (indexOrHtml is int) {
      final paste = convert(html: html, text: '');
      quill.updateContents(Delta()..retain(indexOrHtml)..concat(paste), source: source);
      quill.setSelection(Range(indexOrHtml + paste.length, 0), source: EmitterSource.SILENT);
    }
  }

  void onCaptureCopy(DomClipboardEvent e, bool isCut) {
    if (e.defaultPrevented) return;
    e.preventDefault();
    final range = quill.selection.getRange();
    if (range == null) return;
    final result = onCopy(range, isCut);
    e.clipboardData?.setData('text/plain', result['text']);
    e.clipboardData?.setData('text/html', result['html']);
    if (isCut) {
      deleteRange(quill: quill, range: range);
    }
  }

  String normalizeURIList(String urlList) {
    return urlList.split(RegExp(r'\r?\n')).where((url) => url[0] != '#').join('\n');
  }

  void onCapturePaste(DomClipboardEvent e) {
    if (e.defaultPrevented || !quill.isEnabled()) return;
    e.preventDefault();
    final range = quill.getSelection(focus: true)!;
    final html = e.clipboardData?.getData('text/html');
    var text = e.clipboardData?.getData('text/plain');
    if (html == null && text == null) {
      final urlList = e.clipboardData?.getData('text/uri-list');
      if (urlList != null) {
        text = normalizeURIList(urlList);
      }
    }
    final files = e.clipboardData?.files ?? [];
    if (html == null && files.isNotEmpty) {
      // quill.uploader.upload(range, files); // Placeholder for uploader
      return;
    }
    if (html != null && files.isNotEmpty) {
      final doc = quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
      if (doc.body.childNodes.length == 1 && (doc.body.childNodes.first as DomElement).tagName == 'IMG') {
        // quill.uploader.upload(range, files); // Placeholder for uploader
        return;
      }
    }
    onPaste(range);
  }

  Map<String, dynamic> onCopy(Range range, [bool isCut = false]) {
    final text = quill.getText(range.index, range.length);
    final html = quill.getSemanticHTML(range.index, range.length);
    return {'html': html, 'text': text};
  }

  void onPaste(Range range, {String? text, String? html}) {
    final formats = quill.getFormat(range.index);
    final pastedDelta = convert(html: html, text: text, formats: formats);
    // quill.emitter.emit(Emitter.events.paste, pastedDelta, {
    //   'text': text,
    //   'html': html,
    // });
    final delta = Delta()..retain(range.index)..delete(range.length)..concat(pastedDelta);
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(delta.length - range.length, 0), source: EmitterSource.SILENT);
    // quill.scrollSelectionIntoView(); // Placeholder
  }

  List<dynamic> prepareMatching(DomElement container, Expando<List<Matcher>> nodeMatches) {
    final elementMatchers = <Matcher>[];
    final textMatchers = <Matcher>[];
    matchers.forEach((pair) {
      final selector = pair[0];
      final matcher = pair[1] as Matcher;
      switch (selector) {
        case DomNode.TEXT_NODE:
          textMatchers.add(matcher);
          break;
        case DomNode.ELEMENT_NODE:
          elementMatchers.add(matcher);
          break;
        default:
          container.querySelectorAll(selector as String).forEach((node) {
            if (nodeMatches[node] == null) {
              nodeMatches[node] = [];
            }
            nodeMatches[node]!.add(matcher);
          });
          break;
      }
    });
    return [elementMatchers, textMatchers];
  }
}

Operation _cloneOperation(Operation op) {
  if (op.isInsert) {
    return Operation.insert(op.data, op.attributes);
  }
  if (op.isRetain) {
    return Operation.retain(op.length, op.attributes);
  }
  return Operation.delete(op.length ?? 0);
}

Delta applyFormat(Delta delta, String format, dynamic value, Scroll scroll) {
  final hasRegistryFormat = scroll.query(format, Scope.ANY) != null ||
      ATTRIBUTE_ATTRIBUTORS.containsKey(format) ||
      STYLE_ATTRIBUTORS.containsKey(format);
  if (!hasRegistryFormat) {
    return delta;
  }

  final result = Delta();
  for (final op in delta.operations) {
    if (!op.isInsert) {
      result.push(_cloneOperation(op));
      continue;
    }

    final existing = op.attributes ?? const <String, dynamic>{};
    if (existing.containsKey(format) && existing[format] != null) {
      result.push(_cloneOperation(op));
      continue;
    }

    final merged = <String, dynamic>{};
    if (value != null && value != false) {
      merged[format] = value;
    }
    merged.addAll(existing);
    result.insert(op.data, merged.isEmpty ? null : merged);
  }
  return result;
}

bool deltaEndsWith(Delta delta, String text) {
  var endText = '';
  for (var i = delta.operations.length - 1; i >= 0 && endText.length < text.length; --i) {
    final op = delta.operations[i];
    if (op.data is! String) break;
    endText = (op.data as String) + endText;
  }
  return endText.substring(math.max(0, endText.length - text.length)) == text;
}

bool isLine(DomNode node, Scroll scroll) {
  // Placeholder
  return false;
}

bool isBetweenInlineElements(DomElement node, Scroll scroll) {
  // Placeholder
  return false;
}

final _preNodes = Expando<bool>();
bool isPre(DomNode? node) {
  if (node == null) return false;
  if (_preNodes[node] == null) {
    if (node.nodeName == 'PRE') {
      _preNodes[node] = true;
    } else {
      _preNodes[node] = isPre(node.parentNode);
    }
  }
  return _preNodes[node]!;
}

Delta traverse(
  Scroll scroll,
  DomNode node,
  List<Matcher> elementMatchers,
  List<Matcher> textMatchers,
  Expando<List<Matcher>> nodeMatches,
) {
  if (node.nodeType == DomNode.TEXT_NODE) {
    return textMatchers.fold(
        Delta(), (delta, matcher) => matcher(node, delta, scroll));
  } else if (node.nodeType == DomNode.ELEMENT_NODE) {
    final element = node as DomElement;
    final matchers = nodeMatches[element] ?? [];
    final head = elementMatchers.fold(
        Delta(), (delta, matcher) => matcher(element, delta, scroll));
    final body = [
      ...element.childNodes.map((child) =>
          traverse(scroll, child, elementMatchers, textMatchers, nodeMatches))
    ].fold(Delta(), (delta, childDelta) => delta.concat(childDelta));
    final tail = matchers.fold(
        body, (delta, matcher) => matcher(element, delta, scroll));
    return head.concat(tail);
  } else {
    return Delta();
  }
}

Matcher createMatchAlias(String format) {
  return (DomNode node, Delta delta, Scroll scroll) {
    return applyFormat(delta, format, true, scroll);
  };
}

Delta matchAttributor(DomNode node, Delta delta, Scroll scroll) {
  final formats = <String, dynamic>{};
  final element = node as DomElement;
  final classes = element.className?.split(RegExp(r'\s+')) ?? [];
  final styleAttr = element.getAttribute('style');
  final styles = styleAttr?.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty) ?? [];

  for (final name in classes) {
    final attributor = ATTRIBUTE_ATTRIBUTORS[name];
    if (attributor != null) {
      formats.addAll(attributor.value(node));
    }
  }

  for (final style in styles) {
    final parts = style.split(':');
    if (parts.length < 2) continue;
    final name = parts[0].trim();
    final attributor = STYLE_ATTRIBUTORS[name];
    if (attributor != null) {
      formats.addAll(attributor.value(node));
    }
  }

  if (formats.isNotEmpty) {
    var transformed = delta;
    formats.forEach((name, value) {
      transformed = applyFormat(transformed, name, value, scroll);
    });
    return transformed;
  }
  return delta;
}

Delta matchBlot(DomNode node, Delta delta, Scroll scroll) {
  final blotName = scroll.findBlotName(node);
  if (blotName != null) {
    final blot = scroll.find(node);
    if (blot is EmbedBlot) {
      final value = blot.value;
      return Delta()
        ..insert({blotName: value}, (blot as Embed).formats());
    } else if (blot is BlockBlot) {
      // This should not happen, as block blots are handled by other matchers
    }
  }
  return delta;
}

Delta matchBreak(DomNode node, Delta delta, Scroll scroll) {
  if (!isPre(node)) {
    delta.insert('\n');
  }
  return delta;
}

Delta matchCodeBlock(DomNode node, Delta delta, Scroll scroll) {
  final text = node.textContent ?? '';
  return Delta()..insert(text, {CodeBlock.kBlotName: true});
}

Delta matchIgnore(DomNode node, Delta delta, Scroll scroll) {
  return Delta();
}

Delta matchIndent(DomNode node, Delta delta, Scroll scroll) {
  final match = scroll.find(node).key;
  if (match is! Block || !deltaEndsWith(delta, '\n')) {
    return delta;
  }

  var indentLevel = -1;
  DomNode? current = node.parentNode;
  while (current != null) {
    final tag = (current is DomElement) ? current.tagName.toUpperCase() : '';
    if (tag == 'OL' || tag == 'UL') {
      indentLevel += 1;
    }
    current = current.parentNode;
  }

  if (indentLevel <= 0) {
    return delta;
  }

  final composed = Delta();
  for (final op in delta.operations) {
    if (!op.isInsert) {
      composed.push(_cloneOperation(op));
      continue;
    }
    final attrs = op.attributes ?? const <String, dynamic>{};
    if (attrs['indent'] is num) {
      composed.push(_cloneOperation(op));
      continue;
    }
    final merged = <String, dynamic>{'indent': indentLevel};
    merged.addAll(attrs);
    composed.insert(op.data, merged);
  }
  return composed;
}

Delta matchList(DomNode node, Delta delta, Scroll scroll) {
  final format = node.nodeName == 'OL' ? 'ordered' : 'bullet';
  return applyFormat(delta, 'list', format, scroll);
}

Delta matchNewline(DomNode node, Delta delta, Scroll scroll) {
  if (!isPre(node) &&
      (node.nextSibling is DomElement &&
          (node.nextSibling as DomElement).tagName == 'BR')) {
    return delta;
  }
  if (isLine(node, scroll) && !deltaEndsWith(delta, '\n')) {
    if (node is DomElement &&
        (node.tagName == 'LI' ||
            node.tagName == 'P' ||
            node.tagName == 'H1' ||
            node.tagName == 'H2' ||
            node.tagName == 'H3')) {
      delta.insert('\n');
    }
  }
  return delta;
}

Delta matchStyles(DomNode node, Delta delta, Scroll scroll) {
  final formats = <String, dynamic>{};
  final element = node as DomElement;
  final styleAttr = element.getAttribute('style');
  
  if (styleAttr != null && styleAttr.isNotEmpty) {
    final styles = styleAttr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);
    
    for (final style in styles) {
      final parts = style.split(':');
      if (parts.length < 2) continue;
      
      final prop = parts[0].trim();
      final value = parts.sublist(1).join(':').trim();
      
      if (prop == 'font-weight' && (value == 'bold' || (int.tryParse(value) ?? 0) >= 700)) {
        formats['bold'] = true;
      } else if (prop == 'font-style' && value == 'italic') {
        formats['italic'] = true;
      } else if (prop == 'text-decoration' && value.contains('underline')) {
        formats['underline'] = true;
      } else if (prop == 'text-decoration' && value.contains('line-through')) {
        formats['strike'] = true;
      } else if (prop == 'vertical-align' && value == 'super') {
        formats['script'] = 'super';
      } else if (prop == 'vertical-align' && value == 'sub') {
        formats['script'] = 'sub';
      } else if (prop == 'color' && value.isNotEmpty) {
        formats['color'] = value;
      } else if (prop == 'background-color' && value.isNotEmpty) {
        formats['background'] = value;
      } else if (prop == 'font-family' && value.isNotEmpty) {
        formats['font'] = value.split(',').first.trim();
      } else if (prop == 'font-size' && value.isNotEmpty) {
        formats['size'] = value;
      } else if (prop == 'text-align' && value.isNotEmpty) {
        formats['align'] = value;
      } else if (prop == 'direction' && value.isNotEmpty) {
        formats['direction'] = value;
      }
    }
  }

  if (formats.isEmpty) {
    return delta;
  }

  var transformed = delta;
  formats.forEach((name, value) {
    transformed = applyFormat(transformed, name, value, scroll);
  });
  return transformed;
}

Delta matchTable(DomNode node, Delta delta, Scroll scroll) {
  final table = node.parentNode?.parentNode;
  if (table != null) {
    final tableBlot = scroll.find(table);
    if (tableBlot.key is! TableBlot) {
      return applyFormat(delta, 'table', (table as DomElement?)?.id, scroll);
    }
  }
  return delta;
}

Delta matchText(DomNode node, Delta delta, Scroll scroll) {
  var text = node.textContent ?? '';
  if (!isPre(node)) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    if (node.previousSibling == null || isLine(node.previousSibling!, scroll)) {
      text = text.trimLeft();
    }
    if (node.nextSibling == null || isLine(node.nextSibling!, scroll)) {
      text = text.trimRight();
    }
  }
  return Delta()..insert(text);
}


