/// O diálogo "Parágrafo…" do Word.
///
/// Só expõe o que o COMPOSITOR realmente honra — a lista foi conferida em
/// `layout_composer.dart` (`_resolvedStyleOf`): alinhamento, recuos,
/// espaçamento antes/depois, entrelinha (`lineTwips` + `lineRule`),
/// `contextualSpacing`, e o trio de quebra (`keepNext`, `keepLines`,
/// `widowControl`) mais `pageBreakBefore`. Um controle a mais, que gravasse
/// um atributo que o layout ignora, seria uma caixinha que não muda nada —
/// pior que uma caixinha ausente.
library;

import '../controller.dart';
import '../ribbon_actions.dart' as actions;
import 'dialog.dart';

/// Nomes da entrelinha do Word e o `lineRule`/`lineTwips` de cada um.
///
/// A escada de VALORES vem de `actions.officeLineSpacingSteps`, a mesma que
/// alimenta o dropdown "Espaçamento entre Linhas e Parágrafos" da ribbon —
/// duas tabelas para a mesma propriedade acabariam divergindo, e o diálogo
/// mostraria "Simples" num parágrafo que a ribbon deixou em 1,15. Aqui só os
/// RÓTULOS mudam, porque o diálogo do Word nomeia os três clássicos.
///
/// A regra é sempre `auto`: nela 240 é UM múltiplo de linha, não uma
/// distância. `exact`/`atLeast` são outro controle (o campo "Em", que ainda
/// não existe) e não podem compartilhar a mesma caixa de seleção.
final Map<String, ({String rule, int twips})> officeLineSpacings = {
  for (final step in actions.officeLineSpacingSteps)
    _lineSpacingLabel(step.label): (rule: 'auto', twips: step.twips),
};

String _lineSpacingLabel(String step) => switch (step) {
      '1,0' => 'Simples',
      '1,5' => '1,5 linha',
      '2,0' => 'Duplo',
      _ => step,
    };

/// Abre o diálogo para os blocos da seleção.
void openParagraphDialog(OfficeWordController controller) {
  final style = controller.currentBlockStyle();
  double cm(String key) {
    final value = style?[key];
    return value is num ? value.toDouble() / 567 : 0;
  }

  double points(String key) {
    final value = style?[key];
    return value is num ? value.toDouble() / 20 : 0;
  }

  String currentSpacing() {
    final twips = style?['lineTwips'];
    if (twips is! num) return 'Simples';
    for (final entry in officeLineSpacings.entries) {
      if (entry.value.twips == twips.toInt()) return entry.key;
    }
    return 'Simples';
  }

  String flag(String key) => style?[key] == true ? 'true' : 'false';

  String number(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);

  OfficeDialog(
    controller: controller,
    title: 'Parágrafo',
    fields: [
      OfficeDialogField(
        key: 'align',
        label: 'Alinhamento',
        kind: 'select',
        options: const ['Esquerda', 'Centralizado', 'Direita', 'Justificado'],
        value: switch (style?['align']) {
          'center' => 'Centralizado',
          'right' => 'Direita',
          'justify' => 'Justificado',
          _ => 'Esquerda',
        },
      ),
      OfficeDialogField(
        key: 'indentLeft',
        label: 'Recuo à esquerda',
        kind: 'number',
        step: '0.25',
        min: '0',
        value: number(cm('indentTwips')),
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'indentRight',
        label: 'Recuo à direita',
        kind: 'number',
        step: '0.25',
        min: '0',
        value: number(cm('rightIndentTwips')),
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'indentFirst',
        label: 'Recuo da primeira linha',
        kind: 'number',
        step: '0.25',
        value: number(cm('firstLineIndentTwips')),
        hint: 'cm — negativo produz o recuo deslocado do Word',
      ),
      OfficeDialogField(
        key: 'spaceBefore',
        label: 'Espaçamento antes',
        kind: 'number',
        step: '2',
        min: '0',
        value: number(points('spaceBeforeTwips')),
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'spaceAfter',
        label: 'Espaçamento depois',
        kind: 'number',
        step: '2',
        min: '0',
        value: number(points('spaceAfterTwips')),
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'lineSpacing',
        label: 'Entrelinha',
        kind: 'select',
        options: officeLineSpacings.keys.toList(),
        value: currentSpacing(),
      ),
      OfficeDialogField(
        key: 'contextualSpacing',
        label: 'Não adicionar espaço entre parágrafos do mesmo estilo',
        kind: 'check',
        value: flag('contextualSpacing'),
      ),
      OfficeDialogField(
        key: 'widowControl',
        label: 'Controle de linhas órfãs/viúvas',
        kind: 'check',
        value: style?['widowControl'] == false ? 'false' : 'true',
      ),
      OfficeDialogField(
        key: 'keepNext',
        label: 'Manter com o próximo',
        kind: 'check',
        value: flag('keepNext'),
      ),
      OfficeDialogField(
        key: 'keepLines',
        label: 'Manter linhas juntas',
        kind: 'check',
        value: flag('keepLines'),
      ),
      OfficeDialogField(
        key: 'pageBreakBefore',
        label: 'Quebra de página antes',
        kind: 'check',
        value: flag('pageBreakBefore'),
      ),
    ],
    onApply: (values) {
      int twipsFromCm(String key) {
        final parsed =
            double.tryParse((values[key] ?? '').replaceAll(',', '.')) ?? 0;
        return (parsed * 567).round();
      }

      int twipsFromPoints(String key) {
        final parsed =
            double.tryParse((values[key] ?? '').replaceAll(',', '.')) ?? 0;
        return (parsed * 20).round();
      }

      final spacing = officeLineSpacings[values['lineSpacing']] ??
          officeLineSpacings['Simples']!;
      // UMA transação com tudo: desfazer volta o parágrafo inteiro, não a
      // última caixinha tocada.
      controller.applyBlockStyle({
        'align': switch (values['align']) {
          'Centralizado' => 'center',
          'Direita' => 'right',
          'Justificado' => 'justify',
          _ => 'left',
        },
        'indentTwips': twipsFromCm('indentLeft'),
        'rightIndentTwips': twipsFromCm('indentRight'),
        'firstLineIndentTwips': twipsFromCm('indentFirst'),
        'spaceBeforeTwips': twipsFromPoints('spaceBefore'),
        'spaceAfterTwips': twipsFromPoints('spaceAfter'),
        'lineTwips': spacing.twips,
        'lineRule': spacing.rule,
        'contextualSpacing': values['contextualSpacing'] == 'true',
        'widowControl': values['widowControl'] == 'true',
        'keepNext': values['keepNext'] == 'true',
        'keepLines': values['keepLines'] == 'true',
        'pageBreakBefore': values['pageBreakBefore'] == 'true',
      });
    },
  ).open();
}
