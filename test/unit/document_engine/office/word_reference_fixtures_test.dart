/// As fixtures que o PRÓPRIO WORD produziu (`tool/word_reference/`).
///
/// A diferença entre estes testes e os que usam XML escrito à mão é a
/// autoridade: um `w:pgBorders` que eu escrevo é o que eu ACHO que o Word
/// grava. Estes arquivos saíram do Word real, com os filhos que ele completa
/// sozinho, a ordem de elementos que ele escolhe e os padrões que ele
/// assume. Cada fixture isola UMA capacidade, então uma falha aqui aponta a
/// feature, não "o corpus quebrou".
///
/// O que cada uma protege, e por que ela existe:
///
/// | fixture | contrato |
/// |---|---|
/// | `page_borders` | a moldura de página do Word chega ao editor |
/// | `sections_landscape` | duas geometrias no mesmo documento |
/// | `header_first_even` | `titlePg` + `evenAndOddHeaders` + 3 variantes |
/// | `columns_two` | `w:cols/@num` lido e preservado |
/// | `tab_stops` | os quatro tipos de parada, com líder |
/// | `line_numbers` | lacuna DECLARADA: preservada, não modelada |
/// | `watermark` | lacuna DECLARADA: preservada, não desenhada |
/// | `multilevel_numbering` | lacuna DECLARADA: níveis lidos, rótulo não |
///
/// As três últimas são tão importantes quanto as primeiras: elas travam o
/// que NÃO fazemos, para que a perda continue sendo preservação e nunca vire
/// perda silenciosa.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  final schema = officeQuillSchema();
  const directory = 'resources/word_reference';

  Uint8List bytesOf(String name) =>
      File('$directory/$name.docx').readAsBytesSync();

  OfficeDocumentSnapshot snapshotOf(String name) =>
      OfficeDocxCodec(schema: schema).import(bytesOf(name)).snapshot;

  String documentXmlOf(Uint8List bytes) {
    final archive = ZipArchive.decodeBytes(bytes);
    return archive.readString('word/document.xml')!;
  }

  /// Reexporta sem tocar em nada — o caminho que prova preservação.
  Uint8List resaved(String name) {
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(bytesOf(name));
    return codec.exportEdited(
      imported.snapshot,
      PMNode.fromJSON(schema, imported.snapshot.body),
    );
  }

  // As fixtures vivem em `resources/`, que o repositório NÃO versiona (é a
  // mesma política do corpus ETP/TR: documentos reais e binários grandes não
  // entram no git). Sem elas, os testes passam vazios em vez de derrubar o
  // clone de quem nunca rodou o harness — e a mensagem diz o que fazer.
  final hasFixtures = File('$directory/page_borders.docx').existsSync();
  setUpAll(() {
    if (!hasFixtures) {
      printOnFailure('fixtures ausentes: rode '
          '`cd tool/word_reference && dart run bin/generate_fixtures.dart` '
          '(Windows com Word)');
    }
  });

  group('o que o editor MODELA', () {
    test('page_borders: a moldura do Word chega ao editor', () {
      if (!hasFixtures) return;
      final setup = OfficeDocxCodec.pageSetupOf(snapshotOf('page_borders'));

      final borders = setup.pageBorders;
      expect(borders, isNotNull, reason: 'sem isto a página abre sem moldura '
          'e o usuário a redesenha por cima da que já existe');
      expect(borders!.top!.style, 'double');
      // O Word gravou `w:sz="18"` (oitavos de ponto) = 2,25 pt = 45 twips.
      expect(borders.top!.widthTwips, 45);
      expect(borders.top!.color, '#C00000');
      expect(setup.pageBorderSpacePt, 24);
      // As QUATRO arestas, não só a de cima.
      expect(borders.right!.isVisible, isTrue);
      expect(borders.bottom!.isVisible, isTrue);
      expect(borders.left!.isVisible, isTrue);
    });

    test('sections_landscape: duas geometrias no mesmo documento', () {
      if (!hasFixtures) return;
      final setups =
          OfficeDocxCodec.pageSetupsOf(snapshotOf('sections_landscape'));

      expect(setups, hasLength(2));
      expect(setups.first.widthTwips, lessThan(setups.first.heightTwips),
          reason: 'a primeira seção é retrato');
      expect(setups.last.widthTwips, greaterThan(setups.last.heightTwips),
          reason: 'a segunda é paisagem — o anexo do processo');
      // Margens próprias: 0,5" = 720 twips.
      expect(setups.last.marginTopTwips, 720);
      expect(setups.first.marginTopTwips, isNot(720));
    });

    test('header_first_even: as três variantes de região', () {
      if (!hasFixtures) return;
      final snapshot = snapshotOf('header_first_even');

      expect(OfficeDocxCodec.titlePageOf(snapshot), isTrue);
      expect(OfficeDocxCodec.evenAndOddHeadersOf(snapshot), isTrue);
      final headers =
          OfficeDocxCodec.regionVariantsOf(snapshot.headers, schema);
      expect(headers.keys, containsAll(['default', 'first', 'even']));
      String textOf(String variant) => headers[variant]!.textContent;
      expect(textOf('first'), contains('PRIMEIRA PÁGINA'));
      expect(textOf('default'), contains('ímpares'));
      expect(textOf('even'), contains('par'));
    });

    test('columns_two: a contagem de colunas do Word', () {
      if (!hasFixtures) return;
      final setup = OfficeDocxCodec.pageSetupOf(snapshotOf('columns_two'));
      expect(setup.columnCount, 2);
      expect(setup.columns, 2);
    });

    test('tab_stops: os quatro tipos, com líder pontilhado', () {
      if (!hasFixtures) return;
      final doc = PMNode.fromJSON(schema, snapshotOf('tab_stops').body);
      Map? style;
      for (var i = 0; i < doc.childCount; i++) {
        final raw = doc.child(i).attrs['style'];
        if (raw is Map && raw['tabs'] is List) style = raw;
      }
      expect(style, isNotNull, reason: 'o parágrafo tem w:tabs no arquivo');
      final tabs = (style!['tabs'] as List).cast<Map>();

      expect(tabs.map((t) => t['val']),
          containsAllInOrder(['left', 'center', 'right', 'decimal']));
      // Posições em TWIPS: o Word grava 90 pt como 1800.
      expect(tabs.first['posTwips'], 1800);
      expect(tabs[1]['leader'], 'dot');
      expect(tabs[2]['leader'], 'dot');
    });
  });

  group('as lacunas DECLARADAS: preservar, nunca perder em silêncio', () {
    test('line_numbers: `w:lnNumType` não é modelado, mas SOBREVIVE', () {
      if (!hasFixtures) return;
      // O editor não desenha numeração de linha (item ❌ da aba Layout do
      // plano). O contrato mínimo é o arquivo continuar tendo a dele.
      expect(documentXmlOf(bytesOf('line_numbers')), contains('w:lnNumType'));

      final saved = documentXmlOf(resaved('line_numbers'));

      expect(saved, contains('w:lnNumType'),
          reason: 'reabrir e salvar não pode apagar o que não sabemos ler');
      expect(saved, contains('w:countBy="5"'));
    });

    test('watermark: a forma do cabeçalho sobrevive ao round-trip', () {
      if (!hasFixtures) return;
      // A marca-d'água do Word é um WordArt no cabeçalho; o editor a cria
      // pela aba Design, mas ainda não LÊ a do arquivo. Ela não pode sumir.
      final imported =
          OfficeDocxCodec(schema: schema).import(bytesOf('watermark'));
      // Em QUALQUER das partes de cabeçalho: o Word põe a forma na variante
      // que corresponde à página, e a primeira do pacote costuma ser a de
      // primeira página, vazia. Procurar só na primeira mediria o acaso.
      final headerParts = [
        for (final part in imported.snapshot.resources.opaqueParts)
          if ('${part['uri']}'.contains('header')) '${part['data']}'
      ];
      expect(headerParts, isNotEmpty);
      expect(headerParts.join(), contains('PowerPlusWaterMarkObject'),
          reason: 'é o nome que o Word dá à forma da marca-d\'água');

      final saved = resaved('watermark');
      final archive = ZipArchive.decodeBytes(saved);
      final headers = [
        for (final name in archive.entryNames)
          if (name.contains('header')) archive.readString(name) ?? ''
      ];
      expect(headers.join(), contains('PowerPlusWaterMarkObject'));
    });

    test('multilevel_numbering: os NÍVEIS são lidos; o rótulo "1.1.1" não', () {
      if (!hasFixtures) return;
      final doc =
          PMNode.fromJSON(schema, snapshotOf('multilevel_numbering').body);
      final headings = [
        for (var i = 0; i < doc.childCount; i++)
          if (doc.child(i).type.name == 'heading') doc.child(i)
      ];

      expect(headings, hasLength(5));
      // O outline level do Word vira o nível do heading.
      expect(headings.map((h) => h.attrs['level']), [1, 2, 3, 2, 1]);
      // E o texto NÃO carrega o número: no DOCX ele é calculado pelo Word a
      // partir de `numbering.xml`, e o compositor mantém UM contador para o
      // documento inteiro (§2.12 do plano) — a lacuna está declarada, e o
      // texto do arquivo continua limpo.
      expect(headings.first.textContent, 'Objeto');
      expect(headings.first.textContent, isNot(contains('1.')));
    });
  });

  group('preservação geral', () {
    test('reabrir e salvar mantém todas as partes de todas as fixtures', () {
      if (!hasFixtures) return;
      for (final name in const [
        'page_borders',
        'sections_landscape',
        'header_first_even',
        'columns_two',
        'tab_stops',
        'line_numbers',
        'multilevel_numbering',
        'watermark',
      ]) {
        final original = ZipArchive.decodeBytes(bytesOf(name));
        final saved = ZipArchive.decodeBytes(resaved(name));
        expect(
          saved.entryNames.toSet(),
          containsAll(original.entryNames.toSet()),
          reason: '$name perdeu partes no round-trip',
        );
      }
    });
  });
}
