/// F9 — edição IN-PLACE de caixa de texto: duplo clique na caixa, o cursor
/// aparece dentro dela, e o que é digitado fica onde está desenhado.
///
/// A estrutura é a mesma do modo cabeçalho/rodapé, e de propósito: outra
/// [OfficeEditorView] sobre outra raiz, montada no OVERLAY. O §6 do plano
/// proíbe um segundo laço de edição, e a razão vale igual aqui — `beforeinput`
/// cancelado, IME reconciliado, clipboard pelo modelo e undo pelas extensões
/// já existem na view; uma segunda implementação ficaria para trás no primeiro
/// bug corrigido só de um lado.
///
/// **Onde esta sessão difere da de cabeçalho, e por quê.** O documento da
/// região vive FORA do documento do corpo (`headerVariants`), então gravar a
/// cada tecla lá custa zero repaginação. O `textBoxDoc` vive DENTRO do corpo,
/// como atributo de um nó: gravá-lo a cada tecla dispararia uma repaginação
/// completa por caractere digitado — inaceitável num DOCX de 140 páginas. Por
/// isso aqui a gravação é UMA transação ao sair, exatamente como o arrasto de
/// redimensionamento faz no `pointerup`.
///
/// O preço, dito na íntegra: a sessão inteira é UM passo de undo (o Word
/// desfaz caractere a caractere), e uma sessão que morresse sem passar por
/// [exit] perderia a edição — por isso todos os caminhos de encerramento
/// passam por [exit], e só [dispose] descarta, que é quando o documento em
/// que a caixa vivia deixou de existir.
library;

import '../../platform/dom.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';
import 'controller.dart';

/// A caixa que está sendo editada: onde ela mora no modelo e o que ela era
/// quando a sessão abriu.
final class OfficeTextBoxRef {
  const OfficeTextBoxRef({
    required this.pos,
    required this.node,
  });

  /// Posição do nó `textBox` no documento do CORPO.
  final int pos;
  final PMNode node;
}

/// A sessão de edição de caixa de texto. Uma por editor; inativa por padrão.
class OfficeTextBoxSession {
  OfficeTextBoxSession(this.controller, {required this.onChanged});

  final OfficeWordController controller;

  /// Chamado quando a sessão entra ou sai — o orquestrador reage acendendo a
  /// ribbon pela seleção de DENTRO da caixa.
  final void Function() onChanged;

  bool _active = false;
  OfficeTextBoxRef? _ref;
  PMNode? _mountedDoc;

  OfficeEditorView? _boxView;
  DomElement? _surface;
  DomElement? _frame;

  /// O elemento projetado da caixa: é dele que sai a geometria da superfície.
  DomElement? _boxElement;

  bool get isActive => _active;

  /// A view de dentro da caixa — a MESMA classe do corpo, outra raiz.
  OfficeEditorView? get boxView => _boxView;

  OfficeTextBoxRef? get boxRef => _ref;

  // -- entrada e saída --------------------------------------------------------

  /// Roteia o duplo clique do canvas. Devolve true quando a sessão mudou.
  ///
  /// Duplo clique NUMA caixa entra (ou troca de caixa); duplo clique fora,
  /// com a sessão aberta, sai. É o gesto do Word e o simétrico dele.
  bool handleDoubleClick(DomEvent event) {
    final target = event.target;
    final box = target == null ? null : _boxElementAt(target);
    if (box != null) {
      final pos = int.tryParse(box.getAttribute('data-doc-pos') ?? '');
      if (pos == null) return false;
      return enter(pos, element: box);
    }
    if (!_active) return false;
    exit();
    return true;
  }

  /// Entra na caixa em [pos]. Devolve false quando ali não há uma caixa.
  bool enter(int pos, {DomElement? element}) {
    if (!controller.viewReady) return false;
    final node = controller.view.state.doc.nodeAt(pos);
    if (node == null || node.type.name != 'textBox') return false;
    if (_active && _ref?.pos == pos) return true;

    // Trocar de caixa GRAVA a anterior: perder o que foi digitado por ter
    // clicado na caixa vizinha seria indefensável.
    if (_active) exit();

    _ref = OfficeTextBoxRef(pos: pos, node: node);
    _boxElement = element ?? _boxElementForPos(pos);
    _active = true;
    // Travar o corpo é o que impede a digitação de cair fora da caixa — a
    // opacidade é só o aviso visível disso.
    controller.setBodyEditingSuspended(true);
    _mountBox(node);
    reposition();
    onChanged();
    return true;
  }

  /// Sai da sessão gravando o que foi digitado (uma transação).
  void exit() {
    if (!_active) return;
    _active = false;
    controller.setBodyEditingSuspended(false);
    _commit();
    _disposeBoxView();
    _ref = null;
    _mountedDoc = null;
    _boxElement = null;
    onChanged();
  }

