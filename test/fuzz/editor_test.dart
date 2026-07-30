import 'dart:math';

import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../support/quill_test_helpers.dart';
import '../support/test_helpers.dart';

const _blockEmbedName = 'video';
const _inlineEmbedName = 'image';
const _fuzzDuration = Duration(seconds: 30);

const _attributeDefs = <String, List<(String, List<dynamic>)>>{
  'text': [
    ('color', ['#ffffff', '#000000', '#ff0000', '#ffff00']),
    ('bold', [true]),
    ('code', [true]),
    ('font', ['serif', 'monospace']),
    ('size', ['small', 'large', 'huge']),
  ],
  'newline': [
    ('align', ['center', 'right', 'justify']),
    ('header', [1, 2, 3, 4, 5]),
    ('blockquote', [true]),
    ('list', ['ordered', 'bullet', 'checked', 'unchecked']),
  ],
  'inlineEmbed': [
    ('width', ['100', '200', '300']),
    ('height', ['100', '200', '300']),
  ],
  'blockEmbed': [
    ('align', ['center', 'right']),
    ('width', ['100', '200', '300']),
    ('height', ['100', '200', '300']),
  ],
};

int _extent(Delta delta) => delta.operations.fold(
      0,
      (length, operation) => length + operation.length!,
    );

class _Fuzzer {
  _Fuzzer(this.seed) : random = Random(seed);

  final int seed;
  final Random random;

  int randomInt(int max) => max <= 0 ? 0 : random.nextInt(max);

  T choose<T>(List<T> choices) => choices[randomInt(choices.length)];

  bool isLineFinished(Delta delta) {
    if (delta.operations.isEmpty) return false;
    final insert = delta.operations.last.data;
    if (insert is String) return insert.endsWith('\n');
    if (insert is Map) return insert.keys.firstOrNull == _blockEmbedName;
    throw StateError('invalid op');
  }

  Map<String, dynamic> generateAttributes(String scope) {
    final attributeCount = scope == 'newline'
        ? choose([0, 0, 1])
        : choose([0, 0, 0, 0, 0, 1, 2, 3, 4]);
    final attributes = <String, dynamic>{};
    for (var i = 0; i < attributeCount; i += 1) {
      final definition = choose(_attributeDefs[scope]!);
      attributes[definition.$1] = choose(definition.$2);
    }
    return attributes;
  }

  Operation generateSingleInsert() {
    final scope = choose([
      'text',
      'text',
      'text',
      'newline',
      'inlineEmbed',
      'blockEmbed',
    ]);
    final dynamic insert = switch (scope) {
      'text' => choose([
          'hi',
          'world',
          'Slab',
          ' ',
          'this is a long text that contains spaces',
        ]),
      'newline' => '\n',
      'inlineEmbed' => {_inlineEmbedName: 'https://example.com'},
      'blockEmbed' => {_blockEmbedName: 'https://example.com'},
      _ => throw StateError('invalid scope'),
    };
    final attributes = generateAttributes(scope);
    return Operation.insert(insert, attributes.isEmpty ? null : attributes);
  }

  void safePushInsert(Delta delta, {required bool isDocument}) {
    final operation = generateSingleInsert();
    final insert = operation.data;
    if (insert is Map &&
        insert[_blockEmbedName] != null &&
        (!isDocument ||
            (delta.operations.isNotEmpty && !isLineFinished(delta)))) {
      delta.insert('\n');
    }
    delta.push(operation);
  }

  Delta generateDocument() {
    final delta = Delta();
    final operationCount = 2 + randomInt(20);
    for (var i = 0; i < operationCount; i += 1) {
      safePushInsert(delta, isDocument: true);
    }
    if (!isLineFinished(delta)) delta.insert('\n');
    return delta;
  }

