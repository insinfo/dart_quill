import 'package:test/test.dart';

import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/schema_list/index.dart';
import 'package:dart_quill/src/document_engine/state/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  final bulletList = schema.nodes['bullet_list']!;
  final listItem = schema.nodes['list_item']!;

  EditorState stateWithSelection(PMNode docNode) {
    final a = docNode.tag['a']!;
    final b = docNode.tag['b'];
    return EditorState.create(EditorStateConfig(
      schema: schema,
      doc: docNode,
      selection: TextSelection.create(docNode, a, b),
    ));
  }

  PMNode runCommand(Command command, PMNode docNode) {
    var state = stateWithSelection(docNode);
    final success = command(state, (tr) {
      state = state.apply(tr);
    });
    expect(success, isTrue, reason: 'comando deveria ser aplicável');
    return state.doc;
  }

  group('wrapInList', () {
    test('envolve um parágrafo em bullet list', () {
      final result =
          runCommand(wrapInList(bulletList), doc(p('<a>foo'), p('bar')));
      expect(result.eq(doc(ul(li(p('foo'))), p('bar'))), isTrue,
          reason: result.toString());
    });

    test('envolve dois parágrafos, um item por parágrafo', () {
      final result =
          runCommand(wrapInList(bulletList), doc(p('<a>foo'), p('bar<b>')));
      expect(result.eq(doc(ul(li(p('foo')), li(p('bar'))))), isTrue,
          reason: result.toString());
    });

    test('não se aplica no primeiro item de uma lista existente', () {
      final state = stateWithSelection(doc(ul(li(p('<a>foo')))));
      expect(wrapInList(bulletList)(state), isFalse);
    });
  });

  group('splitListItem', () {
    test('divide o item no cursor', () {
      final result =
          runCommand(splitListItem(listItem), doc(ul(li(p('foo<a>bar')))));
      expect(result.eq(doc(ul(li(p('foo')), li(p('bar'))))), isTrue,
          reason: result.toString());
    });

    test('cursor no fim cria item vazio', () {
      final result =
          runCommand(splitListItem(listItem), doc(ul(li(p('foo<a>')))));
      expect(result.eq(doc(ul(li(p('foo')), li(p())))), isTrue,
          reason: result.toString());
    });
  });

  group('liftListItem', () {
    test('tira o item da lista para o nível de bloco', () {
      final result = runCommand(
          liftListItem(listItem), doc(ul(li(p('one')), li(p('t<a>wo')))));
      expect(result.eq(doc(ul(li(p('one'))), p('two'))), isTrue,
          reason: result.toString());
    });

    test('item aninhado sobe um nível', () {
      final result = runCommand(liftListItem(listItem),
          doc(ul(li(p('one'), ul(li(p('t<a>wo')))))));
      expect(result.eq(doc(ul(li(p('one')), li(p('two'))))), isTrue,
          reason: result.toString());
    });
  });

  group('sinkListItem', () {
    test('afunda o item para dentro do anterior', () {
      final result = runCommand(
          sinkListItem(listItem), doc(ul(li(p('one')), li(p('t<a>wo')))));
      expect(result.eq(doc(ul(li(p('one'), ul(li(p('two'))))))), isTrue,
          reason: result.toString());
    });

    test('não se aplica ao primeiro item', () {
      final state = stateWithSelection(doc(ul(li(p('o<a>ne')), li(p('two')))));
      expect(sinkListItem(listItem)(state), isFalse);
    });
  });
}
