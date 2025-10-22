import 'dart:convert';

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