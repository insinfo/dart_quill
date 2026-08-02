/// Geração de PDF **sem browser** — o caminho de backend.
///
/// Requisito de produto, não conveniência: quando alguém pede assinatura de
/// um despacho no SALI, é o BACKEND que converte o documento em PDF e o
/// guarda para preservação permanente. Não há DOM, não há `package:web`,
/// não há Chrome headless — só a Dart VM.
///
/// Isso é possível porque a autoridade de layout deste projeto é o parser
/// TrueType em Dart (`LayoutFontSet`/`FontMetrics`), nunca a medição do
/// browser. É uma decisão com consequência dupla:
///
/// * o mesmo `PageGraph` roda no editor e no servidor, então a página 18 do
///   editor É a página 18 do PDF assinado — a paridade não depende de o
///   servidor ter um navegador;
/// * em troca, a fidelidade tipográfica é a do nosso shaper (etapa latina),
///   não a do motor do Word. O limite está declarado no plano e não deve
///   ser anunciado como paridade universal.
///
/// Para o PDF assinado sair idêntico ao que o usuário viu, o servidor
/// precisa das MESMAS faces de fonte que o editor usou — é o que o
/// parâmetro `fonts` carrega. Sem elas, a medição cai nas métricas
/// embarcadas e as quebras podem diferir.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../layout/fonts.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../layout/pdf_renderer.dart';
import '../model/index.dart';
import 'docx_codec.dart';
import 'quill_codec.dart';
import 'schema.dart';
import 'snapshot.dart';

/// O PDF e o que foi preciso decidir para produzi-lo.
class OfficePdfResult {
  const OfficePdfResult({
    required this.bytes,
    required this.pageCount,
    required this.diagnostics,
  });

  final Uint8List bytes;

  /// Quantas páginas o PDF tem — o mesmo número que o editor mostraria com
  /// a mesma configuração de página e as mesmas fontes.
  final int pageCount;

  /// Avisos do layout (linha maior que a página, fonte ausente…). Vazio não
  /// significa "idêntico ao Word", significa que nada precisou ser forçado.
  final LayoutDiagnostics diagnostics;
}

/// Converte documento do modo avançado em PDF na Dart VM.
class OfficePdfService {
  OfficePdfService({
    this.setup = const PageSetupTwips(),
    this.quality = LayoutQuality.fidelity,
    this.baseFontFamily = 'Arial',
    this.baseFontSizePt = 12,
    this.title = 'Documento',
    LayoutFontSet? fonts,
    Schema? schema,
  })  : fonts = fonts ?? LayoutFontSet(const []),
        schema = schema ?? officeQuillSchema();

  final PageSetupTwips setup;
  final LayoutQuality quality;
  final String baseFontFamily;
  final double baseFontSizePt;
  final String title;

  /// As faces que o editor usou. Passe as mesmas para o PDF bater com a tela.
  final LayoutFontSet fonts;

  final Schema schema;

  /// A partir do JSON persistido (`OfficeDocumentSnapshot`).
  ///
  /// É a entrada do backend: lê a coluna, devolve os bytes do PDF.
  OfficePdfResult fromSnapshotJson(String json) =>
      fromSnapshot(OfficeDocumentSnapshot.fromJson(
          jsonDecode(json) as Map<String, dynamic>));

  /// Do snapshot, USANDO a geometria de página que veio com o documento.
  ///
  /// Um despacho em ofício ou paisagem tem de sair no papel certo. Ignorar
  /// a seção e paginar tudo em A4 produziria um PDF assinado que não
  /// corresponde ao documento — e o erro só apareceria depois de assinado.
  OfficePdfResult fromSnapshot(OfficeDocumentSnapshot snapshot) {
    final graph = LayoutComposer(
      setup: OfficeDocxCodec.pageSetupOf(snapshot),
      // Um anexo em paisagem tem de sair em paisagem no PDF assinado.
      sections: OfficeDocxCodec.pageSetupsOf(snapshot),
      quality: quality,
      baseFontFamily: baseFontFamily,
      baseFontSizePt: baseFontSizePt,
      fonts: fonts,
      // O timbre e a numeração de página fazem parte do documento assinado.
      header: OfficeDocxCodec.regionOf(snapshot.headers, schema),
      footer: OfficeDocxCodec.regionOf(snapshot.footers, schema),
    ).compose(PMNode.fromJSON(schema, snapshot.body));
    return fromPageGraph(graph);
  }

  /// A partir de um Delta Quill do banco — o caso do SALI hoje, antes de o
  /// documento ser promovido para o formato Office.
  ///
  /// Devolve também o relatório de compatibilidade da importação: um
  /// despacho que use algo que não sabemos representar aparece ali em vez
  /// de sumir em silêncio do PDF assinado.
  ({OfficePdfResult pdf, OfficeCompatibilityReport report}) fromQuillDelta(
      List<dynamic> ops) {
    final imported = importQuillDelta(ops, schema);
    return (pdf: fromDocument(imported.doc), report: imported.report);
  }

  /// A partir da árvore já montada.
  OfficePdfResult fromDocument(PMNode doc) {
    final graph = LayoutComposer(
      setup: setup,
      quality: quality,
      baseFontFamily: baseFontFamily,
      baseFontSizePt: baseFontSizePt,
      fonts: fonts,
    ).compose(doc);
    return fromPageGraph(graph);
  }

  /// A partir de um `PageGraph` já composto.
  ///
  /// É este o ponto que garante a paridade: o editor pode ENVIAR o grafo
  /// que já tem, e o PDF sai da mesma composição, sem recompor nada.
  OfficePdfResult fromPageGraph(PageGraph graph) => OfficePdfResult(
        bytes: PageGraphPdfRenderer(title: title, fonts: fonts).render(graph),
        pageCount: graph.pages.length,
        diagnostics: graph.diagnostics,
      );
}
