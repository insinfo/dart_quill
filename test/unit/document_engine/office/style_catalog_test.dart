/// F8 — o catálogo de estilos do documento.
///
/// O que estes testes protegem: a galeria mostra os estilos DO ARQUIVO com
/// as propriedades resolvidas pela cascata (docDefaults → basedOn → estilo),
/// e o patch do `styles.xml` toca SÓ o estilo editado — o resto da parte sai
/// caractere por caractere, que é o contrato de preservação do repositório.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/docx/reader.dart';
import 'package:dart_quill/src/office/document/docx/styles.dart';
import 'package:dart_quill/src/office/document/docx/validator.dart';

void main() {
  final etpPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(etpPath).existsSync();
  Uint8List corpus() => File(etpPath).readAsBytesSync();

  // Os DOCX de produção são LOCALIZADOS por prefixo: os nomes têm acento e a
  // CI roda em Linux, onde um caminho literal quebraria.
  final productionFiles = Directory('resources').existsSync()
      ? Directory('resources')
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.toLowerCase().endsWith('.docx') &&
              file.uri.pathSegments.last.startsWith('PGCTIC1_-_ETP_-'))
          .toList()
      : <File>[];

  String stylesXmlOf(Uint8List bytes) =>
      DocxReader.read(bytes).package.partString('word/styles.xml')!;

  const minimal = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:docDefaults><w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>'
      '<w:sz w:val="24"/></w:rPr></w:rPrDefault></w:docDefaults>'
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
      '<w:name w:val="Normal"/><w:qFormat/></w:style>'
      '<w:style w:type="paragraph" w:styleId="Ttulo1">'
      '<w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>'
      '<w:uiPriority w:val="9"/><w:qFormat/>'
      '<w:pPr><w:keepNext/><w:spacing w:before="240" w:after="60"/>'
      '<w:jc w:val="center"/></w:pPr>'
      '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/>'
      '<w:sz w:val="32"/><w:color w:val="1F4E79"/></w:rPr></w:style>'
      '<w:style w:type="character" w:styleId="Ttulo1Char">'
      '<w:name w:val="Título 1 Char"/><w:qFormat/></w:style>'
      '<w:style w:type="paragraph" w:styleId="Escondido">'
      '<w:name w:val="Escondido"/><w:basedOn w:val="Normal"/></w:style>'
      '</w:styles>';

  group('resolução da cascata', () {
    test('o estilo herda docDefaults e o basedOn, e o derivado ganha', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);

      final normal = catalog['Normal']!;
      expect(normal.formatting.family, 'Times New Roman',
          reason: 'sem rPr próprio, Normal vale docDefaults');
      expect(normal.formatting.sizePt, 12);

      final heading = catalog['Ttulo1']!;
      expect(heading.name, 'heading 1');
      expect(heading.basedOn, 'Normal');
      expect(heading.formatting.family, 'Arial');
      expect(heading.formatting.sizePt, 16);
      expect(heading.formatting.bold, isTrue);
      expect(heading.formatting.align, 'center');
      expect(heading.formatting.spaceBeforeTwips, 240);
      expect(heading.formatting.spaceAfterTwips, 60);
    });

    test('cor/itálico/sublinhado ficam no PREVIEW, fora do editável', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      final heading = catalog['Ttulo1']!;
      expect(heading.preview.color, '#1F4E79');
      // A formatação editável não tem cor: o compositor não a resolve a
      // partir do bloco (ver o doc de OfficeStyleFormatting).
      expect(heading.formatting.toBlockStyle().containsKey('color'), isFalse);
    });

    test('o mapa resolvido usa as MESMAS chaves de attrs[style]', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      final block = catalog.blockStyleOf('Ttulo1');
      expect(block['family'], 'Arial');
      expect(block['sizePt'], 16);
      expect(block['bold'], isTrue);
      expect(block['align'], 'center');
      expect(block['wordStyleId'], 'Ttulo1');
    });
  });

  group('galeria', () {
    test('só estilos de parágrafo com qFormat, com o default à frente', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      final ids = [for (final style in catalog.gallery) style.id];
      expect(ids, ['Normal', 'Ttulo1'],
          reason: 'Ttulo1Char é de caractere e Escondido não tem qFormat');
    });

    test('a ordem segue uiPriority', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(
        minimal.replaceFirst(
          '<w:style w:type="paragraph" w:styleId="Escondido">'
              '<w:name w:val="Escondido"/><w:basedOn w:val="Normal"/></w:style>',
          '<w:style w:type="paragraph" w:styleId="Nivel01">'
              '<w:name w:val="Nivel 01"/><w:basedOn w:val="Normal"/>'
              '<w:qFormat/></w:style>',
        ),
      );
      // Nivel01 não declara uiPriority (0 pelo padrão do elemento) e vem
      // antes de Ttulo1 (9), como no Word.
      expect([for (final style in catalog.gallery) style.id],
          ['Normal', 'Nivel01', 'Ttulo1']);
    });

    test('o corpus real produz uma galeria com os estilos do documento', () {
      if (!hasCorpus) return;
      final catalog = OfficeStyleCatalog.fromStylesXml(stylesXmlOf(corpus()));
      final names = [for (final style in catalog.gallery) style.name];
      expect(names, isNotEmpty);
      expect(names.first, 'Normal', reason: 'o default abre a galeria');
      expect(names.length, lessThan(catalog.byId.length),
          reason: 'a galeria é um RECORTE — os ~90 estilos não cabem nela');
      for (final style in catalog.gallery) {
        expect(style.type, 'paragraph');
      }
    });

    test('o DOCX de produção traz os estilos "Nivel" na galeria', () {
      if (productionFiles.isEmpty) return;
      final bytes = Uint8List.fromList(productionFiles.first.readAsBytesSync());
      final catalog = OfficeStyleCatalog.fromStylesXml(stylesXmlOf(bytes));
      expect(
        catalog.gallery
            .any((style) => style.name.toLowerCase().contains('nivel')),
        isTrue,
        reason: 'é o critério da F8: a galeria mostra "Nível 01"',
      );
    });
  });

  group('patch do styles.xml', () {
    test('sem edição, o XML volta idêntico', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      expect(catalog.hasEdits, isFalse);
      expect(catalog.patchStylesXml(minimal), minimal);
    });

    test('modificar troca só o estilo editado', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      final heading = catalog['Ttulo1']!;
      catalog.upsert(heading.copyWith(
        formatting: heading.formatting.copyWith(family: 'Verdana', sizePt: 20),
      ));

      final patched = catalog.patchStylesXml(minimal);
      expect(patched, contains('w:ascii="Verdana"'));
      expect(patched, contains('<w:sz w:val="40"/>'));
      // O que não foi tocado continua onde estava, DENTRO do mesmo estilo.
      expect(patched, contains('<w:keepNext/>'));
      expect(patched, contains('<w:color w:val="1F4E79"/>'));
      // …e os outros estilos não sofrem um caractere.
      expect(
          patched,
          contains('<w:style w:type="paragraph" w:styleId="Escondido">'
              '<w:name w:val="Escondido"/><w:basedOn w:val="Normal"/>'
              '</w:style>'));
      expect(patched, contains('<w:docDefaults>'));
    });

    test('renomear troca só o w:name e "remover da galeria" só o qFormat', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      catalog.rename('Ttulo1', 'Nível 1 (nosso)');
      catalog.setInGallery('Ttulo1', false);

      final patched = catalog.patchStylesXml(minimal);
      expect(patched, contains('<w:name w:val="Nível 1 (nosso)"/>'));
      expect(patched, isNot(contains('<w:name w:val="heading 1"/>')));
      // O estilo CONTINUA existindo: apagá-lo invalidaria todo w:pStyle que
      // ainda aponta para ele.
      expect(patched, contains('w:styleId="Ttulo1"'));
      final headingBlock = patched.substring(
          patched.indexOf('w:styleId="Ttulo1"'),
          patched.indexOf('</w:style>', patched.indexOf('w:styleId="Ttulo1"')));
      expect(headingBlock, isNot(contains('<w:qFormat/>')));
    });

    test('um estilo NOVO entra antes de </w:styles> e o resto não muda', () {
      final catalog = OfficeStyleCatalog.fromStylesXml(minimal);
      catalog.upsert(const OfficeStyleDefinition(
        id: 'MeuEstilo',
        name: 'Meu Estilo',
        type: 'paragraph',
        basedOn: 'Normal',
        inGallery: true,
        formatting: OfficeStyleFormatting(
          family: 'Georgia',
          sizePt: 13,
          align: 'justify',
          indentTwips: 567,
        ),
        preview: OfficeStylePreview(),
      ));

      final patched = catalog.patchStylesXml(minimal);
      expect(patched, contains('w:styleId="MeuEstilo"'));
      expect(patched, contains('<w:name w:val="Meu Estilo"/>'));
      expect(patched, contains('<w:basedOn w:val="Normal"/>'));
      expect(patched, contains('<w:jc w:val="both"/>'));
      expect(patched, contains('<w:ind w:left="567"/>'));
      expect(patched.endsWith('</w:styles>'), isTrue);
      expect(
          patched.substring(
              0,
              patched.indexOf('<w:style w:type="paragraph" '
                  'w:styleId="MeuEstilo"')),
          minimal.substring(0, minimal.indexOf('</w:styles>')));
    });

    test('o XML patcheado continua sendo XML válido para o reader', () {
      if (!hasCorpus) return;
      final xml = stylesXmlOf(corpus());
      final catalog = OfficeStyleCatalog.fromStylesXml(xml);
      final first = catalog.gallery.last;
      catalog.upsert(first.copyWith(
        formatting: first.formatting.copyWith(family: 'Verdana', sizePt: 22),
      ));
      final patched = catalog.patchStylesXml(xml);

      final reparsed = WpStyleSheet.parse(patched);
      final style = reparsed.byId[first.id]!;
      expect(style.runProperties?.fontAscii, 'Verdana');
      expect(style.runProperties?.sizeHalfPoints, 44);
      expect(style.name, first.name, reason: 'o nome não foi tocado');
    });
  });

  group('importação', () {
    test('o codec devolve o catálogo junto do snapshot', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final catalog = imported.styleCatalog;
      expect(catalog, isNotNull);
      expect(catalog!.isNotEmpty, isTrue);
      expect(catalog.defaultParagraphStyle?.id, isNotNull);
    });

    test('um snapshot COM partes opacas reconstrói o catálogo sozinho', () {
      if (!hasCorpus) return;
      final snapshot = OfficeDocxCodec()
          .import(corpus(), includePackageResources: true)
          .snapshot;
      final catalog = OfficeStyleCatalog.fromSnapshot(snapshot);
      expect(catalog, isNotNull);
      expect(catalog!.gallery, isNotEmpty);
    });

    test('sem partes opacas não há catálogo pelo snapshot', () {
      if (!hasCorpus) return;
      final snapshot = OfficeDocxCodec()
          .import(corpus(), includePackageResources: false)
          .snapshot;
      expect(OfficeStyleCatalog.fromSnapshot(snapshot), isNull,
          reason: 'é por isso que o catálogo viaja em OfficeDocxImport');
    });
  });

  group('exportação', () {
    test('o styles.xml exportado leva o estilo modificado', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus(), includePackageResources: true);
      final catalog = imported.styleCatalog!;
      final target = catalog.gallery.last;
      catalog.upsert(target.copyWith(
        name: 'Estilo Renomeado F8',
        formatting: target.formatting.copyWith(family: 'Verdana', sizePt: 21),
      ));

      final doc = PMNode.fromJSON(officeQuillSchema(), imported.snapshot.body);
      final bytes =
          codec.exportEdited(imported.snapshot, doc, styleCatalog: catalog);

      expect(DocxValidator.validate(bytes), isEmpty,
          reason: 'o patch textual não pode produzir um pacote inválido');
      final out = DocxReader.read(bytes);
      final style = out.styles.byId[target.id]!;
      expect(style.name, 'Estilo Renomeado F8');
      expect(style.runProperties?.fontAscii, 'Verdana');
      expect(style.runProperties?.sizeHalfPoints, 42);
    });

    test('o styleId aplicado num bloco vira w:pStyle no document.xml', () {
      if (!hasCorpus) return;
      final schema = officeQuillSchema();
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(corpus(), includePackageResources: true);
      final catalog = imported.styleCatalog!;
      final target = catalog.gallery.last;
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      // O que `applyCatalogStyle` grava no bloco, sem o chrome no caminho.
      var index = 0;
      while (
          index < doc.childCount && doc.child(index).type.name != 'paragraph') {
        index++;
      }
      final block = doc.child(index);
      final patched = doc.copy(doc.content.replaceChild(
        index,
        block.type.create(
          {
            ...block.attrs,
            'word': {
              if (block.attrs['word'] is Map)
                ...(block.attrs['word'] as Map).cast<String, dynamic>(),
              'styleId': target.id,
            },
            'style': catalog.blockStyleOf(target.id),
          },
          block.content,
          block.marks,
        ),
      ));

      final bytes = codec.exportEdited(imported.snapshot, patched);
      final out = DocxReader.read(bytes);
      final xml = out.package.partString(out.mainPartName)!;
      expect(xml, contains('<w:pStyle w:val="${target.id}"/>'),
          reason: 'aplicar um estilo tem de chegar ao DOCX como w:pStyle');
    });

    test('sem edição de estilo, o styles.xml sai byte a byte', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus(), includePackageResources: true);
      final original = stylesXmlOf(corpus());

      final doc = PMNode.fromJSON(officeQuillSchema(), imported.snapshot.body);
      final bytes = codec.exportEdited(imported.snapshot, doc,
          styleCatalog: imported.styleCatalog);

      expect(stylesXmlOf(bytes), original,
          reason: 'só a edição EXPLÍCITA de um estilo pode tocar a parte');
      // E o utf8 continua íntegro (acentos dos nomes de estilo brasileiros).
      expect(
          utf8.encode(stylesXmlOf(bytes)).length, utf8.encode(original).length);
    });
  });
}
