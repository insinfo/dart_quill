/// A blot the application registers itself has to paste like a built-in one.
///
/// `matchBlot` used to carry hardcoded knowledge — a set of embed names and a
/// switch over blot names for `static formats` — so only image/video/formula
/// could ever paste as embeds, and only the built-ins reported their formats.
/// The registry entry now declares it (`isEmbed`, `staticValue`,
/// `staticFormats`), which is what these tests pin.
library;

import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/blots/embed.dart';
import 'package:dart_quill/src/blots/inline.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

/// An inline embed of the kind an application would add — a mention chip.
class _Mention extends Embed {
  _Mention(DomElement node) : super(node);

  static const String kBlotName = 'mention';
  static const String kClassName = 'app-mention';
  static const String kTagName = 'SPAN';

  static DomElement create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    node.classes.add(kClassName);
    node.setAttribute('data-id', value);
    return node;
  }

  static String? getValue(DomElement node) => node.getAttribute('data-id');

  @override
  String get blotName => kBlotName;

  @override
  int get scope => Scope.INLINE_BLOT;

  @override
  _Mention clone() => _Mention(element.cloneNode(deep: false));

  @override
  Map<String, dynamic> formats() => {kBlotName: getValue(element)};

  @override
  dynamic value() => getValue(element);
}

/// A plain inline format that reports a value of its own.
class _Highlight extends InlineBlot {
  _Highlight(DomElement node) : super(node);

  static const String kBlotName = 'app-highlight';
  static const String kTagName = 'MARK';

  static String? getFormat(DomElement node) =>
      node.getAttribute('data-tone') ?? 'default';

  @override
  String get blotName => kBlotName;

  @override
  int get scope => Scope.INLINE_BLOT;

  @override
  _Highlight clone() => _Highlight(element.cloneNode(deep: false));
}

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    Quill.register(
      RegistryEntry(
        blotName: _Mention.kBlotName,
        scope: Scope.INLINE_BLOT,
        tagNames: const [_Mention.kTagName],
        classNames: const [_Mention.kClassName],
        isEmbed: true,
        staticValue: _Mention.getValue,
        staticFormats: (node) => {
          if (node.getAttribute('data-kind') != null)
            'kind': node.getAttribute('data-kind'),
        },
        create: ([dynamic value]) => value is DomElement
            ? _Mention(value)
            : _Mention(_Mention.create(value?.toString() ?? '')),
      ),
      true,
    );
    Quill.register(
      RegistryEntry(
        blotName: _Highlight.kBlotName,
        scope: Scope.INLINE_BLOT,
        tagNames: const [_Highlight.kTagName],
        staticFormats: _Highlight.getFormat,
        create: ([dynamic value]) => value is DomElement
            ? _Highlight(value)
            : _Highlight(
                domBindings.adapter.document.createElement(_Highlight.kTagName)),
      ),
      true,
    );
  });

  test('a registered embed pastes as an embed insert', () {
    final quill = createTestQuill();

    expectDelta(
      quill.clipboard.convert(
        html: '<p>oi <span class="app-mention" data-id="u42"></span></p>',
      ),
      // `convert` drops the trailing newline of the last block, as upstream.
      Delta()
        ..insert('oi ')
        ..insert({'mention': 'u42'}),
    );
  });

  test('the embed carries the formats its entry reports', () {
    final quill = createTestQuill();

    expectDelta(
      quill.clipboard.convert(
        html: '<p><span class="app-mention" data-id="u7" data-kind="user">'
            '</span></p>',
      ),
      Delta()..insert({'mention': 'u7'}, {'kind': 'user'}),
    );
  });

  test('an embed with no value is skipped, not inserted empty', () {
    final quill = createTestQuill();

    expectDelta(
      quill.clipboard.convert(html: '<p>a<span class="app-mention"></span></p>'),
      Delta()..insert('a'),
    );
  });

  test('a registered inline format reports its own value', () {
    final quill = createTestQuill();

    expectDelta(
      quill.clipboard.convert(html: '<p><mark data-tone="warn">x</mark></p>'),
      Delta()..insert('x', {'app-highlight': 'warn'}),
    );
  });

  test('the built-ins keep reporting through their entries', () {
    final quill = createTestQuill();

    expectDelta(
      quill.clipboard.convert(
        html: '<img src="https://example.com/a.png" width="100">',
      ),
      Delta()..insert({'image': 'https://example.com/a.png'}, {'width': '100'}),
    );
    expectDelta(
      quill.clipboard.convert(html: '<h2>t</h2>'),
      Delta()..insert('t\n', {'header': 2}),
    );
  });
}
