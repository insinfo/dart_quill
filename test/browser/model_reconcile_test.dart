@TestOn('browser')
library model_reconcile_test;

/// The DOM→model reconciliation, exercised against a REAL browser DOM.
///
/// The fake DOM hands the same objects back in mutation records, so identity
/// checks and type casts that only work there passed for a long time while
/// the browser silently dropped every native edit. These tests pin the
/// browser behaviour: records must carry properly typed wrappers, and the
/// text the browser inserts must reach the document model.
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Quill _createQuill() {
  final host = web.document.createElement('div') as web.HTMLElement;
  web.document.body!.appendChild(host);
  addTearDown(() => host.remove());
  return Quill(HtmlDomElement(host));
}

web.Element _root(Quill quill) =>
    (quill.root as HtmlDomElement).node as web.Element;

void main() {
  setUpAll(initializeQuill);

  group('mutation records', () {
    test('carry wrappers of the proper type, not bare nodes', () async {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('texto\n'));

      final records = <DomMutationRecord>[];
      final observer = domBindings.adapter.createMutationObserver(
        (mutations, _) => records.addAll(mutations),
      );
      observer.observe(quill.root,
          subtree: true, childList: true, characterData: true);
      addTearDown(observer.disconnect);

      // A text edit and a structural edit, the way a browser produces them.
      final paragraph = _root(quill).querySelector('p')!;
      (paragraph.firstChild as web.Text).data = 'texto editado';
      paragraph.appendChild(web.document.createElement('span'));

      final taken = observer.takeRecords();
      expect(taken, isNotEmpty, reason: 'the observer must see the edits');

      final characterData =
          taken.where((record) => record.type == 'characterData');
      expect(characterData, isNotEmpty);
      expect(characterData.first.target, isA<DomText>(),
          reason: 'a characterData target must arrive as a DomText — the '
              'reconciliation casts it, and a bare node wrapper made every '
              'native edit fall through');

      final childList = taken.where((record) => record.type == 'childList');
      expect(childList, isNotEmpty);
      expect(childList.first.target, isA<DomElement>());
      expect(childList.first.addedNodes.first, isA<DomElement>());
    });

    test('a record target compares equal to the blot node it came from',
        () async {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('igualdade\n'));

      final records = <DomMutationRecord>[];
      final observer = domBindings.adapter.createMutationObserver(
        (mutations, _) => records.addAll(mutations),
      );
      observer.observe(quill.root, subtree: true, characterData: true);
      addTearDown(observer.disconnect);

      final textNode = _root(quill).querySelector('p')!.firstChild as web.Text;
      textNode.data = 'igualdade!';
      final taken = observer.takeRecords();

      final leaf = quill.getLeaf(0).key!;
      expect(taken.first.target == leaf.domNode, isTrue,
          reason: 'wrappers are minted per access, so the model must compare '
              'records by node equality — `identical` never matches here');
    });
  });

  group('native edits reach the model', () {
    test('text typed straight into the DOM shows up in getContents',
        () async {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('abc\n'));

      // What the browser does when the user types: it edits the text node.
      final textNode = _root(quill).querySelector('p')!.firstChild as web.Text;
      textNode.data = 'abcdef';
      quill.update();

      expect(quill.getText(), 'abcdef\n');
      expect(quill.getContents().toJson(), [
        {'insert': 'abcdef\n'}
      ]);
    });

    test('a node the browser inserts is hydrated into the document', () async {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('inicio\n'));

      final paragraph = _root(quill).querySelector('p')!;
      final strong = web.document.createElement('strong');
      strong.textContent = 'forte';
      paragraph.appendChild(strong);
      quill.update();

      expect(quill.getText(), 'inicioforte\n');
      final ops = quill.getContents().toJson();
      expect(ops.last['insert'], '\n');
      expect(
          ops.any((op) =>
              op['insert'] == 'forte' && op['attributes']?['bold'] == true),
          isTrue,
          reason: 'the inserted <strong> must hydrate as a bold run: $ops');
    });

    /// Port of `scroll.spec.ts` "api change": an API edit must reach
    /// SCROLL_OPTIMIZE carrying the MutationRecords it produced. Browser-only
    /// by nature — the event fires under `mutations.length > 0`, and the
    /// records come from a real observer.
    test('an api edit emits SCROLL_OPTIMIZE with its mutations', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('Hello World!\n'));

      var optimized = 0;
      List<dynamic>? seen;
      quill.scroll.emitter.on(EmitterEvents.SCROLL_OPTIMIZE,
          (dynamic mutations, [dynamic context]) {
        optimized += 1;
        if (mutations is List) seen = mutations;
      });

      quill.scroll.insertAt(5, '!');
      quill.scroll.optimize([], {});

      expect(optimized, greaterThan(0));
      expect(seen, isNotNull);
      expect(seen, isNotEmpty);
    });

    test('removing a node in the DOM removes it from the model', () async {
      final quill = _createQuill();
      quill.setContents(Delta()
        ..insert('uma\n')
        ..insert('duas\n'));
      expect(quill.getLines().length, 2);

      (_root(quill).querySelectorAll('p').item(1)! as web.Element).remove();
      quill.update();

      expect(quill.getText(), 'uma\n');
      expect(quill.getLines().length, 1);
    });
  });
}
