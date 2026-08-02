// --- Lexer.dart ---
import 'dart:convert';
import 'listener/table_better.dart';

import 'line.dart';
import 'listener.dart';

// Listeners (ajuste conforme seu projeto)
import 'listener/align.dart';
import 'listener/background_color.dart';
import 'listener/blockquote.dart';
import 'listener/bold.dart';
import 'listener/code_block.dart';
import 'listener/color.dart';
import 'listener/font.dart';
import 'listener/header_image.dart';
import 'listener/heading.dart';
import 'listener/image.dart';
import 'listener/italic.dart';
import 'listener/link.dart';
import 'listener/lists.dart';
// import 'listener/mention.dart'; // deixe comentado se não existir
import 'listener/script.dart';
import 'listener/size.dart';
import 'listener/strike.dart';
import 'listener/table.dart';
import 'listener/text.dart';
import 'listener/underline.dart';
import 'listener/video.dart';

/// "Lexer" Delta Parser (porta do nadar/quill-delta-parser).
class DeltaToHtmlConverter {
  /// No delta do Quill, newline é sempre "\n".
  static const String DELTA_EOL = "\n";

  /// Marcador interno para facilitar debug (mesmo do PHP).
  static const String NEWLINE_EXPRESSION = '<!-- <![CDATA[NEWLINE]]> -->';

  /// Se true, escapará entradas antes de compor com HTML.
  bool escapeInput = true;

  /// Modo debug (alinha com o PHP; a aplicação dos listeners que gravam debug fica a cargo deles).
  bool debug = false;

  /// JSON de entrada (String ou estrutura já decodificada).
  final dynamic _json;

  /// Linhas produzidas a partir dos ops.
  List<Line> _lines = [];

  /// listeners[type][priority][ClassType] = instance
  final Map<int, Map<int, Map<Type, Listener>>> _listeners = {
    Listener.TYPE_INLINE: {
      Listener.PRIORITY_EARLY_BIRD: <Type, Listener>{},
      Listener.PRIORITY_GARBAGE_COLLECTOR: <Type, Listener>{},
    },
    Listener.TYPE_BLOCK: {
      Listener.PRIORITY_EARLY_BIRD: <Type, Listener>{},
      Listener.PRIORITY_GARBAGE_COLLECTOR: <Type, Listener>{},
    },
  };

  DeltaToHtmlConverter(dynamic json, [bool loadBuiltinListeners = true])
      : _json = json {
    if (loadBuiltinListeners) {
      this.loadBuiltinListeners();
    }
  }

  /// Carrega listeners padrão (mesma ordem do PHP).
  void loadBuiltinListeners() {
    // inline…
    registerListener(Image());
    registerListener(HeaderImage());
    registerListener(Bold());
    registerListener(Italic());
    registerListener(Color());
    registerListener(BackgroundColor());
    registerListener(Font());
    registerListener(Size());
    registerListener(Link());
    registerListener(Video());
    registerListener(Strike());
    registerListener(Underline());

    // block (early bird)
    registerListener(Heading());
    registerListener(CodeBlock());
    registerListener(Lists());
    registerListener(Blockquote());
    registerListener(Script());

    // >>> Table tem que vir ANTES de Align/Text <<<
    registerListener(Table());
    registerListener(TableBetter());

    registerListener(Align());

    // garbage collector
    registerListener(Text());
  }

  /// Registra um listener dentro do bucket [type]/[priority].
  void registerListener(Listener listener) {
    _listeners[listener.type]![listener.priority]![listener.runtimeType] =
        listener;
  }

  /// Substitui um listener por outro mantendo o mesmo "slot" (type/priority/Type).
  void overwriteListener(Listener listener, Listener newListener) {
    _listeners[listener.type]![listener.priority]![listener.runtimeType] =
        newListener;
  }

  /// Obtém o JSON como estrutura (Map/List).
  dynamic _getJsonData() => (_json is String) ? decodeJson(_json) : _json;

  /// Retorna a lista de ops (ou o array bruto, se já vier nesse formato).
  List<dynamic> getOps() {
    final data = _getJsonData();
    if (data is Map && data.containsKey('ops')) {
      return (data['ops'] as List).cast<dynamic>();
    }
    if (data is List) return data;
    return const [];
  }

  /// Linha por índice (ou null).
  Line? getLine(int index) =>
      (index >= 0 && index < _lines.length) ? _lines[index] : null;

  /// Todas as linhas.
  List<Line> getLines() => _lines;

