// --- align.dart ---
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';
import '../models/pick.dart';

/// Converte os atributos de bloco de parágrafo — `align`, `indent` e
/// `direction` (H5) — num único `<p>` com estilo inline.
///
/// Um listener só por atributo não funcionaria: cada linha é consumida por
/// UM listener de bloco (`setDone`), então "align + indent" na mesma linha
/// perderia um dos dois. Aqui os três compõem o mesmo `<p>`.
class Align extends BlockListener {
  /// Alinhamentos suportados (compatível com Quill).
  final List<String> alignments = ['center', 'right', 'justify', 'left'];

  /// Recuo por nível, como o CSS do editor (`ql-indent-N` = N × 3em).
  static const int _indentStepEm = 3;

  @override
  void process(Line line) {
    // já tratado por outro listener (ex.: Table, Heading, etc.)
    if (line.isDone()) return;

    // não alinhar células de tabela (o listener Table cuida disso)
    if (line.getAttribute('table') != null) return;

    // não alinhar itens de lista (o listener Lists cuida do bloco)
    if (line.getAttribute('list') != null) return;

    final alignAttr = line.getAttribute('align');
    final indentAttr = line.getAttribute('indent');
    final directionAttr = line.getAttribute('direction');

    final hasAlign = alignAttr is String && alignments.contains(alignAttr);
    final indent = indentAttr is int
        ? indentAttr
        : int.tryParse('${indentAttr ?? ''}') ?? 0;
    final isRtl = directionAttr == 'rtl';

    if (hasAlign || indent > 0 || isRtl) {
      pick(line, {
        if (hasAlign) 'alignment': alignAttr,
        if (indent > 0) 'indent': indent,
        if (isRtl) 'direction': 'rtl',
      });
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    // validação defensiva (evita injeção/valores fora da whitelist)
    for (final p in picks) {
      final a = p.optionValue('alignment');
      if (a != null && (a is! String || !alignments.contains(a))) {
        throw Exception('An unknown alignment "$a" has been detected.');
      }
    }

    wrapElement(
      '<p{dir} style="{style}">{__buffer__}</p>',
      callbackOptions: {
        'dir': (Object? _, Pick pick, String __) =>
            pick.optionValue('direction') == 'rtl' ? ' dir="rtl"' : '',
        'style': (Object? _, Pick pick, String __) {
          final buffer = StringBuffer();
          final alignment = pick.optionValue('alignment');
          if (alignment is String) {
            buffer.write('text-align: $alignment;');
          }
          final indent = pick.optionValue('indent');
          if (indent is int && indent > 0) {
            // Espelha o editor: rtl recua pela direita.
            final side =
                pick.optionValue('direction') == 'rtl' ? 'right' : 'left';
            if (buffer.isNotEmpty) buffer.write(' ');
            buffer.write('padding-$side: ${indent * _indentStepEm}em;');
          }
          return buffer.toString();
        },
      },
    );
  }
}
