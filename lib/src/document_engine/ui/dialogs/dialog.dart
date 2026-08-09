/// A base dos diálogos do editor (Fonte…, Parágrafo…, Propriedades…).
///
/// Um diálogo é a saída para o que NÃO cabe na ribbon: as dezenas de
/// propriedades que o usuário ajusta de uma vez, vê juntas e confirma ou
/// descarta em bloco. Duas decisões definem este componente:
///
/// * **Confirmar/Cancelar é atômico.** O diálogo NÃO aplica nada enquanto o
///   usuário mexe nos campos; ele junta tudo e emite UMA transação no OK.
///   Aplicar campo a campo encheria o histórico de undo de passos que o
///   usuário nunca pediu — no Word, desfazer depois de "Parágrafo… → OK"
///   volta o parágrafo inteiro, não a última caixinha tocada.
/// * **Vive no overlay**, como todo popup: mesma camada, mesmo z-index,
///   mesma regra de Esc. A diferença é que o diálogo é MODAL — um véu cobre
///   o editor e o clique fora não fecha, porque fechar sem querer no meio de
///   um formulário perde o que já foi preenchido.
library;

import '../../../platform/dom.dart';
import '../controller.dart';
import '../overlay.dart';

/// Grupo de popup dos diálogos: abrir um fecha o anterior.
const String officeDialogGroup = 'dialog';

/// Um campo do formulário, para os diálogos declararem em vez de montar DOM.
class OfficeDialogField {
  const OfficeDialogField({
    required this.key,
    required this.label,
    required this.kind,
    this.value = '',
    this.options = const [],
    this.step,
    this.min,
    this.max,
    this.hint,
  });

  final String key;
  final String label;

  /// `text`, `number`, `select` ou `check`.
  final String kind;

  /// Valor inicial (para `check`, `'true'`/`'false'`).
  final String value;

  /// Opções de um `select`.
  final List<String> options;

  final String? step;
  final String? min;
  final String? max;

  /// Texto pequeno abaixo do campo, para a unidade ou uma ressalva.
  final String? hint;
}

/// Um diálogo modal montado no overlay.
class OfficeDialog {
  OfficeDialog({
    required this.controller,
    required this.title,
    required this.fields,
    required this.onApply,
  }) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final String title;
  final List<OfficeDialogField> fields;

  /// Chamado UMA vez, no OK, com todos os valores. Cancelar não chama nada.
  final void Function(Map<String, String> values) onApply;

  final OfficeDomKit _kit;
  final Map<String, DomElement> _inputs = {};
  OfficePopupHandle? _handle;

  bool get isOpen => _handle?.isOpen ?? false;

  void open() {
    controller.overlay.closeAll();
    final veil = _kit.el('div', 'dq-office-dialog-veil');
    final dialog = _kit.el('div', 'dq-office-dialog');
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');

    final header = _kit.el('div', 'dq-office-dialog-title');
    header.appendText(title);
    dialog.append(header);

    final body = _kit.el('div', 'dq-office-dialog-body');
    for (final field in fields) {
      body.append(_buildField(field));
    }
    dialog.append(body);

    final footer = _kit.el('div', 'dq-office-dialog-footer');
    footer.append(_kit.button('Cancelar', 'Cancelar', close,
        extraClass: 'dq-office-dialog-button'));
    footer.append(_kit.button('OK', 'Aplicar', _apply,
        extraClass: 'dq-office-dialog-button dq-office-dialog-primary'));
    dialog.append(footer);

    // O véu ENGOLE o clique: um formulário meio preenchido não pode se
    // perder porque o ponteiro escorregou para fora.
    veil.addEventListener('pointerdown', (event) => event.preventDefault());
    veil.addEventListener('click', (event) => event.preventDefault());
    veil.append(dialog);

    _handle = controller.overlay.open(
      officeDialogGroup,
      veil,
      placement: OfficePopupPlacement.atPoint,
      x: 0,
      y: 0,
      extraClass: 'dq-office-dialog-popup',
    );
  }

  void close() {
    controller.overlay.closeGroup(officeDialogGroup);
    _handle = null;
    _inputs.clear();
  }

  void _apply() {
    final values = <String, String>{};
    _inputs.forEach((key, element) {
      values[key] = element.value;
    });
    close();
    // A seleção é ressincronizada ANTES de aplicar: o usuário passou pelo
    // formulário, e o comando tem de agir em onde ele estava, não onde o
    // modelo parou.
    controller.syncSelection();
    onApply(values);
  }

  DomElement _buildField(OfficeDialogField field) {
    final wrap = _kit.el('label', 'dq-office-dialog-field');
    final caption = _kit.el('span', 'dq-office-dialog-label');
    caption.appendText(field.label);
    wrap.append(caption);

    late final DomElement input;
    switch (field.kind) {
      case 'select':
        input = _kit.el('select', 'dq-office-dialog-input');
        for (final option in field.options) {
          final item = _kit.el('option', '');
          item.setAttribute('value', option);
          if (option == field.value) {
            item.setAttribute('selected', 'selected');
          }
          item.appendText(option);
          input.append(item);
        }
        input.value = field.value;
      case 'check':
        input = _kit.el('input', 'dq-office-dialog-check');
        input.setAttribute('type', 'checkbox');
        // Um checkbox devolve `value` fixo; guardamos o estado no próprio
        // atributo para o `_apply` ler de forma uniforme com os outros
        // campos, sem um caminho especial por tipo.
        input.value = field.value;
        input.addEventListener('change', (_) {
          input.value = input.value == 'true' ? 'false' : 'true';
        });
        if (field.value == 'true') input.setAttribute('checked', 'checked');
      case 'number':
        input = _kit.el('input', 'dq-office-dialog-input');
        input.setAttribute('type', 'number');
        if (field.step != null) input.setAttribute('step', field.step!);
        if (field.min != null) input.setAttribute('min', field.min!);
        if (field.max != null) input.setAttribute('max', field.max!);
        input.value = field.value;
      default:
        input = _kit.el('input', 'dq-office-dialog-input');
        input.setAttribute('type', 'text');
        input.value = field.value;
    }
    input.setAttribute('data-field', field.key);
    _inputs[field.key] = input;
    wrap.append(input);

    if (field.hint != null) {
      final hint = _kit.el('span', 'dq-office-dialog-hint');
      hint.appendText(field.hint!);
      wrap.append(hint);
    }
    return wrap;
  }
}