  Delta generateChange(
    Delta document,
    int changeCount, {
    List<String> allowedActions = const ['insert', 'delete', 'retain'],
  }) {
    final documentLength = _extent(document);
    final skipLength =
        allowedActions.contains('retain') ? randomInt(documentLength) : 0;
    var change = Delta()..retain(skipLength);
    final action = choose(allowedActions);
    final nextOperations = document.slice(skipLength).operations;
    if (nextOperations.isEmpty) throw StateError('nextOp expected');
    final nextOperation = nextOperations.first;
    final needNewline = !isLineFinished(document.slice(0, skipLength));

    switch (action) {
      case 'insert':
        final inserted = Delta();
        final operationCount = randomInt(5) + 1;
        for (var i = 0; i < operationCount; i += 1) {
          safePushInsert(inserted, isDocument: false);
        }
        if (needNewline ||
            (nextOperation.data is Map &&
                (nextOperation.data! as Map)[_blockEmbedName] != null)) {
          inserted.insert('\n');
        }
        change = change.concat(inserted);
      case 'delete':
        final lengthToDelete = randomInt(documentLength - skipLength - 1) + 1;
        final remaining =
            document.slice(skipLength + lengthToDelete).operations;
        final nextAfterDelete = remaining.firstOrNull;
        if (needNewline &&
            (nextAfterDelete == null ||
                (nextAfterDelete.data is Map &&
                    (nextAfterDelete.data! as Map)[_blockEmbedName] != null))) {
          change.insert('\n');
        }
        change.delete(lengthToDelete);
      case 'retain':
        final insert = nextOperation.data;
        final retainLength =
            insert is String ? randomInt(insert.length - 1) + 1 : 1;
        if (insert is String) {
          if (insert.contains('\n') && insert.replaceAll('\n', '').isNotEmpty) {
            break;
          }
          final scope = insert.contains('\n') ? 'newline' : 'text';
          change.retain(
            retainLength,
            Delta.diffAttributes(
              nextOperation.attributes,
              generateAttributes(scope),
            ),
          );
        }
    }

    return changeCount <= 1
        ? change
        : change.compose(
            generateChange(
              document.compose(change),
              changeCount - 1,
              allowedActions: allowedActions,
            ),
          );
  }
}

void _runFuzz(int seed, void Function(_Fuzzer fuzzer, int iteration) body) {
  final fuzzer = _Fuzzer(seed);
  final stopwatch = Stopwatch()..start();
  var iteration = 0;
  do {
    printOnFailure('fuzz seed=$seed iteration=$iteration');
    body(fuzzer, iteration);
    iteration += 1;
  } while (stopwatch.elapsed < _fuzzDuration);
}

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('editor', () {
    test('setContents()', () {
      _runFuzz(0x5e7c017, (fuzzer, _) {
        final container = testAdapter.document.createElement('div');
        final quill = Quill(container);
        final delta = fuzzer.generateDocument();
        expectDelta(
          quill.setContents(delta),
          delta.concat(Delta()..delete(1)),
        );
      });
    });

    test('updateContents()', () {
      _runFuzz(0x0da7e, (fuzzer, _) {
        final container = testAdapter.document.createElement('div');
        final quill = Quill(container);
        quill.setContents(fuzzer.generateDocument());

        for (var i = 0; i < 800; i += 1) {
          final document = quill.getContents();
          final change =
              fuzzer.generateChange(document, fuzzer.randomInt(4) + 1);
          final actual = quill.updateContents(change);
          expect(
            actual.toJson(),
            equals(change.toJson()),
            reason: 'seed=${fuzzer.seed} update=$i\n'
                'document=${document.toJson()}\n'
                'change=${change.toJson()}\n'
                'expectedDocument=${document.compose(change).toJson()}\n'
                'actualDocument=${quill.getContents().toJson()}\n'
                'html=${quill.root.outerHTML}',
          );
        }
      });
    });

    test('insertContents() vs applyDelta()', () {
      final quill1 = Quill(testAdapter.document.createElement('div'));
      final quill2 = Quill(testAdapter.document.createElement('div'));

      _runFuzz(0x1a5e47, (fuzzer, _) {
        final delta = fuzzer.generateDocument();
        quill1.setContents(delta);
        quill2.setContents(delta);

        final retain = fuzzer.randomInt(_extent(delta));
        final change = fuzzer.generateChange(
          delta,
          fuzzer.randomInt(20) + 1,
          allowedActions: const ['insert'],
        );
        quill1.editor.insertContents(retain, change);
        quill2.editor.applyDelta(
          (Delta()..retain(retain)).concat(change),
        );

        expectDelta(quill1.getContents(), quill2.getContents());
      });
    });
  });
}
