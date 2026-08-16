/// Opções públicas do editor Word ([OfficeWordEditor]).
library;

import '../layout/fonts.dart';
import '../layout/page_graph.dart';
import '../office/font_library.dart';
import '../view/editor_view.dart';

/// O modo de apresentação do editor.
enum OfficeWordMode {
  /// Somente leitura, paginado. Sem ribbon, sem régua, sem caret.
  view,

  /// Edição contínua sem paginação visível — o modo rascunho.
  flow,

  /// A experiência Word completa.
  word,
}

/// Configuração do componente.
class OfficeWordEditorOptions {
  const OfficeWordEditorOptions({
    this.mode = OfficeWordMode.word,
    this.setup = const PageSetupTwips(),
    this.headerText,
    this.footerText,
    this.zoom = 1.0,
    this.virtualization = const OfficeVirtualization(radius: 3),
    this.title = 'Documento',
    this.showTitleBar = false,
    this.fonts = const LayoutFontSet([]),
    this.fontLoader,
    this.progressivePagination,
    this.spellcheck = false,
  });

  final OfficeWordMode mode;
  final PageSetupTwips setup;

  /// Texto do cabeçalho/rodapé repetido em toda página. Aceita os campos
  /// `{PAGE}` e `{NUMPAGES}`.
  final String? headerText;
  final String? footerText;

  /// Escala inicial (1.0 = 100%).
  final double zoom;

  final OfficeVirtualization? virtualization;

  /// Nome do documento, mostrado na title bar (quando habilitada).
  final String title;

  /// Title bar própria do componente. DESLIGADA por padrão: a aplicação
  /// hospedeira normalmente já tem a sua, e duas barras de título é o erro
  /// clássico de componente embarcado.
  final bool showTitleBar;

  /// Faces fornecidas pela aplicação para medição e embedding no PDF.
  ///
  /// Aliases OOXML também são respeitados: uma face `Calibri`, por exemplo,
  /// atende um run `Ecofont_Spranq_eco_Sans` que declare Calibri como fallback.
  /// Sem faces, o editor usa as métricas compactas e o PDF standard-14.
  final LayoutFontSet fonts;

  /// De onde vêm as faces que o DOCUMENTO pede, sob demanda.
  ///
  /// [fonts] resolve o caso em que a aplicação já tem os bytes na mão; este
  /// resolve o caso real: só depois de abrir o DOCX se sabe que ele usa
  /// "Ecofont_Spranq_eco_Sans" em negrito. O editor varre o documento (corpo,
  /// cabeçalhos, rodapés e caixas de texto), pede ao loader apenas as
  /// combinações que existem, e recompõe UMA vez quando as faces chegam.
  ///
  /// O pacote não faz rede nem lê arquivos: quem busca é a aplicação. Um
  /// `null` de volta significa "não tenho", é memorizado, e o editor segue
  /// com a métrica compatível.
  ///
  /// ```dart
  /// options: OfficeWordEditorOptions(
  ///   fontLoader: (request) async {
  ///     for (final family in [request.family, ...request.aliases]) {
  ///       final bytes = await meuFetch('fonts/$family${request.variantSuffix}.ttf');
  ///       if (bytes != null) return bytes;
  ///     }
  ///     return null;
  ///   },
  /// )
  /// ```
  final OfficeFontLoader? fontLoader;

  /// Liga a paginação progressiva na abertura de documentos. Null (padrão)
  /// compõe todas as páginas antes da primeira projeção — o comportamento
  /// determinístico que os testes e integrações existentes esperam.
  final OfficeProgressivePagination? progressivePagination;

  /// Verificação ortográfica NATIVA do browser na superfície editável.
  ///
  /// Desligada por padrão porque a decisão depende do browser em que o
  /// produto roda, e só o hospedeiro sabe disso: aceitar uma sugestão do
  /// menu do corretor chega como `beforeinput/insertReplacementText`, que o
  /// WebKit entrega NÃO cancelável — e um evento não cancelável é o browser
  /// escrevendo na projeção por baixo do modelo. Em Chromium e Gecko o
  /// evento é cancelável e a correção entra como transação normal.
  ///
  /// O sublinhado em si é seguro em qualquer browser: é pintura, não DOM.
  final bool spellcheck;
}