  /// Converte ops em linhas (espelha a lógica do PHP).
  List<Line> _opsToLines(List<dynamic> ops) {
    final lines = <Line>[];
    var i = 0;
    Line? previousLine;

    for (final delta in ops) {
      if (delta is! Map || !delta.containsKey('insert')) continue;

      final replaced = _replaceNewlineWithExpression(delta['insert']);
      final attributes =
          (delta['attributes'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      // Linha vazia contendo apenas newline
      if (replaced is String && replaced == NEWLINE_EXPRESSION) {
        final line = Line(i, '', attributes, this, true, true);
        if (previousLine != null) {
          line.prevLine = previousLine;
          previousLine.nextLine = line;
        }
        lines.add(line);
        previousLine = line;
        i++;
        continue;
      }

      // Normaliza insert para String (embeds -> JSON)
      final normalizedInsert = _normalizeInsert(replaced);

      // Remove somente o newline do final (se houver)
      final lineInput = _removeLastNewline(normalizedInsert);

      final hasEndNewline = (lineInput != normalizedInsert);

      // ATENÇÃO: no PHP o teste é no ORIGINAL (normalizedInsert), não no lineInput:
      final hadAnyNewlineInOriginal =
          normalizedInsert.contains(NEWLINE_EXPRESSION);

      // Particiona por newlines internos (já com o do final removido)
      final parts = lineInput.split(NEWLINE_EXPRESSION);
      final count = parts.length;

      for (var index = 0; index < count; index++) {
        final value = parts[index];
        final isLast = (index + 1) == count;
        final hadEndNewlineForThis = isLast && hasEndNewline;

        // Replica a regra mutável do PHP de forma funcional:
        // se havia NEWLINE em algum lugar, mas este for o último item e NÃO havia newline final,
        // o "hasNewline" para a última linha vira false.
        final currentHasNewline =
            hadAnyNewlineInOriginal && !(isLast && !hasEndNewline);

        final line = Line(i, value, attributes, this, hadEndNewlineForThis,
            currentHasNewline);

        if (previousLine != null) {
          line.prevLine = previousLine;
          previousLine.nextLine = line;
        }
        lines.add(line);
        previousLine = line;
        i++;
      }
    }

    return lines;
  }

  /// Substitui "\n" por NEWLINE_EXPRESSION em Strings; mantém embeds intactos.
  dynamic _replaceNewlineWithExpression(dynamic input) {
    if (input is String) {
      return input.replaceAll(DELTA_EOL, NEWLINE_EXPRESSION);
    }
    return input; // arrays/embeds passam direto (como no PHP)
  }

  /// Se não for String (embed), serializa para JSON.
  String _normalizeInsert(dynamic insert) {
    if (insert is String) return insert;
    return jsonEncode(insert);
  }

  /// Remove o NEWLINE_EXPRESSION apenas no final da String.
  String _removeLastNewline(String insert) {
    if (insert.endsWith(NEWLINE_EXPRESSION)) {
      return insert.substring(0, insert.length - NEWLINE_EXPRESSION.length);
    }
    return insert;
  }

  void _processListeners(Line line, int type) {
    final buckets = _listeners[type]!;
    // A ordem dos maps literais preserva: EARLY_BIRD -> GARBAGE_COLLECTOR
    for (final byPriority in buckets.values) {
      for (final listener in byPriority.values) {
        listener.process(line);
      }
    }
  }

  void _renderListeners(int type) {
    final buckets = _listeners[type]!;
    for (final byPriority in buckets.values) {
      for (final listener in byPriority.values) {
        listener.render(this);
      }
    }
  }

  /// Rende o HTML para o delta atual.
  String render() {
    // H7: um Delta que não termina em '\n' derrubava a conversão inteira —
    // os listeners inline exigem um terminador de bloco depois deles. Todo
    // documento Quill termina em newline; um que chegue sem (recorte de op,
    // dado antigo) ganha o terminador em vez de uma exceção.
    final ops = List<dynamic>.of(getOps());
    final last = ops.isEmpty ? null : ops.last;
    final lastInsert = last is Map ? last['insert'] : null;
    if (ops.isNotEmpty &&
        (lastInsert is! String || !lastInsert.endsWith(DELTA_EOL))) {
      ops.add(<String, dynamic>{'insert': DELTA_EOL});
    }
    _lines = _opsToLines(ops);

    for (final line in _lines) {
      _processListeners(line, Listener.TYPE_INLINE);
      _processListeners(line, Listener.TYPE_BLOCK);
    }

    _renderListeners(Listener.TYPE_INLINE);
    _renderListeners(Listener.TYPE_BLOCK);

    final buff = StringBuffer();
    for (final line in _lines) {
      buff.write(line.output);
    }
    return buff.toString();
  }

  /// Verifica “parece JSON”.
  static bool isJson(dynamic value) {
    if (value is! String || value.isEmpty) return false;
    final first = value[0];
    if (first != '{' && first != '[') return false;
    try {
      jsonDecode(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Decodifica JSON (Map/List).
  static dynamic decodeJson(String json) => jsonDecode(json);

  /// Escapa texto para contexto HTML (simples; pode re-escapar entidades já escapadas).
  String escape(String value) {
    if (!escapeInput) return value;
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
