/// Compara o PDF que o editor gera com o PDF que o WORD gerou do MESMO DOCX.
///
/// O oráculo é o arquivo de referência em `resources/`: o Word abriu o DOCX e
/// exportou o PDF, então tudo que divergir é divergência NOSSA. O que esta
/// ferramenta compara não são pixels — fidelidade tipográfica pixel a pixel
/// não é meta do projeto — e sim as três coisas que um usuário percebe na
/// primeira olhada e que um teste automatizado consegue afirmar:
///
/// 1. **contagem de páginas** — se o nosso PDF tem 21 páginas onde o Word tem
///    19, a paginação está errada, e nenhum detalhe adiante importa;
/// 2. **texto por página** — a página N nossa tem de conter o mesmo texto que
///    a página N do Word. É o que pega parágrafo que migrou de página,
///    cabeçalho que sumiu, célula perdida e campo `PAGE` resolvido errado;
/// 3. **texto total** — o que existe no documento e não chegou ao PDF (ou o
///    que apareceu duplicado).
///
/// Uso:
///
/// ```
/// dart run tool/pdf_reference_diff.dart                # os dois corpus
/// dart run tool/pdf_reference_diff.dart caminho.docx   # um arquivo
/// dart run tool/pdf_reference_diff.dart --out=dir      # onde gravar o PDF
/// dart run tool/pdf_reference_diff.dart --fonts=C:/Windows/Fonts
/// ```
///
/// **`--fonts`** liga a API opcional de fontes
/// (`document_engine/office/font_library.dart`) com um loader de sistema de
/// arquivos: o compositor passa a medir pela face REAL e o PDF a embute. É a
/// diferença entre "a linha quebra quase no mesmo lugar que o Word" e "quebra
/// no mesmo lugar" — e serve de demonstração de um [OfficeFontLoader] em ~20
/// linhas.
///
/// A extração de texto do PDF usa `pdftotext` (poppler), que já vem no
/// ambiente de desenvolvimento deste repositório; sem ele a ferramenta
/// compara só a contagem de páginas e diz o que faltou.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/dart_quill_office.dart';

const List<({String docx, String pdf})> _corpus = [
  (
    docx: 'resources/PGCTIC1_-_ETP_-_Sistema_de_Gestão_Pública.docx',
    pdf: 'resources/PGCTIC1_-_ETP_-_Sistema_de_Gestão_Pública.pdf',
  ),
  (
    docx: 'resources/PGCTIC1_-_TR_-_SISTEMA_GESTAO_PUBLICA__Recuperação_Automática_.docx',
    pdf: 'resources/PGCTIC1_-_TR_-_SISTEMA_GESTAO_PUBLICA__Recuperação_Automática_.pdf',
  ),
];

Future<void> main(List<String> arguments) async {
  var outDir = Directory.systemTemp.path;
  var pageLimit = 0;
  String? fontDir;
  final paths = <String>[];
  for (final argument in arguments) {
    if (argument.startsWith('--out=')) {
      outDir = argument.substring('--out='.length);
    } else if (argument.startsWith('--pages=')) {
      pageLimit = int.parse(argument.substring('--pages='.length));
    } else if (argument.startsWith('--fonts=')) {
      fontDir = argument.substring('--fonts='.length);
    } else {
      paths.add(argument);
    }
  }

  final targets = paths.isEmpty
      ? _corpus
      : [for (final path in paths) (docx: path, pdf: _siblingPdf(path))];

  var failures = 0;
  for (final target in targets) {
    final file = File(target.docx);
    if (!file.existsSync()) {
      stderr.writeln('não encontrado: ${target.docx}');
      failures++;
      continue;
    }
    failures += await _compare(target, outDir, pageLimit, fontDir);
  }
  if (failures != 0) exit(1);
}

