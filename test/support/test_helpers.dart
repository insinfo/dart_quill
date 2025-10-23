import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/blots/block.dart';
import 'package:dart_quill/src/blots/break.dart';
import 'package:dart_quill/src/blots/cursor.dart';
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/blots/text.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/formats/list.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'fake_dom.dart';

// Global test adapter - set this once at the start of tests
final testAdapter = FakeDomAdapter();

/// Initialize the fake DOM adapter for testing
/// This swaps out the real HTML DOM with a fake implementation
void initializeFakeDom() {
  domBindings.adapter = testAdapter;
}

/// Normalize HTML by removing newlines and extra spaces
String normalizeHTML(String html) {
  return html.replaceAll(RegExp(r'\n\s*'), '');
}

/// Helper to create RegistryEntry for a blot type
RegistryEntry _createEntry(String name, int scope, Blot Function([dynamic]) create, 
    {List<String> tagNames = const [], List<String> classNames = const []}) {
  return RegistryEntry(
    blotName: name,
    scope: scope,
    create: create,
    tagNames: tagNames,
    classNames: classNames,
  );
}

/// Create a Registry with default blots and optional custom formats
Registry createRegistry([List<RegistryEntry>? formats]) {
  final registry = Registry();

  // Register custom formats first
  if (formats != null) {
    for (final format in formats) {
      registry.register(format);
    }
  }

  // Register basic blots using testAdapter (FakeDom)
  registry.register(_createEntry('block', Scope.BLOCK_BLOT, 
    ([value]) => Block(value is DomElement ? value : testAdapter.document.createElement('p')),
    tagNames: ['P']));
  
  registry.register(_createEntry('break', Scope.INLINE_BLOT,
    ([value]) => Break(value is DomElement ? value : testAdapter.document.createElement('br')),
    tagNames: ['BR']));
  
  registry.register(_createEntry('cursor', Scope.INLINE_BLOT,
    ([value]) => Cursor(value is DomElement ? value : testAdapter.document.createElement('span')),
    tagNames: ['SPAN'], classNames: ['ql-cursor']));
  
  // Note: InlineBlot is abstract, skip registration as it's a base class
  
  registry.register(_createEntry('scroll', Scope.BLOCK_BLOT,
    ([value]) {
      if (value is! DomElement) throw ArgumentError('Scroll requires DomElement');
      return Scroll(registry, value, emitter: Emitter());
    },
    tagNames: ['DIV']));
  
  registry.register(_createEntry('text', Scope.INLINE_BLOT,
    ([value]) {
      final text = value is String ? value : '';
      return TextBlot(testAdapter.document.createTextNode(text));
    }));
  
  registry.register(_createEntry('list-container', Scope.BLOCK_BLOT,
    ([value]) => ListContainer(value is DomElement ? value : testAdapter.document.createElement('ol')),
    tagNames: ['OL', 'UL']));
  
  registry.register(_createEntry('list', Scope.BLOCK_BLOT,
    ([value]) => ListItem(value is DomElement ? value : testAdapter.document.createElement('li')),
    tagNames: ['LI']));

  return registry;
}

/// Create a Scroll with initial HTML content using FakeDom
Scroll createScroll(String html, {Registry? registry, DomElement? container}) {
  final emitter = Emitter();
  // Always use testAdapter which is FakeDomAdapter
  final doc = testAdapter.document;
  final root = container ?? doc.body;
  
  // Set innerHTML
  if (root is FakeDomElement) {
    root.innerHTML = normalizeHTML(html);
  }
  final resolvedRegistry = registry ?? createRegistry();
  final scroll = Scroll(
    resolvedRegistry,
    root,
    emitter: emitter,
  );
  _hydrateScrollFromDom(scroll, resolvedRegistry);
  return scroll;
}

void _hydrateScrollFromDom(Scroll scroll, Registry registry) {
  final root = scroll.domNode;
  if (root is! DomElement) return;
  final nodes = List<DomNode>.from(root.childNodes);
  for (final node in nodes) {
    final blot = _createBlotFromDomNode(scroll, registry, node);
    if (blot != null) {
      scroll.insertBefore(blot, null);
    }
  }
  scroll.optimize();
}

Blot? _createBlotFromDomNode(Scroll scroll, Registry registry, DomNode node) {
  if (node is DomText) {
    final trimmed = node.data.trim();
    if (trimmed.isEmpty && node.data.isNotEmpty) {
      // Whitespace between blocks; drop it to avoid phantom text blots.
      node.remove();
      return null;
    }
    return TextBlot(node);
  }

  if (node is DomElement) {
    final registryEntry =
        registry.queryByTagName(node.tagName, scope: Scope.ANY) ??
            registry.queryByClassName(node.className ?? '', scope: Scope.ANY);

    final blotName = registryEntry?.blotName ?? Block.kBlotName;
    final blot = scroll.create(blotName, node);
    if (blot is ParentBlot) {
      final children = List<DomNode>.from(node.childNodes);
      for (final child in children) {
        final childBlot = _createBlotFromDomNode(scroll, registry, child);
        if (childBlot != null) {
          blot.insertBefore(childBlot, null);
        }
      }
    }
    return blot;
  }

  return null;
}

/// Custom matcher for comparing HTML content (innerHTML by default)
class EqualHTML extends Matcher {
  EqualHTML(this.expected, {this.includeOuterTag = false});
  
  final String expected;
  final bool includeOuterTag;
  
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! DomElement) return false;
    
    final actual = _getHTML(item, includeOuterTag: includeOuterTag);
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
    
    final actual = normalizeHTML(_getHTML(item, includeOuterTag: includeOuterTag));
    return mismatchDescription
        .add('has HTML ')
        .addDescriptionOf(actual);
  }
  
  String _getHTML(DomElement element, {bool includeOuterTag = false}) {
    final buffer = StringBuffer();
    if (includeOuterTag) {
      _buildHTML(element, buffer);
    } else {
      // innerHTML only - children without the outer tag
      for (final child in element.childNodes) {
        _buildHTML(child, buffer);
      }
    }
    return buffer.toString();
  }
  
  void _buildHTML(DomNode node, StringBuffer buffer) {
    if (node is DomText) {
      buffer.write(node.data);
    } else if (node is DomElement) {
      final tagName = node.tagName.toLowerCase();
      buffer.write('<$tagName');
      
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
      
      // Check if it's a void/self-closing element
      const voidElements = ['br', 'hr', 'img', 'input', 'meta', 'link'];
      final isVoid = voidElements.contains(tagName);
      
      if (!isVoid) {
        // Add children
        for (final child in node.childNodes) {
          _buildHTML(child, buffer);
        }
        
        buffer.write('</$tagName>');
      }
    }
  }
}

/// Extension to add toEqualHTML matcher to test API
extension HtmlMatchers on DomElement {
  Matcher toEqualHTML(String expected) => EqualHTML(expected);
}

/// Expect that a DomElement's innerHTML equals the expected HTML (default behavior)
void expectHTML(DomElement element, String expected, {bool includeOuterTag = false}) {
  expect(element, EqualHTML(expected, includeOuterTag: includeOuterTag));
}
