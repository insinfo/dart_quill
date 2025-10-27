import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/table_embed.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  group('tableHandler', () {
    setUp(() {
      TableEmbed.register();
    });

    tearDown(() {
      TableEmbed.unregister();
    });

    group('compose', () {
      test('adds a row', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                }
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '55555555'}},
              ],
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '55555555'}},
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                },
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '2:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        expectDelta(base.compose(change), expected);
      });

      test('adds two rows', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                }
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '55555555'}},
                {'insert': {'id': '66666666'}},
              ],
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '55555555'}},
                {'insert': {'id': '66666666'}},
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                },
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '3:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        expectDelta(base.compose(change), expected);
      });

      test('adds a row and changes cell content', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
                {
                  'insert': {'id': '22222222'},
                  'attributes': {'height': 20},
                },
              ],
              'columns': [
                {'insert': {'id': '33333333'}},
                {
                  'insert': {'id': '44444444'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '55555555'}},
              ],
              'cells': {
                '2:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                },
                '2:3': {
                  'content': [
                    {'insert': 'World'},
                  ],
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '66666666'}},
              ],
              'cells': {
                '3:2': {
                  'attributes': {'align': 'right'},
                },
                '3:3': {
                  'content': [
                    {'insert': 'Hello '},
                  ],
                },
              },
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '66666666'}},
                {'insert': {'id': '11111111'}},
                {
                  'insert': {'id': '22222222'},
                  'attributes': {'height': 20},
                },
              ],
              'columns': [
                {'insert': {'id': '33333333'}},
                {
                  'insert': {'id': '44444444'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '55555555'}},
              ],
              'cells': {
                '3:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'right'},
                },
                '3:3': {
                  'content': [
                    {'insert': 'Hello World'},
                  ],
                },
              },
            },
          });
        expectDelta(base.compose(change), expected);
      });

      test('deletes a column', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                }
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'width': 30},
                },
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'Hello'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'columns': [
                {'retain': 1},
                {'delete': 1},
              ],
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {
                  'insert': {'id': '11111111'},
                  'attributes': {'height': 20},
                }
              ],
              'columns': [
                {'insert': {'id': '22222222'}},
                {'insert': {'id': '44444444'}},
              ],
            },
          });
        expectDelta(base.compose(change), expected);
      });

      test('removes a cell attributes', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'cells': {
                '1:2': {
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'cells': {
                '1:2': {
                  'attributes': {'align': null},
                },
              },
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {},
          });
        expectDelta(base.compose(change), expected);
      });

      test('removes all rows', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
              ],
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'delete': 1},
              ],
            },
          });
        final expected = Delta()
          ..insert({
            'table-embed': {},
          });
        expectDelta(base.compose(change), expected);
      });
    });

    group('transform', () {
      test('transform rows and columns', () {
        final change1 = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
                {'insert': {'id': '22222222'}},
                {
                  'insert': {'id': '33333333'},
                  'attributes': {'height': 100},
                },
              ],
              'columns': [
                {
                  'insert': {'id': '44444444'},
                  'attributes': {'width': 100},
                },
                {'insert': {'id': '55555555'}},
                {'insert': {'id': '66666666'}},
              ],
            },
          });
        final change2 = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'delete': 1},
                {
                  'retain': 1,
                  'attributes': {'height': 50},
                },
              ],
              'columns': [
                {'delete': 1},
                {
                  'retain': 2,
                  'attributes': {'width': 40},
                },
              ],
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'retain': 3},
                {'delete': 1},
                {
                  'retain': 1,
                  'attributes': {'height': 50},
                },
              ],
              'columns': [
                {'retain': 3},
                {'delete': 1},
                {
                  'retain': 2,
                  'attributes': {'width': 40},
                },
              ],
            },
          });
  expectDelta(change1.transform(change2, false), expected);
      });

      test('transform cells', () {
        final change1 = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '22222222'}},
              ],
              'cells': {
                '8:1': {
                  'content': [
                    {'insert': 'Hello 8:1!'},
                  ],
                },
                '21:2': {
                  'content': [
                    {'insert': 'Hello 21:2!'},
                  ],
                },
              },
            },
          });
        final change2 = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'delete': 1},
              ],
              'cells': {
                '6:1': {
                  'content': [
                    {'insert': 'Hello 6:1!'},
                  ],
                },
                '52:8': {
                  'content': [
                    {'insert': 'Hello 52:8!'},
                  ],
                },
              },
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'retain': 1},
                {'delete': 1},
              ],
              'cells': {
                '7:1': {
                  'content': [
                    {'insert': 'Hello 6:1!'},
                  ],
                },
                '53:8': {
                  'content': [
                    {'insert': 'Hello 52:8!'},
                  ],
                },
              },
            },
          });
  expectDelta(change1.transform(change2, false), expected);
      });

      test('transform cell attributes', () {
        final change1 = Delta()
          ..retain(1, {
            'table-embed': {
              'cells': {
                '8:1': {
                  'attributes': {'align': 'right'},
                },
              },
            },
          });
        final change2 = Delta()
          ..retain(1, {
            'table-embed': {
              'cells': {
                '8:1': {
                  'attributes': {'align': 'left'},
                },
              },
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'cells': {
                '8:1': {
                  'attributes': {'align': 'left'},
                },
              },
            },
          });
  expectDelta(change1.transform(change2, false), expected);

        final expectedPriority = Delta()
          ..retain(1, {
            'table-embed': {},
          });
        expectDelta(change1.transform(change2, true), expectedPriority);
      });
    });

    group('invert', () {
      test('reverts rows and columns', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
                {'insert': {'id': '22222222'}},
              ],
              'columns': [
                {'insert': {'id': '33333333'}},
                {
                  'insert': {'id': '44444444'},
                  'attributes': {'width': 100},
                },
              ],
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'delete': 1},
              ],
              'columns': [
                {'retain': 1},
                {'delete': 1},
              ],
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
              ],
              'columns': [
                {'retain': 1},
                {
                  'insert': {'id': '44444444'},
                  'attributes': {'width': 100},
                },
              ],
            },
          });
        expectDelta(change.invert(base), expected);
      });

      test('inverts cell content', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
                {'insert': {'id': '22222222'}},
              ],
              'columns': [
                {'insert': {'id': '33333333'}},
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'Hello 1:2'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'insert': {'id': '55555555'}},
              ],
              'cells': {
                '2:2': {
                  'content': [
                    {'retain': 6},
                    {'insert': '2'},
                    {'delete': 1},
                  ],
                },
              },
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'rows': [
                {'delete': 1},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'retain': 6},
                    {'insert': '1'},
                    {'delete': 1},
                  ],
                },
              },
            },
          });
        expectDelta(change.invert(base), expected);
      });

      test('inverts cells removed by row/column delta', () {
        final base = Delta()
          ..insert({
            'table-embed': {
              'rows': [
                {'insert': {'id': '11111111'}},
                {'insert': {'id': '22222222'}},
              ],
              'columns': [
                {'insert': {'id': '33333333'}},
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'content'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        final change = Delta()
          ..retain(1, {
            'table-embed': {
              'columns': [
                {'retain': 1},
                {'delete': 1},
              ],
            },
          });
        final expected = Delta()
          ..retain(1, {
            'table-embed': {
              'columns': [
                {'retain': 1},
                {'insert': {'id': '44444444'}},
              ],
              'cells': {
                '1:2': {
                  'content': [
                    {'insert': 'content'},
                  ],
                  'attributes': {'align': 'center'},
                },
              },
            },
          });
        expectDelta(change.invert(base), expected);
      });
    });
  });
}
