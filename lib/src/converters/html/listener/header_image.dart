// listener/header_image.dart
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

/// Converte o embed 'headerImage' para a tag <img> correspondente.
class HeaderImage extends BlockListener {
  @override
  void process(Line line) {
    final embedUrl = line.insertJsonKey('headerImage');
    if (embedUrl != null) {
      // "Pega" esta linha para si, armazenando a URL da imagem.
      pick(line, {'url': embedUrl});
      // Marca a linha como processada para que outros listeners (como o de texto) a ignorem.
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    if (picks.isEmpty) return;
    for (final p in picks) {
      final url = p.optionValue('url')?.toString() ?? '';
      if (url.isNotEmpty) {
        final escapedUrl = lexer.escape(url);
        // Gera o mesmo HTML que o Blot do JavaScript, com a mesma classe CSS.
        p.line.output =
            '<div class="ql-header-image" ><img src="$escapedUrl" style="height: 60px;" alt="Cabeçalho"></div>';
        p.line.setDone();
      }
    }
  }
}
