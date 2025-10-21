import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../formats/code.dart';
import '../formats/align.dart';
import '../formats/background.dart';
import '../formats/color.dart';
import '../formats/direction.dart';
import '../formats/font.dart';
import '../formats/size.dart';
import '../modules/keyboard.dart';
import '../formats/abstract/attributor.dart';
import 'dart:html';
import 'package:quill_delta/quill_delta.dart';

// Placeholder for normalizeExternalHTML
class NormalizeExternalHTML {
  void normalize(Document doc) {}
}

final normalizeExternalHTML = NormalizeExternalHTML();

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Type definitions
typedef Selector = dynamic; // String | Node.TEXT_NODE | Node.ELEMENT_NODE
typedef Matcher = Delta Function(Node node, Delta delta, Scroll scroll);

class ClipboardOptions {
  final List<dynamic> matchers;

  ClipboardOptions({
    this.matchers = const [],
  });
}

final CLIPBOARD_CONFIG = <List<dynamic>>[
  [Node.TEXT_NODE, matchText],
  [Node.TEXT_NODE, matchNewline],
  ['br', matchBreak],
  [Node.ELEMENT_NODE, matchNewline],
  [Node.ELEMENT_NODE, matchBlot],
  [Node.ELEMENT_NODE, matchAttributor],
  [Node.ELEMENT_NODE, matchStyles],
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
    quill.root.addEventListener('copy', (e) => onCaptureCopy(e as ClipboardEvent, false));
    quill.root.addEventListener('cut', (e) => onCaptureCopy(e as ClipboardEvent, true));
    quill.root.addEventListener('paste', (e) => onCapturePaste(e as ClipboardEvent));

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
    if (formats[CodeBlock.blotName] != null) {
      return Delta()..insert(text ?? '', {CodeBlock.blotName: formats[CodeBlock.blotName]});
    }
    if (html == null) {
      return Delta()..insert(text ?? '', formats);
    }
    final delta = convertHTML(html);
    if (deltaEndsWith(delta, '\n') && (delta.ops.last.attributes == null || formats['table'] != null)) {
      return delta.compose(Delta()..retain(delta.length() - 1)..delete(1));
    }
    return delta;
  }

  void normalizeHTML(Document doc) {
    normalizeExternalHTML.normalize(doc);
  }

  Delta convertHTML(String html) {
    final doc = DomParser().parseFromString(html, 'text/html');
    normalizeHTML(doc);
    final container = doc.body!;
    final nodeMatches = Expando<List<Matcher>>();
    final prepared = prepareMatching(container, nodeMatches);
    final elementMatchers = prepared[0] as List<Matcher>;
    final textMatchers = prepared[1] as List<Matcher>;
    return traverse(quill.scroll, container, elementMatchers, textMatchers, nodeMatches);
  }

  void dangerouslyPasteHTML(dynamic indexOrHtml, [String? html, String source = Quill.sources.API]) {
    if (indexOrHtml is String) {
      final delta = convert(html: indexOrHtml, text: '');
      quill.setContents(delta, html as String?); // html is actually source here
      quill.setSelection(0, Quill.sources.SILENT);
    } else if (indexOrHtml is int) {
      final paste = convert(html: html, text: '');
      quill.updateContents(Delta()..retain(indexOrHtml)..concat(paste), source);
      quill.setSelection(indexOrHtml + paste.length(), Quill.sources.SILENT);
    }
  }

  void onCaptureCopy(ClipboardEvent e, bool isCut) {
    if (e.defaultPrevented) return;
    e.preventDefault();
    final range = quill.selection.getRange()[0] as Range?;
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

  void onCapturePaste(ClipboardEvent e) {
    if (e.defaultPrevented || !quill.isEnabled()) return;
    e.preventDefault();
    final range = quill.getSelection(true)!;
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
      final doc = DomParser().parseFromString(html, 'text/html');
      if (doc.body!.childElementCount == 1 && doc.body!.firstElementChild?.tagName == 'IMG') {
        // quill.uploader.upload(range, files); // Placeholder for uploader
        return;
      }
    }
    onPaste(range, {'html': html, 'text': text});
  }

  Map<String, dynamic> onCopy(Range range, [bool isCut = false]) {
    final text = quill.getText(range.index, range.length);
    final html = quill.getSemanticHTML(range.index, range.length);
    return {'html': html, 'text': text};
  }

  void onPaste(Range range, {String? text, String? html}) {
    final formats = quill.getFormat(range.index);
    final pastedDelta = convert(html: html, text: text, formats: formats);
    debug.log('onPaste', pastedDelta, {'text': text, 'html': html});
    final delta = Delta()..retain(range.index)..delete(range.length)..concat(pastedDelta);
    quill.updateContents(delta, Quill.sources.USER);
    quill.setSelection(delta.length() - range.length, Quill.sources.SILENT);
    // quill.scrollSelectionIntoView(); // Placeholder
  }

  List<dynamic> prepareMatching(HtmlElement container, Expando<List<Matcher>> nodeMatches) {
    final elementMatchers = <Matcher>[];
    final textMatchers = <Matcher>[];
    matchers.forEach((pair) {
      final selector = pair[0];
      final matcher = pair[1] as Matcher;
      switch (selector) {
        case Node.TEXT_NODE:
          textMatchers.add(matcher);
          break;
        case Node.ELEMENT_NODE:
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

Delta applyFormat(Delta delta, String format, dynamic value, Scroll scroll) {
  // Placeholder
  return delta;
}

bool deltaEndsWith(Delta delta, String text) {
  var endText = '';
  for (var i = delta.ops.length - 1; i >= 0 && endText.length < text.length; --i) {
    final op = delta.ops[i];
    if (op.insert is! String) break;
    endText = (op.insert as String) + endText;
  }
  return endText.substring(math.max(0, endText.length - text.length)) == text;
}

bool isLine(Node node, Scroll scroll) {
  // Placeholder
  return false;
}

bool isBetweenInlineElements(HtmlElement node, Scroll scroll) {
  // Placeholder
  return false;
}

final _preNodes = Expando<bool>();
bool isPre(Node? node) {
  // Placeholder
  return false;
}

Delta traverse(Scroll scroll, Node node, List<Matcher> elementMatchers, List<Matcher> textMatchers, Expando<List<Matcher>> nodeMatches) {
  // Placeholder
  return Delta();
}

Matcher createMatchAlias(String format) {
  return (node, delta, scroll) => applyFormat(delta, format, true, scroll);
}

Matcher matchAttributor(HtmlElement node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchBlot(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchBreak(Node node, Delta delta, Scroll scroll) {
  if (!deltaEndsWith(delta, '\n')) {
    delta.insert('\n');
  }
  return delta;
}

Matcher matchCodeBlock(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchIgnore(Node node, Delta delta, Scroll scroll) {
  return Delta();
}

Matcher matchIndent(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchList(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchNewline(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchStyles(HtmlElement node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchTable(HtmlElement node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}

Matcher matchText(Node node, Delta delta, Scroll scroll) {
  // Placeholder
  return delta;
}
