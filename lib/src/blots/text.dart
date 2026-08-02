import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';

class TextBlot extends LeafBlot {
  static const String kBlotName = 'text';
  static const int kScope = Scope.INLINE_BLOT;

  TextBlot(DomText domNode) : super(domNode);

  static TextBlot create([dynamic value]) {
    final text = value?.toString() ?? '';
    final node = domBindings.adapter.document.createTextNode(text);
    return TextBlot(node);
  }

  DomText get textNode => domNode as DomText;

  /// Todo write de texto passa por aqui: o comprimento da cadeia de pais
  /// está cacheado e uma escrita que não invalidasse corromperia índices.
  void _setData(String value) {
    textNode.data = value;
    parent?.invalidateLengthCache();
  }

  @override
  String get blotName => TextBlot.kBlotName;

  @override
  int get scope => TextBlot.kScope;

  @override
  int length() => textNode.data.length;

  @override
  Map<String, dynamic> formats() => const {};

  @override
  TextBlot clone() =>
      TextBlot(domBindings.adapter.document.createTextNode(textNode.data));

  @override
  String value() => textNode.data;

  @override
  MapEntry<DomNode, int> position(int index, [bool inclusive = false]) {
    return MapEntry(domNode, index);
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    // Parity parchment text.ts:50-59 — drop empty text nodes and merge with
    // an adjacent TextBlot so the document doesn't fragment progressively
    // after splits/formats.
    super.optimize(mutations, context);
    if (textNode.data.isEmpty) {
      remove();
      return;
    }
    final following = next;
    if (following is TextBlot && identical(following.prev, this)) {
      _setData(textNode.data + following.textNode.data);
      following.remove();
    }
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    final data = textNode.data;
    if (index < 0 || index > data.length) {
      throw RangeError.index(index, data, 'index');
    }

    if (def != null) {
      final parentBlot = parent;
      if (parentBlot is! ParentBlot) {
        throw ArgumentError('Cannot insert embed into TextBlot without parent');
      }
      final ref = split(index);
      final embed = scroll.create(value, def);
      parentBlot.insertBefore(embed, ref);
      return;
    }
    _setData(data.substring(0, index) + value + data.substring(index));
  }

  @override
  void deleteAt(int index, int length) {
    final data = textNode.data;
    if (index < 0 || index + length > data.length) {
      throw RangeError.range(index, index, data.length, 'index');
    }
    _setData(data.replaceRange(index, index + length, ''));
  }

  // Parity: parchment's TextBlot has NO `formatAt` — the base
  // `ShadowBlot.formatAt` (isolate + wrap / attribute parent) plus
  // `Inline.formatAt` (which isolates the WRAPPER when the new format belongs
  // outside it) do the whole job. The bespoke version that lived here climbed
  // to the outermost inline wrapper and wrapped that, so formatting one
  // character inside `<em>45</em>` painted both.

  @override
  Blot? split(int index, {bool force = false}) {
    final len = length();
    if (!force) {
      if (index <= 0) return this;
      if (index >= len) return next;
    }

    final clamped = index.clamp(0, len);
    final left = textNode.data.substring(0, clamped);
    final right = textNode.data.substring(clamped);

    _setData(left);
    final newNode = domBindings.adapter.document.createTextNode(right);
    final newBlot = TextBlot(newNode);
    parent?.insertBefore(newBlot, next);
    return newBlot;
  }
}

/// Parity text.ts:8-16 — the exact upstream entity map. Dart's `HtmlEscape`
/// escapes a different set (notably `/`), which changes the serialized HTML.
String escapeText(String text) {
  return text.replaceAllMapped(RegExp(r'''[&<>"']'''), (match) {
    switch (match[0]) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '"':
        return '&quot;';
      default:
        return '&#39;';
    }
  });
}
