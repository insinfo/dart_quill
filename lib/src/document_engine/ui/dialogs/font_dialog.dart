/// O diálogo "Fonte…" do Word.
///
/// Expõe as marcas que EXISTEM no schema Office (`office/schema.dart`) e que
/// o compositor desenha: família, corpo, negrito, itálico, sublinhado,
/// tachado, sub/sobrescrito, cor e realce. Efeitos que o layout não
/// implementa (versalete, espaçamento entre caracteres) ficam de fora — um
/// controle que grava algo invisível é ruído no formulário.
///
/// Como todo diálogo, aplica em BLOCO no OK: uma passagem só pelo texto
/// selecionado, e um único ponto no histórico de undo.
library;

import '../controller.dart';
import '../ribbon_actions.dart' as actions;
import '../tabs/home_tab.dart' show officeFontFamilies;
import 'dialog.dart';

/// Abre o diálogo para a seleção corrente.
void openFontDialog(OfficeWordController controller) {
  final state = controller.view.state;
  final selection = state.selection;

  bool hasMark(String name) {
    final type = controller.schema.marks[name];
    if (type == null) return false;
    if (selection.empty) {
      final marks = state.storedMarks ?? selection.fromRes.marks();
      return marks.any((mark) => mark.type == type);
    }
    return state.doc.rangeHasMark(selection.from, selection.to, type);
  }

  final family = actions.effectiveInlineValue(controller, 'font') ?? '';
  final size = actions.effectiveInlineValue(controller, 'size') ?? '';
  final script = actions.currentMarkValue(controller, 'script') ?? '';

  // A família efetiva pode não estar na lista (veio de um DOCX): incluí-la
  // evita que abrir o diálogo TROQUE a fonte do texto sem o usuário pedir.
  final families = <String>[
    if (family.isNotEmpty && !officeFontFamilies.contains(family)) family,
    ...officeFontFamilies,
  ];

  OfficeDialog(
    controller: controller,
    title: 'Fonte',
    fields: [
      OfficeDialogField(
        key: 'family',
        label: 'Fonte',
        kind: 'select',
        options: families,
        value: family.isEmpty ? families.first : family,
      ),
      OfficeDialogField(
        key: 'size',
        label: 'Tamanho',
        kind: 'number',
        step: '0.5',
        min: '1',
        max: '1638',
        value: size,
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'bold',
        label: 'Negrito',
        kind: 'check',
        value: hasMark('bold') ? 'true' : 'false',
      ),
      OfficeDialogField(
        key: 'italic',
        label: 'Itálico',
        kind: 'check',
        value: hasMark('italic') ? 'true' : 'false',
      ),
      OfficeDialogField(
        key: 'underline',
        label: 'Sublinhado',
        kind: 'check',
        value: hasMark('underline') ? 'true' : 'false',
      ),
      OfficeDialogField(
        key: 'strike',
        label: 'Tachado',
        kind: 'check',
        value: hasMark('strike') ? 'true' : 'false',
      ),
      OfficeDialogField(
        key: 'script',
        label: 'Posição',
        kind: 'select',
        options: const ['Normal', 'Sobrescrito', 'Subscrito'],
        value: switch (script) {
          'super' => 'Sobrescrito',
          'sub' => 'Subscrito',
          _ => 'Normal',
        },
      ),
      OfficeDialogField(
        key: 'color',
        label: 'Cor da fonte',
        kind: 'text',
        value: actions.currentMarkValue(controller, 'color') ?? '',
        hint: 'vazio = automático; ou #rrggbb',
      ),
      OfficeDialogField(
        key: 'highlight',
        label: 'Realce',
        kind: 'text',
        value: actions.currentMarkValue(controller, 'background') ?? '',
        hint: 'vazio = sem realce; ou #rrggbb',
      ),
    ],
    onApply: (values) => _applyFont(controller, values),
  ).open();
}

/// Aplica TODAS as escolhas numa transação só.
void _applyFont(OfficeWordController controller, Map<String, String> values) {
  final state = controller.view.state;
  final selection = state.selection;
  final tr = state.tr;

  void setMark(String name, bool enabled, [Map<String, dynamic>? attrs]) {
    final type = controller.schema.marks[name];
    if (type == null) return;
    if (selection.empty) {
      if (enabled) {
        tr.addStoredMark(type.create(attrs));
      } else {
        tr.removeStoredMark(type);
      }
      return;
    }
    if (enabled) {
      tr.addMark(selection.from, selection.to, type.create(attrs));
    } else {
      tr.removeMark(selection.from, selection.to, type);
    }
  }

  final family = values['family'] ?? '';
  if (family.isNotEmpty) setMark('font', true, {'value': family});

  final size = double.tryParse((values['size'] ?? '').replaceAll(',', '.'));
  if (size != null && size > 0) {
    final snapped = (size * 2).round() / 2;
    final label =
        snapped == snapped.roundToDouble() ? '${snapped.round()}' : '$snapped';
    setMark('size', true, {'value': '${label}pt'});
  }

  for (final name in const ['bold', 'italic', 'underline', 'strike']) {
    setMark(name, values[name] == 'true');
  }

  switch (values['script']) {
    case 'Sobrescrito':
      setMark('script', true, {'value': 'super'});
    case 'Subscrito':
      setMark('script', true, {'value': 'sub'});
    default:
      setMark('script', false);
  }

  for (final (key, mark) in const [
    ('color', 'color'),
    ('highlight', 'background'),
  ]) {
    final value = (values[key] ?? '').trim();
    setMark(mark, value.isNotEmpty, value.isEmpty ? null : {'value': value});
  }

  // Sem passos não há transação: aplicar "nada mudou" poluiria o undo.
  if (tr.steps.isNotEmpty || tr.storedMarks != null) controller.dispatch(tr);
}

/// Exposto para o teste: os nomes de marca que o diálogo sabe aplicar.
const List<String> officeFontDialogMarks = [
  'font',
  'size',
  'bold',
  'italic',
  'underline',
  'strike',
  'script',
  'color',
  'background',
];
