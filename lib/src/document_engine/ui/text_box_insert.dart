/// Inserir → Caixa de Texto: criar a caixa que até aqui só existia importada.
///
/// A caixa nova é deliberadamente MAGRA em atributos, e isso é a decisão
/// central deste arquivo: ela nasce **sem `word`**. O atributo `word` guarda o
/// DrawingML de origem, e o writer o carimba de volta no save
/// (`docx_codec._textBoxRawXml`). Se a caixa nova nascesse com um XML pronto,
/// a primeira alça de redimensionamento arrastada gravaria uma largura no
/// modelo e outra no arquivo — o `wp:extent` carimbado continuaria com o
/// tamanho do nascimento. Sem `word`, a exportação GERA a forma a partir dos
/// atributos (`docx_codec._newTextBoxRawXml`), então o que está na tela é o
/// que vai para o arquivo.
///
/// A ausência de `word` também é o que diz ao compositor que esta caixa não
/// tem `wrapTopAndBottom` (ele procura a string no XML de origem,
/// `layout_composer.dart`): ela flutua SOBRE o texto, que é o
/// "na frente do texto" com que o Word cria uma caixa desenhada — e é o único
/// contorno que o compositor sabe desenhar hoje.
library;

import '../model/index.dart';
import '../office/text_box_drawing.dart';
import 'controller.dart';

/// Insere uma caixa de texto vazia no cursor e ENTRA nela para digitar.
///
/// Entrar em seguida é o comportamento do Word e não é enfeite: uma caixa
/// vazia sem cursor dentro parece um retângulo quebrado, e o usuário não tem
/// como saber que o caminho para escrever nela é um duplo clique.
///
/// Devolve a posição do nó no documento, ou null quando o schema não tem o
/// tipo `textBox` (documento montado com um schema reduzido).
int? insertTextBox(
  OfficeWordController c, {
  int widthTwips = officeDefaultTextBoxWidthTwips,
  int heightTwips = officeDefaultTextBoxHeightTwips,
  bool enterEditing = true,
}) {
  final type = c.schema.nodes['textBox'];
  if (type == null) return null;

  // Uma caixa recém-criada não tem o que preservar; o `textBoxDoc` nasce com
  // o parágrafo vazio que a sessão de edição vai montar. Criá-lo aqui (em vez
  // de deixar null) evita que a sessão caia no fallback de texto plano, que
  // existe para snapshots legados e não para conteúdo novo.
  final inner = c.schema.node(
    'doc',
    null,
    Fragment.from([c.schema.node('paragraph')]),
  );

  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr
    ..replaceSelectionWith(type.create({
      'text': '',
      'textBoxDoc': inner.toJSON(),
      'width': widthTwips,
      'height': heightTwips,
      'insetLeft': officeDefaultTextBoxInsetXTwips,
      'insetTop': officeDefaultTextBoxInsetYTwips,
      'insetRight': officeDefaultTextBoxInsetXTwips,
      'insetBottom': officeDefaultTextBoxInsetYTwips,
      'borderWidth': officeDefaultTextBoxBorderTwips,
      'borderColor': '#000000',
      'background': '#FFFFFF',
    }));
  final at = tr.selection.from;
  c.dispatch(tr);

  // A posição do NÓ é a anterior ao ponto onde a seleção parou: o átomo
  // ocupa uma unidade e `replaceSelectionWith` deixa o cursor depois dele.
  final pos = at - 1;
  final node = pos < 0 ? null : c.view.state.doc.nodeAt(pos);
  if (node == null || node.type.name != 'textBox') return null;
  // Só o corpo hospeda a sessão de caixa; inserir dentro de um cabeçalho em
  // edição continua criando o nó, mas abrir uma segunda sessão sobre a
  // primeira é o caminho para duas views disputando o mesmo foco.
  if (enterEditing && c.activeView == c.view) {
    c.textBoxSession.enter(pos);
  }
  return pos;
}
