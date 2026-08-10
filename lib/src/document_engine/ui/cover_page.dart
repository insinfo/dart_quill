/// Inserir → Folha de Rosto.
///
/// **O que estas capas são, e o que elas deliberadamente NÃO são.** As
/// galerias do Word ("Austin", "Faceta", "Retrospectiva") são desenhos:
/// faixas coloridas, retângulos, imagens de fundo. O compositor deste
/// projeto desenha texto, tabela, imagem e caixa flutuante — não desenha
/// faixa nem forma decorativa. Uma capa "Faceta" gravaria no arquivo um
/// visual que a tela não mostra, que é a divergência que o §6 do plano
/// proíbe.
///
/// Por isso as capas daqui são TIPOGRÁFICAS: título, subtítulo, autor e
/// data, com corpo, peso, alinhamento e espaçamento que o compositor pagina
/// de verdade e o writer exporta inteiros. É menos do que o Word oferece, e
/// é dito no menu — um item que entrega menos com o rótulo certo é melhor
/// que um que promete o catálogo e desenha uma página em branco.
///
/// **Onde a formatação mora, e por quê.** Corpo, peso e família vão em
/// MARCAS de run (`size`/`bold`/`font`), não no mapa `attrs['style']` do
/// bloco. O motivo é a exportação: `docx_codec._paragraphPropertiesWith`
/// `Presentation` leva do `style` só alinhamento, recuos, espaçamento e as
/// quebras — `sizePt` e `bold` de bloco NÃO viram `w:rPr`. Escritos ali, o
/// título apareceria em 28 pt na tela e em 11 pt no Word.
library;

import '../model/index.dart';
import 'controller.dart';

/// Uma capa da galeria.
class OfficeCoverPageLayout {
  const OfficeCoverPageLayout({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;

  /// Rótulo do item no menu.
  final String name;

  /// A linha de baixo do item — descreve o que a capa REALMENTE tem.
  final String description;
}

/// As capas oferecidas. Duas, e não doze: cada uma tem de ser desenhada pelo
/// compositor, e repetir a mesma capa com nomes diferentes seria enfeite.
const List<OfficeCoverPageLayout> officeCoverPageLayouts = [
  OfficeCoverPageLayout(
    id: 'centralizada',
    name: 'Centralizada',
    description: 'Título, subtítulo, autor e data centralizados',
  ),
  OfficeCoverPageLayout(
    id: 'alinhada',
    name: 'Alinhada à Esquerda',
    description: 'Título e subtítulo à esquerda, autor e data no rodapé da '
        'capa',
  ),
];

/// Textos de exemplo, no formato do Word: colchetes marcam o que trocar.
const String officeCoverTitlePlaceholder = '[Título do documento]';
const String officeCoverSubtitlePlaceholder = '[Subtítulo do documento]';
const String officeCoverAuthorPlaceholder = '[Nome do autor]';

/// Insere a capa [layoutId] no INÍCIO do documento.
///
/// Como no Word, a capa é sempre a página 1 (não "no cursor"): o bloco que
/// era o primeiro ganha `pageBreakBefore`, e é ele que empurra o documento
/// para a página seguinte. Sem essa marca a capa e o texto dividiriam a
/// mesma página, que é o oposto de uma folha de rosto.
///
/// Devolve false quando [layoutId] não existe na galeria.
bool insertCoverPage(
  OfficeWordController c,
  String layoutId, {
  String? title,
  String? subtitle,
  String? author,
  DateTime? date,
}) {
  if (!officeCoverPageLayouts.any((layout) => layout.id == layoutId)) {
    return false;
  }
  final schema = c.schema;
  final blocks = _blocksFor(
    schema,
    layoutId,
    title: title ?? officeCoverTitlePlaceholder,
    subtitle: subtitle ?? officeCoverSubtitlePlaceholder,
    author: author ?? officeCoverAuthorPlaceholder,
    date: _formatDate(date ?? DateTime.now()),
  );
  if (blocks.isEmpty) return false;

  c.syncSelection();
  // A capa é do CORPO: inseri-la enquanto o cabeçalho está aberto escreveria
  // uma folha de rosto dentro do cabeçalho.
  c.headerFooter.exit();
  c.textBoxSession.exit();

  final state = c.view.state;
  final tr = state.tr;
  final first = state.doc.childCount > 0 ? state.doc.child(0) : null;
  if (first != null) {
    final style = first.attrs['style'];
    tr.setNodeMarkup(0, null, {
      ...first.attrs,
      'style': {
        if (style is Map) ...style.cast<String, dynamic>(),
        'pageBreakBefore': true,
      },
    });
  }
  tr.insert(0, Fragment.from(blocks));
  c.dispatch(tr);
  return true;
}

/// Os parágrafos da capa.
///
/// O espaço vem de `spaceBeforeTwips`, não de parágrafos vazios empilhados:
/// parágrafos vazios seriam apagados por quem editasse a capa e mudariam a
/// altura de forma imprevisível; o espaçamento é uma propriedade, e o
/// compositor e o Word o leem igual.
List<PMNode> _blocksFor(
  Schema schema,
  String layoutId, {
  required String title,
  required String subtitle,
  required String author,
  required String date,
}) {
  final centered = layoutId == 'centralizada';
  final align = centered ? 'center' : 'left';

  PMNode line(
    String text, {
    required double sizePt,
    bool bold = false,
    int spaceBefore = 0,
    int spaceAfter = 0,
  }) {
    final marks = <Mark>[
      if (schema.marks['size'] != null)
        schema.marks['size']!.create({'value': _sizeMarkValue(sizePt)}),
      if (bold && schema.marks['bold'] != null) schema.marks['bold']!.create(),
    ];
    return schema.node(
      'paragraph',
      {
        'style': {
          'align': align,
          'spaceBeforeTwips': spaceBefore,
          'spaceAfterTwips': spaceAfter,
          // A capa não herda a entrelinha do documento: um título de 28 pt
          // com entrelinha de corpo de texto encavala.
          'lineRule': 'auto',
          'lineTwips': 240,
        },
      },
      Fragment.from([schema.text(text, marks)]),
    );
  }

  return [
    // ~5 cm de respiro no topo: é onde o título cai numa folha de rosto do
    // Word, e ele é o primeiro bloco da página (o `spaceBefore` do topo
    // automático continua valendo aqui porque a página é aberta por quebra).
    line(title, sizePt: 28, bold: true, spaceBefore: 2835, spaceAfter: 240),
    line(subtitle, sizePt: 16, spaceAfter: 120),
    line(author, sizePt: 12, spaceBefore: 3402),
    line(date, sizePt: 12),
  ];
}

String _sizeMarkValue(double points) =>
    points == points.roundToDouble() ? '${points.round()}pt' : '${points}pt';

/// dd/MM/yyyy — o formato do documento oficial brasileiro, que é o público
/// deste editor. Sem `intl`: uma dependência inteira para quatro barras.
String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