/// Um [OfficeFontLoader] de sistema de arquivos — a demonstração mais curta
/// possível da API: o pacote diz de que face precisa, isto devolve bytes.
///
/// Cobre a convenção do Windows (`calibri.ttf`, `calibrib.ttf`, `calibribi`)
/// e a convenção "Família-Bold.ttf" dos pacotes livres, tentando a família
/// pedida e depois os aliases metricamente compatíveis.
OfficeFontLoader? _fileSystemLoader(String? dir) {
  if (dir == null) return null;
  return (request) async {
    for (final family in <String>{request.family, ...request.aliases}) {
      final flat = family.replaceAll(' ', '').toLowerCase();
      final windowsSuffix = request.bold && request.italic
          ? 'z'
          : request.bold
              ? 'b'
              : request.italic
                  ? 'i'
                  : '';
      for (final candidate in [
        '$flat$windowsSuffix.ttf',
        '${family.replaceAll(' ', '')}${request.variantSuffix}.ttf',
        if (!request.bold && !request.italic) '$flat.ttf',
      ]) {
        final file = File('$dir/$candidate');
        if (file.existsSync()) return file.readAsBytesSync();
      }
    }
    return null;
  };
}

String _siblingPdf(String docx) =>
    docx.replaceFirst(RegExp(r'\.docx$', caseSensitive: false), '.pdf');

Future<int> _compare(({String docx, String pdf}) target, String outDir,
    int pageLimit, String? fontDir) async {
  final name = Uri.file(target.docx).pathSegments.last;
  stdout.writeln('\n=== $name ===');

  final schema = officeQuillSchema();
  final codec = OfficeDocxCodec(schema: schema);
  final bytes = File(target.docx).readAsBytesSync();
  final imported = codec.import(bytes, includePackageResources: false);
  final snapshot = imported.snapshot;
  final document = PMNode.fromJSON(schema, snapshot.body);

  // A MESMA montagem que a aba Arquivo faz ao abrir um DOCX: geometria por
  // seção, variantes de região e as duas flags. Compor com menos que isso
  // mediria um documento que o editor nunca mostra.
  final empty = schema.node(
      'doc', null, Fragment.from([schema.node('paragraph', null, Fragment.empty)]));
  final headerVariants =
      OfficeDocxCodec.regionVariantsOf(snapshot.headers, schema);
  final footerVariants =
      OfficeDocxCodec.regionVariantsOf(snapshot.footers, schema);
  // A API opcional de fontes: as MESMAS faces medem e são embutidas.
  final library = OfficeFontLibrary(loader: _fileSystemLoader(fontDir));
  await library.ensureForDocument(
    document,
    extraDocuments: [
      ...OfficeDocxCodec.regionVariantsOf(snapshot.headers, schema).values,
      ...OfficeDocxCodec.regionVariantsOf(snapshot.footers, schema).values,
    ],
  );
  if (!library.isEmpty) {
    stdout.writeln('faces embutidas: ${library.faceCount}'
        '${library.missing.isEmpty ? '' : '  (sem face: ${library.missing.length})'}');
  }

  final composer = LayoutComposer(
    fonts: library.fontSet,
    setup: OfficeDocxCodec.pageSetupOf(snapshot),
    sections: OfficeDocxCodec.pageSetupsOf(snapshot),
    header: headerVariants['default'] ?? empty,
    footer: footerVariants['default'] ?? empty,
    headerVariants: headerVariants,
    footerVariants: footerVariants,
    titlePage: OfficeDocxCodec.titlePageOf(snapshot),
    evenAndOddHeaders: OfficeDocxCodec.evenAndOddHeadersOf(snapshot),
  );
  final graph = composer.compose(document);
  final pdf = OfficePdfService(title: name, fonts: library.fontSet)
      .fromPageGraph(graph)
      .bytes;

  final outPath = '$outDir/${name.replaceAll(RegExp(r'\.docx$'), '')}.ours.pdf';
  File(outPath).writeAsBytesSync(pdf);
  stdout.writeln('nosso PDF: $outPath');

  var failures = 0;
  final reference = File(target.pdf);
  final referencePages =
      reference.existsSync() ? await _pdfPages(reference.path) : null;
  stdout.writeln('páginas — nosso: ${graph.pages.length}'
      '${referencePages == null ? '' : '  Word: ${referencePages.length}'}');
  if (referencePages == null) {
    stderr.writeln('sem PDF de referência (${target.pdf}) — só a contagem '
        'própria foi verificada');
    return failures;
  }
  if (graph.pages.length != referencePages.length) failures++;

  final ourPages = await _pdfPages(outPath);
  if (ourPages == null) {
    stderr.writeln('pdftotext indisponível: comparação de texto pulada');
    return failures;
  }

  final limit = pageLimit > 0
      ? pageLimit
      : (ourPages.length < referencePages.length
          ? ourPages.length
          : referencePages.length);
  var mismatches = 0;
  for (var i = 0; i < limit; i++) {
    final ours = _words(ourPages[i]);
    final theirs = _words(referencePages[i]);
    final missing = theirs.where((w) => !ours.contains(w)).toList();
    final extra = ours.where((w) => !theirs.contains(w)).toList();
    if (missing.isEmpty && extra.isEmpty) continue;
    mismatches++;
    if (mismatches <= 6) {
      stdout.writeln('página ${i + 1}:');
      if (missing.isNotEmpty) {
        stdout.writeln('  faltando (${missing.length}): '
            '${missing.take(12).join(' · ')}');
      }
      if (extra.isNotEmpty) {
        stdout.writeln('  sobrando (${extra.length}): '
            '${extra.take(12).join(' · ')}');
      }
    }
  }
  stdout.writeln('páginas com texto divergente: $mismatches de $limit');
  if (mismatches > 0) failures++;
  return failures;
}

