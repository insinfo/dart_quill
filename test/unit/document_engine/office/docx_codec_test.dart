/// Fase 4 — DOCX preservador: importar sem perder e reconstruir sem os bytes.
///
/// O gate desta fase não é "abre o Word": é DOCX → Snapshot → DOCX sem
/// alteração semântica. Um documento tem dezenas de partes que o editor não
/// entende — temas, custom XML, assinaturas, extensões de fabricante — e o
/// usuário nunca autorizou descartá-las só porque abriu o arquivo.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/ce_opc.dart';
import 'package:dart_quill/src/office/ce_xml.dart';
import 'package:dart_quill/src/office/document/docx/reader.dart';
import 'package:dart_quill/src/office/document/docx/validator.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  // UMA instância: officeQuillSchema() devolve um Schema NOVO a cada
  // chamada, e nós de schemas diferentes não se misturam.
  final schema = officeQuillSchema();
  final etpPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(etpPath).existsSync();
  final trFiles = Directory('resources').existsSync()
      ? Directory('resources')
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.toLowerCase().endsWith('.docx') &&
              file.uri.pathSegments.last.startsWith('PGCTIC1_-_TR_-'))
          .toList()
      : <File>[];
  final hasTrCorpus = trFiles.isNotEmpty;
  final productionEtpFiles = Directory('resources').existsSync()
      ? Directory('resources')
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.toLowerCase().endsWith('.docx') &&
              file.uri.pathSegments.last.startsWith('PGCTIC1_-_ETP_-'))
          .toList()
      : <File>[];
  final hasProductionEtpCorpus = productionEtpFiles.isNotEmpty;

  Uint8List corpus() => File(etpPath).readAsBytesSync();
  Uint8List trCorpus() => Uint8List.fromList(trFiles.first.readAsBytesSync());
  Uint8List productionEtpCorpus() =>
      Uint8List.fromList(productionEtpFiles.first.readAsBytesSync());

  bool containsNode(PMNode node, String type) {
    if (node.type.name == type) return true;
    for (var i = 0; i < node.childCount; i++) {
      if (containsNode(node.child(i), type)) return true;
    }
    return false;
  }

  int countNodes(PMNode node, String type) {
    var count = node.type.name == type ? 1 : 0;
    for (var i = 0; i < node.childCount; i++) {
      count += countNodes(node.child(i), type);
    }
    return count;
  }

  Map<String, List<int>> partsOf(Uint8List docx) {
    final archive = ZipArchive.decodeBytes(docx);
    return {for (final e in archive.entries) e.name: e.content};
  }

  int renderedPageBreakCount(Uint8List docx) => RegExp(
        r'<w:lastRenderedPageBreak\b',
      ).allMatches(utf8.decode(partsOf(docx)['word/document.xml']!)).length;

  String visiblePageText(PageLayout page) {
    final out = StringBuffer();
    void addLines(Iterable<LineBox> lines) {
      for (final line in lines) {
        for (final segment in line.segments) {
          out.write(segment.text);
        }
        out.write(' ');
      }
    }

    for (final fragment in page.fragments) {
      switch (fragment) {
        case BlockFragment(:final lines):
          addLines(lines);
        case TableFragment(:final rows):
          for (final row in rows) {
            for (final cell in row.cells) {
              for (final block in cell.blocks) {
                addLines(block.lines);
              }
            }
          }
      }
    }
    return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  PMNode documentWithLetterSpacing(int twips) {
    final spacing = schema.marks['letterSpacing']!.create({'twips': twips});
    return schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node(
              'paragraph',
              null,
              Fragment.from([
                schema.text('Espaçado', [spacing])
              ]))
        ]));
  }

  group('w:rPr/w:spacing', () {
    test('exporta letterSpacing PM como twips assinados', () {
      final bytes = OfficeDocxCodec(schema: schema)
          .exportDocument(documentWithLetterSpacing(-2));
      final xml = utf8.decode(partsOf(bytes)['word/document.xml']!);

      expect(xml, contains('<w:spacing w:val="-2"/>'));
    });

    test('importa spacing negativo como mark letterSpacing em twips', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(documentWithLetterSpacing(-2));
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final text = reopened.child(0).child(0);
      final spacing =
          text.marks.singleWhere((mark) => mark.type.name == 'letterSpacing');

      expect(spacing.attrs['twips'], -2);
    });

    test('zero explícito sobrevive a exportar e reimportar', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(documentWithLetterSpacing(0));
      final xml = utf8.decode(partsOf(bytes)['word/document.xml']!);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final spacing = reopened
          .child(0)
          .child(0)
          .marks
          .singleWhere((mark) => mark.type.name == 'letterSpacing');

      expect(xml, contains('<w:spacing w:val="0"/>'));
      expect(spacing.attrs['twips'], 0);
    });
  });

  group('listas Word editáveis', () {
    test('listas novas geram numbering válido e reimportam kind/numPr', () {
      PMNode item(String kind, String text) => schema.node(
          'listItem', {'kind': kind}, Fragment.from([schema.text(text)]));
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            item('ordered', 'Primeiro'),
            item('ordered', 'Segundo'),
            item('bullet', 'Marcador'),
          ]));
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(doc);
      final parts = partsOf(bytes);
      final documentXml = utf8.decode(parts['word/document.xml']!);
      final numberingXml = utf8.decode(parts['word/numbering.xml']!);
      final relationships = utf8.decode(parts['word/_rels/document.xml.rels']!);
      final contentTypes = utf8.decode(parts['[Content_Types].xml']!);

      expect(DocxValidator.validate(bytes), isEmpty);
      expect(RegExp(r'<w:numPr>').allMatches(documentXml), hasLength(3));
      expect(numberingXml, contains('<w:numFmt w:val="decimal"/>'));
      expect(numberingXml, contains('<w:numFmt w:val="bullet"/>'));
      expect(relationships, contains('/relationships/numbering'));
      expect(contentTypes, contains('/word/numbering.xml'));

      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      expect([
        for (var i = 0; i < reopened.childCount; i++)
          reopened.child(i).type.name
      ], everyElement('listItem'));
      expect(reopened.child(0).attrs['kind'], 'ordered');
      expect(reopened.child(1).attrs['kind'], 'ordered');
      expect(reopened.child(2).attrs['kind'], 'bullet');
      for (var i = 0; i < reopened.childCount; i++) {
        final word = reopened.child(i).attrs['word'] as Map;
        expect((word['numPr'] as Map)['numId'], isNot(0));
      }
    });

    test('trocar bloco importado preserva id/style/pPr e ancora o save', () {
      final sourceDoc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'id': 'source-paragraph',
                  'align': 'right',
                  'style': {
                    'family': 'Calibri',
                    'sizePt': 11.0,
                    'spaceBeforeTwips': 120,
                  },
                  'word': {
                    'styleId': 'Normal',
                    'jc': 'right',
                    'spacing': {
                      'beforeTwips': 120,
                      'afterTwips': 80,
                      'line': 276,
                      'lineRule': 'auto',
                    },
                    'tabs': [
                      {'val': 'right', 'posTwips': 7200, 'leader': 'dot'}
                    ],
                    'keepLines': true,
                  },
                },
                Fragment.from([schema.text('Metadados preservados')]))
          ]));
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = codec.exportDocument(sourceDoc);
      final imported = codec.import(sourceBytes);
      final importedDoc = PMNode.fromJSON(schema, imported.snapshot.body);
      final before = importedDoc.child(0);
      final beforeId = before.attrs['id'];
      final beforeStyle = before.attrs['style'];
      final beforeWord = before.attrs['word'];

      var state = EditorState.create(EditorStateConfig(doc: importedDoc));
      final changed = setBlockType(
        schema.nodes['listItem']!,
        {'kind': 'ordered'},
      )(state, (transaction) => state = state.apply(transaction));
      expect(changed, isTrue);
      final list = state.doc.child(0);
      expect(list.type.name, 'listItem');
      expect(list.attrs['id'], beforeId);
      expect(list.attrs['style'], beforeStyle);
      expect(list.attrs['word'], beforeWord);

      final saved = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        state.doc,
      );
      expect(DocxValidator.validate(saved), isEmpty);
      final reopened = PMNode.fromJSON(schema,
          codec.import(saved, documentId: 'reopened-list').snapshot.body);
      final reopenedList = reopened.child(0);
      final reopenedWord = reopenedList.attrs['word'] as Map;
      final spacing = reopenedWord['spacing'] as Map;
      final tabs = reopenedWord['tabs'] as List;

      expect(reopenedList.type.name, 'listItem');
      expect(reopenedList.attrs['kind'], 'ordered');
      expect(reopenedWord['styleId'], 'Normal');
      expect(reopenedWord['jc'], 'right');
      expect(reopenedWord['keepLines'], isTrue);
      expect(spacing['beforeTwips'], 120);
      expect(spacing['afterTwips'], 80);
      expect(tabs.single, containsPair('posTwips', 7200));
      expect((reopenedWord['numPr'] as Map)['numId'], isNot(0));
      expect(reopened.textContent, 'Metadados preservados');
    });
  });

  group('importação preservadora', () {
    test('importAsync separa reader e conversão sem mudar o resultado',
        () async {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceDoc = schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node(
            'paragraph',
            null,
            Fragment.from([schema.text('importação cooperativa')]),
          ),
        ]),
      );
      final bytes = codec.exportDocument(sourceDoc);
      final synchronous = codec.import(
        bytes,
        includePackageResources: false,
      );
      var timers = 0;
      final asynchronous = await runZoned(
        () => codec.importAsync(bytes, includePackageResources: false),
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            timers++;
            return parent.createTimer(zone, duration, callback);
          },
        ),
      );

      expect(asynchronous.snapshot.body, synchronous.snapshot.body);
      expect(asynchronous.snapshot.sourceMap, synchronous.snapshot.sourceMap);
      expect(timers, greaterThanOrEqualTo(1),
          reason: 'o browser precisa recuperar o event loop entre as fases');
    });

    test(
      'importAsync equivale ao sync nos dois corpus de produção',
      () async {
        // Os arquivos são LOCALIZADOS por prefixo, não por caminho literal:
        // os nomes têm acentos e a forma de normalização Unicode do nome no
        // disco difere entre Windows (NFC) e o checkout do Linux da CI —
        // `File('…Gestão…').existsSync()` devolvia false lá e derrubava só
        // este teste. Os demais deste arquivo já varriam o diretório.
        final files = <File>[...productionEtpFiles, ...trFiles];
        if (files.isEmpty) return;
        for (final file in files) {
          final path = file.path;
          final bytes = file.readAsBytesSync();
          final synchronous = OfficeDocxCodec(schema: schema).import(
            bytes,
            includePackageResources: false,
          );
          final asynchronous = await OfficeDocxCodec(schema: schema)
              .importAsync(bytes, includePackageResources: false);

          expect(
            asynchronous.snapshot.toJson(),
            synchronous.snapshot.toJson(),
            reason: 'snapshot divergente em $path',
          );
          expect(
            [for (final anchor in asynchronous.anchors) anchor.toJson()],
            [for (final anchor in synchronous.anchors) anchor.toJson()],
            reason: 'âncoras divergentes em $path',
          );
          expect(
            [
              for (final issue in asynchronous.report.issues)
                (issue.code, issue.detail),
            ],
            [
              for (final issue in synchronous.report.issues)
                (issue.code, issue.detail),
            ],
            reason: 'relatório divergente em $path',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('cataloga TODAS as entradas do pacote', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final original = partsOf(bytes);
      final imported = OfficeDocxCodec().import(bytes);

      final catalogued = {
        for (final part in imported.snapshot.resources.opaqueParts)
          part['uri'] as String
      };
      expect(catalogued, containsAll(original.keys),
          reason: 'uma parte fora do catálogo é uma parte perdida');
    });

    test('partes binárias são deduplicadas por hash', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final assetIds = [
        for (final a in imported.snapshot.resources.assets) a['id'] as String
      ];
      expect(assetIds.toSet().length, assetIds.length,
          reason: 'o mesmo conteúdo não pode entrar duas vezes');
      for (final id in assetIds) {
        expect(id, startsWith('sha256:'));
      }
    });

    test('modo leve mantém edição e geometria sem duplicar o pacote', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec(schema: schema)
          .import(corpus(), includePackageResources: false);
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      expect(doc.textContent, isNotEmpty);
      expect(imported.anchors, isNotEmpty);
      expect(imported.snapshot.resources.sections, isNotEmpty);
      expect(imported.snapshot.resources.opaqueParts, isEmpty);
      expect(imported.snapshot.resources.assets, isEmpty);
    });

    test('o corpo vira árvore editável com texto real', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      expect(doc.childCount, greaterThan(10));
      final text = doc.textBetween(0, doc.content.size, blockSeparator: ' ');
      expect(text.trim(), isNotEmpty);
    });

    test('tabelas reais entram na árvore editável, com linhas e células', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec(schema: schema).import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      expect(countNodes(doc, 'table'), 3);
      expect(countNodes(doc, 'tableCell'), 82);
      expect(doc.textContent, contains('Severidade'));
    });

    test('cada bloco importado tem âncora para a origem', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      expect(imported.anchors.length, doc.childCount);
      for (final anchor in imported.anchors) {
        expect(anchor.partUri, isNotEmpty);
        expect(anchor.rawHash, isNotEmpty);
      }
    });

    test('o que não sabemos representar entra no relatório', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      // O corpus ainda contém recursos OOXML fora do perfil editável. Eles
      // precisam aparecer no relatório em vez de desaparecer em silêncio.
      expect(imported.report.issues, isNotEmpty,
          reason: 'perda silenciosa é o que este projeto não aceita');
    });
  });

  group('DOCX → Snapshot → DOCX', () {
    test('toda parte volta com o CONTEÚDO idêntico', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final original = partsOf(bytes);
      final codec = OfficeDocxCodec();

      final rebuilt = partsOf(codec.export(codec.import(bytes).snapshot));

      expect(rebuilt.keys.toSet(), original.keys.toSet());
      for (final name in original.keys) {
        expect(rebuilt[name], original[name],
            reason: 'a parte $name mudou de conteúdo no round-trip');
      }
    });

    test('reconstrói SEM os bytes originais, só do JSON', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final json = jsonEncode(codec.import(bytes).snapshot.toJson());

      // A partir daqui o `.docx` original não existe mais para nós.
      final restored = OfficeDocumentSnapshot.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
      final rebuilt = partsOf(codec.export(restored));

      expect(rebuilt.keys.toSet(), partsOf(bytes).keys.toSet());
      expect(rebuilt['word/document.xml'], partsOf(bytes)['word/document.xml']);
    });

    test('o pacote reconstruído reabre no leitor', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final rebuilt = codec.export(codec.import(bytes).snapshot);

      final second = codec.import(rebuilt);
      final firstDoc =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final secondDoc = PMNode.fromJSON(schema, second.snapshot.body);
      expect(secondDoc.childCount, firstDoc.childCount,
          reason: 'reabrir o que geramos tem de dar o mesmo documento');
    });

    test('snapshot → docx → snapshot é ponto fixo nas partes', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final first = codec.import(corpus()).snapshot;
      final second = codec.import(codec.export(first)).snapshot;

      String partsKey(OfficeDocumentSnapshot s) => jsonEncode([
            for (final p in s.resources.opaqueParts)
              {'uri': p['uri'], 'data': p['data'], 'assetId': p['assetId']}
          ]);
      expect(partsKey(second), partsKey(first));
    });
  });

  group('writer patch-based', () {
    PMNode bodyOf(OfficeDocumentSnapshot snapshot) =>
        PMNode.fromJSON(schema, snapshot.body);

    Uint8List syntheticParagraphDocx(String paragraphXml) {
      final codec = OfficeDocxCodec(schema: schema);
      final base = codec.exportDocument(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null,
                Fragment.from([schema.text('FIELD SYNTHETIC PLACEHOLDER')]))
          ])));
      final archive = ZipArchive.decodeBytes(base);
      final xml = archive.readString('word/document.xml')!;
      const placeholder = '<w:p><w:r><w:t>FIELD SYNTHETIC PLACEHOLDER</w:t>'
          '</w:r></w:p>';
      expect(xml, contains(placeholder));
      archive.setFile('word/document.xml',
          utf8.encode(xml.replaceFirst(placeholder, paragraphXml)));
      return archive.encode();
    }

    test('tabs PM regeneram w:tab dentro das mesmas marcas e hyperlink', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bold = schema.marks['bold']!.create();
      final link = schema.marks['link']!
          .create({'href': 'https://example.test/documento'});
      final source = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.text('ANTES\tDEPOIS', [bold, link])
                ]))
          ]));
      final sourceBytes = codec.exportDocument(source);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final original = importedDoc.child(0);
      expect(original.textContent, 'ANTES\tDEPOIS');
      expect(original.child(0).marks.map((mark) => mark.type.name),
          containsAll(<String>['bold', 'link']));

      final edited = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                original.type.name,
                original.attrs,
                Fragment.from(
                    [schema.text('NOVO\tCONTEÚDO', original.child(0).marks)]))
          ]));
      final saved = codec.exportEdited(imported.snapshot, edited);
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(RegExp(r'<w:tab\s*/>').allMatches(xml), hasLength(1));
      expect(xml, isNot(matches(RegExp(r'<w:t\b[^>]*>[^<]*\t[^<]*</w:t>'))));
      expect(xml, contains('<w:b/>'));
      expect(xml, contains('<w:hyperlink'));
      expect(xml.indexOf('<w:hyperlink'), lessThan(xml.indexOf('<w:tab/>')));
      expect(xml.indexOf('<w:tab/>'), lessThan(xml.indexOf('</w:hyperlink>')));
      expect(
          bodyOf(codec.import(saved).snapshot).textContent, 'NOVO\tCONTEÚDO');
    });

    test('page e column breaks mantêm posição inline após editar parágrafo',
        () {
      final codec = OfficeDocxCodec(schema: schema);
      final source = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.text('ANTES'),
                  schema.node('hardBreak', {'breakType': 'page'}, null),
                  schema.text('MEIO'),
                  schema.node('hardBreak', {'breakType': 'column'}, null),
                  schema.text('DEPOIS'),
                ]))
          ]));
      final sourceBytes = codec.exportDocument(source);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final paragraph = importedDoc.child(0);

      expect(paragraph.childCount, 5);
      expect(paragraph.child(1).type.name, 'hardBreak');
      expect(paragraph.child(1).attrs['breakType'], 'page');
      expect(paragraph.child(3).type.name, 'hardBreak');
      expect(paragraph.child(3).attrs['breakType'], 'column');
      final style = paragraph.attrs['style'];
      expect(style is Map ? style['pageBreakBefore'] : null, isNot(true));
      final graph = LayoutComposer().compose(importedDoc);
      expect(graph.pages, hasLength(3));
      expect(visiblePageText(graph.pages.first), contains('ANTES'));
      expect(visiblePageText(graph.pages.first), isNot(contains('MEIO')));
      expect(visiblePageText(graph.pages[1]), contains('MEIO'));
      expect(visiblePageText(graph.pages[1]), isNot(contains('DEPOIS')));
      expect(visiblePageText(graph.pages.last), contains('DEPOIS'));

      final editedParagraph = schema.node(
        paragraph.type.name,
        paragraph.attrs,
        Fragment.from([
          schema.text('ANTES EDITADO', paragraph.child(0).marks),
          for (var i = 1; i < paragraph.childCount; i++) paragraph.child(i),
        ]),
      );
      final saved = codec.exportEdited(
        imported.snapshot,
        schema.node('doc', null, Fragment.from([editedParagraph])),
      );
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);
      final before = xml.indexOf('ANTES EDITADO');
      final page = xml.indexOf('<w:br w:type="page"/>');
      final middle = xml.indexOf('MEIO');
      final column = xml.indexOf('<w:br w:type="column"/>');
      final after = xml.indexOf('DEPOIS');

      expect(DocxValidator.validate(saved), isEmpty);
      expect([before, page, middle, column, after].every((value) => value >= 0),
          isTrue);
      expect(before, lessThan(page));
      expect(page, lessThan(middle));
      expect(middle, lessThan(column));
      expect(column, lessThan(after));
      expect(xml, isNot(contains('<w:pageBreakBefore')));
      final reopened = bodyOf(codec.import(saved).snapshot).child(0);
      expect(reopened.child(1).attrs['breakType'], 'page');
      expect(reopened.child(3).attrs['breakType'], 'column');
    });

    test('PAGE e NUMPAGES preservam cache e resolvem só no layout', () {
      const sourceParagraph = '<w:p>'
          '<w:r><w:t xml:space="preserve">Página </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin" w:dirty="true" '
          'w:fldLock="true"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> PAGE \\* MERGEFORMAT </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>7</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> de </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> NUMPAGES \\* MERGEFORMAT </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>140</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> / seção </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> SECTIONPAGES </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>9</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '</w:p>';
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = syntheticParagraphDocx(sourceParagraph);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final paragraph = importedDoc.child(0);

      expect(paragraph.textContent, 'Página 7 de 140 / seção 9');
      expect(countNodes(paragraph, 'opaqueInline'), 12,
          reason: 'cada campo mantém begin/instr/separate/end como átomos');

      // O mesmo nó projetado como rodapé é resolvido por página sem alterar
      // o documento editável nem congelar o valor cacheado do Word.
      final body = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph', null, Fragment.from([schema.text('PRIMEIRA')])),
            schema.node(
                'paragraph',
                {
                  'style': {'pageBreakBefore': true}
                },
                Fragment.from([schema.text('SEGUNDA')]))
          ]));
      final graph = LayoutComposer(footer: importedDoc).compose(body);
      String footerText(PageLayout page) => [
            for (final block in page.footer)
              for (final line in block.lines)
                for (final segment in line.segments) segment.text
          ].join();
      expect(graph.pages, hasLength(2));
      expect(footerText(graph.pages[0]), contains('Página 1 de 2 / seção 9'));
      expect(footerText(graph.pages[1]), contains('Página 2 de 2 / seção 9'));

      final children = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ];
      children[0] = schema.text('Folha ', paragraph.child(0).marks);
      final edited = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                paragraph.type.name, paragraph.attrs, Fragment.from(children))
          ]));
      final saved = codec.exportEdited(imported.snapshot, edited);
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(RegExp(r'w:fldCharType="begin"').allMatches(xml), hasLength(3));
      expect(RegExp(r'w:fldCharType="separate"').allMatches(xml), hasLength(3));
      expect(RegExp(r'w:fldCharType="end"').allMatches(xml), hasLength(3));
      expect(RegExp(r'<w:instrText\b').allMatches(xml), hasLength(3));
      expect(xml, contains('<w:t>7</w:t>'));
      expect(xml, contains('<w:t>140</w:t>'));
      expect(xml, contains('<w:t>9</w:t>'));
      expect(xml, contains('SECTIONPAGES'));
      expect(xml, isNot(contains('{PAGE}')));
      expect(xml, isNot(contains('{NUMPAGES}')));
      expect(xml, contains('w:dirty="true"'));
      expect(xml, contains('w:fldLock="true"'));
      expect(bodyOf(codec.import(saved).snapshot).textContent,
          'Folha 7 de 140 / seção 9');
    });

    test('PAGEREF, DATE e IF mantêm instrução e resultado ao editar vizinho',
        () {
      const sourceParagraph = '<w:p>'
          '<w:r><w:t xml:space="preserve">ANTES </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> PAGEREF alvo \\h </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>12</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> | </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> DATE \\@ "dd/MM/yyyy" </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>08/08/2026</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> | </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> IF 1 = 1 "SIM" "NÃO" </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>SIM</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> DEPOIS</w:t></w:r>'
          '</w:p>';
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = syntheticParagraphDocx(sourceParagraph);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final paragraph = importedDoc.child(0);

      expect(paragraph.textContent, 'ANTES 12 | 08/08/2026 | SIM DEPOIS');
      expect(paragraph.textContent, isNot(contains('{PAGE}')),
          reason: 'PAGEREF não pode ser classificado por substring como PAGE');
      expect(countNodes(paragraph, 'opaqueInline'), 12);

      final children = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ];
      children[0] = schema.text('VIZINHO EDITADO ', children[0].marks);
      final saved = codec.exportEdited(
        imported.snapshot,
        schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node(
                  paragraph.type.name, paragraph.attrs, Fragment.from(children))
            ])),
      );
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(RegExp(r'w:fldCharType="begin"').allMatches(xml), hasLength(3));
      expect(RegExp(r'w:fldCharType="separate"').allMatches(xml), hasLength(3));
      expect(RegExp(r'w:fldCharType="end"').allMatches(xml), hasLength(3));
      expect(RegExp(r'<w:instrText\b').allMatches(xml), hasLength(3));
      expect(xml, contains('PAGEREF alvo'));
      expect(xml, contains('DATE'));
      expect(xml, contains('IF 1 = 1'));
      expect(xml, contains('<w:t>12</w:t>'));
      expect(xml, contains('<w:t>08/08/2026</w:t>'));
      expect(xml, contains('<w:t>SIM</w:t>'));
      final reopened = bodyOf(codec.import(saved).snapshot).textContent;
      expect(reopened, 'VIZINHO EDITADO 12 | 08/08/2026 | SIM DEPOIS');
    });

    test('campo MERGEFIELD aninhado em IF mantém stack e caches', () {
      const sourceParagraph = '<w:p>'
          '<w:r><w:t xml:space="preserve">NESTED </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> IF 1 = 1 "ok" "não" </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t xml:space="preserve">Olá </w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
          '<w:r><w:instrText xml:space="preserve"> MERGEFIELD Nome \\* MERGEFORMAT </w:instrText></w:r>'
          '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
          '<w:r><w:t>Maria</w:t></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
          '<w:r><w:t xml:space="preserve"> FIM</w:t></w:r>'
          '</w:p>';
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = syntheticParagraphDocx(sourceParagraph);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final paragraph = importedDoc.child(0);

      expect(paragraph.textContent, 'NESTED Olá Maria FIM');
      expect(countNodes(paragraph, 'opaqueInline'), 8);
      final children = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ];
      children[0] = schema.text('STACK EDITADO ', children[0].marks);
      final saved = codec.exportEdited(
        imported.snapshot,
        schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node(
                  paragraph.type.name, paragraph.attrs, Fragment.from(children))
            ])),
      );
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(RegExp(r'w:fldCharType="begin"').allMatches(xml), hasLength(2));
      expect(RegExp(r'w:fldCharType="separate"').allMatches(xml), hasLength(2));
      expect(RegExp(r'w:fldCharType="end"').allMatches(xml), hasLength(2));
      expect(xml, contains('IF 1 = 1'));
      expect(xml, contains('MERGEFIELD Nome'));
      expect(xml, contains('Olá '));
      expect(xml, contains('<w:t>Maria</w:t>'));
      expect(bodyOf(codec.import(saved).snapshot).textContent,
          'STACK EDITADO Olá Maria FIM');
    });

    test('fldSimple vira campo complexo válido sem perder resultado ou run',
        () {
      const sourceParagraph = '<w:p>'
          '<w:r><w:t xml:space="preserve">Data: </w:t></w:r>'
          '<w:fldSimple w:instr=" DATE \\@ &quot;dd MMMM yyyy&quot; " '
          'w:fldLock="1" w:dirty="true">'
          '<w:r><w:rPr><w:i/></w:rPr><w:t>8 agosto 2026</w:t></w:r>'
          '</w:fldSimple>'
          '<w:r><w:t xml:space="preserve"> fim</w:t></w:r>'
          '</w:p>';
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = syntheticParagraphDocx(sourceParagraph);
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final paragraph = importedDoc.child(0);

      expect(paragraph.textContent, 'Data: 8 agosto 2026 fim');
      expect(countNodes(paragraph, 'opaqueInline'), 4);
      final result = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ].singleWhere((node) => node.text == '8 agosto 2026');
      expect(result.marks.map((mark) => mark.type.name), contains('italic'));

      final children = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ];
      children[0] = schema.text('Campo simples: ', children[0].marks);
      final saved = codec.exportEdited(
        imported.snapshot,
        schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node(
                  paragraph.type.name, paragraph.attrs, Fragment.from(children))
            ])),
      );
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(xml, isNot(contains('<w:fldSimple')));
      expect(RegExp(r'w:fldCharType="begin"').allMatches(xml), hasLength(1));
      expect(RegExp(r'w:fldCharType="separate"').allMatches(xml), hasLength(1));
      expect(RegExp(r'w:fldCharType="end"').allMatches(xml), hasLength(1));
      expect(xml, contains('DATE \\@ "dd MMMM yyyy"'));
      expect(xml, contains('w:fldLock="1"'));
      expect(xml, contains('w:dirty="true"'));
      expect(xml, contains('<w:i/>'));
      expect(xml, contains('<w:t>8 agosto 2026</w:t>'));
      expect(bodyOf(codec.import(saved).snapshot).textContent,
          'Campo simples: 8 agosto 2026 fim');
    });

    test('imagem data URI em documento novo gera namespaces, mídia e rel OPC',
        () {
      const pixel =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      final codec = OfficeDocxCodec(schema: schema);
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('image', {
                    'src': 'data:image/png;base64,$pixel',
                    'width': 720,
                    'height': 360,
                  })
                ]))
          ]));
      final saved = codec.exportDocument(doc);
      final file = DocxReader.read(saved);
      final xml = file.package.partString(file.mainPartName)!;
      final root = XmlDocument.parse(xml).rootElement;
      final inline = root.descendantsNamed('wp:inline').single;
      final graphic = root.descendantsNamed('a:graphic').single;
      final picture = root.descendantsNamed('pic:pic').single;
      final blip = root.descendantsNamed('a:blip').single;
      final relId = blip.getAttribute('r:embed');

      expect(DocxValidator.validate(saved), isEmpty);
      expect(inline.resolvePrefix('wp'),
          'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing');
      expect(graphic.resolvePrefix('a'),
          'http://schemas.openxmlformats.org/drawingml/2006/main');
      expect(picture.resolvePrefix('pic'),
          'http://schemas.openxmlformats.org/drawingml/2006/picture');
      expect(blip.resolvePrefix('r'),
          'http://schemas.openxmlformats.org/officeDocument/2006/relationships');
      expect(relId, isNotNull);
      final rel = file.package.relationshipsFor(file.mainPartName).byId(relId!);
      expect(rel, isNotNull);
      expect(rel!.type, endsWith('/image'));
      final media = file.package.resolveTarget(file.mainPartName, rel.target);
      expect(file.package.hasPart(media), isTrue);
      expect(file.package.contentTypeOf(media), 'image/png');
      expect(countNodes(bodyOf(codec.import(saved).snapshot), 'image'), 1);
    });

    test('imagem importada copiada para pacote vazio não deixa embed órfão',
        () {
      const pixel =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      final sourceCodec = OfficeDocxCodec(schema: schema);
      final source = sourceCodec.exportDocument(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('image', {
                    'src': 'data:image/png;base64,$pixel',
                    'width': 480,
                    'height': 480,
                  })
                ]))
          ])));
      final imported = sourceCodec.import(source);
      final copiedImage = bodyOf(imported.snapshot).child(0).child(0);
      expect((copiedImage.attrs['extra'] as Map)['wordDrawing'], isA<String>());

      // exportDocument starts from a fresh minimal package. The raw drawing
      // still mentions the source package's rId, so the codec must bind the
      // data URI again instead of copying that orphan reference verbatim.
      final targetCodec = OfficeDocxCodec(schema: schema);
      final target = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null, Fragment.from([copiedImage]))
          ]));
      final saved = targetCodec.exportDocument(target);
      final file = DocxReader.read(saved);
      final root =
          XmlDocument.parse(file.package.partString(file.mainPartName)!)
              .rootElement;
      final blip = root.descendantsNamed('a:blip').single;
      final relId = blip.getAttribute('r:embed');
      final rel = relId == null
          ? null
          : file.package.relationshipsFor(file.mainPartName).byId(relId);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(rel, isNotNull);
      expect(
          file.package.hasPart(
              file.package.resolveTarget(file.mainPartName, rel!.target)),
          isTrue);
      expect(
          countNodes(bodyOf(targetCodec.import(saved).snapshot), 'image'), 1);
    });

    test('colisão de rId entre DOCX usa os bytes do data URI copiado', () {
      const pixelA =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      const pixelB =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2c9sAAAAASUVORK5CYII=';

      Uint8List oneImageDocx(OfficeDocxCodec codec, String pixel) =>
          codec.exportDocument(schema.node(
              'doc',
              null,
              Fragment.from([
                schema.node(
                    'paragraph',
                    null,
                    Fragment.from([
                      schema.node('image', {
                        'src': 'data:image/png;base64,$pixel',
                        'width': 480,
                        'height': 360,
                      })
                    ]))
              ])));

      String firstEmbed(Uint8List bytes) {
        final file = DocxReader.read(bytes);
        return XmlDocument.parse(file.package.partString(file.mainPartName)!)
            .rootElement
            .descendantsNamed('a:blip')
            .first
            .getAttribute('r:embed')!;
      }

      final sourceCodec = OfficeDocxCodec(schema: schema);
      final targetCodec = OfficeDocxCodec(schema: schema);
      final sourceBytes = oneImageDocx(sourceCodec, pixelB);
      final targetBytes = oneImageDocx(targetCodec, pixelA);
      expect(firstEmbed(sourceBytes), firstEmbed(targetBytes),
          reason: 'o cenário precisa colidir no mesmo nome rId');

      final sourceImage =
          bodyOf(sourceCodec.import(sourceBytes).snapshot).child(0).child(0);
      final targetImport = targetCodec.import(targetBytes);
      final targetParagraph = bodyOf(targetImport.snapshot).child(0);
      final edited = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(targetParagraph.type.name, targetParagraph.attrs,
                Fragment.from([sourceImage]))
          ]));
      final saved = targetCodec.exportEdited(targetImport.snapshot, edited);
      final file = DocxReader.read(saved);
      final root =
          XmlDocument.parse(file.package.partString(file.mainPartName)!)
              .rootElement;
      final savedRelId =
          root.descendantsNamed('a:blip').single.getAttribute('r:embed')!;
      final savedRel =
          file.package.relationshipsFor(file.mainPartName).byId(savedRelId)!;
      final savedMedia = file.package.partBytes(
          file.package.resolveTarget(file.mainPartName, savedRel.target));

      expect(DocxValidator.validate(saved), isEmpty);
      expect(savedMedia, orderedEquals(base64Decode(pixelB)));
      expect(savedMedia, isNot(orderedEquals(base64Decode(pixelA))));
    });

    test('copiar o mesmo drawing gera docPr únicos e deduplica a mídia', () {
      const pixel =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      final sourceCodec = OfficeDocxCodec(schema: schema);
      final sourceBytes = sourceCodec.exportDocument(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('image', {
                    'src': 'data:image/png;base64,$pixel',
                    'width': 400,
                    'height': 300,
                  })
                ]))
          ])));
      final copied =
          bodyOf(sourceCodec.import(sourceBytes).snapshot).child(0).child(0);
      final targetCodec = OfficeDocxCodec(schema: schema);
      final saved = targetCodec.exportDocument(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null, Fragment.from([copied, copied]))
          ])));
      final file = DocxReader.read(saved);
      final root =
          XmlDocument.parse(file.package.partString(file.mainPartName)!)
              .rootElement;
      final ids = [
        for (final value in root.descendantsNamed('wp:docPr'))
          value.getAttribute('id')
      ];
      final blips = root.descendantsNamed('a:blip').toList();
      final mediaParts = file.package.partNames
          .where((name) => name.startsWith('word/media/dq-'))
          .toList();

      expect(DocxValidator.validate(saved), isEmpty);
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      expect(blips, hasLength(2));
      for (final blip in blips) {
        final relId = blip.getAttribute('r:embed')!;
        final rel =
            file.package.relationshipsFor(file.mainPartName).byId(relId)!;
        expect(
            file.package.hasPart(
                file.package.resolveTarget(file.mainPartName, rel.target)),
            isTrue);
      }
      expect(mediaParts, hasLength(1));
    });

    test('resize da imagem real do TR altera ambos extents e preserva XML', () {
      if (!hasTrCorpus) return;
      const widthTwips = 2468;
      const heightTwips = 1357;
      final bytes = trCorpus();
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(bytes);
      final source = bodyOf(imported.snapshot);
      var resized = false;

      PMNode resizeFirstImage(PMNode node) {
        if (!resized && node.type.name == 'image') {
          resized = true;
          return schema.node(
            node.type,
            {
              ...node.attrs,
              'width': widthTwips,
              'height': heightTwips,
            },
            null,
            node.marks,
          );
        }
        if (node.childCount == 0) return node;
        final children = <PMNode>[];
        var changed = false;
        for (var i = 0; i < node.childCount; i++) {
          final child = node.child(i);
          final replacement = resizeFirstImage(child);
          children.add(replacement);
          if (!identical(replacement, child)) changed = true;
        }
        return changed
            ? schema.node(
                node.type, node.attrs, Fragment.from(children), node.marks)
            : node;
      }

      final edited = resizeFirstImage(source);
      expect(resized, isTrue);
      final saved = codec.exportEditedFromDocx(
          bytes, imported.snapshot.sourceMap, edited);
      final file = DocxReader.read(saved);
      final xml = file.package.partString(file.mainPartName)!;
      final root = XmlDocument.parse(xml).rootElement;
      final drawing = root.descendantsNamed('w:drawing').single;
      final wordExtent = drawing.descendantsNamed('wp:extent').first;
      final pictureExtent = drawing
          .descendantsNamed('pic:spPr')
          .single
          .firstChild('a:xfrm')!
          .firstChild('a:ext')!;
      final relId =
          drawing.descendantsNamed('a:blip').single.getAttribute('r:embed')!;
      final rel = file.package.relationshipsFor(file.mainPartName).byId(relId)!;
      final media = file.package
          .partBytes(file.package.resolveTarget(file.mainPartName, rel.target));
      final originalFile = DocxReader.read(bytes);
      final originalRel = originalFile.package
          .relationshipsFor(originalFile.mainPartName)
          .byId('rId11')!;
      final originalMedia = originalFile.package.partBytes(originalFile.package
          .resolveTarget(originalFile.mainPartName, originalRel.target));

      expect(DocxValidator.validate(saved), isEmpty);
      expect(wordExtent.getAttribute('cx'), '${widthTwips * 635}');
      expect(wordExtent.getAttribute('cy'), '${heightTwips * 635}');
      expect(pictureExtent.getAttribute('cx'), '${widthTwips * 635}');
      expect(pictureExtent.getAttribute('cy'), '${heightTwips * 635}');
      expect(media, orderedEquals(originalMedia!));
      for (final preserved in const [
        '<wp:effectExtent l="0" t="0" r="2540" b="8255"/>',
        '<a:srcRect/>',
        '<a:extLst>',
        '<pic:spPr bwMode="auto">',
        '<a:noFill/>',
      ]) {
        expect(xml, contains(preserved));
      }
    });

    test('r:link externo sobrevive ao editar texto adjacente', () {
      final codec = OfficeDocxCodec(schema: schema);
      final base = codec.exportDocument(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph', null, Fragment.from([schema.text('ANTES DEPOIS')]))
          ])));
      final file = DocxReader.read(base);
      final rels = file.package.relationshipsFor(file.mainPartName);
      rels.add(const Relationship(
        id: 'rId77',
        type: RelType.image,
        target: 'https://example.test/imagem.png',
        isExternal: true,
      ));
      file.package.setRelationshipsFor(file.mainPartName, rels);
      final xml = file.package.partString(file.mainPartName)!;
      const original = '<w:p><w:r><w:t>ANTES DEPOIS</w:t></w:r></w:p>';
      const linked = '<w:p>'
          '<w:r><w:t xml:space="preserve">ANTES </w:t></w:r>'
          '<w:r><w:drawing>'
          '<wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
          '<wp:extent cx="63500" cy="63500"/>'
          '<wp:docPr id="37" name="Linked 37"/>'
          '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:nvPicPr><pic:cNvPr id="37" name="Linked 37"/><pic:cNvPicPr/></pic:nvPicPr>'
          '<pic:blipFill><a:blip r:link="rId77"/></pic:blipFill>'
          '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="63500" cy="63500"/></a:xfrm>'
          '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
          '</pic:pic></a:graphicData></a:graphic>'
          '</wp:inline></w:drawing></w:r>'
          '<w:r><w:t>DEPOIS</w:t></w:r>'
          '</w:p>';
      expect(xml, contains(original));
      file.package
          .setPartString(file.mainPartName, xml.replaceFirst(original, linked));
      final sourceBytes = file.package.save();
      final imported = codec.import(sourceBytes);
      final paragraph = bodyOf(imported.snapshot).child(0);
      expect(countNodes(paragraph, 'opaqueInline'), 1);
      final children = [
        for (var i = 0; i < paragraph.childCount; i++) paragraph.child(i)
      ];
      children[0] = schema.text('EDITADO ', children[0].marks);
      final saved = codec.exportEdited(
        imported.snapshot,
        schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node(
                  paragraph.type, paragraph.attrs, Fragment.from(children))
            ])),
      );
      final reopened = DocxReader.read(saved);
      final savedXml = reopened.package.partString(reopened.mainPartName)!;
      final linkedRel = reopened.package
          .relationshipsFor(reopened.mainPartName)
          .byId('rId77');

      expect(DocxValidator.validate(saved), isEmpty);
      expect(savedXml, contains('r:link="rId77"'));
      expect(savedXml, contains('EDITADO'));
      expect(linkedRel, isNotNull);
      expect(linkedRel!.isExternal, isTrue);
      expect(linkedRel.type, RelType.image);
      expect(linkedRel.target, 'https://example.test/imagem.png');
    });

    test('MIME desconhecido falha sem gravar bytes como PNG falso', () {
      final codec = OfficeDocxCodec(schema: schema);
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('image', {
                    'src': 'data:image/avif;base64,AAECAwQ=',
                    'width': 100,
                    'height': 100,
                  })
                ]))
          ]));

      expect(
        () => codec.exportDocument(doc),
        throwsA(isA<UnsupportedError>()
            .having((error) => '$error', 'mensagem', contains('image/avif'))),
      );
    });

    test('parágrafo real do TR mantém tabs como átomos Word ao editar', () {
      if (!hasTrCorpus) return;
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = trCorpus();
      final imported = codec.import(bytes);
      final sourceDoc = bodyOf(imported.snapshot);
      var editedTabParagraph = false;

      PMNode editFirst(PMNode node) {
        if (!editedTabParagraph &&
            const {'paragraph', 'heading', 'listItem'}
                .contains(node.type.name) &&
            node.textContent.contains('\t')) {
          editedTabParagraph = true;
          return schema.node(
            node.type.name,
            node.attrs,
            Fragment.from([
              for (var i = 0; i < node.childCount; i++) node.child(i),
              schema.text(' TAB CORPUS EDITADO'),
            ]),
          );
        }
        if (node.childCount == 0) return node;
        final children = <PMNode>[];
        var changed = false;
        for (var i = 0; i < node.childCount; i++) {
          final child = node.child(i);
          final replacement = editFirst(child);
          children.add(replacement);
          if (!identical(child, replacement)) changed = true;
        }
        return changed
            ? schema.node(
                node.type.name, node.attrs, Fragment.from(children), node.marks)
            : node;
      }

      final edited = editFirst(sourceDoc);
      expect(editedTabParagraph, isTrue,
          reason: 'o TR de produção contém tabs inline reais');
      final saved = codec.exportEdited(
        imported.snapshot,
        edited,
      );
      final xml = utf8.decode(partsOf(saved)['word/document.xml']!);
      final sourceXml = utf8.decode(partsOf(bytes)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(xml, contains('TAB CORPUS EDITADO'));
      expect(RegExp(r'<w:tab\s*/>').allMatches(xml).length,
          RegExp(r'<w:tab\s*/>').allMatches(sourceXml).length);
      expect(xml, isNot(matches(RegExp(r'<w:t\b[^>]*>[^<]*\t[^<]*</w:t>'))));
    });

    test('sem edição, o corpo volta byte a byte', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final imported = codec.import(bytes);

      final rebuilt =
          codec.exportEdited(imported.snapshot, bodyOf(imported.snapshot));
      final before = partsOf(bytes)['word/document.xml']!;
      final after = partsOf(rebuilt)['word/document.xml']!;
      expect(after, before,
          reason: 'não tocar em nada não pode reescrever o documento');
    });

    test('fast path sobre bytes originais preserva pacote e edição', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(bytes);
      final doc = bodyOf(imported.snapshot);
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      final first = blocks.first;
      blocks[0] = schema.node(
        first.type.name,
        first.attrs,
        Fragment.from([schema.text('FAST PATH EDITADO')]),
      );

      final saved = codec.exportEditedFromDocx(
        bytes,
        imported.snapshot.sourceMap,
        schema.node('doc', null, Fragment.from(blocks)),
      );
      final reopened = codec.import(saved);
      expect(
          bodyOf(reopened.snapshot).textContent, contains('FAST PATH EDITADO'));
      expect(partsOf(saved).keys.toSet(), partsOf(bytes).keys.toSet(),
          reason: 'salvar direto no pacote não pode perder partes OPC');
    });

    test('editar UM parágrafo não reescreve os outros', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final imported = codec.import(bytes);
      final doc = bodyOf(imported.snapshot);

      // Troca o texto do primeiro bloco; todos os demais ficam idênticos.
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node(blocks[0].type.name, blocks[0].attrs,
          Fragment.from([schema.text('TEXTO EDITADO')]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final xml = utf8.decode(partsOf(
          codec.exportEdited(imported.snapshot, edited))['word/document.xml']!);

      expect(xml, contains('TEXTO EDITADO'));
      // Um parágrafo mais adiante tem de continuar com o XML de origem.
      final untouched = doc.child(doc.childCount - 1).textContent;
      if (untouched.trim().isNotEmpty) {
        expect(xml, contains(untouched.trim().split(' ').first));
      }
    });

    test('a edição sobrevive a reabrir o arquivo', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node('paragraph', null,
          Fragment.from([schema.text('MARCADOR UNICO 12345')]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final reopened =
          codec.import(codec.exportEdited(imported.snapshot, edited));
      final text = bodyOf(reopened.snapshot).textBetween(
          0, bodyOf(reopened.snapshot).content.size,
          blockSeparator: ' ');
      expect(text, contains('MARCADOR UNICO 12345'));
    });

    test('aplicar negrito conta como edição (assinatura vê as marcas)', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);

      final first = doc.child(0);
      if (first.childCount == 0) return;
      final bold = schema.marks['bold']!.create();
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node(
          first.type.name,
          first.attrs,
          Fragment.from([
            schema.text(first.textContent, [bold])
          ]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final before = OfficeDocxCodec.nodeSignature(first);
      final after = OfficeDocxCodec.nodeSignature(blocks[0]);
      expect(after, isNot(before),
          reason: 'formatação sem mudar texto ainda é edição');

      final xml = utf8.decode(partsOf(
          codec.exportEdited(imported.snapshot, edited))['word/document.xml']!);
      expect(xml, contains('<w:b/>'));
    });

    test('parágrafo editado preserva ids/rsids, autoSpaceDN e rPr seguro', () {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceDoc = schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node(
            'paragraph',
            null,
            Fragment.from([schema.text('TEXTO ORIGINAL DESCARTAR')]),
          ),
        ]),
      );
      final archive = ZipArchive.decodeBytes(codec.exportDocument(sourceDoc));
      var documentXml = archive.readString('word/document.xml')!;
      const relationshipNamespace =
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
      const w14Namespace =
          'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"';
      expect(documentXml, contains(relationshipNamespace));
      documentXml = documentXml.replaceFirst(
        relationshipNamespace,
        '$relationshipNamespace $w14Namespace',
      );
      const plain = '<w:p><w:r><w:t>TEXTO ORIGINAL DESCARTAR</w:t></w:r></w:p>';
      const decorated = '<w:p w14:paraId="351FC4C1" '
          'w14:textId="77777777" w:rsidRPr="00E85692" '
          'w:rsidR="00284487" w:rsidDel="00112233" '
          'w:rsidP="000A02D0" w:rsidRDefault="00284487">'
          '<w:pPr><w:autoSpaceDN/></w:pPr>'
          '<w:r><w:rPr><w:rFonts w:eastAsia="Times New Roman"/>'
          '<w:bCs/></w:rPr><w:t>TEXTO ORIGINAL DESCARTAR</w:t></w:r>'
          '</w:p>';
      expect(documentXml, contains(plain));
      archive.setFile(
        'word/document.xml',
        utf8.encode(documentXml.replaceFirst(plain, decorated)),
      );
      final sourceBytes = archive.encode();
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final original = importedDoc.child(0);
      final bold = schema.marks['bold']!.create();

      // Recria texto e marcas sem copiar o opaqueAttrs importado. Assim o
      // teste prova o fallback tipado do parágrafo/run de origem — e não um
      // reaproveitamento acidental do XML/texto antigo.
      final editedParagraph = schema.node(
        original.type.name,
        original.attrs,
        Fragment.from([
          schema.text('CONTEÚDO NOVO COM NEGRITO', [bold])
        ]),
      );
      final editedDoc = schema.node(
        'doc',
        null,
        Fragment.from([editedParagraph]),
      );
      // Exercita o caminho persistido Snapshot -> DOCX. O teste de corpus
      // abaixo cobre em paralelo o fast path assíncrono sobre os bytes fonte.
      final saved = codec.exportEdited(imported.snapshot, editedDoc);
      final savedXml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(savedXml, contains('<w:p w14:paraId="351FC4C1"'));
      expect(savedXml, contains('w14:textId="77777777"'));
      for (final attribute in const {
        'w:rsidRPr': '00E85692',
        'w:rsidR': '00284487',
        'w:rsidDel': '00112233',
        'w:rsidP': '000A02D0',
        'w:rsidRDefault': '00284487',
      }.entries) {
        expect(savedXml, contains('${attribute.key}="${attribute.value}"'));
      }
      expect(savedXml, contains('<w:autoSpaceDN/>'));
      expect(savedXml, contains('w:eastAsia="Times New Roman"'));
      expect(savedXml, contains('<w:bCs/>'));
      expect(savedXml, contains('<w:b/>'));
      expect(savedXml, contains('CONTEÚDO NOVO COM NEGRITO'));
      expect(savedXml, isNot(contains('TEXTO ORIGINAL DESCARTAR')));

      final reopened = bodyOf(codec.import(saved).snapshot);
      expect(reopened.textContent, 'CONTEÚDO NOVO COM NEGRITO');
      final reopenedWord = reopened.child(0).attrs['word'] as Map;
      expect(reopenedWord['autoSpaceDN'], isTrue);
      expect(
          (reopenedWord['paragraphAttributes'] as Map)['paraId'], '351FC4C1');
      final opaque = reopened.child(0).child(0).marks.singleWhere(
            (mark) => mark.type.name == 'opaqueAttrs',
          );
      expect((opaque.attrs['attrs'] as Map)['wordFontEastAsia'],
          'Times New Roman');
      expect((opaque.attrs['attrs'] as Map)['wordBoldCs'], isTrue);
    });

    test('blocos opacos (tabelas) não somem ao salvar editado', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);

      final xml = utf8.decode(partsOf(
          codec.exportEdited(imported.snapshot, doc))['word/document.xml']!);
      final originalXml = utf8.decode(partsOf(corpus())['word/document.xml']!);
      expect('<w:tbl'.allMatches(xml).length,
          '<w:tbl'.allMatches(originalXml).length,
          reason: 'tabela preservada opaca não pode desaparecer no save');
    });

    test('editar uma célula de tabela sobrevive a salvar e reabrir', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      final tableIndex = blocks.indexWhere((node) => node.type.name == 'table');
      expect(tableIndex, isNonNegative);

      final table = blocks[tableIndex];
      final rows = [for (var i = 0; i < table.childCount; i++) table.child(i)];
      final firstRow = rows.first;
      final cells = [
        for (var i = 0; i < firstRow.childCount; i++) firstRow.child(i)
      ];
      final firstCell = cells.first;
      final cellBlocks = [
        for (var i = 0; i < firstCell.childCount; i++) firstCell.child(i)
      ];
      final originalParagraph = cellBlocks.first;
      cellBlocks[0] = schema.node(
        originalParagraph.type.name,
        originalParagraph.attrs,
        Fragment.from([schema.text('CELULA EDITADA 98765')]),
      );
      cells[0] =
          schema.node('tableCell', firstCell.attrs, Fragment.from(cellBlocks));
      rows[0] = schema.node('tableRow', firstRow.attrs, Fragment.from(cells));
      blocks[tableIndex] =
          schema.node('table', table.attrs, Fragment.from(rows));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final reopened =
          codec.import(codec.exportEdited(imported.snapshot, edited));
      final reopenedDoc = bodyOf(reopened.snapshot);
      expect(reopenedDoc.textContent, contains('CELULA EDITADA 98765'));
      expect(countNodes(reopenedDoc, 'table'), 3);
    });

    test('editar primeiro parágrafo preserva XML do segundo na célula', () {
      final first = schema.node(
          'paragraph', null, Fragment.from([schema.text('PRIMEIRO EDITÁVEL')]));
      final second = schema.node(
          'paragraph', null, Fragment.from([schema.text('SEGUNDO INTACTO')]));
      final cell =
          schema.node('tableCell', null, Fragment.from([first, second]));
      final row = schema.node('tableRow', null, Fragment.from([cell]));
      final table = schema.node('table', null, Fragment.from([row]));
      final sourceDoc = schema.node('doc', null, Fragment.from([table]));
      final codec = OfficeDocxCodec(schema: schema);

      // Injeta propriedades que o modelo editável deliberadamente não
      // representa. Elas tornam observável se o segundo parágrafo foi
      // reserializado por engano junto com o primeiro.
      final archive = ZipArchive.decodeBytes(codec.exportDocument(sourceDoc));
      final documentXml = archive.readString('word/document.xml')!;
      const plainSecond = '<w:p><w:r><w:t>SEGUNDO INTACTO</w:t></w:r></w:p>';
      const preservedSecond = '<w:p w:rsidR="00ABCDEF">'
          '<w:pPr><w:autoSpaceDN/></w:pPr>'
          '<w:r><w:t>SEGUNDO INTACTO</w:t></w:r></w:p>';
      expect(documentXml, contains(plainSecond));
      archive.setFile(
        'word/document.xml',
        utf8.encode(documentXml.replaceFirst(plainSecond, preservedSecond)),
      );
      final sourceBytes = archive.encode();
      final imported = codec.import(sourceBytes);
      final doc = bodyOf(imported.snapshot);
      final importedTable = doc.child(0);
      final importedRow = importedTable.child(0);
      final importedCell = importedRow.child(0);
      final cellBlocks = [
        for (var i = 0; i < importedCell.childCount; i++) importedCell.child(i)
      ];
      final originalFirst = cellBlocks.first;
      cellBlocks[0] = schema.node(
        originalFirst.type.name,
        originalFirst.attrs,
        Fragment.from([schema.text('PRIMEIRO ALTERADO')]),
      );
      final editedCell = schema.node(
          'tableCell', importedCell.attrs, Fragment.from(cellBlocks));
      final editedRow = schema.node(
          'tableRow', importedRow.attrs, Fragment.from([editedCell]));
      final editedTable =
          schema.node('table', importedTable.attrs, Fragment.from([editedRow]));
      final edited = schema.node('doc', null, Fragment.from([editedTable]));

      final saved = codec.exportEdited(imported.snapshot, edited);
      final savedXml = utf8.decode(partsOf(saved)['word/document.xml']!);
      expect(savedXml, contains('PRIMEIRO ALTERADO'));
      expect(savedXml, contains(preservedSecond),
          reason: 'bloco intacto da célula deve voltar com o XML de origem');
      final reopened = bodyOf(codec.import(saved).snapshot);
      expect(
          reopened.textContent, contains('PRIMEIRO ALTERADOSEGUNDO INTACTO'));
    });

    test('w:shd fill auto não vira fundo preto nem cor CSS inválida', () {
      final paragraph = schema.node(
          'paragraph', null, Fragment.from([schema.text('CÉLULA CLARA')]));
      final cell = schema.node('tableCell', null, Fragment.from([paragraph]));
      final row = schema.node('tableRow', null, Fragment.from([cell]));
      final table = schema.node('table', null, Fragment.from([row]));
      final sourceDoc = schema.node('doc', null, Fragment.from([table]));
      final codec = OfficeDocxCodec(schema: schema);
      final archive = ZipArchive.decodeBytes(codec.exportDocument(sourceDoc));
      final documentXml = archive.readString('word/document.xml')!;
      archive.setFile(
        'word/document.xml',
        utf8.encode(documentXml.replaceFirst(
          '<w:tcPr>',
          '<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="auto"/>',
        )),
      );

      final reopened = PMNode.fromJSON(
        schema,
        codec.import(archive.encode()).snapshot.body,
      );
      final reopenedCell = reopened.child(0).child(0).child(0);
      final presentation = reopenedCell.attrs['cell'];

      expect(presentation,
          anyOf(isNull, isNot(containsPair('background', '#auto'))));
      if (presentation is Map) {
        expect(presentation['background'], isNull);
      }
    });

    test(
        'editar célula preserva ordem, ranges e propriedades da tabela sem ressuscitar texto',
        () {
      final paragraph = schema.node('paragraph', null,
          Fragment.from([schema.text('TEXTO ORIGINAL DESCARTAR')]));
      final cell = schema.node('tableCell', null, Fragment.from([paragraph]));
      final row = schema.node('tableRow', null, Fragment.from([cell]));
      final table = schema.node(
          'table',
          {
            'colWidths': [2400]
          },
          Fragment.from([row]));
      final sourceDoc = schema.node('doc', null, Fragment.from([table]));
      final codec = OfficeDocxCodec(schema: schema);

      final archive = ZipArchive.decodeBytes(codec.exportDocument(sourceDoc));
      var documentXml = archive.readString('word/document.xml')!;
      expect(documentXml, contains('<w:tblPr></w:tblPr>'));
      documentXml = documentXml
          .replaceFirst(
            '<w:tblPr></w:tblPr>',
            '<w:tblPr><w:tblLook w:val="04A0" w:firstRow="1"/>'
                '</w:tblPr>',
          )
          .replaceFirst(
            '<w:tr>',
            '<w:tr><w:trPr><w:jc w:val="center"/></w:trPr>',
          )
          .replaceFirst(
            '<w:tc>',
            '<w:tc><w:tcPr><w:noWrap/><w:hideMark/></w:tcPr>',
          )
          .replaceFirst(
            '<w:p>',
            '<w:p><w:bookmarkStart w:id="77" w:name="table_scope"/>',
          )
          .replaceFirst(
            '</w:tr></w:tbl>',
            '</w:tr><w:bookmarkEnd w:id="77"/></w:tbl>',
          );
      archive.setFile('word/document.xml', utf8.encode(documentXml));
      final sourceBytes = archive.encode();
      final imported = codec.import(sourceBytes);
      final importedDoc = bodyOf(imported.snapshot);
      final importedTable = importedDoc.child(0);
      final importedRow = importedTable.child(0);
      final importedCell = importedRow.child(0);
      final importedParagraph = importedCell.child(0);
      final editedInline = <PMNode>[
        for (final child in importedParagraph.children)
          child.isText
              ? schema.text('TEXTO EDITADO 24680', child.marks)
              : child,
      ];
      final editedParagraph = schema.node(
        importedParagraph.type.name,
        importedParagraph.attrs,
        Fragment.from(editedInline),
      );
      final editedCell = schema.node(
          'tableCell', importedCell.attrs, Fragment.from([editedParagraph]));
      final editedRow = schema.node(
          'tableRow', importedRow.attrs, Fragment.from([editedCell]));
      final editedTable =
          schema.node('table', importedTable.attrs, Fragment.from([editedRow]));
      final editedDoc = schema.node('doc', null, Fragment.from([editedTable]));

      final saved = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        editedDoc,
      );
      final savedXml = utf8.decode(partsOf(saved)['word/document.xml']!);

      expect(DocxValidator.validate(saved), isEmpty);
      expect(savedXml, contains('TEXTO EDITADO 24680'));
      expect(savedXml, isNot(contains('TEXTO ORIGINAL DESCARTAR')));
      expect(savedXml, contains('<w:tblLook w:val="04A0" w:firstRow="1"/>'));
      expect(savedXml, contains('<w:jc w:val="center"/>'));
      expect(savedXml, contains('<w:noWrap/>'));
      expect(savedXml, contains('<w:hideMark/>'));
      expect(RegExp(r'<w:bookmarkStart\b').allMatches(savedXml), hasLength(1));
      expect(RegExp(r'<w:bookmarkEnd\b').allMatches(savedXml), hasLength(1));
      expect(savedXml, contains('<w:bookmarkEnd w:id="77"/>'));

      final rowEnd = savedXml.indexOf('</w:tr>');
      final bookmarkEnd = savedXml.indexOf('<w:bookmarkEnd w:id="77"/>');
      final tableEnd = savedXml.indexOf('</w:tbl>');
      expect(rowEnd, isNonNegative);
      expect(bookmarkEnd, greaterThan(rowEnd));
      expect(tableEnd, greaterThan(bookmarkEnd));

      final reopened = bodyOf(codec.import(saved).snapshot);
      expect(reopened.textContent, 'TEXTO EDITADO 24680');
      final reopenedTable = reopened.child(0);
      final reopenedRow = reopenedTable.child(0);
      final reopenedCell = reopenedRow.child(0);
      expect((reopenedTable.attrs['word'] as Map)['tableLookXml'],
          contains('w:tblLook'));
      expect((reopenedRow.attrs['word'] as Map)['jc'], 'center');
      expect((reopenedCell.attrs['word'] as Map)['noWrap'], isTrue);
      expect((reopenedCell.attrs['word'] as Map)['hideMark'], isTrue);
    });

    test('TR mantém topologia e texto após edição combinada', () async {
      if (!hasTrCorpus) return;
      final sourceBytes = trCorpus();
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(
        sourceBytes,
        includePackageResources: false,
      );
      final doc = bodyOf(imported.snapshot);
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];

      final paragraphIndex = blocks.indexWhere((node) => node.isTextblock);
      final paragraph = blocks[paragraphIndex];
      blocks[paragraphIndex] = schema.node(
        paragraph.type.name,
        paragraph.attrs,
        Fragment.from([...paragraph.children, schema.text(' [TR_BODY_EDIT]')]),
      );

      var tableIndex = -1;
      var largestRows = -1;
      for (var i = 0; i < blocks.length; i++) {
        final candidate = blocks[i];
        if (candidate.type.name == 'table' &&
            candidate.childCount > largestRows) {
          tableIndex = i;
          largestRows = candidate.childCount;
        }
      }
      expect(largestRows, 1367);
      final table = blocks[tableIndex];
      final rows = [for (var i = 0; i < table.childCount; i++) table.child(i)];
      final row = rows.first;
      final cells = [for (var i = 0; i < row.childCount; i++) row.child(i)];
      final cell = cells.first;
      final cellBlocks = [
        for (var i = 0; i < cell.childCount; i++) cell.child(i)
      ];
      final cellParagraph = cellBlocks.first;
      cellBlocks[0] = schema.node(
        cellParagraph.type.name,
        cellParagraph.attrs,
        Fragment.from(
            [...cellParagraph.children, schema.text(' [TR_TABLE_EDIT]')]),
      );
      cells[0] =
          schema.node('tableCell', cell.attrs, Fragment.from(cellBlocks));
      rows[0] = schema.node('tableRow', row.attrs, Fragment.from(cells));
      blocks[tableIndex] =
          schema.node('table', table.attrs, Fragment.from(rows));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final saved = await codec.exportEditedFromDocxAsync(
        sourceBytes,
        imported.snapshot.sourceMap,
        edited,
      );
      final reopened =
          bodyOf(codec.import(saved, includePackageResources: false).snapshot);
      String linearText(PMNode node) {
        final buffer = StringBuffer();
        void append(PMNode value) {
          final text = value.text;
          if (text != null) buffer.write(text);
          for (var i = 0; i < value.childCount; i++) {
            append(value.child(i));
          }
        }

        append(node);
        return buffer.toString();
      }

      final reopenedText = linearText(reopened);
      expect(reopenedText, linearText(edited));
      expect(reopenedText, contains('[TR_BODY_EDIT]'));
      expect(reopenedText, contains('[TR_TABLE_EDIT]'));

      Map<String, int> topology(Uint8List bytes) {
        final parts = partsOf(bytes);
        final xml = utf8.decode(parts['word/document.xml']!);
        int tags(String name) =>
            RegExp('<$name(?:\\s|>)').allMatches(xml).length;
        int nestedTags(String wrapper, String name) {
          var count = 0;
          for (final match in RegExp(
            '<$wrapper\\b[^>]*>(.*?)</$wrapper>',
            dotAll: true,
          ).allMatches(xml)) {
            count +=
                RegExp('<$name(?:\\s|>)').allMatches(match.group(1)!).length;
          }
          return count;
        }

        var relationships = 0;
        for (final entry in parts.entries) {
          if (entry.key.endsWith('.rels')) {
            relationships += RegExp(r'<Relationship(?:\s|>)')
                .allMatches(utf8.decode(entry.value))
                .length;
          }
        }
        return {
          'parts': parts.length,
          'tables': tags('w:tbl'),
          'rows': tags('w:tr'),
          'cells': tags('w:tc'),
          'bookmarkStarts': tags('w:bookmarkStart'),
          'bookmarkEnds': tags('w:bookmarkEnd'),
          'tableLooks': tags('w:tblLook'),
          'rowJustifications': nestedTags('w:trPr', 'w:jc'),
          'cellHideMarks': nestedTags('w:tcPr', 'w:hideMark'),
          'cellNoWrap': nestedTags('w:tcPr', 'w:noWrap'),
          'hyperlinks': tags('w:hyperlink'),
          'sections': tags('w:sectPr'),
          'images':
              parts.keys.where((name) => name.startsWith('word/media/')).length,
          'headers': parts.keys
              .where((name) => RegExp(r'^word/header\d+\.xml$').hasMatch(name))
              .length,
          'footers': parts.keys
              .where((name) => RegExp(r'^word/footer\d+\.xml$').hasMatch(name))
              .length,
          'relationships': relationships,
        };
      }

      List<String> bookmarkIds(Uint8List bytes, String tag) {
        final xml = utf8.decode(partsOf(bytes)['word/document.xml']!);
        return [
          for (final match in RegExp(
            '<w:$tag\\b[^>]*\\bw:id="([^"]+)"',
          ).allMatches(xml))
            match.group(1)!,
        ];
      }

      expect(topology(saved), topology(sourceBytes));
      expect(bookmarkIds(saved, 'bookmarkStart'),
          bookmarkIds(sourceBytes, 'bookmarkStart'));
      expect(bookmarkIds(saved, 'bookmarkEnd'),
          bookmarkIds(sourceBytes, 'bookmarkEnd'));
    });

    test('documento novo exporta tabelas, não apenas textblocks', () {
      final paragraph =
          schema.node('paragraph', null, Fragment.from([schema.text('dado')]));
      final cell = schema.node(
          'tableCell',
          {
            'word': {
              'margins': {
                'top': {'value': 0, 'type': 'dxa'},
                'left': {'value': 90, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'right': {'value': 90, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([paragraph]));
      final row = schema.node('tableRow', null, Fragment.from([cell]));
      final table = schema.node(
          'table',
          {
            'colWidths': [2400],
            'word': {
              'cellMargins': {
                'left': {'value': 70, 'type': 'dxa'},
                'right': {'value': 70, 'type': 'dxa'},
              }
            },
          },
          Fragment.from([row]));
      final doc = schema.node('doc', null, Fragment.from([table]));

      final codec = OfficeDocxCodec(schema: schema);
      final reopened = PMNode.fromJSON(
          schema, codec.import(codec.exportDocument(doc)).snapshot.body);
      expect(countNodes(reopened, 'table'), 1);
      expect(reopened.textContent, contains('dado'));
      final reopenedTable = reopened.child(0);
      final tableWord = reopenedTable.attrs['word'] as Map;
      final tableMargins = tableWord['cellMargins'] as Map;
      expect((tableMargins['left'] as Map)['value'], 70);
      final cellWord = reopenedTable.child(0).child(0).attrs['word'] as Map;
      final cellMargins = cellWord['margins'] as Map;
      expect((cellMargins['left'] as Map)['value'], 90);
    });
  });

  group('cache de paginação Word', () {
    test('preserva sem edição e invalida em texto ou pageSetup sync/async',
        () async {
      final marker = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:lastRenderedPageBreak',
          'officeXml': '<w:lastRenderedPageBreak/>',
          'runContent': true,
        }
      });
      final sourceDoc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph', null, Fragment.from([schema.text('primeiro')])),
            schema.node('paragraph', null,
                Fragment.from([marker, schema.text('segundo')])),
          ]));
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = codec.exportDocument(sourceDoc);
      expect(renderedPageBreakCount(sourceBytes), 1);

      final imported = codec.import(sourceBytes);
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final untouched = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        doc,
      );
      expect(renderedPageBreakCount(untouched), 1,
          reason: 'abrir e salvar sem editar mantém o cache do Word');

      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      final first = blocks.first;
      blocks[0] = schema.node(
        first.type.name,
        first.attrs,
        Fragment.from([schema.text('primeiro editado')]),
      );
      final edited = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        schema.node('doc', null, Fragment.from(blocks)),
      );
      expect(renderedPageBreakCount(edited), 0,
          reason: 'edição em outro bloco também torna o cache global obsoleto');

      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final layoutOnlySync = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        doc,
        pageSetup: setup,
      );
      expect(renderedPageBreakCount(layoutOnlySync), 0,
          reason: 'margens/papel invalidam os cortes mesmo sem mudar o texto');

      final layoutOnlyAsync = await codec.exportEditedFromDocxAsync(
        sourceBytes,
        imported.snapshot.sourceMap,
        doc,
        pageSetup: setup,
      );
      expect(renderedPageBreakCount(layoutOnlyAsync), 0,
          reason: 'o caminho cooperativo deve ter a mesma semântica');
    });

    test('pPr/rPr direto governa a altura de parágrafos vazios', () {
      final corpora = <Uint8List>[
        if (hasTrCorpus) trCorpus(),
        if (hasProductionEtpCorpus) productionEtpCorpus(),
      ];
      if (corpora.isEmpty) return;
      for (final bytes in corpora) {
        final snapshot = OfficeDocxCodec(schema: schema).import(bytes).snapshot;
        final document = PMNode.fromJSON(schema, snapshot.body);
        var markedEmpty = 0;
        var correctlyProjected = 0;
        void visit(PMNode node) {
          if (node.isTextblock && node.textContent.isEmpty) {
            final word = node.attrs['word'];
            final mark = word is Map ? word['markRunProperties'] : null;
            final halfPoints =
                mark is Map ? mark['sizeHalfPoints'] as num? : null;
            if (halfPoints != null) {
              markedEmpty++;
              final style = node.attrs['style'];
              final size = style is Map ? style['sizePt'] as num? : null;
              if (size == halfPoints / 2) correctlyProjected++;
            }
          }
          for (var index = 0; index < node.childCount; index++) {
            visit(node.child(index));
          }
        }

        visit(document);
        expect(markedEmpty, greaterThan(0));
        expect(correctlyProjected, markedEmpty,
            reason: 'a marca direta do pilcrow define a caixa vazia');
      }
    });

    test('pPr/rPr direto continua valendo sem styles.xml', () {
      final codec = OfficeDocxCodec(schema: schema);
      final base = codec.exportDocument(schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null,
              Fragment.from([schema.text('SEM ESTILOS PLACEHOLDER')]))
        ]),
      ));
      final archive = ZipArchive.decodeBytes(base);
      final xml = archive.readString('word/document.xml')!;
      const plain = '<w:p><w:r><w:t>SEM ESTILOS PLACEHOLDER</w:t>'
          '</w:r></w:p>';
      const direct = '<w:p><w:pPr>'
          '<w:spacing w:before="120" w:after="40"/>'
          '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/>'
          '<w:b/><w:sz w:val="10"/></w:rPr>'
          '</w:pPr></w:p>';
      expect(xml, contains(plain));
      archive.setFile(
        'word/document.xml',
        utf8.encode(xml.replaceFirst(plain, direct)),
      );
      expect(archive.removeFile('word/styles.xml'), isTrue);

      final imported = codec.import(archive.encode()).snapshot;
      final paragraph = PMNode.fromJSON(schema, imported.body).child(0);
      final style = paragraph.attrs['style'] as Map;

      expect(paragraph.textContent, isEmpty);
      expect(style['sizePt'], 5.0);
      expect(style['family'], 'Arial');
      expect(style['bold'], isTrue);
      expect(style['spaceBeforeTwips'], 120);
      expect(style['spaceAfterTwips'], 40);
    });

    test('TR mantém 140 páginas, anexos e tabela em cache e paginação natural',
        () {
      if (!hasTrCorpus) return;
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(trCorpus());
      final snapshot = imported.snapshot;
      final document = PMNode.fromJSON(schema, snapshot.body);
      final composer = LayoutComposer(
        setup: OfficeDocxCodec.pageSetupOf(snapshot),
        sections: OfficeDocxCodec.pageSetupsOf(snapshot),
        header: OfficeDocxCodec.regionOf(snapshot.headers, schema),
        footer: OfficeDocxCodec.regionOf(snapshot.footers, schema),
      );
      final graph = composer.compose(document);
      final natural =
          composer.compose(document, honorRenderedPageBreaks: false);

      PMNode? largestTable;
      for (final block in document.children) {
        if (block.type.name == 'table' &&
            (largestTable == null ||
                block.childCount > largestTable.childCount)) {
          largestTable = block;
        }
      }
      final tableId = officeNodeId(largestTable!);
      List<int> tablePages(PageGraph candidate) => [
            for (final page in candidate.pages)
              if (page.fragments.whereType<TableFragment>().any(
                    (fragment) => fragment.sourceTableId == tableId,
                  ))
                page.index + 1,
          ];

      expect(graph.pages, hasLength(140));
      expect(natural.pages, hasLength(140),
          reason:
              'salvar após editar remove o cache; a paginação recomposta continua estável');
      for (final candidate in [graph, natural]) {
        final pages = tablePages(candidate);
        expect(pages, hasLength(88));
        expect(pages.first, 53);
        expect(pages.last, 140);
      }
      // O rodapé do TR é mais alto que a margem inferior e as métricas
      // locais divergem do cache do Word já na primeira página: a partir da
      // primeira quebra forçada pela capacidade FÍSICA os hints são
      // descartados, então as fronteiras abaixo são as da paginação natural
      // (idênticas em `graph` e `natural` para este corpus).
      expect(visiblePageText(graph.pages[18]),
          startsWith('pela empresa proponente'));
      expect(visiblePageText(graph.pages[30]),
          startsWith('Enviar a documentação pertinente'));
      expect(visiblePageText(graph.pages[42]),
          startsWith('ESTIMATIVAS DO VALOR DA CONTRATAÇÃO'));
      expect(visiblePageText(graph.pages[43]), startsWith('ANEXO I'));
      final page53 = graph.pages[52];
      final page53Text = visiblePageText(page53);
      expect(page53Text, startsWith('ANEXO III'));
      expect(
          page53Text, isNot(contains('acionamento de suporte técnico através')),
          reason: 'a linha seguinte ao item 17 pertence à página 54');
      final item14 = page53.fragments
          .whereType<TableFragment>()
          .expand((table) => table.rows)
          .expand((row) => row.cells)
          .expand((cell) => cell.blocks)
          .firstWhere((block) => block.lines
              .expand((line) => line.segments)
              .any((segment) => segment.text.contains(
                  'autenticação integrada ao sistema utilizando serviços')));
      expect(item14.lines, hasLength(2),
          reason: 'Arial 10 justificado quebra antes de Directory/LDAP');
      final footerExtent = page53.footer.fold<int>(
        0,
        (extent, fragment) => fragment.yTwips + fragment.heightTwips > extent
            ? fragment.yTwips + fragment.heightTwips
            : extent,
      );
      final footerInset = page53.setup.footerDistanceTwips +
          footerExtent -
          page53.setup.marginBottomTwips;
      final bodyCapacity =
          page53.setup.contentHeightTwips - (footerInset > 0 ? footerInset : 0);
      final bodyBottom = page53.fragments.fold<int>(
        0,
        (bottom, fragment) => fragment.yTwips + fragment.heightTwips > bottom
            ? fragment.yTwips + fragment.heightTwips
            : bottom,
      );
      expect(bodyBottom, lessThanOrEqualTo(bodyCapacity),
          reason: 'a tabela da página 53 não pode invadir o rodapé');
      expect(visiblePageText(graph.pages[139]),
          startsWith('23 Cadastro de equipamentos da obra'));
    });

    test('ETP de produção mantém 19 páginas e rodapé fora do corpo', () {
      if (!hasProductionEtpCorpus) return;
      final codec = OfficeDocxCodec(schema: schema);
      final snapshot = codec.import(productionEtpCorpus()).snapshot;
      final document = PMNode.fromJSON(schema, snapshot.body);
      final composer = LayoutComposer(
        setup: OfficeDocxCodec.pageSetupOf(snapshot),
        sections: OfficeDocxCodec.pageSetupsOf(snapshot),
        header: OfficeDocxCodec.regionOf(snapshot.headers, schema),
        footer: OfficeDocxCodec.regionOf(snapshot.footers, schema),
      );
      final hinted = composer.compose(document);
      final natural =
          composer.compose(document, honorRenderedPageBreaks: false);

      expect(hinted.pages, hasLength(19));
      expect(natural.pages, hasLength(19));
      for (final graph in [hinted, natural]) {
        final page = graph.pages[9];
        expect(
            visiblePageText(page), contains('Análise comparativa de soluções'));
        final footerExtent = page.footer.fold<int>(
          0,
          (extent, fragment) => fragment.yTwips + fragment.heightTwips > extent
              ? fragment.yTwips + fragment.heightTwips
              : extent,
        );
        final footerInset = page.setup.footerDistanceTwips +
            footerExtent -
            page.setup.marginBottomTwips;
        final bodyCapacity =
            page.setup.contentHeightTwips - (footerInset > 0 ? footerInset : 0);
        final bodyBottom = page.fragments.fold<int>(
          0,
          (bottom, fragment) => fragment.yTwips + fragment.heightTwips > bottom
              ? fragment.yTwips + fragment.heightTwips
              : bottom,
        );
        expect(bodyBottom, lessThanOrEqualTo(bodyCapacity));
      }
    });
  });

  group('geometria da seção', () {
    test('documento novo reabre com papel, orientação e margens escolhidos',
        () {
      const setup = PageSetupTwips(
        widthTwips: 15840,
        heightTwips: 12240,
        marginTopTwips: 720,
        marginRightTwips: 900,
        marginBottomTwips: 1080,
        marginLeftTwips: 1260,
        headerDistanceTwips: 360,
        footerDistanceTwips: 480,
        documentGridType: 'lines',
        documentGridLinePitchTwips: 300,
      );
      final doc = schema.node('doc', null,
          Fragment.from([schema.node('paragraph', null, Fragment.empty)]));
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(doc, pageSetup: setup);
      final imported = codec.import(bytes);
      final reopened = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final xml = utf8.decode(partsOf(bytes)['word/document.xml']!);

      expect(reopened.widthTwips, setup.widthTwips);
      expect(reopened.heightTwips, setup.heightTwips);
      expect(reopened.marginTopTwips, setup.marginTopTwips);
      expect(reopened.marginRightTwips, setup.marginRightTwips);
      expect(reopened.marginBottomTwips, setup.marginBottomTwips);
      expect(reopened.marginLeftTwips, setup.marginLeftTwips);
      expect(reopened.headerDistanceTwips, setup.headerDistanceTwips);
      expect(reopened.footerDistanceTwips, setup.footerDistanceTwips);
      expect(reopened.documentGridType, 'lines');
      expect(reopened.documentGridLinePitchTwips, 300);
      expect(xml, contains('w:orient="landscape"'));
    });

    test('override altera geometria sem reescrever filhos ancillary do sectPr',
        () {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceDoc = schema.node('doc', null,
          Fragment.from([schema.node('paragraph', null, Fragment.empty)]));
      final archive = ZipArchive.decodeBytes(codec.exportDocument(sourceDoc));
      final originalXml = archive.readString('word/document.xml')!;
      final sectionMatch =
          RegExp(r'<w:sectPr\b[\s\S]*?</w:sectPr>').firstMatch(originalXml);
      expect(sectionMatch, isNotNull);
      const sourceSection = '<w:sectPr w:rsidR="00ABC123">'
          '<w:type w:val="nextPage"/>'
          '<w:pgSz w:w="11906" w:h="16838" w:code="9"/>'
          '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" '
          'w:left="1440" w:header="720" w:footer="720" w:gutter="120"/>'
          '<w:paperSrc w:first="1" w:other="2"/>'
          '<w:lnNumType w:countBy="5" w:start="1" w:restart="newPage"/>'
          '<w:pgNumType w:start="3" w:fmt="decimal"/>'
          '<w:cols w:num="2" w:space="777" w:equalWidth="0">'
          '<w:col w:w="4800" w:space="777"/>'
          '<w:col w:w="4800" w:space="777"/>'
          '</w:cols>'
          '<w:bidi/>'
          '<w:rtlGutter/>'
          '<w:docGrid w:type="lines" w:linePitch="360" w:charSpace="12"/>'
          '</w:sectPr>';
      archive.setFile(
        'word/document.xml',
        utf8.encode(originalXml.replaceRange(
          sectionMatch!.start,
          sectionMatch.end,
          sourceSection,
        )),
      );
      final sourceBytes = archive.encode();
      final imported = codec.import(sourceBytes);
      const override = PageSetupTwips(
        widthTwips: 16838,
        heightTwips: 11906,
        marginTopTwips: 800,
        marginRightTwips: 900,
        marginBottomTwips: 1000,
        marginLeftTwips: 1100,
      );
      final saved = codec.exportEdited(
        imported.snapshot,
        PMNode.fromJSON(schema, imported.snapshot.body),
        pageSetup: override,
      );
      final savedXml = utf8.decode(partsOf(saved)['word/document.xml']!);
      final savedSection = RegExp(r'<w:sectPr\b[\s\S]*?</w:sectPr>')
          .firstMatch(savedXml)!
          .group(0)!;

      expect(DocxValidator.validate(saved), isEmpty);
      expect(savedSection, contains('w:rsidR="00ABC123"'));
      expect(
          savedSection, contains('<w:pgSz w:w="16838" w:h="11906" w:code="9"'));
      expect(savedSection, contains('w:orient="landscape"'));
      expect(savedSection,
          contains('w:top="800" w:right="900" w:bottom="1000" w:left="1100"'));
      expect(savedSection, contains('w:header="720"'));
      expect(savedSection, contains('w:footer="720"'));
      expect(savedSection, contains('w:gutter="120"'));
      for (final ancillary in const [
        '<w:type w:val="nextPage"/>',
        '<w:paperSrc w:first="1" w:other="2"/>',
        '<w:lnNumType w:countBy="5" w:start="1" w:restart="newPage"/>',
        '<w:pgNumType w:start="3" w:fmt="decimal"/>',
        '<w:cols w:num="2" w:space="777" w:equalWidth="0"><w:col w:w="4800" w:space="777"/><w:col w:w="4800" w:space="777"/></w:cols>',
        '<w:bidi/>',
        '<w:rtlGutter/>',
        '<w:docGrid w:type="lines" w:linePitch="360" w:charSpace="12"/>',
      ]) {
        expect(savedSection, contains(ancillary));
      }
      expect(
        savedSection.indexOf('<w:type'),
        lessThan(savedSection.indexOf('<w:pgSz')),
      );
      expect(
        savedSection.indexOf('<w:pgNumType'),
        lessThan(savedSection.indexOf('<w:cols')),
      );
    });

    test('override preserva metadados da seção nos dois caminhos editados', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(bytes);
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final before = DocxReader.read(bytes).document.section!;
      final beforeXml = utf8.decode(partsOf(bytes)['word/document.xml']!);
      final beforeCols = RegExp(r'<w:cols\b(?:[^>]*/>|[^>]*>[\s\S]*?</w:cols>)')
          .firstMatch(beforeXml)
          ?.group(0);
      expect(beforeCols, isNotNull,
          reason: 'o corpus ETP declara w:cols na seção final');
      const override = PageSetupTwips(
        widthTwips: 16838,
        heightTwips: 11906,
        marginTopTwips: 800,
        marginRightTwips: 900,
        marginBottomTwips: 1000,
        marginLeftTwips: 1100,
      );

      final outputs = [
        codec.exportEdited(
          imported.snapshot,
          doc,
          pageSetup: override,
        ),
        codec.exportEditedFromDocx(
          bytes,
          imported.snapshot.sourceMap,
          doc,
          pageSetup: override,
        ),
      ];

      for (final output in outputs) {
        final after = DocxReader.read(output).document.section!;
        final afterXml = utf8.decode(partsOf(output)['word/document.xml']!);
        final afterCols =
            RegExp(r'<w:cols\b(?:[^>]*/>|[^>]*>[\s\S]*?</w:cols>)')
                .firstMatch(afterXml)
                ?.group(0);
        expect(after.pageWidthTwips, override.widthTwips);
        expect(after.pageHeightTwips, override.heightTwips);
        expect(after.orientation, 'landscape');
        expect(after.marginTopTwips, override.marginTopTwips);
        expect(after.marginRightTwips, override.marginRightTwips);
        expect(after.marginBottomTwips, override.marginBottomTwips);
        expect(after.marginLeftTwips, override.marginLeftTwips);
        expect(after.headerDistanceTwips, before.headerDistanceTwips);
        expect(after.footerDistanceTwips, before.footerDistanceTwips);
        expect(after.gutterTwips, before.gutterTwips);
        expect(after.documentGridType, before.documentGridType);
        expect(after.documentGridLinePitchTwips,
            before.documentGridLinePitchTwips);
        expect(after.titlePage, before.titlePage);
        expect(
          [for (final ref in after.headerReferences) (ref.type, ref.relId)],
          [for (final ref in before.headerReferences) (ref.type, ref.relId)],
        );
        expect(
          [for (final ref in after.footerReferences) (ref.type, ref.relId)],
          [for (final ref in before.footerReferences) (ref.type, ref.relId)],
        );
        expect(afterCols, beforeCols,
            reason: 'page setup não pode remover nem alterar w:cols');
      }
    });

    test('a página do DOCX chega ao snapshot em twips', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      expect(imported.snapshot.resources.sections, isNotEmpty);

      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      expect(setup.widthTwips, greaterThan(0));
      expect(setup.heightTwips, greaterThan(setup.widthTwips),
          reason: 'o corpus é retrato');
      expect(setup.contentWidthTwips, lessThan(setup.widthTwips),
          reason: 'as margens do documento têm de entrar');
    });

    test('o documento pagina com a geometria DELE, não com A4 padrão', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final own = LayoutComposer(setup: setup).compose(doc);
      final defaulted = LayoutComposer().compose(doc);

      // O corpus é A4 como o default, mas com margens de 2,5 cm em vez de
      // 2 cm: a ÁREA ÚTIL difere, e é ela que decide onde a página quebra.
      expect(setup.contentHeightTwips,
          isNot(const PageSetupTwips().contentHeightTwips));
      expect(own.pages, isNotEmpty);
      expect(own.pages.every((page) => identical(page.setup, setup)), isTrue,
          reason: 'cada página precisa conservar a geometria importada');
      expect(defaulted.pages.first.setup.contentHeightTwips,
          isNot(own.pages.first.setup.contentHeightTwips));
    });

    test('o PDF do snapshot usa a mesma geometria', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final expected = LayoutComposer(setup: setup)
          .compose(PMNode.fromJSON(schema, imported.snapshot.body));

      final pdf = OfficePdfService().fromSnapshot(imported.snapshot);
      expect(pdf.pageCount, expected.pages.length,
          reason: 'o PDF assinado tem de sair no papel do documento');
    });

    test('sem seção declarada, cai no default sem explodir', () {
      final snapshot = OfficeDocumentSnapshot(
          documentId: 'x',
          body: schema
              .node(
                  'doc',
                  null,
                  Fragment.from(
                      [schema.node('paragraph', null, Fragment.empty)]))
              .toJSON() as Map<String, dynamic>);
      final setup = OfficeDocxCodec.pageSetupOf(snapshot);
      expect(setup.widthTwips, const PageSetupTwips().widthTwips);
    });
  });

  group('cabeçalho e rodapé', () {
    test('viram raízes próprias do snapshot, não parte do corpo', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final regions = {
        ...imported.snapshot.headers,
        ...imported.snapshot.footers
      };
      if (regions.isEmpty) return; // corpus sem timbre: nada a provar aqui

      final body = PMNode.fromJSON(schema, imported.snapshot.body);
      final bodyText =
          body.textBetween(0, body.content.size, blockSeparator: ' ');
      for (final json in regions.values) {
        final region = PMNode.fromJSON(schema, json);
        final text = region.textBetween(0, region.content.size).trim();
        if (text.isEmpty) continue;
        expect(bodyText, isNot(contains(text)),
            reason: 'a região não pode ter vazado para dentro do corpo');
      }
    });

    test('o PDF do snapshot desenha a região em todas as páginas', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final header =
          OfficeDocxCodec.regionOf(imported.snapshot.headers, schema);
      if (header == null) return;

      final pdf = OfficePdfService().fromSnapshot(imported.snapshot);
      expect(pdf.pageCount, greaterThan(0));
      expect(pdf.bytes.length, greaterThan(1000));
    });

    test('preserva imagens e campos de página nas raízes', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final header =
          OfficeDocxCodec.regionOf(imported.snapshot.headers, schema);
      final footer =
          OfficeDocxCodec.regionOf(imported.snapshot.footers, schema);

      expect(header, isNotNull);
      expect(footer, isNotNull);
      expect(containsNode(header!, 'image'), isTrue);
      final footerText = footer!.textBetween(0, footer.content.size);
      expect(footerText, isNot(contains('{PAGE}')),
          reason: 'o PM persiste o cached result, não um placeholder literal');
      final commands = <String>[];
      void collectFieldCommands(PMNode node) {
        if (node.type.name == 'opaqueInline') {
          final insert = node.attrs['insert'];
          if (insert is Map && insert['fieldMarker'] == 'separate') {
            commands.add('${insert['fieldCommand']}');
          }
        }
        for (var i = 0; i < node.childCount; i++) {
          collectFieldCommands(node.child(i));
        }
      }

      collectFieldCommands(footer);
      expect(commands, containsAll(<String>['PAGE', 'NUMPAGES']));
    });

    test('ETP real herda tabs center/right do estilo Rodap', () {
      if (!hasProductionEtpCorpus) return;
      final imported = OfficeDocxCodec().import(productionEtpCorpus());
      final footerVariants =
          OfficeDocxCodec.regionVariantsOf(imported.snapshot.footers, schema);
      final footer =
          OfficeDocxCodec.regionOf(imported.snapshot.footers, schema);
      expect(footer, isNotNull);
      expect(footerVariants.keys, containsAll(<String>['default', 'first']));
      expect(OfficeDocxCodec.titlePageOf(imported.snapshot), isFalse,
          reason: 'a mera existência de footer2/first não ativa titlePg');
      expect(OfficeDocxCodec.evenAndOddHeadersOf(imported.snapshot), isFalse);

      PMNode? pageParagraph;
      void visit(PMNode node) {
        if (node.isTextblock && node.textContent.contains('Página')) {
          pageParagraph = node;
          return;
        }
        for (var i = 0; i < node.childCount && pageParagraph == null; i++) {
          visit(node.child(i));
        }
      }

      visit(footer!);
      expect(pageParagraph, isNotNull);
      final style = pageParagraph!.attrs['style'] as Map;
      final tabs = style['tabs'] as List;
      expect(
        tabs,
        containsAll(<Object>[
          containsPair('posTwips', 4252),
          containsPair('posTwips', 8504),
        ]),
        reason: 'a cascata do styles.xml também vale dentro do footer',
      );

      final body = PMNode.fromJSON(schema, imported.snapshot.body);
      final graph = LayoutComposer(
        setup: OfficeDocxCodec.pageSetupOf(imported.snapshot),
        sections: OfficeDocxCodec.pageSetupsOf(imported.snapshot),
        footerVariants: footerVariants,
        titlePage: OfficeDocxCodec.titlePageOf(imported.snapshot),
        evenAndOddHeaders:
            OfficeDocxCodec.evenAndOddHeadersOf(imported.snapshot),
      ).compose(body);
      expect(graph.pages, hasLength(19));
      for (final pageIndex in <int>[0, 18]) {
        final pageLine = graph.pages[pageIndex].footer
            .expand((fragment) => fragment.lines)
            .firstWhere((line) => line.segments
                .any((segment) => segment.text.contains('Página')));
        expect(pageLine.widthTwips, 8504,
            reason:
                'p${pageIndex + 1}: a borda direita do número deve cair no tab right do Word');
      }
    });

    test('projeta o carimbo flutuante do cabeçalho com geometria em twips', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final header =
          OfficeDocxCodec.regionOf(imported.snapshot.headers, schema);
      expect(header, isNotNull);

      PMNode? findTextBox(PMNode node) {
        if (node.type.name == 'textBox') return node;
        for (var i = 0; i < node.childCount; i++) {
          final found = findTextBox(node.child(i));
          if (found != null) return found;
        }
        return null;
      }

      final textBox = findTextBox(header!);
      expect(textBox, isNotNull);
      expect(textBox!.attrs['text'], contains('Continuação de Processo'));
      expect(textBox.attrs['width'], inInclusiveRange(100, 5000));
      expect(textBox.attrs['positionVRelativeFrom'], 'paragraph');
      final offsetX = textBox.attrs['offsetX'] as num?;
      if (offsetX != null) {
        expect(offsetX.abs(), lessThan(20000),
            reason: 'offset de layout deve estar em twips, não EMU');
      } else {
        expect(textBox.attrs['positionHAlign'], isNotNull,
            reason: 'a caixa precisa de offset ou alinhamento de âncora');
      }
    });

    test(
        'ETP e TR reais projetam txbxContent rico com assinatura, runs e insets',
        () {
      if (!hasProductionEtpCorpus || !hasTrCorpus) return;

      PMNode? findTextBox(PMNode node) {
        if (node.type.name == 'textBox') return node;
        for (var i = 0; i < node.childCount; i++) {
          final found = findTextBox(node.child(i));
          if (found != null) return found;
        }
        return null;
      }

      bool hasMark(PMNode node, String name) =>
          node.marks.any((mark) => mark.type.name == name);

      final cases = <({String name, Uint8List bytes, String firstAlign})>[
        (
          name: 'ETP',
          bytes: productionEtpCorpus(),
          firstAlign: 'center',
        ),
        (name: 'TR', bytes: trCorpus(), firstAlign: 'right'),
      ];
      for (final sample in cases) {
        final imported = OfficeDocxCodec(schema: schema).import(sample.bytes);
        final regions = OfficeDocxCodec.regionVariantsOf(
          imported.snapshot.headers,
          schema,
        );
        PMNode? textBox;
        for (final region in regions.values) {
          textBox ??= findTextBox(region);
        }

        expect(textBox, isNotNull, reason: '${sample.name}: carimbo ausente');
        final rawDoc = textBox!.attrs['textBoxDoc'];
        expect(rawDoc, isA<Map>(),
            reason: '${sample.name}: txbxContent foi achatado');
        final miniDoc = PMNode.fromJSON(schema, rawDoc);
        expect(miniDoc.childCount, 4,
            reason: '${sample.name}: os quatro w:p devem sobreviver');
        expect(
          textBox.attrs['textBoxSourceSignature'],
          OfficeDocxCodec.nodeSignature(miniDoc),
        );
        expect(textBox.attrs['insetLeft'], 144);
        expect(textBox.attrs['insetTop'], 72);
        expect(textBox.attrs['insetRight'], 144);
        expect(textBox.attrs['insetBottom'], 72);
        expect(textBox.attrs['word'], contains('w:txbxContent'));

        final first = miniDoc.child(0);
        expect((first.attrs['style'] as Map)['align'], sample.firstAlign);
        expect(first.textContent, contains('Continuação de Processo'));
        final firstRuns = <PMNode>[
          for (var i = 0; i < first.childCount; i++)
            if (first.child(i).isText) first.child(i),
        ];
        expect(firstRuns, isNotEmpty);
        expect(firstRuns.every((run) => hasMark(run, 'underline')), isTrue);
        expect(
          firstRuns.expand((run) => run.marks).any(
                (mark) =>
                    mark.type.name == 'size' && mark.attrs['value'] == '10.0pt',
              ),
          isTrue,
          reason: '${sample.name}: o w:sz=20 interno deve renderizar como 10pt',
        );

        final process = miniDoc.child(1);
        final processRuns = <PMNode>[
          for (var i = 0; i < process.childCount; i++)
            if (process.child(i).isText) process.child(i),
        ];
        expect(
          processRuns.any((run) =>
              run.textContent.contains('Processo nº') && !hasMark(run, 'bold')),
          isTrue,
        );
        final boldText = processRuns
            .where((run) => hasMark(run, 'bold'))
            .map((run) => run.textContent)
            .join();
        expect(boldText, contains('44505'));
        expect(boldText, contains('/2025'));
      }
    });
  });

  test('o corpus de teste existe', () {
    expect(hasCorpus, isTrue,
        reason: 'sem corpus real o round-trip não prova nada');
  });
}