  /// Encerra SEM gravar — o caminho de `openDocument`/`dispose`, onde a caixa
  /// que estava sendo editada deixou de existir.
  void dispose() {
    _active = false;
    _ref = null;
    _mountedDoc = null;
    _boxElement = null;
    _disposeBoxView();
  }

  // -- geometria --------------------------------------------------------------

  /// Reacompanha a caixa projetada: chamado a cada refresh e no scroll.
  ///
  /// A superfície não recalcula a posição da caixa em twips; ela LÊ o
  /// retângulo do elemento desenhado. Um cálculo paralelo divergiria do
  /// desenho no primeiro caso de alinhamento ou offset que eu esquecesse.
  void reposition() {
    if (!_active) return;
    final surface = _surface;
    final frame = _frame;
    if (surface == null || frame == null) return;

    // Reprojetar troca o elemento: reencontrá-lo pela posição do modelo é o
    // que mantém a superfície colada na caixa depois de um scroll.
    final element = _boxElement = _boxElementForPos(_ref?.pos) ?? _boxElement;
    // Com virtualização, rolar para longe substitui a página por um
    // placeholder. Sem elemento não há geometria: some até a página voltar,
    // em vez de encalhar a superfície no canto do editor.
    final bounds = element == null
        ? null
        : controller.adapter.getElementBounds(
            element,
            relativeTo: controller.overlay.layer,
          );
    final offscreen = bounds == null;
    for (final target in [surface, frame]) {
      if (offscreen) {
        target.classes.add('dq-office-tb-offscreen');
      } else {
        target.classes.remove('dq-office-tb-offscreen');
      }
    }
    if (bounds == null) return;

    final px = controller.pxPerTwip;
    final node = _ref?.node;
    final insetLeft = _twipsAttr(node, 'insetLeft') * px;
    final insetTop = _twipsAttr(node, 'insetTop') * px;
    final insetRight = _twipsAttr(node, 'insetRight') * px;
    final insetBottom = _twipsAttr(node, 'insetBottom') * px;
    final left = _numOf(bounds['left']);
    final top = _numOf(bounds['top']);
    final width = _numOf(bounds['width']);
    final height = _numOf(bounds['height']);

    // A MOLDURA marca a caixa inteira; a SUPERFÍCIE editável ocupa só a área
    // interna, que é onde o texto da caixa realmente cabe.
    frame.setAttribute(
        'style',
        'left:${left.toStringAsFixed(1)}px;'
            'top:${top.toStringAsFixed(1)}px;'
            'width:${width.toStringAsFixed(1)}px;'
            'height:${height.toStringAsFixed(1)}px;');
    final innerWidth = width - insetLeft - insetRight;
    final innerHeight = height - insetTop - insetBottom;
    surface.setAttribute(
        'style',
        'left:${(left + insetLeft).toStringAsFixed(1)}px;'
            'top:${(top + insetTop).toStringAsFixed(1)}px;'
            'width:${(innerWidth > 1 ? innerWidth : 1).toStringAsFixed(1)}px;'
            'height:${(innerHeight > 1 ? innerHeight : 1).toStringAsFixed(1)}px;');
  }

  // -- montagem ---------------------------------------------------------------

  void _mountBox(PMNode node) {
    final doc = _documentOf(node);
    _mountedDoc = doc;

    final surface = controller.adapter.document.createElement('div');
    surface.classes.add('dq-office-tb-surface');
    surface.setAttribute('data-dq-office-text-box', '${_ref?.pos}');
    controller.overlay.layer.append(surface);
    _surface = surface;

    final frame = controller.adapter.document.createElement('div');
    frame.classes.add('dq-office-tb-frame');
    controller.overlay.layer.append(frame);
    _frame = frame;

    final extensions = officeDefaultExtensions(controller.schema);
    _boxView = OfficeEditorView(
      host: surface,
      state: EditorState.create(EditorStateConfig(
        doc: doc,
        plugins: OfficeExtensionSet(extensions).plugins,
      )),
      adapter: controller.adapter,
      extensions: extensions,
      composer: LayoutComposer(
        setup: _boxSetup(node),
        fonts: controller.options.fonts,
      ),
      renderer: PageGraphDomRenderer(
        document: controller.adapter.document,
        editable: true,
        pxPerPt: 96 / 72 * controller.zoom,
      ),
      // Os hints `lastRenderedPageBreak` descrevem o CORPO gravado pelo Word;
      // não existem para o conteúdo de uma caixa.
      honorRenderedPageBreaks: false,
      onStateChange: (_) => onChanged(),
    );

    final content = surface.querySelector('.$officeCssPrefix-page-content');
    if (content != null) controller.adapter.focus(content);
  }

