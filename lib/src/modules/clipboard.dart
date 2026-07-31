import 'dart:math' as math;

import '../delta/delta.dart';

import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../formats/abstract/attributor.dart';
import '../formats/align.dart';
import '../formats/background.dart';
import '../formats/blockquote.dart';
import '../formats/code.dart';
import '../formats/color.dart';
import '../formats/direction.dart';
import '../formats/font.dart';
import '../formats/formula.dart';
import '../formats/header.dart';
import '../formats/image.dart';
import '../formats/link.dart';
import '../formats/list.dart';
import '../formats/script.dart';
import '../formats/size.dart';
import '../formats/table.dart';
import '../formats/video.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import 'normalize_external_html/index.dart';
import 'uploader.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Track clipboard-specific attributors per scroll instance so applyFormat can
// determine which custom formats are allowed when converting HTML.
final _clipboardAttributorsByName =
    Expando<Map<String, Attributor>>('_clipboardAttributorsByName');

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

// Parity clipboard.ts:50-68 — attributors the clipboard understands even when
// they are not part of the editor registry, keyed by their DOM key name.
final Map<String, Attributor> ATTRIBUTE_ATTRIBUTORS = _byKeyName([
  AlignAttribute.instance,
  DirectionAttribute.instance,
]);

final Map<String, Attributor> STYLE_ATTRIBUTORS = _byKeyName([
  AlignStyle.instance,
  BackgroundStyle.instance,
  ColorStyle.instance,
  DirectionStyle.instance,
  FontStyleAttributor.instance,
  SizeStyle.instance,
]);

