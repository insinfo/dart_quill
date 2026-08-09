import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/state/index.dart';
import 'dart:convert';
import '../test_builder_support/test_builder.dart';

void main() {
  final messageCountKey = PluginKey<int>("messageCount");
  final messageCountPlugin = Plugin<int>(PluginSpec<int>(
    key: messageCountKey,
    state: StateField<int>(
      init: (config, instance) => 0,
      apply: (tr, count, oldState, newState) => count + 1,
      toJSON: (count) => count,
      fromJSON: (config, count, state) => count as int,
    ),
    props: {
      "testProp": (Plugin plugin) => plugin,
    },
  ));

  final transactionPlugin = Plugin<dynamic>(PluginSpec<dynamic>(
    filterTransaction: (tr, state) => tr.getMeta("filtered") != true,
    appendTransaction: (trs, oldState, newState) {
      var last = trs.isNotEmpty ? trs.last : null;
      if (last != null && last.getMeta("append") == true) {
        return newState.tr.insertText("A");
      }
      return null;
    },
  ));

  group("State", () {
    test("creates a default doc", () {
      var state = EditorState.create(EditorStateConfig(schema: schema));
      expect(state.doc.eq(doc(p())), isTrue);
    });

    test("creates a default selection", () {
      var state = EditorState.create(EditorStateConfig(doc: doc(p("foo"))));
      expect(state.selection.from, equals(1));
      expect(state.selection.to, equals(1));
    });

    test("applies transform transactions", () {
      var state = EditorState.create(EditorStateConfig(schema: schema));
      var newState = state.apply(state.tr.insertText("hi"));
      expect(state.doc.eq(doc(p())), isTrue);
      expect(newState.doc.eq(doc(p("hi"))), isTrue);
      expect(newState.selection.from, equals(3));
    });

    test("supports plugin fields", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [messageCountPlugin], schema: schema));
      var newState = state.apply(state.tr).apply(state.tr);
      expect(messageCountPlugin.getState(state), equals(0));
      expect(messageCountPlugin.getState(newState), equals(2));
    });

    test("can be serialized to JSON", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [messageCountPlugin], doc: doc(p("ok"))));
      state = state
          .apply(state.tr.setSelection(TextSelection.create(state.doc, 3)));
      var pluginProps = {"count": messageCountPlugin};
      var expected = {
        "doc": {
          "type": "doc",
          "content": [
            {
              "type": "paragraph",
              "content": [
                {"type": "text", "text": "ok"}
              ]
            }
          ]
        },
        "selection": {"type": "text", "anchor": 3, "head": 3},
        "count": 1
      };
      var json = state.toJSON(pluginProps);
      expect(jsonEncode(json), equals(jsonEncode(expected)));
      var copy = EditorState.fromJSON(
          EditorStateConfig(plugins: [messageCountPlugin], schema: schema),
          json,
          pluginProps);
      expect(copy.doc.eq(state.doc), isTrue);
      expect(copy.selection.from, equals(3));
      expect(messageCountPlugin.getState(copy), equals(1));

      var limitedJSON = state.toJSON();
      expect(limitedJSON["doc"], isNotNull);
      expect(limitedJSON["messageCount\$"], isNull);
      var deserialized = EditorState.fromJSON(
          EditorStateConfig(plugins: [messageCountPlugin], schema: schema),
          limitedJSON);
      expect(messageCountPlugin.getState(deserialized), equals(0));
    });

    test("supports specifying and persisting storedMarks", () {
      var state = EditorState.create(EditorStateConfig(
          doc: doc(p("ok")), storedMarks: [schema.mark("em")]));
      expect(state.storedMarks!.length, equals(1));
      var copy = EditorState.fromJSON(
          EditorStateConfig(schema: schema), state.toJSON());
      expect(copy.storedMarks!.length, equals(1));
    });

    test("supports reconfiguration", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [messageCountPlugin], schema: schema));
      expect(messageCountPlugin.getState(state), equals(0));
      var without = state.reconfigure(plugins: []);
      expect(messageCountPlugin.getState(without), isNull);
      expect(without.plugins.length, equals(0));
      expect(without.doc.eq(doc(p())), isTrue);
      var reAdd = without.reconfigure(plugins: [messageCountPlugin]);
      expect(messageCountPlugin.getState(reAdd), equals(0));
      expect(reAdd.plugins.length, equals(1));
    });

    test("allows plugins to filter transactions", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [transactionPlugin], schema: schema));
      var applied = state.applyTransaction(state.tr.insertText("X"));
      expect(applied.state.doc.eq(doc(p("X"))), isTrue);
      expect(applied.transactions.length, equals(1));
      applied = state
          .applyTransaction(state.tr.insertText("Y").setMeta("filtered", true));
      expect(applied.state, equals(state));
      expect(applied.transactions.length, equals(0));
    });

    test("allows plugins to append transactions", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [transactionPlugin], schema: schema));
      var applied = state
          .applyTransaction(state.tr.insertText("X").setMeta("append", true));
      expect(applied.state.doc.eq(doc(p("XA"))), isTrue);
      expect(applied.transactions.length, equals(2));
    });

    test("stores a reference to a root transaction for appended transactions",
        () {
      var state =
          EditorState.create(EditorStateConfig(schema: schema, plugins: [
        Plugin<dynamic>(PluginSpec<dynamic>(
          appendTransaction: (trs, oldState, newState) =>
              newState.tr.insertText("Y"),
        ))
      ]));
      var applied = state.applyTransaction(state.tr.insertText("X"));
      var transactions = applied.transactions;
      expect(transactions.length, equals(2));
      expect(transactions[1].getMeta("appendedTransaction"),
          equals(transactions[0]));
    });
  });

  group("Plugin", () {
    test("calls prop functions bound to the plugin", () {
      expect(
          (messageCountPlugin.props["testProp"]
              as Function)(messageCountPlugin),
          equals(messageCountPlugin));
    });

    test("can be found by key", () {
      var state = EditorState.create(
          EditorStateConfig(plugins: [messageCountPlugin], schema: schema));
      expect(messageCountKey.get(state), equals(messageCountPlugin));
      expect(messageCountKey.getState(state), equals(0));
    });

    test("generates new keys", () {
      var p1 = Plugin<dynamic>(PluginSpec<dynamic>());
      var p2 = Plugin<dynamic>(PluginSpec<dynamic>());
      expect(p1.key != p2.key, isTrue);
      var k1 = PluginKey<dynamic>("foo");
      var k2 = PluginKey<dynamic>("foo");
      expect(k1.key != k2.key, isTrue);
    });
  });
}