/// O texto de cada página, via `pdftotext`. Null quando a ferramenta não
/// existe no ambiente.
Future<List<String>?> _pdfPages(String path) async {
  try {
    final result = await Process.run(
      'pdftotext',
      ['-layout', '-enc', 'UTF-8', path, '-'],
      stdoutEncoding: const Utf8Codec(allowMalformed: true),
    );
    if (result.exitCode != 0) return null;
    // \f é o separador de página do pdftotext; a última quebra sobra vazia.
    final pages = '${result.stdout}'.split('\f');
    if (pages.isNotEmpty && pages.last.trim().isEmpty) pages.removeLast();
    return pages;
  } on ProcessException {
    return null;
  }
}

/// As PALAVRAS de uma página, normalizadas.
///
/// A comparação é por conjunto de palavras, não por linha: quebra de linha,
/// espaçamento e hifenização dependem de métricas de fonte que não são
/// (e não pretendem ser) idênticas às do Word. O que TEM de bater é o
/// conteúdo que caiu naquela folha.
Set<String> _words(String page) {
  final normalized = page
      // Hifenização: "efici-\nência" e "eficiên-\ncia" são a MESMA palavra
      // partida em pontos diferentes. Onde o Word e o editor quebram uma
      // palavra depende do dicionário e das métricas da fonte, e o plano já
      // aceita essa diferença — juntar antes de comparar é o que faz o
      // diagnóstico apontar conteúdo que migrou de página, que é o defeito
      // real.
      .replaceAllMapped(RegExp(r'(\w)-[ \t]*\r?\n[ \t]*(\w)'),
          (m) => '${m[1]}${m[2]}')
      .replaceAll(RegExp(r'[   ]'), ' ')
      .replaceAll(RegExp(r'[“”„]'), '"')
      .replaceAll(RegExp(r"[‘’]"), "'")
      .replaceAll('­', '');
  return {
    for (final raw in normalized.split(RegExp(r'\s+')))
      if (raw.replaceAll(RegExp(r'[^\wÀ-ÿ%º°/–—-]'), '').isNotEmpty)
        raw.replaceAll(RegExp(r'^[^\wÀ-ÿ]+|[^\wÀ-ÿ%]+$'), '').toLowerCase()
  }..remove('');
}
