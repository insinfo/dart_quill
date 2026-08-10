/// Os diálogos "Criar Novo Estilo…" e "Modificar Estilo…" (F8).
///
/// A lista de campos foi cortada pela mesma régua do diálogo Parágrafo, e o
/// corte aqui é MAIS estreito porque um estilo tem duas pontas para provar:
///
/// * o compositor precisa honrar a propriedade a partir do BLOCO
///   (`LayoutComposer._resolvedStyleOf` → `_BlockStyle`), já que aplicar um
///   estilo grava `attrs['style']`;
/// * a exportação precisa gravá-la no `<w:style>`
///   (`OfficeStyleCatalog.patchStylesXml`).
///
/// Passam nas duas: família, corpo, negrito, alinhamento, recuos
/// (esquerdo e de primeira linha), espaçamento antes/depois e entrelinha.
///
/// **Não** passam, e por isso NÃO têm controle aqui: cor da fonte, itálico e
/// sublinhado. `_BlockStyle` não tem esses três campos — o compositor só os
/// obtém de MARCAS de run (`_styleOfText`), então um controle de "cor do
/// estilo" gravaria uma definição que a tela ignoraria em todo parágrafo
/// novo. É o botão-que-não-faz-nada que o plano proíbe.
library;

import '../../office/style_catalog.dart';
import '../controller.dart';
import '../ribbon_actions.dart' as actions;
import '../tabs/home_tab.dart' show officeFontFamilies;
import 'dialog.dart';
import 'paragraph_dialog.dart' show officeLineSpacings;

/// Rótulo do select "Baseado em" quando o estilo não herda de ninguém.
const String officeStyleNoBase = '(nenhum)';

/// "Modificar Estilo…" do menu do cartão.
void openModifyStyleDialog(OfficeWordController controller, String styleId) {
  final catalog = controller.styleCatalog;
  final definition = catalog?[styleId];
  if (catalog == null || definition == null) return;
  _open(
    controller,
    catalog,
    title: 'Modificar Estilo',
    name: definition.name,
    basedOn: definition.basedOn,
    formatting: definition.formatting,
    onApply: (name, basedOn, formatting) {
      actions.applyStyleDefinition(
        controller,
        definition.copyWith(
          name: name,
          basedOn: basedOn,
          formatting: formatting,
          preview: actions.officeStylePreviewOf(formatting, definition.preview),
        ),
      );
    },
  );
}

/// "Criar Estilo…" — nasce da formatação do parágrafo do cursor, como o
/// "Criar um Estilo" do Word, e já entra na galeria (`w:qFormat`).
void openCreateStyleDialog(OfficeWordController controller) {
  final catalog = controller.styleCatalog;
  if (catalog == null) return;
  controller.syncSelection();
  final current = actions.styleFormattingOfSelection(controller);
  _open(
    controller,
    catalog,
    title: 'Criar Novo Estilo',
    name: '',
    basedOn: actions.currentStyleId(controller),
    formatting: current,
    onApply: (name, basedOn, formatting) {
      final id = catalog.newIdFor(name);
      final definition = OfficeStyleDefinition(
        id: id,
        name: name,
        type: 'paragraph',
        basedOn: basedOn,
        inGallery: true,
        formatting: formatting,
        preview: actions.officeStylePreviewOf(
            formatting, const OfficeStylePreview()),
      );
      // Primeiro o estilo existe, depois o parágrafo o adota: o inverso
      // gravaria um `w:pStyle` apontando para um estilo que o `styles.xml`
      // ainda não tem.
      actions.applyStyleDefinition(controller, definition);
      actions.applyCatalogStyle(controller, id);
    },
  );
}

