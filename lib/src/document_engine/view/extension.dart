/// A camada de extensões do modo avançado — Tiptap-INSPIRADA, não portada.
///
/// A decisão arquitetural: o Tiptap não é outro motor documental, é ergonomia
/// sobre o ProseMirror. Portar a biblioteca inteira traria compatibilidade
/// histórica de JavaScript, adaptadores de React/Vue e abstrações que não
/// significam nada em Dart. O que vale é o CONCEITO — configuração
/// declarativa por extensão, com comandos, atalhos e plugins compostos numa
/// lista — e é só isso que existe aqui.
///
/// Uma extensão é a unidade de configuração do editor:
///
/// ```dart
/// OfficeEditorView.withExtensions(
///   host: host,
///   doc: doc,
///   adapter: adapter,
///   extensions: [OfficeHistoryExtension(), OfficeBaseKeymapExtension(),
///                OfficeMarksExtension()],
/// );
/// ```
///
/// Nada aqui expõe nomes ProseMirror/Tiptap na API pública — o plano exige
/// que a fachada seja `Office*` para a evolução interna não ficar presa à
/// API JavaScript de origem.
library;

import '../commands/index.dart' as cmd;
import '../history/history.dart' as history;
import '../model/index.dart';
import '../state/index.dart';

/// Um comando nomeado, invocável pela UI (`view.runCommand('bold')`).
class OfficeCommandEntry {
  const OfficeCommandEntry(this.name, this.command);

  final String name;
  final Command command;
}

/// Uma tecla ligada a um comando.
///
/// A sintaxe segue a convenção do ProseMirror por ser a mais reconhecível:
/// `Mod-b`, `Mod-Shift-z`, `Enter`, `Backspace`, `Alt-ArrowUp`.
class OfficeKeyBinding {
  const OfficeKeyBinding(this.keys, this.command);

  final String keys;
  final Command command;
}

/// Unidade de configuração do editor.
abstract interface class OfficeExtension {
  String get name;
  List<OfficeCommandEntry> get commands;
  List<OfficeKeyBinding> get shortcuts;

  /// Plugins de estado que a extensão precisa instalar (histórico, regras de
  /// entrada, decorações). Entram no `EditorState` na criação.
  List<Plugin> get plugins;
}

/// Base com tudo vazio, para uma extensão declarar só o que usa.
abstract class OfficeExtensionBase implements OfficeExtension {
  const OfficeExtensionBase();

  @override
  List<OfficeCommandEntry> get commands => const [];

  @override
  List<OfficeKeyBinding> get shortcuts => const [];

  @override
  List<Plugin> get plugins => const [];
}

/// Uma tecla normalizada, para comparar o que a extensão declarou com o que
/// o browser entregou.
class _KeyStroke {
  const _KeyStroke({
    required this.key,
    required this.mod,
    required this.shift,
    required this.alt,
  });

  final String key;
  final bool mod;
  final bool shift;
  final bool alt;

  /// Interpreta `Mod-Shift-z` e afins.
  ///
  /// `Mod` casa com Ctrl **ou** Meta deliberadamente: sem essa escolha seria
  /// preciso farejar a plataforma, e farejar erra (Chrome no iPad, teclado
  /// externo, emulação). O custo é Ctrl+B também funcionar no macOS — um
  /// atalho a mais, nunca um atalho errado.
  static _KeyStroke parse(String spec) {
    final parts = spec.split('-');
    var mod = false, shift = false, alt = false;
    for (var i = 0; i < parts.length - 1; i++) {
      switch (parts[i]) {
        case 'Mod' || 'Ctrl' || 'Cmd' || 'Meta':
          mod = true;
        case 'Shift':
          shift = true;
        case 'Alt':
          alt = true;
      }
    }
    return _KeyStroke(
      key: _normalizeKey(parts.last),
      mod: mod,
      shift: shift,
      alt: alt,
    );
  }

  /// Letra vira minúscula (Shift já é modificador explícito); o resto —
  /// `Enter`, `Backspace`, `ArrowLeft` — mantém o nome do browser.
  static String _normalizeKey(String key) =>
      key.length == 1 ? key.toLowerCase() : key;

  @override
  bool operator ==(Object other) =>
      other is _KeyStroke &&
      other.key == key &&
      other.mod == mod &&
      other.shift == shift &&
      other.alt == alt;

  @override
  int get hashCode => Object.hash(key, mod, shift, alt);
}

/// O conjunto resolvido de extensões de um editor.
///
/// Ordem importa: uma extensão POSTERIOR ganha do conflito, para a aplicação
/// conseguir sobrescrever um atalho embutido sem reconstruir a lista base.
class OfficeExtensionSet {
  OfficeExtensionSet(List<OfficeExtension> extensions)
      : _extensions = List.unmodifiable(extensions) {
    for (final extension in _extensions) {
      for (final entry in extension.commands) {
        _commands[entry.name] = entry.command;
      }
      for (final shortcut in extension.shortcuts) {
        _keys[_KeyStroke.parse(shortcut.keys)] = shortcut.command;
      }
    }
  }

