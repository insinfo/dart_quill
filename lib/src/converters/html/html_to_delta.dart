/// HTML → Delta.
///
/// O par de [deltaToHtml]. Serve a dois casos que o editor sozinho não cobre:
/// importar um documento que veio de fora (um `.html` salvo, um e-mail, o
/// corpo de um sistema legado) e converter no backend, onde não há DOM nem
/// editor para colar dentro.
///
/// Diferente do caminho de colagem do editor (`Clipboard.convert`), que
/// trabalha sobre o DOM vivo do navegador, este parseia a string com o package
/// `html` e roda igual na VM e na web.
library;

import '../../delta/delta.dart';
import 'from_html/delta_from_html.dart';

export 'from_html/delta_from_html.dart'
    show HtmlToDelta, HtmlOperations, CustomHtmlPart;

/// Converte [html] em um [Delta].
///
/// [transformTableAsEmbed] decide o que fazer com `<table>`: `false` (padrão)
/// converte célula a célula para os formatos de tabela do editor; `true` a
/// guarda como um embed único.
Delta htmlToDelta(
  String html, {
  bool transformTableAsEmbed = false,
  List<CustomHtmlPart>? customBlocks,
}) =>
    HtmlToDelta(customBlocks: customBlocks)
        .convert(html, transformTableAsEmbed: transformTableAsEmbed);