void _open(
  OfficeWordController controller,
  OfficeStyleCatalog catalog, {
  required String title,
  required String name,
  required String? basedOn,
  required OfficeStyleFormatting formatting,
  required void Function(
          String name, String? basedOn, OfficeStyleFormatting formatting)
      onApply,
}) {
  // O select de "Baseado em" trabalha com NOMES (é o que o usuário lê) e
  // devolve ids pelo caminho inverso — dois estilos podem ter o mesmo nome
  // em documentos mal formados, então a última ocorrência ganha, como no
  // Word.
  final baseNames = <String, String>{officeStyleNoBase: ''};
  for (final style in catalog.paragraphStyles) {
    baseNames[style.name] = style.id;
  }
  final baseByName = {
    for (final entry in baseNames.entries) entry.key: entry.value
  };
  String nameOfId(String? id) {
    for (final entry in baseByName.entries) {
      if (entry.value == id) return entry.key;
    }
    return officeStyleNoBase;
  }

  String number(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);

  String cm(int? twips) => number((twips ?? 0) / 567);
  String points(int? twips) => number((twips ?? 0) / 20);

  String spacingName() {
    for (final entry in officeLineSpacings.entries) {
      if (entry.value.twips == formatting.lineTwips) return entry.key;
    }
    return 'Simples';
  }

  final families = [
    if (formatting.family != null &&
        !officeFontFamilies.contains(formatting.family))
      formatting.family!,
    ...officeFontFamilies,
  ];

  OfficeDialog(
    controller: controller,
    title: title,
    fields: [
      OfficeDialogField(key: 'name', label: 'Nome', kind: 'text', value: name),
      OfficeDialogField(
        key: 'basedOn',
        label: 'Estilo baseado em',
        kind: 'select',
        options: baseNames.keys.toList(),
        value: nameOfId(basedOn),
        hint: 'o que este estilo não declara vem do estilo base',
      ),
      OfficeDialogField(
        key: 'family',
        label: 'Fonte',
        kind: 'select',
        options: families,
        value: formatting.family ?? families.first,
      ),
      OfficeDialogField(
        key: 'size',
        label: 'Tamanho',
        kind: 'number',
        step: '0.5',
        min: '1',
        max: '1638',
        value: number(formatting.sizePt ?? 12),
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'bold',
        label: 'Negrito',
        kind: 'check',
        value: formatting.bold == true ? 'true' : 'false',
      ),
      OfficeDialogField(
        key: 'align',
        label: 'Alinhamento',
        kind: 'select',
        options: const ['Esquerda', 'Centralizado', 'Direita', 'Justificado'],
        value: switch (formatting.align) {
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
        value: cm(formatting.indentTwips),
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'indentFirst',
        label: 'Recuo da primeira linha',
        kind: 'number',
        step: '0.25',
        value: cm(formatting.firstLineIndentTwips),
        hint: 'cm — negativo produz o recuo deslocado do Word',
      ),
      OfficeDialogField(
        key: 'spaceBefore',
        label: 'Espaçamento antes',
        kind: 'number',
        step: '2',
        min: '0',
        value: points(formatting.spaceBeforeTwips),
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'spaceAfter',
        label: 'Espaçamento depois',
        kind: 'number',
        step: '2',
        min: '0',
        value: points(formatting.spaceAfterTwips),
        hint: 'pt',
      ),
      OfficeDialogField(
        key: 'lineSpacing',
        label: 'Entrelinha',
        kind: 'select',
        options: officeLineSpacings.keys.toList(),
        value: spacingName(),
      ),
    ],
    onApply: (values) {
      int twipsFrom(String key, double factor) {
        final raw = (values[key] ?? '').replaceAll(',', '.').trim();
        return ((double.tryParse(raw) ?? 0) * factor).round();
      }

      final finalName = (values['name'] ?? '').trim();
      // Um estilo sem nome não tem como ser encontrado na galeria nem
      // renomeado depois; melhor recusar em silêncio do que criar um cartão
      // em branco.
      if (finalName.isEmpty) return;
      final spacing = officeLineSpacings[values['lineSpacing']] ??
          officeLineSpacings['Simples']!;
      final size =
          double.tryParse((values['size'] ?? '').replaceAll(',', '.').trim());
      final base = baseByName[values['basedOn']];
      onApply(
        finalName,
        base == null || base.isEmpty ? null : base,
        OfficeStyleFormatting(
          family: values['family'],
          sizePt: size == null || size <= 0 ? formatting.sizePt : size,
          bold: values['bold'] == 'true',
          align: switch (values['align']) {
            'Centralizado' => 'center',
            'Direita' => 'right',
            'Justificado' => 'justify',
            _ => 'left',
          },
          indentTwips: twipsFrom('indentLeft', 567),
          rightIndentTwips: formatting.rightIndentTwips,
          firstLineIndentTwips: twipsFrom('indentFirst', 567),
          spaceBeforeTwips: twipsFrom('spaceBefore', 20),
          spaceAfterTwips: twipsFrom('spaceAfter', 20),
          lineTwips: spacing.twips,
          lineRule: spacing.rule,
        ),
      );
    },
  ).open();
}
