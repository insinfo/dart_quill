// --- align.dart ---
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

/// Converte o atributo de alinhamento em <p style="text-align: ...">
class Align extends BlockListener {
  /// Alinhamentos suportados (compatível com Quill).
  final List<String> alignments = ['center', 'right', 'justify', 'left'];

  @override
  void process(Line line) {
    // já tratado por outro listener (ex.: Table, Heading, etc.)
    if (line.isDone()) return;

    // não alinhar células de tabela (o listener Table cuida disso)
    if (line.getAttribute('table') != null) return;

    // não alinhar itens de lista (o listener Lists cuida do bloco)
    if (line.getAttribute('list') != null) return;

    final alignAttr = line.getAttribute('align');
    if (alignAttr is String && alignments.contains(alignAttr)) {
      pick(line, {'alignment': alignAttr});
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    // validação defensiva (evita injeção/valores fora da whitelist)
    for (final p in picks) {
      final a = p.optionValue('alignment');
      if (a is! String || !alignments.contains(a)) {
        throw Exception('An unknown alignment "$a" has been detected.');
      }
    }

    // envolve os blocos alinhados em <p style="text-align: {alignment};">...</p>
    wrapElement(
      '<p style="text-align: {alignment};">{__buffer__}</p>',
      simpleOptions: ['alignment'],
    );
  }
}