Map<String, Attributor> _byKeyName(List<Attributor> attributors) {
  return {for (final attributor in attributors) attributor.keyName: attributor};
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
    _clipboardAttributorsByName[quill.scroll] = {
      for (final attributor in attributors) ...{
        attributor.attrName: attributor,
        attributor.keyName: attributor,
      },
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
    // Parity clipboard.ts:104-108 — pasting inside a code block never parses
    // HTML: the plain text is inserted with the surrounding code-block format.
    final codeBlockFormat = formats[CodeBlock.kBlotName];
    if (codeBlockFormat != null && codeBlockFormat != false) {
      return Delta()
        ..insert(text ?? '', {CodeBlock.kBlotName: codeBlockFormat});
    }
    if (html == null) {
      final attrs = formats.isEmpty ? null : Map<String, dynamic>.from(formats);
      return Delta()..insert(text ?? '', attrs);
    }

    final delta = convertHTML(html);
    // Remove trailing newline
    if (deltaEndsWith(delta, '\n') &&
        (delta.operations.last.attributes == null ||
            formats['table'] != null)) {
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
    // A MAP keyed by node equality, not an Expando keyed by identity: the
    // browser adapter mints a NEW wrapper on every DOM access, so the nodes
    // collected here by `querySelectorAll` are never the same objects the
    // traversal walks into. With an Expando every selector-based matcher
    // (lists, tables, code blocks, the Word/Docs normalizers) silently did
    // nothing in a real browser — pasting lost those formats — while the
    // fake DOM, which hands back the same objects, kept the VM suite green.
    final nodeMatches = <DomNode, List<Matcher>>{};
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
    final range = quill.getSelection();
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
        .where((url) => url.isNotEmpty && url[0] != '#')
        .join('\n');
  }

  void onCapturePaste(DomClipboardEvent e) {
    if (e.defaultPrevented || !quill.isEnabled()) return;
    e.preventDefault();
    final range = quill.getSelection(focus: true) ?? quill.selection.savedRange;
    if (range == null) {
      return;
    }
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
      if (_uploadFiles(range, files)) {
        return;
      }
    }
    if (html != null && files.isNotEmpty) {
      final doc =
          quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
      final children = doc.body.childNodes.whereType<DomElement>().toList();
      if (children.length == 1 && children.first.tagName == 'IMG') {
        if (_uploadFiles(range, files)) {
          return;
        }
      }
    }
    onPaste(range, text: text, html: html);
  }

  /// Parity clipboard.ts:211-223 — hands pasted files to the uploader module.
  /// Returns false (so the regular paste path runs) when the module is not
  /// enabled for this editor.
  bool _uploadFiles(Range range, List<DomFile> files) {
    final uploader = quill.getModule('uploader');
    if (uploader is! Uploader) {
      return false;
    }
    uploader.upload(range, files);
    return true;
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
    quill.setSelection(Range(newIndex, 0), source: EmitterSource.SILENT);
    quill.scrollSelectionIntoView();
  }

  List<dynamic> prepareMatching(
      DomElement container, Map<DomNode, List<Matcher>> nodeMatches) {
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

bool _isTruthy(dynamic value) => value != null && value != false && value != '';

Delta applyFormat(Delta delta, String format, dynamic value, Scroll scroll) {
  // Parity clipboard.ts:286-288 — parchment's `Registry.query` resolves both
  // blots and attributors, so a registered attributor ('align', 'color', ...)
  // is enough for the format to survive a paste.
  final hasRegistryFormat = scroll.query(format, Scope.ANY) != null ||
      scroll.queryAttributor(format, Scope.ANY) != null;
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
    if (_isTruthy(value)) {
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
  Map<DomNode, List<Matcher>> nodeMatches,
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

/// Reads an attributor value the way parchment does (attributor.ts:52-56,
/// class.ts:24-27, style.ts:29-32): a value that fails the whitelist check is
/// reported as absent instead of being applied verbatim.
dynamic _attributorValue(Attributor attributor, DomElement node) {
  final value = attributor.value(node);
  if (!_isTruthy(value)) {
    return null;
  }
  return attributor.canAdd(node, value) ? value : null;
}

/// Resolves [name] (an attribute/class/style key or a format name) to an
/// attributor: clipboard-scoped ones first, then the editor registry.
Attributor? _resolveAttributor(Scroll scroll, String name) {
  return _attributorMapForScroll(scroll)[name] ??
      scroll.queryAttributor(name, Scope.ATTRIBUTE);
}

/// Parity clipboard.ts:426-455.
Delta matchAttributor(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) {
    return delta;
  }

  final names = <String>[
    ...Attributor.keys(node),
    ...ClassAttributor.keys(node),
    ...StyleAttributor.keys(node),
  ];

  final formats = <String, dynamic>{};
  for (final name in names) {
    if (name.isEmpty) {
      continue;
    }
    var attr = _resolveAttributor(scroll, name);
    if (attr != null) {
      final value = _attributorValue(attr, node);
      formats[attr.attrName] = value;
      if (_isTruthy(value)) {
        continue;
      }
    }
    attr = ATTRIBUTE_ATTRIBUTORS[name];
    if (attr != null && (attr.attrName == name || attr.keyName == name)) {
      formats[attr.attrName] = _attributorValue(attr, node);
    }
    attr = STYLE_ATTRIBUTORS[name];
    if (attr != null && (attr.attrName == name || attr.keyName == name)) {
      formats[attr.attrName] = _attributorValue(attr, node);
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

/// Blots that only exist to structure the tree. Upstream resolves them to
/// parchment `ContainerBlot`s (or to the scroll/default block), which produce
/// neither a format nor a newline in `matchBlot`.
// Upstream's filter is `'formats' in match`: parchment containers declare no
// static `formats`, so matchBlot never reports them. Containers that DO
// declare one (quill-table-better's table-cell) opt back in through
// `RegistryEntry.staticFormats`.
const _structuralBlotNames = <String>{
  'block',
  'break',
  'cursor',
  'inline',
  'scroll',
  'text',
  'code-block-container',
  'list-container',
  'table-container',
  'table-body',
  'table-thead',
  'table-row',
  'table-th-row',
  'table-colgroup',
  'table-list-container',
};

/// Blots whose DOM node maps to an embed insert instead of a text format.
///
/// Only a fallback for entries registered before `isEmbed` existed: the
/// registry is the source of truth, so a third-party embed pastes as an embed
/// by declaring `isEmbed: true` and `staticValue`.
const _legacyEmbedBlotNames = <String>{
  Image.kBlotName,
  Video.kBlotName,
  Formula.kBlotName,
};

/// Parity parchment `Registry.query(Node)`: class names win over tag names.
RegistryEntry? _queryEntryForNode(Scroll scroll, DomElement node) {
  final className = node.getAttribute('class');
  if (className != null && className.isNotEmpty) {
    final byClass = scroll.registry.queryByClassName(className);
    if (byClass != null) {
      return byClass;
    }
  }
  final tagName = node.tagName;
  if (tagName.isEmpty) {
    return null;
  }
  return scroll.registry.queryByTagName(tagName);
}

/// Fallback for blots registered before `RegistryEntry.staticFormats` existed.
///
/// The built-ins now declare it on their registry entry (initialization.dart),
/// which is what makes a third-party blot report its own formats too. Kept so
/// an entry that declares nothing still behaves as it did.
dynamic _blotStaticFormats(String blotName, DomElement node, Scroll scroll) {
  switch (blotName) {
    case Header.kBlotName:
      final level = Header.getLevel(node);
      return level > 0 ? level : null;
    case ListItem.kBlotName:
      // Parity list.ts:18-20 — `<li>` carries its own list style.
      return node.getAttribute('data-list');
    case CodeBlock.kBlotName:
      // Parity syntax.ts — the highlighted code block reports its language.
      return node.getAttribute('data-language') ?? true;
    case TableCell.kBlotName:
      return node.getAttribute('data-row');
    case Link.kBlotName:
      return Link.getFormat(node);
    case Script.kBlotName:
      return Script.getFormat(node);
    case Blockquote.kBlotName:
      return true;
    default:
      // Parity parchment Inline/BlockBlot.formats: a blot matched through a
      // single tag name simply reports `true`.
      return true;
  }
}

/// Parity clipboard.ts matchBlot's embed branch: `{[blotName]: value}` plus
/// whatever the blot's `static formats` reports for the node.
///
/// Both come from the registry entry, so an application's own embed pastes by
/// registering it — nothing here knows about image, video or formula.
Delta? _matchEmbedBlot(RegistryEntry entry, DomElement node) {
  final rawValue = entry.staticValue?.call(node) ??
      _legacyEmbedValue(entry.blotName, node);
  if (rawValue == null || (rawValue is String && rawValue.isEmpty)) {
    return null;
  }
  final rawFormats = entry.staticFormats?.call(node);
  final formats = <String, dynamic>{};
  if (rawFormats is Map) {
    rawFormats.forEach((key, value) {
      if (value != null && !(value is String && value.isEmpty)) {
        formats['$key'] = value;
      }
    });
  }
  return Delta()
    ..insert({entry.blotName: rawValue}, formats.isEmpty ? null : formats);
}

/// Values for embeds registered before `staticValue` existed.
String? _legacyEmbedValue(String blotName, DomElement node) {
  switch (blotName) {
    case Image.kBlotName:
      return Image.getValue(node);
    case Video.kBlotName:
      return Video.valueDom(node);
    case Formula.kBlotName:
      return Formula.getValue(node);
  }
  return null;
}

/// Parity clipboard.ts:457-490 — resolve the blot for [node] through the
/// registry instead of hardcoding tag names.
Delta matchBlot(DomNode node, Delta delta, Scroll scroll) {
  if (node is! DomElement) {
    return delta;
  }

  final entry = _queryEntryForNode(scroll, node);
  if (entry == null) {
    return delta;
  }

  final blotName = entry.blotName;
  if (entry.isEmbed || _legacyEmbedBlotNames.contains(blotName)) {
    return _matchEmbedBlot(entry, node) ?? delta;
  }
  // Parity clipboard.ts matchBlot: `'formats' in match` — a blot that declares
  // its own static formats reports through it even when it is a container
  // (quill-table-better's table-cell returns the attribute map the `<td>`
  // carries, `{}` when bare, and that empty map is truthy upstream, so the
  // format is still applied).
  if (entry.staticFormats == null && _structuralBlotNames.contains(blotName)) {
    return delta;
  }

  final isBlockBlot = Scope.matches(entry.scope, Scope.BLOCK_BLOT);
  if (isBlockBlot && !deltaEndsWith(delta, '\n')) {
    delta.insert('\n');
  }
  final value = entry.staticFormats != null
      ? entry.staticFormats!(node)
      : _blotStaticFormats(blotName, node, scroll);
  return applyFormat(delta, blotName, value, scroll);
}

Delta matchBreak(DomNode node, Delta delta, Scroll scroll) {
  if (!deltaEndsWith(delta, '\n')) {
    delta.insert('\n');
  }
  return delta;
}

/// Parity clipboard.ts:499-506 — the code-block blot reports the language of
/// the `<pre>` element (`true` when the syntax module is not installed).
Delta matchCodeBlock(DomNode node, Delta delta, Scroll scroll) {
  final match = scroll.query(CodeBlock.kBlotName, Scope.ANY);
  final language = match == null || node is! DomElement
      ? true
      : _blotStaticFormats(CodeBlock.kBlotName, node, scroll);
  return applyFormat(delta, CodeBlock.kBlotName, language, scroll);
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

/// Parity clipboard.ts:541-551.
Delta matchList(DomNode node, Delta delta, Scroll scroll) {
  final element = node as DomElement;
  var format = element.tagName.toUpperCase() == 'OL' ? 'ordered' : 'bullet';
  final checkedAttr = element.getAttribute('data-checked');
  if (checkedAttr != null && checkedAttr.isNotEmpty) {
    format = checkedAttr == 'true' ? 'checked' : 'unchecked';
  }
  return applyFormat(delta, 'list', format, scroll);
}

Delta matchNewline(DomNode node, Delta delta, Scroll scroll) {
  if (deltaEndsWith(delta, '\n')) {
    return delta;
  }

  final hasContent = node.childNodes.isNotEmpty;
  final isParagraph = node is DomElement && node.tagName == 'P';
  final isTableCell =
      node is DomElement && (node.tagName == 'TD' || node.tagName == 'TH');
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
      }
      // color/background/font/size/align/direction are intentionally absent:
      // parity clipboard.ts:579-608 leaves them to `matchAttributor`, which
      // resolves them through the registered attributors (and therefore
      // honours their whitelists).
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
