/// A API OPCIONAL de fontes: a aplicação entrega bytes, o editor mede,
/// desenha e embute com a MESMA face.
///
/// O que estes testes protegem:
/// * o editor pede só as combinações que o documento REALMENTE usa (uma
///   biblioteca que faz rede não pode pedir família × 4 variantes às cegas);
/// * ausência é memorizada — um `null` do loader não vira uma requisição por
///   recomposição;
/// * um arquivo inválido não derruba a abertura do documento;
/// * a face entra no compositor E é registrada na plataforma, senão a
///   projeção continuaria desenhando com outra fonte;
/// * o PDF passa a EMBUTIR a face (CID/Identity-H) em vez da standard-14.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();
  final interBytes =
      File('test/assets/fonts/Inter-Regular.ttf').readAsBytesSync();

  late DomAdapter adapter;
  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
    (adapter as FakeDomAdapter)
      ..registeredFonts.clear()
      ..acceptsFontFaces = true;
  });

  PMNode run(String text, {String? family, bool bold = false}) => schema.text(
        text,
        [
          if (family != null) schema.marks['font']!.create({'value': family}),
          if (bold) schema.marks['bold']!.create(),
        ],
      );

  PMNode docWith(List<PMNode> inline) => schema.node(
        'doc',
        null,
        Fragment.from([schema.node('paragraph', null, Fragment.from(inline))]),
      );

  group('varredura de uso', () {
    test('coleta família + peso + estilo das marcas dos runs', () {
      final usage = officeFontUsageOf(docWith([
        run('normal ', family: 'Inter'),
        run('negrito', family: 'Inter', bold: true),
        run(' outra', family: 'Georgia'),
      ]));

      expect(usage, contains(const OfficeFontUsage('Inter')));
      expect(usage, contains(const OfficeFontUsage('Inter', bold: true)));
      expect(usage, contains(const OfficeFontUsage('Georgia')));
      expect(usage, hasLength(3));
    });

    test('a família resolvida no estilo do BLOCO também conta', () {
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'style': {'family': 'Carlito', 'bold': true}
                },
                Fragment.from([schema.text('sem marca de fonte')])),
          ]));

      expect(officeFontUsageOf(doc),
          contains(const OfficeFontUsage('Carlito', bold: true)));
    });

    test('o conteúdo da CAIXA DE TEXTO entra na conta', () {
      // O timbre de um documento oficial vive numa caixa; a fonte dela não
      // aparece em nenhuma marca do corpo.
      final inner = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null,
                Fragment.from([run('Continuação', family: 'Ecofont')])),
          ]));
      final doc = docWith([
        schema.node('textBox', {'text': 'x', 'textBoxDoc': inner.toJSON()}),
      ]);

      expect(officeFontUsageOf(doc), contains(const OfficeFontUsage('Ecofont')));
    });
  });

  group('acervo', () {
    test('pede cada combinação UMA vez e memoriza a ausência', () async {
      final asked = <String>[];
      final library = OfficeFontLibrary(loader: (request) async {
        asked.add('${request.family}${request.variantSuffix}');
        return null; // "não tenho"
      });

      final usage = {
        const OfficeFontUsage('Inter'),
        const OfficeFontUsage('Inter', bold: true),
      };
      expect(await library.ensureAll(usage), 0);
      expect(asked, hasLength(2));

      // Segunda rodada: nada é perguntado de novo.
      expect(await library.ensureAll(usage), 0);
      expect(asked, hasLength(2), reason: 'ausência memorizada');
      expect(library.missing, hasLength(2));
      expect(library.isEmpty, isTrue);
    });

    test('a face carregada fica disponível para o compositor', () async {
      final library = OfficeFontLibrary(
        loader: (request) async =>
            request.family == 'Inter' ? interBytes : null,
      );

      final added = await library.ensureAll({const OfficeFontUsage('Inter')});

      expect(added, 1);
      expect(library.has('Inter'), isTrue);
      final face = library.fontSet.faceFor('Inter');
      expect(face, isNotNull);
      expect(face!.measureWidthPt('Documento', 12), greaterThan(0));
    });

    test('a requisição carrega os aliases metricamente compatíveis', () async {
      late OfficeFontRequest seen;
      final library = OfficeFontLibrary(loader: (request) async {
        seen = request;
        return null;
      });

      await library
          .ensureAll({const OfficeFontUsage('Ecofont_Spranq_eco_Sans')});

      expect(seen.family, 'Ecofont_Spranq_eco_Sans');
      // É o que permite a um loader simples servir Carlito quando o documento
      // pede a Ecofont — sem reimplementar a tabela de aliases.
      expect(seen.aliases, isNotEmpty);
      expect(seen.variantSuffix, '-Regular');
    });

    test('arquivo inválido NÃO derruba nada: vira ausência', () async {
      final library = OfficeFontLibrary(
        loader: (_) async => Uint8List.fromList('<html>404</html>'.codeUnits),
      );

      expect(await library.ensureAll({const OfficeFontUsage('Inter')}), 0);
      expect(library.isEmpty, isTrue);
      expect(library.missing, hasLength(1));
    });

    test('loader que lança também vira ausência', () async {
      final library =
          OfficeFontLibrary(loader: (_) async => throw StateError('offline'));

      expect(await library.ensureAll({const OfficeFontUsage('Inter')}), 0);
      expect(library.missing, hasLength(1));
    });

    test('sem loader, o acervo continua sendo o que a aplicação passou',
        () async {
      final library = OfficeFontLibrary(
        faces: [LayoutFontFace('Inter', interBytes)],
      );

      expect(await library.ensureAll({const OfficeFontUsage('Georgia')}), 0);
      expect(library.faceCount, 1);
      expect(library.has('Inter'), isTrue);
    });

    test('registra a face na plataforma', () async {
      final fake = adapter as FakeDomAdapter;
      final library = OfficeFontLibrary(
        adapter: adapter,
        loader: (_) async => interBytes,
      );

      await library.ensureAll({const OfficeFontUsage('Inter', bold: true)});
      // O registro é best-effort e não é esperado pelo carregamento; um giro
      // do event loop basta para ele acontecer.
      await Future<void>.delayed(Duration.zero);

      expect(fake.registeredFonts, hasLength(1));
      expect(fake.registeredFonts.single.family, 'Inter');
      expect(fake.registeredFonts.single.bold, isTrue);
      expect(fake.registeredFonts.single.byteLength, interBytes.length);
    });
  });

  group('editor', () {
    OfficeWordEditor mount({OfficeFontLoader? loader}) => editor =
        OfficeWordEditor.mount(
          host: host,
          adapter: adapter,
          document: docWith([run('Acentuação — “aspas”', family: 'Inter')]),
          schema: schema,
          options: OfficeWordEditorOptions(fontLoader: loader),
        );

    test('sem loader, nada muda (o comportamento histórico)', () async {
      final editor = mount();
      expect(editor.fontLibrary.isEmpty, isTrue);
      expect(await editor.loadDocumentFonts(), 0);
    });

    test('com loader, a face do documento entra e o documento repagina',
        () async {
      final editor = mount(loader: (request) async =>
          request.family == 'Inter' ? interBytes : null);
      final graphBefore = editor.pageGraph;

      final added = await editor.loadDocumentFonts();

      expect(added, 1);
      expect(editor.fontLibrary.has('Inter'), isTrue);
      expect(identical(editor.pageGraph, graphBefore), isFalse,
          reason: 'a métrica mudou: o documento tem de repaginar');
      // O estado (documento e histórico) sobrevive à recomposição.
      expect(editor.state.doc.textContent, contains('Acentuação'));
    });

    test('o PDF passa a EMBUTIR a face em vez da standard-14', () async {
      final editor = mount(loader: (_) async => interBytes);
      final before = String.fromCharCodes(editor.exportPdf());
      expect(before, isNot(contains('/Identity-H')),
          reason: 'sem faces, o PDF usa standard-14 + WinAnsi');

      await editor.loadDocumentFonts();
      final after = String.fromCharCodes(editor.exportPdf());

      expect(after, contains('/Identity-H'));
      expect(after, contains('/FontFile2'),
          reason: 'a face é embutida com subset, não referenciada');
    });

    test('abrir um documento pede as fontes DELE', () async {
      final asked = <String>[];
      final editor = mount(loader: (request) async {
        asked.add(request.family);
        return null;
      });
      await editor.loadDocumentFonts();
      asked.clear();

      editor.openDocument(
        docWith([run('outro documento', family: 'Georgia')]),
        header: schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node('paragraph', null,
                  Fragment.from([run('timbre', family: 'Cambria')])),
            ])),
      );
      // `openDocument` dispara em segundo plano; aguardamos o caminho
      // explícito, que é o mesmo.
      await editor.loadDocumentFonts();

      expect(asked, contains('Georgia'));
      expect(asked, contains('Cambria'),
          reason: 'cabeçalhos e rodapés são raízes próprias e também contam');
      expect(asked, isNot(contains('Inter')));
    });
  });
}
