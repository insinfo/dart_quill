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
  return html.replaceAll(RegExp(r'\r?\n\s*'), '').trim();
}

/// Helper to create RegistryEntry for a blot type
RegistryEntry _createEntry(
    String name, int scope, Blot Function([dynamic]) create,
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
  registry.register(_createEntry(
      'block',
      Scope.BLOCK_BLOT,
      ([value]) => Block(value is DomElement
          ? value
          : testAdapter.document.createElement('p')),
      tagNames: ['P']));

  registry.register(_createEntry(
      'break',
      Scope.INLINE_BLOT,
      ([value]) => Break(value is DomElement
          ? value
          : testAdapter.document.createElement('br')),
      tagNames: ['BR']));

  registry.register(_createEntry(
      'cursor',
      Scope.INLINE_BLOT,
      ([value]) => Cursor(value is DomElement
          ? value
          : testAdapter.document.createElement('span')),
      tagNames: ['SPAN'],
      classNames: ['ql-cursor']));

  // The generic inline wrapper (`<span>`), which upstream's factory registers
  // too: it is what hosts an inline ATTRIBUTOR (color/size/font) when the
  // text has no wrapper yet. Without it `TextBlot.formatAt` throws
  // "Unknown blot inline".
  registry.register(_createEntry(
      'inline',
      Scope.INLINE_BLOT,
      ([value]) => Inline(value is DomElement
          ? value
          : testAdapter.document.createElement('span')),
      tagNames: ['SPAN']));

  registry.register(_createEntry('scroll', Scope.BLOCK_BLOT, ([value]) {
    if (value is! DomElement) throw ArgumentError('Scroll requires DomElement');
    return Scroll(registry, value, emitter: Emitter());
  }, tagNames: ['DIV']));

  registry.register(_createEntry('text', Scope.INLINE_BLOT, ([value]) {
    final text = value is String ? value : '';
    return TextBlot(testAdapter.document.createTextNode(text));
  }));

  registry.register(_createEntry(
      'list-container',
      Scope.BLOCK_BLOT,
      ([value]) => ListContainer(value is DomElement
          ? value
          : testAdapter.document.createElement('ol')),
      tagNames: ['OL', 'UL']));

  registry.register(_createEntry(
      'list',
      Scope.BLOCK_BLOT,
      ([value]) => ListItem(value is DomElement
          ? value
          : testAdapter.document.createElement('li')),
      tagNames: ['LI']));

  return registry;
}

/// Create a Scroll with initial HTML content using FakeDom.
///
/// Port of the upstream factory (`test/unit/__helpers__/factory.ts`): the
/// scroll root is a FRESH `<div>` appended to [container] (the body by
/// default), never the container itself — so two scrolls in one test are
/// independent, exactly as upstream.
Scroll createScroll(String html, {Registry? registry, DomElement? container}) {
  final emitter = Emitter();
  // Always use testAdapter which is FakeDomAdapter
  final doc = testAdapter.document;
  final parent = container ?? doc.body;
  final root = doc.createElement('div');
  parent.append(root);
  root.innerHTML = normalizeHTML(html);
  final resolvedRegistry = registry ?? createRegistry();
  final scroll = Scroll(
    resolvedRegistry,
    root,
    emitter: emitter,
  );
  return scroll;
}

/// Custom matcher for comparing HTML content (innerHTML by default).
///
/// Port of the upstream test helper `toEqualHTML`
/// (`referencias/quilljs/test/unit/__helpers__/expect.ts`): both sides are
/// parsed and re-serialized, `.ql-ui` nodes are dropped and attributes are
/// sorted by name, so only meaningful differences fail.
///
/// The previous version serialized a **whitelist** of attributes, which hid
/// everything else — `data-list`, `rel`, `target`, `style` never showed up,
/// so a wrong element compared equal to a right one.
class EqualHTML extends Matcher {
  EqualHTML(this.expected,
      {this.includeOuterTag = false, this.ignoreAttrs = const []});

  final String expected;
  final bool includeOuterTag;

  /// Attributes dropped from BOTH sides before comparing, like upstream's
  /// `toEqualHTML(html, { ignoreAttrs })` — used for values that are random
  /// by design, such as the table module's `data-row` ids.
  final List<String> ignoreAttrs;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! DomElement) return false;
    return _getHTML(item, includeOuterTag: includeOuterTag) ==
        _expectedHTML();
  }

  /// Parses the expectation with the same DOM the editor uses, then
  /// serializes it through the same writer — upstream does exactly this by
  /// assigning `innerHTML` on a scratch `<div>`.
  String _expectedHTML() {
    final holder = testAdapter.document.createElement('div');
    if (holder is FakeDomElement) {
      holder.innerHTML = normalizeHTML(expected);
    }
    return _getHTML(holder);
  }

  @override
  Description describe(Description description) {
    return description.add('HTML equals ').addDescriptionOf(_expectedHTML());
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! DomElement) {
      return mismatchDescription.add('is not a DomElement');
    }

    final actual = _getHTML(item, includeOuterTag: includeOuterTag);
    return mismatchDescription.add('has HTML ').addDescriptionOf(actual);
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
      return;
    }
    if (node is! DomElement) return;
    // Upstream's helper deletes every `.ql-ui` node before comparing: they
    // are editor chrome (the checklist/list marker), not document content.
    if (node.classes.contains('ql-ui')) return;

    final tagName = node.tagName.toLowerCase();
    buffer.write('<$tagName');

    // ALL attributes, sorted by name — upstream sorts both sides so the
    // comparison never depends on insertion order.
    final names = node.attributeNames.toList()..sort();
    for (final name in names) {
      if (ignoreAttrs.contains(name)) continue;
      final value = node.getAttribute(name);
      if (value == null) continue;
      buffer.write(' $name="$value"');
    }

    buffer.write('>');

    const voidElements = [
      'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', //
      'link', 'meta', 'source', 'track', 'wbr',
    ];
    if (voidElements.contains(tagName)) return;

    for (final child in node.childNodes) {
      _buildHTML(child, buffer);
    }
    buffer.write('</$tagName>');
  }
}

/// The string form of the upstream `toEqualHTML`: both sides are parsed with
/// the same DOM and re-serialized, so indentation and attribute order in the
/// expectation are irrelevant. Used where the subject is an HTML *string*
/// (e.g. `Editor.getHTML`) rather than a live element.
void expectHtmlStringEquals(String actual, String expected) {
  final holder = testAdapter.document.createElement('div');
  if (holder is FakeDomElement) {
    holder.innerHTML = normalizeHTML(actual);
  }
  expect(holder, EqualHTML(expected));
}

/// Extension to add toEqualHTML matcher to test API
extension HtmlMatchers on DomElement {
  Matcher toEqualHTML(String expected) => EqualHTML(expected);
}

/// Expect that a DomElement's innerHTML equals the expected HTML (default behavior)
void expectHTML(DomElement element, String expected,
    {bool includeOuterTag = false, List<String> ignoreAttrs = const []}) {
  expect(
      element,
      EqualHTML(expected,
          includeOuterTag: includeOuterTag, ignoreAttrs: ignoreAttrs));
}
