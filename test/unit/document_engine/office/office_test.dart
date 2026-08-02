/// Fase 1 do modo avançado — a camada Office sobre o núcleo vendorizado:
/// SHA-256 (hash canônico/assets), IDs estáveis de nó (plugin) e o
/// OfficeDocumentSnapshot (envelope canônico versionado).
import 'dart:convert';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

import '../test_builder_support/test_builder.dart';

void main() {
  group('sha256', () {
    test('vetores conhecidos (FIPS 180-4)', () {
      expect(
          sha256Hex(utf8.encode('abc')),
          'ba7816bf8f01cfea414140de5dae2223'
          'b00361a396177a9cb410ff61f20015ad');
      expect(
          sha256Hex(const []),
          'e3b0c44298fc1c149afbf4c8996fb924'
          '27ae41e4649b934ca495991b7852b855');
      expect(
          sha256Hex(utf8.encode(
              'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
          '248d6a61d20638b8e5c026930c3e6039'
          'a33ce45964ff2167f6ecedd419db06c1');
    });

    test('mensagem maior que um bloco (padding em dois blocos)', () {
      // 56..63 bytes forçam o comprimento a cair no bloco seguinte.
      expect(sha256Hex(utf8.encode('a' * 60)).length, 64);
      expect(sha256Hex(utf8.encode('a' * 1000)),
          sha256Hex(utf8.encode('a' * 1000)),
          reason: 'determinístico');
      expect(sha256Hex(utf8.encode('a' * 1000)),
          isNot(sha256Hex(utf8.encode('a' * 999))));
    });
  });

  group('officeIdsPlugin', () {
    // Schema de teste com um parágrafo que declara o atributo `id`.
    late Schema schema;
    setUp(() {
      schema = Schema(SchemaSpec(
        nodes: {
          'doc': NodeSpec(content: 'block+'),
          'paragraph': NodeSpec(
            content: 'inline*',
            group: 'block',
            attrs: {'id': AttributeSpec(defaultValue: null, hasDefault: true)},
          ),
          'text': NodeSpec(group: 'inline'),
        },
      ));
    });

    EditorState stateWith(String Function() generator) => EditorState.create(
          EditorStateConfig(
            schema: schema,
            plugins: [officeIdsPlugin(generate: generator)],
          ),
        );

    test('parágrafo novo ganha id na transação seguinte', () {
      var counter = 0;
      final state = stateWith(() => 'id-${counter++}');
      final tr = state.tr
        ..insert(
            0,
            schema.node('paragraph', null,
                Fragment.from([schema.text('primeiro')])));
      final next = state.apply(tr);
      final ids = <String>[];
      next.doc.descendants((node, pos, parent, index) {
        final id = officeNodeId(node);
        if (id != null) ids.add(id);
        return true;
      });
      expect(ids, isNotEmpty);
      expect(ids.toSet().length, ids.length, reason: 'todos únicos: $ids');
    });

    test('id duplicado (colar) é re-cunhado na segunda ocorrência', () {
      var counter = 0;
      final state = stateWith(() => 'id-${counter++}');
      final paragraph = schema.node('paragraph', {'id': 'DUP'},
          Fragment.from([schema.text('x')]));
      final tr = state.tr
        ..insert(0, paragraph)
        ..insert(0, paragraph);
      final next = state.apply(tr);
      final ids = <String>[];
      next.doc.descendants((node, pos, parent, index) {
        final id = officeNodeId(node);
        if (id != null) ids.add(id);
        return true;
      });
      expect(ids.length, greaterThanOrEqualTo(2));
      expect(ids.toSet().length, ids.length,
          reason: 'o segundo DUP tem de virar outro id: $ids');
      expect(ids, contains('DUP'),
          reason: 'a PRIMEIRA ocorrência mantém o id original');
    });

    test('transação sem docChanged não gera transação extra', () {
      final state = stateWith(defaultOfficeIdGenerator());
      final before = state.doc;
      final next = state.apply(state.tr);
      expect(identical(next.doc, before), isTrue);
    });
  });

  group('OfficeDocumentSnapshot', () {
    test('round-trip JSON e decodificação do body', () {
      final document = doc(p('Olá mundo'));
      final snapshot = OfficeDocumentSnapshot.fromDocument(
        document,
        documentId: 'doc-1',
        revision: 7,
      );
      final decoded =
          OfficeDocumentSnapshot.fromJson(snapshot.toJson());
      expect(decoded.documentId, 'doc-1');
      expect(decoded.revision, 7);
      final body = decoded.decodeBody(testSchema);
      expect(body.textBetween(0, body.content.size), 'Olá mundo');
    });

    test('hash canônico independe da ordem de inserção das chaves', () {
      final document = doc(p('conteúdo'));
      final a =
          OfficeDocumentSnapshot.fromDocument(document, documentId: 'x');
      // reserializa por um caminho que embaralha a ordem das chaves
      final shuffled = json.decode(json.encode(a.toJson()));
      final b = OfficeDocumentSnapshot.fromJson(
          (shuffled as Map).cast<String, dynamic>());
      expect(b.contentHash(), a.contentHash());
      expect(a.contentHash(), hasLength(64));
    });

    test('conteúdo diferente => hash diferente', () {
      final a = OfficeDocumentSnapshot.fromDocument(doc(p('um')),
          documentId: 'x');
      final b = OfficeDocumentSnapshot.fromDocument(doc(p('dois')),
          documentId: 'x');
      expect(a.contentHash(), isNot(b.contentHash()));
    });

    test('formato desconhecido e versão futura são rejeitados', () {
      final good =
          OfficeDocumentSnapshot.fromDocument(doc(p('x')), documentId: 'x')
              .toJson();
      expect(
          () => OfficeDocumentSnapshot.fromJson(
              {...good, 'format': 'outra-coisa'}),
          throwsA(isA<OfficeSnapshotFormatException>()));
      expect(
          () => OfficeDocumentSnapshot.fromJson(
              {...good, 'formatVersion': 999}),
          throwsA(isA<OfficeSnapshotFormatException>()));
    });

    test('fachada Office*: os alias apontam para o núcleo', () {
      final OfficeNode document = doc(p('via fachada'));
      final OfficeSchema s = testSchema;
      expect(document, isA<PMNode>());
      expect(s, isA<Schema>());
    });
  });
}