  /// A geometria em que o conteúdo da caixa é composto.
  ///
  /// Largura é a área INTERNA da caixa — é o que faz o texto quebrar onde ele
  /// quebra na projeção. A altura é deliberadamente generosa e as margens são
  /// zero: paginar o conteúdo de uma caixa não significaria nada, e o recorte
  /// visível é feito pelo `overflow:hidden` da superfície.
  PageSetupTwips _boxSetup(PMNode node) {
    final width = _twipsAttr(node, 'width', fallback: 2880) -
        _twipsAttr(node, 'insetLeft') -
        _twipsAttr(node, 'insetRight');
    return PageSetupTwips(
      widthTwips: width > 1 ? width : 1,
      heightTwips: _canvasHeightTwips,
      marginTopTwips: 0,
      marginRightTwips: 0,
      marginBottomTwips: 0,
      marginLeftTwips: 0,
    );
  }

  /// 22 polegadas: alto o bastante para que nenhuma caixa real pagine.
  static const int _canvasHeightTwips = 31680;

  /// O documento de dentro da caixa.
  ///
  /// `textBoxDoc` é a projeção rica de `w:txbxContent`. Quando ela falta
  /// (snapshot legado, caixa criada por outro produtor), o texto plano vira um
  /// parágrafo — editar uma caixa que só tinha `text` é melhor que não poder
  /// abri-la.
  PMNode _documentOf(PMNode node) {
    final raw = node.attrs['textBoxDoc'];
    if (raw is Map) {
      try {
        final doc = PMNode.fromJSON(controller.schema, raw);
        if (doc.type.name == 'doc' && doc.childCount > 0) return doc;
      } catch (_) {
        // Cai no fallback abaixo: um `textBoxDoc` corrompido não pode
        // impedir a edição da caixa.
      }
    }
    final text = '${node.attrs['text'] ?? ''}';
    final lines = text.isEmpty ? const [''] : text.split('\n');
    return controller.schema.node(
      'doc',
      null,
      Fragment.from([
        for (final line in lines)
          controller.schema.node(
            'paragraph',
            null,
            line.isEmpty
                ? Fragment.empty
                : Fragment.from([controller.schema.text(line)]),
          ),
      ]),
    );
  }

  /// Grava o conteúdo editado no nó, em UMA transação.
  ///
  /// A comparação é por identidade contra o documento montado: entrar na
  /// caixa, olhar e sair não pode marcar o documento como sujo.
  ///
  /// `text` é reescrito junto porque ele é o fallback visual de renderers
  /// antigos e o que a busca de texto enxerga; deixá-lo velho faria a caixa
  /// mostrar uma coisa e ser encontrada por outra.
  void _commit() {
    final ref = _ref;
    final view = _boxView;
    if (ref == null || view == null) return;
    final doc = view.state.doc;
    if (identical(doc, _mountedDoc)) return;

    final state = controller.view.state;
    final current = state.doc.nodeAt(ref.pos);
    // A caixa pode ter saído do documento durante a sessão (undo, colagem):
    // gravar por posição nesse caso escreveria em cima de outro nó.
    if (current == null || current.type.name != 'textBox') return;

    final tr = state.tr;
    tr.setNodeMarkup(ref.pos, null, {
      ...current.attrs,
      'textBoxDoc': doc.toJSON(),
      'text': [
        for (var i = 0; i < doc.childCount; i++) doc.child(i).textContent,
      ].join('\n'),
    });
    // Direto na view do CORPO, não por `controller.dispatch`: a view da caixa
    // ainda existe neste ponto, então `activeView` ainda aponta para ela — e
    // a transação é do documento do corpo. Aplicá-la na caixa é exatamente o
    // "Applying a mismatched transaction" que o estado recusa.
    controller.view.dispatch(tr);
  }

  void _disposeBoxView() {
    _boxView?.dispose();
    _boxView = null;
    _surface?.remove();
    _surface = null;
    _frame?.remove();
    _frame = null;
  }

  // -- hit-testing ------------------------------------------------------------

  /// A caixa projetada que contém [node], ou null.
  ///
  /// Só caixas do CORPO respondem: a projeção dentro da superfície da própria
  /// sessão também tem a classe, e reentrar nela a cada duplo clique
  /// remontaria a view por baixo do cursor.
  DomElement? _boxElementAt(DomNode node) {
    DomNode? current = node;
    var insideSurface = false;
    DomElement? box;
    while (current != null) {
      if (current is DomElement) {
        if (current.classes.contains('dq-office-tb-surface')) {
          insideSurface = true;
        }
        if (box == null &&
            current.classes.contains('$officeCssPrefix-text-box')) {
          box = current;
        }
      }
      current = current.parentNode;
    }
    return insideSurface ? null : box;
  }

  /// O elemento projetado da caixa em [pos] — reencontrado a cada reprojeção.
  DomElement? _boxElementForPos(int? pos) {
    if (pos == null) return null;
    final root = controller.view.host;
    for (final element in root.querySelectorAll('.$officeCssPrefix-text-box')) {
      if (element.getAttribute('data-doc-pos') == '$pos') return element;
    }
    return null;
  }

  static int _twipsAttr(PMNode? node, String key, {int fallback = 0}) {
    final raw = node?.attrs[key];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? fallback;
  }

  static double _numOf(Object? value) => value is num ? value.toDouble() : 0.0;
}