  final List<OfficeExtension> _extensions;
  final Map<String, Command> _commands = {};
  final Map<_KeyStroke, Command> _keys = {};

  List<OfficeExtension> get extensions => _extensions;

  List<Plugin> get plugins =>
      [for (final extension in _extensions) ...extension.plugins];

  Iterable<String> get commandNames => _commands.keys;

  Command? command(String name) => _commands[name];

  /// Roda o comando ligado a esta combinação. Devolve true quando ALGUM
  /// comando tratou a tecla — o chamador usa isso para decidir o
  /// `preventDefault`.
  bool handleKey({
    required String key,
    required bool ctrl,
    required bool meta,
    required bool shift,
    required bool alt,
    required EditorState state,
    required void Function(Transaction) dispatch,
  }) {
    final stroke = _KeyStroke(
      key: _KeyStroke._normalizeKey(key),
      mod: ctrl || meta,
      shift: shift,
      alt: alt,
    );
    final command = _keys[stroke];
    if (command == null) return false;
    return command(state, dispatch);
  }
}

// -- extensões embutidas -----------------------------------------------------

/// Undo/redo. O plugin de histórico precisa estar no estado, então esta
/// extensão o fornece junto com os atalhos.
class OfficeHistoryExtension extends OfficeExtensionBase {
  const OfficeHistoryExtension();

  @override
  String get name => 'history';

  @override
  List<Plugin> get plugins => [history.history()];

  @override
  List<OfficeCommandEntry> get commands => [
        OfficeCommandEntry('undo', history.undo),
        OfficeCommandEntry('redo', history.redo),
      ];

  @override
  List<OfficeKeyBinding> get shortcuts => [
        OfficeKeyBinding('Mod-z', history.undo),
        OfficeKeyBinding('Mod-y', history.redo),
        OfficeKeyBinding('Mod-Shift-z', history.redo),
      ];
}

/// As teclas estruturais que NÃO são simples inserção de texto.
///
/// Enter, Backspace e Delete chegam como `beforeinput` e a view já os trata;
/// aqui ficam os comandos que dependem da ESTRUTURA da árvore (juntar
/// blocos, sair de um bloco de código, selecionar o pai) — o que o
/// `beforeinput` sozinho não sabe fazer.
class OfficeBaseKeymapExtension extends OfficeExtensionBase {
  const OfficeBaseKeymapExtension();

  @override
  String get name => 'baseKeymap';

  @override
  List<OfficeCommandEntry> get commands => [
        OfficeCommandEntry('selectAll', cmd.selectAll),
        OfficeCommandEntry('selectParentNode', cmd.selectParentNode),
        OfficeCommandEntry('joinUp', cmd.joinUp),
        OfficeCommandEntry('joinDown', cmd.joinDown),
        OfficeCommandEntry('lift', cmd.lift),
      ];

  @override
  List<OfficeKeyBinding> get shortcuts => [
        OfficeKeyBinding('Mod-a', cmd.selectAll),
        OfficeKeyBinding('Escape', cmd.selectParentNode),
        OfficeKeyBinding('Alt-ArrowUp', cmd.joinUp),
        OfficeKeyBinding('Alt-ArrowDown', cmd.joinDown),
        OfficeKeyBinding('Mod-BracketLeft', cmd.lift),
      ];
}

/// Negrito, itálico, sublinhado, tachado e código — as marcas do perfil
/// Quill que têm atalho consagrado.
class OfficeMarksExtension extends OfficeExtensionBase {
  OfficeMarksExtension(this.schema);

  final Schema schema;

  @override
  String get name => 'marks';

  Command _toggle(String markName) {
    final type = schema.marks[markName];
    if (type == null) return (state, [dispatch, view]) => false;
    return cmd.toggleMark(type);
  }

  @override
  List<OfficeCommandEntry> get commands => [
        for (final mark in const [
          'bold',
          'italic',
          'underline',
          'strike',
          'code',
        ])
          OfficeCommandEntry(mark, _toggle(mark)),
      ];

  @override
  List<OfficeKeyBinding> get shortcuts => [
        OfficeKeyBinding('Mod-b', _toggle('bold')),
        OfficeKeyBinding('Mod-i', _toggle('italic')),
        OfficeKeyBinding('Mod-u', _toggle('underline')),
        OfficeKeyBinding('Mod-Shift-x', _toggle('strike')),
      ];
}

/// O conjunto padrão de um editor Office sobre o perfil Quill.
List<OfficeExtension> officeDefaultExtensions(Schema schema) => [
      const OfficeHistoryExtension(),
      const OfficeBaseKeymapExtension(),
      OfficeMarksExtension(schema),
    ];
