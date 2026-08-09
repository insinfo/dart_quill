import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart';

void main() {
  ContentMatch get(String expr) {
    return ContentMatch.parse(expr, testSchema.nodes);
  }

  bool match(String expr, String types) {
    ContentMatch? m = get(expr);
    List<NodeType> ts = types.isNotEmpty
        ? types.split(" ").map<NodeType>((t) => testSchema.nodes[t]!).toList()
        : <NodeType>[];
    for (int i = 0; m != null && i < ts.length; i++) {
      m = m.matchType(ts[i]);
    }
    return m != null && m.validEnd;
  }

  void valid(String expr, String types) {
    expect(match(expr, types), isTrue);
  }

  void invalid(String expr, String types) {
    expect(match(expr, types), isFalse);
  }

  void fill(String expr, PMNode before, PMNode after, PMNode? result) {
    Fragment? filled = get(expr)
        .matchFragment(before.content)
        ?.fillBefore(after.content, true);
    if (result != null) {
      expect(filled, isNotNull);
      expect(filled!.eq(result.content), isTrue);
    } else {
      expect(filled, isNull);
    }
  }

  void fill3(String expr, PMNode before, PMNode mid, PMNode after, PMNode? left,
      [PMNode? right]) {
    ContentMatch content = get(expr);
    Fragment? a =
        content.matchFragment(before.content)?.fillBefore(mid.content);
    Fragment? b = a != null
        ? content
            .matchFragment(before.content.append(a).append(mid.content))
            ?.fillBefore(after.content, true)
        : null;
    if (left != null) {
      expect(a, isNotNull);
      expect(a!.eq(left.content), isTrue);
      expect(b, isNotNull);
      expect(b!.eq(right!.content), isTrue);
    } else {
      expect(b, isNull);
    }
  }

  group('ContentMatch', () {
    group('matchType', () {
      test('accepts empty content for the empty expr', () => valid("", ""));
      test('doesn\'t accept content in the empty expr',
          () => invalid("", "image"));

      test('matches nothing to an asterisk', () => valid("image*", ""));
      test(
          'matches one element to an asterisk', () => valid("image*", "image"));
      test('matches multiple elements to an asterisk',
          () => valid("image*", "image image image image"));
      test('only matches appropriate elements to an asterisk',
          () => invalid("image*", "image text"));

      test('matches group members to a group',
          () => valid("inline*", "image text"));
      test('doesn\'t match non-members to a group',
          () => invalid("inline*", "paragraph"));
      test('matches an element to a choice expression',
          () => valid("(paragraph | heading)", "paragraph"));
      test('doesn\'t match unmentioned elements to a choice expr',
          () => invalid("(paragraph | heading)", "image"));

      test(
          'matches a simple sequence',
          () => valid("paragraph horizontal_rule paragraph",
              "paragraph horizontal_rule paragraph"));
      test(
          'fails when a sequence is too long',
          () => invalid("paragraph horizontal_rule",
              "paragraph horizontal_rule paragraph"));
      test(
          'fails when a sequence is too short',
          () => invalid("paragraph horizontal_rule paragraph",
              "paragraph horizontal_rule"));
      test(
          'fails when a sequence starts incorrectly',
          () => invalid("paragraph horizontal_rule",
              "horizontal_rule paragraph horizontal_rule"));

      test('accepts a sequence asterisk matching zero elements',
          () => valid("heading paragraph*", "heading"));
      test('accepts a sequence asterisk matching multiple elts',
          () => valid("heading paragraph*", "heading paragraph paragraph"));
      test('accepts a sequence plus matching one element',
          () => valid("heading paragraph+", "heading paragraph"));
      test('accepts a sequence plus matching multiple elts',
          () => valid("heading paragraph+", "heading paragraph paragraph"));
      test('fails when a sequence plus has no elements',
          () => invalid("heading paragraph+", "heading"));
      test('fails when a sequence plus misses its start',
          () => invalid("heading paragraph+", "paragraph paragraph"));

      test('accepts an optional element being present',
          () => valid("image?", "image"));
      test('accepts an optional element being missing',
          () => valid("image?", ""));
      test('fails when an optional element is present twice',
          () => invalid("image?", "image image"));

      test(
          'accepts a nested repeat',
          () => valid("(heading paragraph+)+",
              "heading paragraph heading paragraph paragraph"));
      test(
          'fails on extra input after a nested repeat',
          () => invalid("(heading paragraph+)+",
              "heading paragraph heading paragraph paragraph horizontal_rule"));

      test('accepts a matching count',
          () => valid("hard_break{2}", "hard_break hard_break"));
      test('rejects a count that comes up short',
          () => invalid("hard_break{2}", "hard_break"));
      test('rejects a count that has too many elements',
          () => invalid("hard_break{2}", "hard_break hard_break hard_break"));
      test('accepts a count on the lower bound',
          () => valid("hard_break{2, 4}", "hard_break hard_break"));
      test(
          'accepts a count on the upper bound',
          () => valid("hard_break{2, 4}",
              "hard_break hard_break hard_break hard_break"));
      test('accepts a count between the bounds',
          () => valid("hard_break{2, 4}", "hard_break hard_break hard_break"));
      test('rejects a sequence with too few elements',
          () => invalid("hard_break{2, 4}", "hard_break"));
      test(
          'rejects a sequence with too many elements',
          () => invalid("hard_break{2, 4}",
              "hard_break hard_break hard_break hard_break hard_break"));
      test(
          'rejects a sequence with a bad element after it',
          () =>
              invalid("hard_break{2, 4} text*", "hard_break hard_break image"));
      test(
          'accepts a sequence with a matching element after it',
          () =>
              valid("hard_break{2, 4} image?", "hard_break hard_break image"));
      test('accepts an open range',
          () => valid("hard_break{2,}", "hard_break hard_break"));
      test(
          'accepts an open range matching many',
          () => valid(
              "hard_break{2,}", "hard_break hard_break hard_break hard_break"));
      test('rejects an open range with too few elements',
          () => invalid("hard_break{2,}", "hard_break"));
    });

    group('fillBefore', () {
      test(
          'returns the empty fragment when things match',
          () => fill("paragraph horizontal_rule paragraph", doc(p(), hr()),
              doc(p()), doc()));

      test(
          'adds a node when necessary',
          () => fill("paragraph horizontal_rule paragraph", doc(p()), doc(p()),
              doc(hr())));

      test('accepts an asterisk across the bound',
          () => fill("hard_break*", p(br()), p(br()), p()));

      test('accepts an asterisk only on the left',
          () => fill("hard_break*", p(br()), p(), p()));

      test('accepts an asterisk only on the right',
          () => fill("hard_break*", p(), p(br()), p()));

      test('accepts an asterisk with no elements',
          () => fill("hard_break*", p(), p(), p()));

      test('accepts a plus across the bound',
          () => fill("hard_break+", p(br()), p(br()), p()));

      test('adds an element for a content-less plus',
          () => fill("hard_break+", p(), p(), p(br())));

      test('fails for a mismatched plus',
          () => fill("hard_break+", p(), p(img({'src': ''})), null));

      test('accepts asterisk with content on both sides',
          () => fill("heading* paragraph*", doc(h1()), doc(p()), doc()));

      test('accepts asterisk with no content after',
          () => fill("heading* paragraph*", doc(h1()), doc(), doc()));

      test('accepts plus with content on both sides',
          () => fill("heading+ paragraph+", doc(h1()), doc(p()), doc()));

      test('accepts plus with no content after',
          () => fill("heading+ paragraph+", doc(h1()), doc(), doc(p())));

      test('adds elements to match a count',
          () => fill("hard_break{3}", p(br()), p(br()), p(br())));

      test('fails when there are too many elements',
          () => fill("hard_break{3}", p(br(), br()), p(br(), br()), null));

      test(
          'adds elements for two counted groups',
          () => fill("code_block{2} paragraph{2}", doc(pre()), doc(p()),
              doc(pre(), p())));

      test(
          'doesn\'t include optional elements',
          () => fill("heading paragraph? horizontal_rule", doc(h1()), doc(),
              doc(hr())));

      test(
          'completes a sequence',
          () => fill3(
              "paragraph horizontal_rule paragraph horizontal_rule paragraph",
              doc(p()),
              doc(p()),
              doc(p()),
              doc(hr()),
              doc(hr())));

      test(
          'accepts plus across two bounds',
          () => fill3("code_block+ paragraph+", doc(pre()), doc(pre()),
              doc(p()), doc(), doc()));

      test(
          'fills a plus from empty input',
          () => fill3("code_block+ paragraph+", doc(), doc(), doc(), doc(),
              doc(pre(), p())));

      test(
          'completes a count',
          () => fill3("code_block{3} paragraph{3}", doc(pre()), doc(p()), doc(),
              doc(pre(), pre()), doc(p(), p())));

      test('fails on non-matching elements',
          () => fill3("paragraph*", doc(p()), doc(pre()), doc(p()), null));

      test(
          'completes a plus across two bounds',
          () => fill3(
              "paragraph{4}", doc(p()), doc(p()), doc(p()), doc(), doc(p())));

      test('refuses to complete an overflown count across two bounds',
          () => fill3("paragraph{2}", doc(p()), doc(p()), doc(p()), null));
    });
  });
}
