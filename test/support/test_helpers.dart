import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/blots/block.dart';
import 'package:dart_quill/src/blots/break.dart';
import 'package:dart_quill/src/blots/cursor.dart';
import 'package:dart_quill/src/blots/inline.dart';
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/blots/text.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/formats/list.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';
import 'fake_dom.dart';

/// Normalize HTML by removing newlines and extra spaces
String normalizeHTML(String html) {
  return html.replaceAll(RegExp(r'\n\s*'), '');
}

/// Create a Registry with default blots and optional custom formats
Registry createRegistry([List<Type>? formats]) {
  final registry = Registry();

  // Register custom formats first
  if (formats != null) {
    for (final format in formats) {
      registry.register(format);
    }
  }

  // Register basic blots
  registry.register(Block);
  registry.register(Break);
  registry.register(Cursor);
  registry.register(InlineBlot);
  registry.register(Scroll);
  registry.register(TextBlot);
  registry.register(ListContainer);
  registry.register(ListItem);

  return registry;
}

/// Create a Scroll with initial HTML content
Scroll createScroll(String html, {Registry? registry, DomElement? container}) {
  final emitter = Emitter();
  final adapter = FakeDomAdapter();
  final doc = adapter.document;
  final root = container ?? doc.body;
  
  // Set innerHTML
  if (root is FakeDomElement) {
    root.innerHTML = normalizeHTML(html);
  }
  
  final scroll = Scroll(
    registry ?? createRegistry(),
    root,
    emitter: emitter,
  );
  
  return scroll;
}

/// Custom matcher for comparing HTML content
class EqualHTML extends Matcher {
  EqualHTML(this.expected);
  
  final String expected;
  
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! DomElement) return false;
    
    final actual = _getHTML(item);
    final normalizedExpected = normalizeHTML(expected);
    final normalizedActual = normalizeHTML(actual);
    
    return normalizedActual == normalizedExpected;
  }
  
  @override
  Description describe(Description description) {
    return description.add('HTML equals ').addDescriptionOf(normalizeHTML(expected));
  }
  
  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! DomElement) {
      return mismatchDescription.add('is not a DomElement');
    }
    
    final actual = normalizeHTML(_getHTML(item));
    return mismatchDescription
        .add('has HTML ')
        .addDescriptionOf(actual);
  }
  
  String _getHTML(DomElement element) {
    final buffer = StringBuffer();
    _buildHTML(element, buffer);
    return buffer.toString();
  }
  
  void _buildHTML(DomNode node, StringBuffer buffer) {
    if (node is DomText) {
      buffer.write(node.data);
    } else if (node is DomElement) {
      buffer.write('<${node.tagName.toLowerCase()}');
      
      // Add attributes
      if (node is FakeDomElement) {
        final attrs = <String, String>{};
        // Collect attributes
        if (node.getAttribute('src') != null) {
          attrs['src'] = node.getAttribute('src')!;
        }
        if (node.getAttribute('href') != null) {
          attrs['href'] = node.getAttribute('href')!;
        }
        if (node.className != null && node.className!.isNotEmpty) {
          attrs['class'] = node.className!;
        }
        if (node.id != null && node.id!.isNotEmpty) {
          attrs['id'] = node.id!;
        }
        
        // Write attributes
        attrs.forEach((key, value) {
          buffer.write(' $key="$value"');
        });
      }
      
      buffer.write('>');
      
      // Add children
      for (final child in node.childNodes) {
        _buildHTML(child, buffer);
      }
      
      buffer.write('</${node.tagName.toLowerCase()}>');
    }
  }
}

/// Extension to add toEqualHTML matcher to test API
extension HtmlMatchers on DomElement {
  Matcher toEqualHTML(String expected) => EqualHTML(expected);
}

/// Expect that a DomElement's HTML equals the expected HTML
void expectHTML(DomElement element, String expected) {
  expect(element, EqualHTML(expected));
}
