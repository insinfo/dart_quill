import 'dart:math' as math;

import '../dependencies/dart_quill_delta/dart_quill_delta.dart';

import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../formats/abstract/attributor.dart';
import '../formats/code.dart';
import '../formats/header.dart';
import '../formats/image.dart';
import '../formats/link.dart';
import '../formats/video.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import 'normalize_external_html/index.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Track clipboard-specific attributors per scroll instance so applyFormat can
// determine which custom formats are allowed when converting HTML.
final _clipboardAttributors = Expando<List<Attributor>>('_clipboardAttributors');
final _clipboardAttributorsByName =
    Expando<Map<String, Attributor>>('_clipboardAttributorsByName');

List<Attributor> _attributorsForScroll(Scroll scroll) {
  return _clipboardAttributors[scroll] ?? const <Attributor>[];
}

Map<String, Attributor> _attributorMapForScroll(Scroll scroll) {
  return _clipboardAttributorsByName[scroll] ?? const <String, Attributor>{};
}

// Type definitions
typedef Selector = dynamic; // String | DomNode.TEXT_NODE | DomNode.ELEMENT_NODE
typedef Matcher = Delta Function(DomNode node, Delta delta, Scroll scroll);

class ClipboardOptions {
  final List<dynamic> matchers;
  final List<Attributor> attributors;

