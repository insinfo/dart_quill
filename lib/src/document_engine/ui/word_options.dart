/// Opções públicas do editor Word ([OfficeWordEditor]).
library;

import '../layout/fonts.dart';
import '../layout/page_graph.dart';
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
}
