// --- listener.dart ---
import 'line.dart';
import 'lexer.dart';
import 'models/pick.dart';

/// Listener base (paridade com PHP).
abstract class Listener {
  static const int TYPE_INLINE = 1;
  static const int TYPE_BLOCK = 2;

  static const int PRIORITY_EARLY_BIRD = 1;
  static const int PRIORITY_GARBAGE_COLLECTOR = 2;

  /// Tipo do listener: INLINE (1) ou BLOCK (2)
  int get type;

  /// Prioridade: 1 (early bird) ou 2 (garbage collector)
  int get priority => PRIORITY_EARLY_BIRD;

  /// Processa uma linha (fase 1).
  void process(Line line);

  /// Itens “capturados” na fase de process() para uso em render().
  final List<Pick> _picks = <Pick>[];

  /// Marca a linha como “picked” e armazena com opções.
  void pick(Line line, [Map<String, dynamic> options = const {}]) {
    line.setPicked();
    line.debugInfo('picked by ${runtimeType.toString()}');
    _picks.add(Pick(this, line, options, _picks.length));
  }

  /// Acesso aos picks (paridade com picks(): array em PHP).
  List<Pick> get picks => _picks;

  /// Fase 2: chamada após todos os process().
  void render(DeltaToHtmlConverter lexer) {
    // implementação padrão vazia
  }
}