  const ClipboardOptions({
    this.matchers = const [],
    this.attributors = const [],
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
  ['strong', createMatchAlias('bold')],
  ['i', createMatchAlias('italic')],
  ['em', createMatchAlias('italic')],
  ['strike', createMatchAlias('strike')],
  ['style', matchIgnore],
];

class Clipboard extends Module<ClipboardOptions> {
  static final DEFAULTS = ClipboardOptions();

  final List<List<dynamic>> matchers = [];

  Clipboard(Quill quill, ClipboardOptions options) : super(quill, options) {
    final attributors = List<Attributor>.from(options.attributors);
    _clipboardAttributors[quill.scroll] = attributors;
    _clipboardAttributorsByName[quill.scroll] = {
      for (final attributor in attributors) attributor.attrName: attributor,
    };

    quill.root.addEventListener(
        'copy', (e) => onCaptureCopy(e as DomClipboardEvent, false));
    quill.root.addEventListener(
        'cut', (e) => onCaptureCopy(e as DomClipboardEvent, true));
    quill.root.addEventListener(
        'paste', (e) => onCapturePaste(e as DomClipboardEvent));

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

  Delta convert(
      {String? html, String? text, Map<String, dynamic> formats = const {}}) {
    final hasCodeBlockFormat = formats.containsKey(CodeBlock.kBlotName);
    if (html == null) {
      final attrs = formats.isEmpty ? null : Map<String, dynamic>.from(formats);
      return Delta()..insert(text ?? '', attrs);
    }

    var delta = convertHTML(html);
    if (hasCodeBlockFormat) {
      delta = applyFormat(delta, CodeBlock.kBlotName,
          formats[CodeBlock.kBlotName], quill.scroll);
    } else {
      delta = _stripAttribute(delta, CodeBlock.kBlotName);
    }

    if (deltaEndsWith(delta, '\n') &&
        (delta.operations.last.attributes == null ||
            formats['table'] != null ||
            hasCodeBlockFormat)) {
      return _trimTrailingNewline(delta);
    }
    return delta;
  }

  void normalizeHTML(DomDocument doc) {
    normalizeExternalHTML.normalize(doc);
  }

  Delta convertHTML(String html) {
    final doc =
        quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
    normalizeHTML(doc);
    final container = doc.body;
    final nodeMatches = Expando<List<Matcher>>();
    final prepared = prepareMatching(container, nodeMatches);
    final elementMatchers = prepared[0] as List<Matcher>;
    final textMatchers = prepared[1] as List<Matcher>;
    return traverse(
        quill.scroll, container, elementMatchers, textMatchers, nodeMatches);
  }

  void dangerouslyPasteHTML(dynamic indexOrHtml,
      [String? html, String source = EmitterSource.API]) {
    if (indexOrHtml is String) {
  final delta = convert(html: indexOrHtml, text: '');
      final resolvedSource = html ?? source;
      quill.setContents(delta, source: resolvedSource);
      quill.setSelection(Range(0, 0), source: EmitterSource.SILENT);
    } else if (indexOrHtml is int) {
      final paste = convert(html: html, text: '');
      final change = (Delta()..retain(indexOrHtml)).concat(paste);
      quill.updateContents(change, source: source);
      final insertedLength = _deltaInsertLength(paste);
      quill.setSelection(Range(indexOrHtml + insertedLength, 0),
          source: EmitterSource.SILENT);
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
    return urlList
        .split(RegExp(r'\r?\n'))
        .where((url) => url[0] != '#')
        .join('\n');
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
      final doc =
          quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
      if (doc.body.childNodes.length == 1 &&
          (doc.body.childNodes.first as DomElement).tagName == 'IMG') {
        // quill.uploader.upload(range, files); // Placeholder for uploader
        return;
      }
    }
    onPaste(range, text: text, html: html);
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
    final baseDelta = Delta()
      ..retain(range.index)
      ..delete(range.length);
    final change = baseDelta.concat(pastedDelta);
    quill.updateContents(change, source: EmitterSource.USER);

    final insertedLength = _deltaInsertLength(pastedDelta);
    final newIndex = range.index + insertedLength;
    quill.setSelection(Range(newIndex, 0),
        source: EmitterSource.SILENT);
    // quill.scrollSelectionIntoView(); // Placeholder
  }

  List<dynamic> prepareMatching(
      DomElement container, Expando<List<Matcher>> nodeMatches) {
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
          final selectorStr = selector as String;
          final parts = selectorStr
              .split(',')
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty);
          for (final part in parts) {
            container.querySelectorAll(part).forEach((node) {
              nodeMatches[node] ??= [];
              nodeMatches[node]!.add(matcher);
            });
          }
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
  final hasRegistryFormat = scroll.query(format, Scope.ANY) != null;
  final hasAttributor = _attributorMapForScroll(scroll).containsKey(format);
  if (!hasRegistryFormat && !hasAttributor) {
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

int _deltaInsertLength(Delta delta) {
  var length = 0;
  for (final op in delta.operations) {
    if (!op.isInsert) {
      continue;
    }
    final data = op.data;
    if (data is String) {
      length += data.length;
    } else {
      length += 1;
    }
  }
  return length;
}

bool deltaEndsWith(Delta delta, String text) {
  var endText = '';
  for (var i = delta.operations.length - 1;
      i >= 0 && endText.length < text.length;
      --i) {
    final op = delta.operations[i];
    if (op.data is! String) break;
    endText = (op.data as String) + endText;
  }
  return endText.substring(math.max(0, endText.length - text.length)) == text;
}

Delta _trimTrailingNewline(Delta delta) {
  if (delta.operations.isEmpty) {
    return delta;
  }
  final last = delta.operations.last;
  final data = last.data;
  if (data is! String || !data.endsWith('\n')) {
    return delta;
  }

  final result = Delta.from(delta);
  result.operations.removeLast();

  final trimmed = data.substring(0, data.length - 1);
  if (trimmed.isNotEmpty) {
    result.insert(trimmed, last.attributes);
  }
  return result;
}

Delta _stripAttribute(Delta delta, String attribute) {
  if (delta.isEmpty) {
    return delta;
  }
  final result = Delta();
  for (final op in delta.operations) {
    Map<String, dynamic>? attrs = op.attributes;
    if (attrs != null && attrs.containsKey(attribute)) {
      attrs = Map<String, dynamic>.from(attrs)..remove(attribute);
      if (attrs.isEmpty) {
        attrs = null;
      }
    }
    if (op.isInsert) {
      result.insert(op.data, attrs);
    } else if (op.isRetain) {
      result.retain(op.length ?? 0, attrs);
    } else if (op.isDelete) {
      result.delete(op.length ?? 0);
    }
  }
  return result;
}

const _lineTagNames = {
  'address',
  'article',
  'blockquote',
  'canvas',
  'dd',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'iframe',
  'li',
  'main',
  'nav',
  'ol',
  'output',
  'p',
  'pre',
  'section',
  'table',
  'td',
  'tr',
  'ul',
  'video',
};

DomElement? _previousElementSibling(DomNode node) {
  var current = node.previousSibling;
  while (current != null) {
    if (current is DomElement) {
      return current;
    }
    current = current.previousSibling;
  }
  return null;
}

DomElement? _nextElementSibling(DomNode node) {
  var current = node.nextSibling;
  while (current != null) {
    if (current is DomElement) {
      return current;
    }
    current = current.nextSibling;
  }
  return null;
}

bool isLine(DomNode node, Scroll scroll) {
  if (node is! DomElement) {
    return false;
  }
  final tag = node.tagName.toLowerCase();
  return _lineTagNames.contains(tag);
}

int? _classIndentLevel(DomElement element) {
  final classAttr = element.className;
  if (classAttr == null || classAttr.isEmpty) {
    return null;
  }
  final match = RegExp(r'ql-indent-(\d+)').firstMatch(classAttr);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

bool isBetweenInlineElements(DomNode node, Scroll scroll) {
  final previous = _previousElementSibling(node);
  final next = _nextElementSibling(node);
  if (previous == null || next == null) {
    return false;
  }
  return !isLine(previous, scroll) && !isLine(next, scroll);
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
    return textMatchers.fold<Delta>(
      Delta(),
      (current, matcher) => matcher(node, current, scroll),
    );
  }

  if (node.nodeType == DomNode.ELEMENT_NODE) {
    final element = node as DomElement;
    final children = element.childNodes;
    return children.fold<Delta>(Delta(), (delta, child) {
      var childDelta =
          traverse(scroll, child, elementMatchers, textMatchers, nodeMatches);
      if (child.nodeType == DomNode.ELEMENT_NODE) {
        childDelta = elementMatchers.fold<Delta>(
          childDelta,
          (current, matcher) => matcher(child, current, scroll),
        );
        final matchers = nodeMatches[child];
        if (matchers != null) {
          childDelta = matchers.fold<Delta>(
            childDelta,
            (current, matcher) => matcher(child, current, scroll),
          );
        }
      }
      return delta.concat(childDelta);
    });
  }

  return Delta();
}

Matcher createMatchAlias(String format) {
  return (DomNode node, Delta delta, Scroll scroll) {
    return applyFormat(delta, format, true, scroll);
  };
}

bool _isVideoElement(DomElement element) {
  final tag = element.tagName.toUpperCase();
  if (tag == Video.kTagName) {
    return true;
  }
  return element.classes.contains(Video.kClassName);
}

bool _isBlockEmbedElement(DomElement element) {
  return _isVideoElement(element);
}

Delta matchAttributor(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) {
    return delta;
  }

  final attributors = _attributorsForScroll(scroll);
  if (attributors.isEmpty) {
    return delta;
  }

  final formats = <String, dynamic>{};
  for (final attributor in attributors) {
    final value = attributor.value(node);
    if (value == null) {
      continue;
    }
    if (value is String && value.isEmpty) {
      continue;
    }
    formats[attributor.attrName] = value;
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

Delta matchBlot(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) {
    return delta;
  }

  final tag = node.tagName.toUpperCase();

  if (tag == Image.kTagName) {
    final value = Image.getValue(node);
    if (value == null || value.isEmpty) {
      return delta;
    }
    final attrs = <String, dynamic>{};
    Image.getAttributes(node).forEach((key, attrValue) {
      if (attrValue != null && attrValue.isNotEmpty) {
        attrs[key] = attrValue;
      }
    });
    return Delta()
      ..insert({Image.kBlotName: value}, attrs.isEmpty ? null : attrs);
  }

  if (_isVideoElement(node)) {
    final src = Video.valueDom(node);
    if (src == null || src.isEmpty) {
      return delta;
    }
    final formats = <String, dynamic>{};
    Video.formatsDom(node).forEach((key, attrValue) {
      if (attrValue != null && attrValue.isNotEmpty) {
        formats[key] = attrValue;
      }
    });
    return Delta()
      ..insert({Video.kBlotName: src}, formats.isEmpty ? null : formats);
  }

  if (tag == Link.kTagName) {
    final href = Link.getFormat(node);
    if (href == null || href.isEmpty) {
      return delta;
    }
    return applyFormat(delta, Link.kBlotName, href, scroll);
  }

  if (Header.kTagNames.contains(node.tagName)) {
    if (!deltaEndsWith(delta, '\n')) {
      delta.insert('\n');
    }
    final level = Header.getLevel(node);
    return applyFormat(delta, Header.kBlotName, level, scroll);
  }
  return delta;
}

Delta matchBreak(DomNode node, Delta delta, Scroll scroll) {
  if (!deltaEndsWith(delta, '\n')) {
    delta.insert('\n');
  }
  return delta;
}

Delta matchCodeBlock(DomNode node, Delta delta, Scroll scroll) {
  return applyFormat(delta, CodeBlock.kBlotName, true, scroll);
}

Delta matchIgnore(DomNode node, Delta delta, Scroll scroll) {
  return Delta();
}

Delta matchIndent(DomNode node, Delta delta, Scroll scroll) {
  if (!deltaEndsWith(delta, '\n')) {
    return delta;
  }
  if (node is! DomElement) {
    return delta;
  }

  final classIndent = _classIndentLevel(node);
  int indentLevel;
  if (classIndent != null) {
    indentLevel = classIndent;
  } else {
    var depth = -1;
    DomNode? current = node.parentNode;
    while (current != null) {
      if (current is DomElement) {
        final tag = current.tagName.toUpperCase();
        if (tag == 'OL' || tag == 'UL') {
          depth += 1;
        }
      }
      current = current.parentNode;
    }
    indentLevel = depth;
  }

  final resolvedIndent = indentLevel;
  final explicitList = node.getAttribute('data-list');
  final hasExplicitList = explicitList != null && explicitList.isNotEmpty;
  final needsIndent = resolvedIndent > 0;
  if (!needsIndent && !hasExplicitList) {
    return delta;
  }

  final composed = Delta();
  for (final op in delta.operations) {
    if (!op.isInsert) {
      composed.push(_cloneOperation(op));
      continue;
    }
    final attrs = op.attributes ?? const <String, dynamic>{};
    final merged = <String, dynamic>{};
    if (needsIndent && !(attrs['indent'] is num)) {
      merged['indent'] = resolvedIndent;
    }
    if (hasExplicitList && !attrs.containsKey('list')) {
      merged['list'] = explicitList;
    }
    merged.addAll(attrs);
    composed.insert(op.data, merged.isEmpty ? null : merged);
  }
  return composed;
}

Delta matchList(DomNode node, Delta delta, Scroll scroll) {
  final element = node as DomElement;
  var format = element.tagName == 'OL' ? 'ordered' : 'bullet';
  final checklistAttr = element.getAttribute('data-list');
  if (checklistAttr != null && checklistAttr.isNotEmpty) {
    format = checklistAttr;
  }
  return applyFormat(delta, 'list', format, scroll);
}

Delta matchNewline(DomNode node, Delta delta, Scroll scroll) {
  if (deltaEndsWith(delta, '\n')) {
    return delta;
  }

  final hasContent = node.childNodes.isNotEmpty;
  final isParagraph = node is DomElement && node.tagName == 'P';
  final isTableCell = node is DomElement &&
      (node.tagName == 'TD' || node.tagName == 'TH');
  if (isLine(node, scroll) && (hasContent || isParagraph || isTableCell)) {
    delta.insert('\n');
    return delta;
  }

  if (delta.length > 0 && node.nextSibling != null) {
    DomNode? nextSibling = node.nextSibling;
    while (nextSibling != null) {
      if (isLine(nextSibling, scroll)) {
        delta.insert('\n');
        return delta;
      }
      if (nextSibling is DomElement) {
        if (_isBlockEmbedElement(nextSibling)) {
          delta.insert('\n');
          return delta;
        }
        nextSibling = nextSibling.firstChild;
        continue;
      }
      break;
    }
  }
  return delta;
}

Delta matchStyles(DomNode node, Delta delta, Scroll scroll) {
  final formats = <String, dynamic>{};
  final element = node as DomElement;
  final styleAttr = element.getAttribute('style');

  if (styleAttr != null && styleAttr.isNotEmpty) {
    final styles =
        styleAttr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);

    for (final style in styles) {
      final parts = style.split(':');
      if (parts.length < 2) continue;

      final prop = parts[0].trim();
      final value = parts.sublist(1).join(':').trim();

      if (prop == 'font-weight' &&
          (value == 'bold' || (int.tryParse(value) ?? 0) >= 700)) {
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
  if (node is! DomElement) {
    return delta;
  }

  DomElement? table;
  final parent = node.parentNode;
  if (parent is DomElement && parent.tagName.toUpperCase() == 'TABLE') {
    table = parent;
  } else if (parent is DomElement) {
    final grandParent = parent.parentNode;
    if (grandParent is DomElement &&
        grandParent.tagName.toUpperCase() == 'TABLE') {
      table = grandParent;
    }
  }

  if (table == null) {
    return delta;
  }

  final rows = table.querySelectorAll('tr');
  final rowIndex = rows.indexOf(node) + 1;
  if (rowIndex <= 0) {
    return delta;
  }

  return applyFormat(delta, 'table', rowIndex, scroll);
}

Delta matchText(DomNode node, Delta delta, Scroll scroll) {
  var text = node.textContent ?? '';
  final parent = node.parentNode;
  if (parent is DomElement && parent.tagName == 'O:P') {
    return delta..insert(text.trim());
  }

  if (!isPre(node)) {
    if (text.trim().isEmpty &&
        text.contains('\n') &&
        !isBetweenInlineElements(node, scroll)) {
      return delta;
    }

    text = text.replaceAll(RegExp(r'[^\S\u00A0]'), ' ');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');

    final parentIsLine = parent != null && isLine(parent, scroll);
    final previousSibling = node.previousSibling;
    if ((previousSibling == null && parentIsLine) ||
        (previousSibling is DomElement && isLine(previousSibling, scroll))) {
      text = text.replaceFirst(RegExp(r'^ '), '');
    }
    final nextSibling = node.nextSibling;
    if ((nextSibling == null && parentIsLine) ||
        (nextSibling is DomElement && isLine(nextSibling, scroll))) {
      text = text.replaceFirst(RegExp(r' $'), '');
    }
    text = text.replaceAll('\u00A0', ' ');
  }

  if (text.isEmpty) {
    return delta;
  }

  return delta..insert(text);
}
