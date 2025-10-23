import 'dart:convert';

import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';
import 'inline.dart';

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
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      throw ArgumentError('Cannot insert embed definition into TextBlot');
    }
    final data = textNode.data;
    if (index < 0 || index > data.length) {
      throw RangeError.index(index, data, 'index');
    }
    textNode.data = data.substring(0, index) + value + data.substring(index);
  }

  @override
  void deleteAt(int index, int length) {
    final data = textNode.data;
    if (index < 0 || index + length > data.length) {
      throw RangeError.range(index, index, data.length, 'index');
    }
    textNode.data = data.replaceRange(index, index + length, '');
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) {
      return;
    }

    final inlineEntry = scroll.query(name, Scope.INLINE_BLOT);
    if (inlineEntry == null) {
      super.formatAt(index, length, name, value);
      return;
    }

    final target = _isolate(index, length);
    if (value == null || value == false) {
      _removeInlineFormat(target, name);
      return;
    }

    if (_hasAncestorWithFormat(target, name)) {
      return;
    }

    final parentToWrap = _highestWrapTarget(target, name);
    final parent = parentToWrap.parent;
    if (parent is! ParentBlot) {
      return;
    }

    final wrapper = scroll.create(name, value) as ParentBlot;
    parent.insertBefore(wrapper, parentToWrap);
    wrapper.appendChild(parentToWrap);
    wrapper.optimize();
  }

  TextBlot _isolate(int index, int length) {
    final endIndex = index + length;
    split(endIndex);
    if (index > 0) {
      final middle = split(index);
      if (middle is TextBlot) {
        return middle;
      }
    }
    return this;
  }

  bool _hasAncestorWithFormat(Blot blot, String name) {
    Blot? current = blot.parent;
    while (current is InlineBlot) {
      if (current.blotName == name) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  Blot _highestWrapTarget(Blot blot, String name) {
    Blot current = blot;
    InlineBlot? parentInline =
        current.parent is InlineBlot ? current.parent as InlineBlot : null;
    while (parentInline != null) {
      if (parentInline.blotName == name) {
        return parentInline;
      }
      final comparison = InlineBlot.compare(parentInline.blotName, name);
      if (comparison > 0) {
        break;
      }
      current = parentInline;
      parentInline = parentInline.parent is InlineBlot
          ? parentInline.parent as InlineBlot
          : null;
    }
    return current;
  }

  void _removeInlineFormat(Blot blot, String name) {
    Blot? current = blot.parent;
    while (current is InlineBlot) {
      if (current.blotName == name) {
        current.unwrap();
        return;
      }
      current = current.parent;
    }
  }

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

    textNode.data = left;
    final newNode = domBindings.adapter.document.createTextNode(right);
    final newBlot = TextBlot(newNode);
    parent?.insertBefore(newBlot, next);
    return newBlot;
  }
}

String escapeText(String text) {
  return const HtmlEscape().convert(text);
}
