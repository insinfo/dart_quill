// --- listener/size.dart ---
import '../inline_listener.dart';
import '../line.dart';

/// Aplica attributes.size como <span style="font-size:...">...</span>.
/// Ex.: { size: "11pt" } -> <span style="font-size:11pt">texto</span>
class Size extends InlineListener {
  @override
  void process(Line line) {
    final raw = line.getAttribute('size');
    if (raw == null) return;

    final css = _normalizeCssSize(raw);
    if (css.isEmpty) return;

    // Envolve o conteúdo e marca a linha como inline + escaped + done.
    updateInput(
        line, '<span style="font-size:$css;">${line.getInput()}</span>');
  }

  /// Aceita '10pt', '16px', '1.2em', '120%' ou número cru (vira pt).
  String _normalizeCssSize(dynamic v) {
    final s = (v?.toString() ?? '').trim().toLowerCase();
    if (s.isEmpty) return '';
    final ok = RegExp(r'^\d+(\.\d+)?(pt|px|em|rem|%)$');
    if (ok.hasMatch(s)) return s;

    final n = num.tryParse(s);
    if (n != null) return '${n}pt'; // padrão “estilo Word”
    return '';
  }
}
