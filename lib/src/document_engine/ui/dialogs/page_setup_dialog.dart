/// "Margens Personalizadas…" e "Mais Tamanhos de Papel…" — a saída do menu
/// Layout para o que as predefinições não cobrem.
///
/// Os dois abrem O MESMO diálogo, em abas diferentes do Word, e aqui num só
/// formulário: a geometria da página é uma coisa só, e um usuário que abre
/// "Margens Personalizadas…" para caber mais texto quase sempre quer olhar o
/// papel na mesma passada. Separar em dois formulários faria ele confirmar
/// duas vezes e gerar dois passos de undo para uma decisão só.
///
/// **As medidas são em centímetros**, não em twips. O modelo é em twips (e
/// continua sendo), mas ninguém digita 1418; o Word em pt-BR pede cm, e a
/// conversão fica aqui, num lugar só, com a mesma constante que o resto do
/// editor usa (567 twips por cm).
///
/// **A distância do cabeçalho e do rodapé entra no formulário.** Elas são
/// medidas da BORDA da página, não da margem, e nenhuma predefinição do menu
/// as toca — quem as perde perde o alinhamento do cabeçalho importado. Como o
/// dropdown de margens preserva esses dois valores, o formulário é o único
/// lugar onde eles podem ser ajustados de propósito.
library;

import '../../layout/page_graph.dart';
import '../controller.dart';
import 'dialog.dart';

/// Twips por centímetro. A mesma constante que o resto do editor usa.
const double officeTwipsPerCm = 567.0;

/// Abre o diálogo de configuração de página.
///
/// [focusPaper] só troca o título — é o que separa a entrada por "Margens
/// Personalizadas…" da entrada por "Mais Tamanhos de Papel…", sem duplicar o
/// formulário nem a validação.
OfficeDialog openPageSetupDialog(
  OfficeWordController controller, {
  bool focusPaper = false,
}) {
  final setup = controller.pageSetup;
  // A orientação é derivada, não um campo: no Word ela é o resultado de qual
  // dimensão é a maior. Um campo separado poderia contradizer largura e
  // altura digitadas, e aí não haveria resposta certa.
  final dialog = OfficeDialog(
    controller: controller,
    title: focusPaper ? 'Tamanho do Papel' : 'Configurar Página',
    fields: [
      OfficeDialogField(
        key: 'marginTop',
        label: 'Margem superior',
        kind: 'number',
        value: _cm(setup.marginTopTwips),
        step: '0,1',
        min: '0',
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'marginBottom',
        label: 'Margem inferior',
        kind: 'number',
        value: _cm(setup.marginBottomTwips),
        step: '0,1',
        min: '0',
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'marginLeft',
        label: 'Margem esquerda',
        kind: 'number',
        value: _cm(setup.marginLeftTwips),
        step: '0,1',
        min: '0',
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'marginRight',
        label: 'Margem direita',
        kind: 'number',
        value: _cm(setup.marginRightTwips),
        step: '0,1',
        min: '0',
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'headerDistance',
        label: 'Cabeçalho a partir da borda',
        kind: 'number',
        value: _cm(setup.headerDistanceTwips),
        step: '0,1',
        min: '0',
        hint: 'cm — medida da BORDA da página, como no Word',
      ),
      OfficeDialogField(
        key: 'footerDistance',
        label: 'Rodapé a partir da borda',
        kind: 'number',
        value: _cm(setup.footerDistanceTwips),
        step: '0,1',
        min: '0',
        hint: 'cm — medida da BORDA da página, como no Word',
      ),
      OfficeDialogField(
        key: 'width',
        label: 'Largura do papel',
        kind: 'number',
        value: _cm(setup.widthTwips),
        step: '0,1',
        min: '1',
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'height',
        label: 'Altura do papel',
        kind: 'number',
        value: _cm(setup.heightTwips),
        step: '0,1',
        min: '1',
        hint: 'cm — trocar largura e altura é o que muda a orientação',
      ),
    ],
    onApply: (values) {
      final next = officePageSetupFromForm(values, setup);
      if (next != null) controller.setPageSetup(next);
    },
  );
  dialog.open();
  return dialog;
}

/// Converte os valores do formulário numa geometria, ou null se ela for
/// impossível.
///
/// Público porque é aqui que mora a única lógica do diálogo, e um teste que
/// tenha de montar DOM para exercitá-la testaria o formulário, não a regra.
///
/// **Um formulário inválido não aplica NADA.** Margens que somam mais que o
/// papel produziriam largura de conteúdo negativa; o compositor sobreviveria
/// (ele satura a capacidade em zero), mas o usuário veria uma página em
/// branco sem entender o porquê. Recusar em bloco preserva o que estava lá,
/// que é a única resposta que ele consegue interpretar.
PageSetupTwips? officePageSetupFromForm(
  Map<String, String> values,
  PageSetupTwips current,
) {
  int? twips(String key, int fallback) {
    final raw = values[key];
    if (raw == null || raw.trim().isEmpty) return fallback;
    // Vírgula decimal: é o que o usuário em pt-BR digita, e o que os hints
    // do formulário mostram.
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed < 0) return null;
    return (parsed * officeTwipsPerCm).round();
  }

  final width = twips('width', current.widthTwips);
  final height = twips('height', current.heightTwips);
  final top = twips('marginTop', current.marginTopTwips);
  final bottom = twips('marginBottom', current.marginBottomTwips);
  final left = twips('marginLeft', current.marginLeftTwips);
  final right = twips('marginRight', current.marginRightTwips);
  final header = twips('headerDistance', current.headerDistanceTwips);
  final footer = twips('footerDistance', current.footerDistanceTwips);
  if (width == null ||
      height == null ||
      top == null ||
      bottom == null ||
      left == null ||
      right == null ||
      header == null ||
      footer == null) {
    return null;
  }
  if (width < _minimumPageTwips || height < _minimumPageTwips) return null;
  if (left + right >= width) return null;
  if (top + bottom >= height) return null;

  return PageSetupTwips(
    widthTwips: width,
    heightTwips: height,
    marginTopTwips: top,
    marginRightTwips: right,
    marginBottomTwips: bottom,
    marginLeftTwips: left,
    headerDistanceTwips: header,
    footerDistanceTwips: footer,
    // A grade de texto do documento não é um campo do formulário: ela vem do
    // `w:docGrid` importado e afeta a altura das linhas. Recriá-la a partir
    // de valores que o usuário não viu apagaria a métrica do documento.
    documentGridLinePitchTwips: current.documentGridLinePitchTwips,
    documentGridType: current.documentGridType,
  );
}

/// Meia polegada: abaixo disso não existe papel real, e a página composta
/// não teria onde desenhar nem uma linha.
const int _minimumPageTwips = 720;

/// twips → o número em cm que o campo mostra (vírgula decimal, duas casas).
String _cm(int twips) =>
    (twips / officeTwipsPerCm).toStringAsFixed(2).replaceAll('.', ',');
