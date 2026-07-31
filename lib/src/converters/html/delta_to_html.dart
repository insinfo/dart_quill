/// Delta → HTML semântico.
///
/// A saída é HTML de verdade — `<strong>`, `<h1>`, `<ul><li>`, `<table>` — e
/// **não** o markup interno do editor com classes `ql-*`. É a diferença entre
/// um documento que pode ser exibido, guardado e impresso em qualquer lugar e
/// um que só faz sentido dentro do Quill.
library;

import '../../delta/delta.dart';
import 'lexer.dart';

/// Como embrulhar o HTML gerado.
class HtmlConvertOptions {
  const HtmlConvertOptions({
    this.escapeInput = true,
    this.wrapperStyle,
  });

  /// Escapa o texto do documento antes de compor o HTML. Deixar `false` só
  /// faz sentido quando o Delta já contém markup confiável — e confiar em
  /// conteúdo de usuário é como se abre um XSS.
  final bool escapeInput;

  /// Quando presente, o resultado sai dentro de `<div style="...">`.
  ///
  /// Serve ao caso real que motivou este conversor: exibir um despacho não
  /// assinado com a mesma tipografia do editor.
  final String? wrapperStyle;

  /// O estilo que o SALI aplica ao exibir um despacho.
  static const String saliDocumentStyle =
      "font-size: 12pt; font-family: 'Inter', Helvetica, Arial, sans-serif; "
      'line-height: 1.5;';
}

/// Converte [delta] em HTML semântico.
String deltaToHtml(
  Delta delta, {
  HtmlConvertOptions options = const HtmlConvertOptions(),
}) =>
    opsToHtml(delta.toJson(), options: options);

/// Igual a [deltaToHtml], a partir dos ops crus (`List<Map>` de um JSON já
/// decodificado) — o formato em que um Delta chega do banco ou da rede, sem
/// precisar instanciar um [Delta] só para convertê-lo.
String opsToHtml(
  List<dynamic> ops, {
  HtmlConvertOptions options = const HtmlConvertOptions(),
}) {
  final converter = DeltaToHtmlConverter(ops)..escapeInput = options.escapeInput;
  final html = converter.render();
  final style = options.wrapperStyle;
  return style == null ? html : '<div style="$style">$html</div>';
}
