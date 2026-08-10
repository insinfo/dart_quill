/// O contrato entre o orquestrador ([OfficeWordEditor]) e os componentes do
/// chrome (ribbon, réguas, barra de status, abas).
///
/// Os componentes NUNCA falam com o motor diretamente: tudo passa por esta
/// interface. É o que mantém cada arquivo pequeno, testável isoladamente e
/// sem dependência circular de implementação — a regra do mini-framework.
library;

import 'dart:typed_data';

import '../../platform/dom.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../office/snapshot.dart';
import '../office/style_catalog.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import 'header_footer.dart';
import 'overlay.dart';
import 'word_options.dart';

abstract interface class OfficeWordController {
  DomAdapter get adapter;
  Schema get schema;
  OfficeWordEditorOptions get options;

  /// A camada de popups/adornos do editor. Todo controle flutuante (paleta,
  /// dropdown, combobox, quickbar, menu de contexto) abre por aqui — é o que
  /// garante uma única regra de fechamento e nenhum popup recortado.
  OfficeOverlay get overlay;

  /// O elemento que hospeda o editor INTEIRO (chrome, páginas e overlay).
  ///
  /// Existe para as duas coisas que valem para o componente todo e não para
  /// uma peça dele: uma classe de modo (as marcas de formatação ¶) e um
  /// popup que não pode fechar quando o usuário clica no documento (o painel
  /// Localizar). Nenhum componente monta nada aqui dentro por conta própria.
  DomElement get hostElement;

  /// Nome base do documento corrente, sem caminho nem extensão.
  ///
  /// Um arquivo aberto substitui o título inicial para que salvar/exportar
  /// nunca baixe outro documento com um nome herdado da demonstração.
  String get documentBaseName;

  /// Indica se o modelo/geometria mudou desde a abertura ou último save.
  bool get isDirty;

  /// O laço de edição do CORPO. Só é válido depois de [viewReady].
  ///
  /// É o que réguas, barra de status e adornos usam: eles falam da página, da
  /// paginação e da geometria do documento, que continuam sendo do corpo
  /// mesmo com o modo cabeçalho/rodapé aberto.
  OfficeEditorView get view;

  /// A view em que a EDIÇÃO acontece agora — a do corpo, ou a da região
  /// quando a sessão de cabeçalho/rodapé está aberta.
  ///
  /// A separação é o que faz negrito, undo e a quickbar agirem no cabeçalho
  /// enquanto ele está sendo editado, sem que a régua vertical passe a
  /// acompanhar um documento de uma linha.
  OfficeEditorView get activeView;

  /// A sessão de edição de cabeçalho/rodapé (F6). Sempre existe; pergunte
  /// [OfficeHeaderFooterSession.isActive] antes de reagir a ela.
  OfficeHeaderFooterSession get headerFooter;

  /// `w:titlePg` — a primeira página usa as variantes `first`.
  bool get titlePage;

  /// `w:evenAndOddHeaders` — páginas pares usam as variantes `even`.
  bool get evenAndOddHeaders;

  /// Liga/desliga as variantes de cabeçalho/rodapé. O documento REPAGINA (a
  /// altura das regiões muda o inset do corpo) e fica sujo.
  void setHeaderFooterFlags({bool? titlePage, bool? evenAndOddHeaders});

  /// Qual região o compositor usa na página [pageIndex], e de onde ela veio.
  OfficeRegionRef regionForPage(int pageIndex, {required bool isHeader});

  /// Substitui a região descrita por [ref] pelo documento [doc].
  ///
  /// Com [recompose] falso a troca é só de MODELO (marca sujo e nada mais):
  /// é o caminho de cada tecla digitada na região, e recompor o documento
  /// inteiro a cada caractere travaria a digitação num DOCX longo. O
  /// fechamento do modo passa `recompose: true` e paga a repaginação uma vez.
  void setRegionDocument(OfficeRegionRef ref, PMNode doc,
      {bool recompose = false});

  /// Suspende (ou devolve) a edição do CORPO.
  ///
  /// Suspenso, as páginas perdem o `contenteditable` e o host ganha a classe
  /// de esmaecimento. Tirar só a opacidade não bastaria: o caret continuaria
  /// podendo voltar ao texto pelo teclado enquanto o usuário pensa estar
  /// digitando no cabeçalho.
  void setBodyEditingSuspended(bool suspended);

  /// A ribbon nasce ANTES da view (a ordem visual do chrome manda); os
  /// refreshes de estado só valem quando isto for true.
  bool get viewReady;

  /// Geometria corrente (a aba Layout a altera).
  PageSetupTwips get pageSetup;

  double get zoom;
  double get pxPerTwip;

  void dispatch(Transaction tr);
  bool runCommand(String name);

  /// Puxa a seleção nativa para o modelo (guardada pelo host da view).
  void syncSelection();

  /// Os estilos DO DOCUMENTO aberto (F8), ou null quando não há um pacote de
  /// origem — documento novo, ou Delta do Quill, que não tem `styles.xml`.
  ///
  /// A galeria da Página Inicial é construída daqui; sem catálogo ela cai nos
  /// quatro cartões fixos (Normal/Título 1–3), que é o comportamento
  /// histórico e continua correto para um documento sem estilos nomeados.
  OfficeStyleCatalog? get styleCatalog;

  /// Avisa que o CATÁLOGO mudou sem que o documento mudasse — renomear um
  /// estilo, tirá-lo da galeria.
  ///
  /// Existe separado de [dispatch] porque essas duas operações não produzem
  /// transação: sem um aviso explícito a galeria continuaria mostrando o
  /// nome antigo até a próxima troca de aba, e o botão Salvar não saberia
  /// que há algo novo para gravar no `styles.xml`.
  void styleCatalogChanged();

  /// Rola o viewport até a seleção corrente, se ela estiver fora dele.
  ///
  /// Despachar uma seleção já FIXA a página na janela virtualizada e escreve
  /// a seleção nativa, mas o browser não rola por conta própria quando quem
  /// moveu o caret foi o programa e não o usuário. Sem isto, "Próximo" no
  /// painel Localizar acha a ocorrência na página 40 e deixa o usuário
  /// olhando para a página 1.
  void revealSelection();

  /// O mapa `style` do bloco corrente, ou null.
  Map? currentBlockStyle();

  /// Grava chaves de apresentação nos blocos da seleção — o mesmo mapa
  /// PARCIAL da cascata de estilos, então nada além do que foi pedido muda.
  void applyBlockStyle(Map<String, dynamic> patch);

  void setZoom(double zoom);
  void setPageSetup(PageSetupTwips setup);

  /// Cria uma seção nova logo depois da seção onde o cursor está, com a MESMA
  /// geometria dela.
  ///
  /// Duplicar em vez de inventar uma geometria é o que faz a quebra ser
  /// invisível até o usuário mudar algo — igual ao Word. Quem marca o bloco
  /// com `style.sectionBreak` é a ação da ribbon; sem esta entrada
  /// correspondente em `sections` o compositor ignoraria a marca.
  void insertSectionAfterSelection();

  /// Substitui o documento aberto (Abrir DOCX/Delta na aba Arquivo).
  ///
  /// O histórico de undo recomeça — é um documento NOVO, não uma edição.
  /// Com [setup], a geometria de página do arquivo aberto vale (um DOCX
  /// ofício abre em ofício). Headers and footers are separate roots because
  /// the same content is projected on every page.
  void openDocument(
    PMNode doc, {
    PageSetupTwips? setup,
    List<PageSetupTwips>? sections,
    PMNode? header,
    PMNode? footer,
    Map<String, PMNode>? headerVariants,
    Map<String, PMNode>? footerVariants,
    bool titlePage = false,
    bool evenAndOddHeaders = false,
    OfficeDocumentSnapshot? sourceSnapshot,
    Uint8List? sourceDocxBytes,
    Map<String, dynamic>? sourceMap,
    String? sourceFileName,
    OfficeStyleCatalog? styleCatalog,
  });

  /// Prepares font and table geometry in cooperative slices before opening a
  /// large imported document. It does not mutate the current document.
  Future<int> prewarmLayout(
    PMNode document, {
    required PageSetupTwips setup,
    List<PageSetupTwips> sections = const [],
    PMNode? header,
    PMNode? footer,
    Map<String, PMNode> headerVariants = const {},
    Map<String, PMNode> footerVariants = const {},
    bool titlePage = false,
    bool evenAndOddHeaders = false,
    bool honorRenderedPageBreaks = true,
    Map<String, int>? timings,
  });

  Uint8List exportPdf();
  Future<Uint8List> exportPdfAsync({Map<String, int>? timings});
  Uint8List exportDocx();
  Future<Uint8List> exportDocxAsync({Map<String, int>? timings});

  /// Salva pelo caminho assíncrono e baixa o DOCX com o nome corrente.
  Future<void> saveDocx();

  /// Gera e baixa o PDF cooperativamente, sem bloquear documentos longos.
  Future<void> savePdf();

  /// Executa [action] com o overlay de ocupado ([label]: "Abrindo documento…",
  /// "Salvando DOCX…"). Chamadas aninhadas empilham; o overlay some quando a
  /// última termina. O overlay é do COMPONENTE — a aplicação não precisa de
  /// spinner próprio para abrir/salvar.
  Future<T> runBusy<T>(String label, Future<T> Function() action);
}

/// Helpers de construção de DOM compartilhados pelos componentes.
///
/// Não é um framework de verdade — é o mínimo que evita cada componente
/// reinventar `createElement` + classes + listeners.
final class OfficeDomKit {
  const OfficeDomKit(this.adapter);

  final DomAdapter adapter;

  DomElement el(String tag, String cssClass) {
    final element = adapter.document.createElement(tag);
    if (cssClass.isNotEmpty) {
      for (final name in cssClass.split(' ')) {
        element.classes.add(name);
      }
    }
    return element;
  }

  void setText(DomElement element, String text) {
    while (element.firstChild != null) {
      element.firstChild!.remove();
    }
    element.appendText(text);
  }

  void clear(DomElement element) {
    while (element.firstChild != null) {
      element.firstChild!.remove();
    }
  }

  /// Botão da ribbon. Com [icon], o botão exibe a classe `dq-icon-<icon>`
  /// do stylesheet de ícones e o TEXTO vira fallback: o CSS de ícones o
  /// esconde quando o ícone existe, e sem o stylesheet o texto aparece —
  /// o consumidor pode trocar (ou omitir) o asset de ícones livremente.
  DomElement button(String text, String title, void Function() action,
      {String? extraClass, String? icon}) {
    final button = el(
        'button', 'dq-office-btn${extraClass == null ? '' : ' $extraClass'}');
    button.setAttribute('type', 'button');
    button.setAttribute('title', title);
    button.setAttribute('aria-label', title);
    if (icon != null) {
      button.append(el('span', 'dq-icon dq-icon-$icon'));
      final label = el('span', 'dq-office-btn-text');
      label.appendText(text);
      button.append(label);
    } else {
      button.appendText(text);
    }
    // B6: um controle da ribbon NUNCA tira o foco do documento. Sem isto o
    // browser move o foco para o botão no mousedown, a seleção visível
    // some/pisca e o usuário perde de vista o texto que está formatando —
    // é o mesmo `preventDefault` que ONLYOFFICE aplica em toda a toolbar.
    button.addEventListener('mousedown', (event) => event.preventDefault());
    button.addEventListener('click', (event) {
      event.preventDefault();
      action();
    });
    return button;
  }

  DomElement select(String cssClass, List<String> items, String selected,
      void Function(String value) onChange) {
    final select = el('select', 'dq-office-select $cssClass');
    for (final item in items) {
      final option = el('option', '');
      option.setAttribute('value', item);
      if (item == selected) option.setAttribute('selected', 'selected');
      option.appendText(item);
      select.append(option);
    }
    select.addEventListener('change', (_) => onChange(select.value));
    return select;
  }

  DomElement group(String label, List<DomElement> rows) {
    final group = el('div', 'dq-office-ribbon-group');
    group.setAttribute('data-group-label', label);
    final content = el('div', 'dq-office-ribbon-rows');
    for (final row in rows) {
      content.append(row);
    }
    group.append(content);
    return group;
  }

  DomElement row(List<DomElement> controls) {
    final row = el('div', 'dq-office-ribbon-row');
    for (final control in controls) {
      row.append(control);
    }
    return row;
  }
}

/// Combobox EDITÁVEL da ribbon (fonte e tamanho), como no Word.
///
/// Um `<select>` não serve para estes dois controles por dois motivos que
/// aparecem em todo DOCX real: ele não exibe um valor fora da lista (a fonte
/// do documento importado simplesmente sumiria) e não deixa digitar um
/// tamanho que não esteja na escada (10,5 é comum em ofícios).
///
/// O campo é um `<input>`; a lista abre no [OfficeOverlay], então nunca é
/// recortada pelo grupo da ribbon. O valor VAZIO é significativo: é como o
/// Word mostra uma seleção com fontes/tamanhos misturados.
final class OfficeComboBox {
  OfficeComboBox({
    required this.controller,
    required this.cssClass,
    required this.items,
    required this.onCommit,
    this.title,
    this.previewFontPerItem = false,
    this.parseValue,
  }) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final String cssClass;
  final List<String> items;

  /// Chamado com o valor final (digitado e confirmado, ou escolhido na
  /// lista). Só dispara quando o valor MUDA — reaplicar a mesma fonte a cada
  /// blur poluiria o histórico de undo com transações vazias.
  final void Function(String value) onCommit;
  final String? title;

  /// Cada item da lista é desenhado com a própria fonte (galeria de fontes).
  final bool previewFontPerItem;

  /// Normaliza/valida o que foi digitado; devolver null rejeita a entrada e
  /// o campo volta ao valor do modelo.
  final String? Function(String raw)? parseValue;

  final OfficeDomKit _kit;
  late final DomElement _input;
  late final DomElement _root;
  String _current = '';

  DomElement build() {
    final wrap = _kit.el('div', 'dq-office-combo');
    _root = wrap;
    // A classe semântica fica no INPUT, não no invólucro: para quem consome
    // o componente (tema, teste, automação) `.dq-office-font-size` continua
    // sendo o campo com `.value`, exatamente como era o `<select>`.
    final input = _kit.el('input', 'dq-office-combo-input $cssClass');
    input.setAttribute('type', 'text');
    input.setAttribute('spellcheck', 'false');
    if (title != null) {
      input.setAttribute('title', title!);
      input.setAttribute('aria-label', title!);
    }
    _input = input;
    input.addEventListener('change', (_) => _commitTyped());
    input.addEventListener('keydown', (event) {
      if (event is! DomKeyboardEvent) return;
      if (event.key == 'Enter') {
        event.preventDefault();
        _commitTyped();
      } else if (event.key == 'Escape') {
        // Esc no campo desiste da digitação e devolve o valor do modelo —
        // sem isso o usuário fica preso a um texto inválido.
        _input.value = _current;
        controller.overlay.closeGroup(_group);
      } else if (event.key == 'ArrowDown') {
        event.preventDefault();
        _openList();
      }
    });
    wrap.append(input);

    final caret = _kit.el('button', 'dq-office-combo-caret');
    caret.setAttribute('type', 'button');
    caret.setAttribute('tabindex', '-1');
    if (title != null) caret.setAttribute('aria-label', title!);
    caret.addEventListener('mousedown', (event) => event.preventDefault());
    caret.addEventListener('click', (event) {
      event.preventDefault();
      // Clicar de novo fecha, como toda galeria da ribbon.
      if (controller.overlay.closeGroup(_group)) return;
      _openList();
    });
    wrap.append(caret);
    return wrap;
  }

  String get _group => 'combo:$cssClass';

  /// Reflete o modelo. Vazio = seleção mista (o comportamento do Word).
  void setValue(String? value) {
    _current = value ?? '';
    _input.value = _current;
  }

  void _commitTyped() {
    final raw = _input.value.trim();
    if (raw.isEmpty) {
      _input.value = _current;
      return;
    }
    final parsed = parseValue == null ? raw : parseValue!(raw);
    if (parsed == null) {
      _input.value = _current;
      return;
    }
    if (parsed == _current) {
      _input.value = parsed;
      return;
    }
    _current = parsed;
    _input.value = parsed;
    controller.syncSelection();
    onCommit(parsed);
  }

  void _openList() {
    final list = _kit.el('div', 'dq-office-combo-list');
    for (final item in items) {
      final option = _kit.el('button', 'dq-office-combo-item');
      option.setAttribute('type', 'button');
      if (item == _current) option.classes.add('dq-office-combo-item-active');
      if (previewFontPerItem) {
        option.setAttribute('style', "font-family:'$item';");
      }
      option.appendText(item);
      option.addEventListener('click', (event) {
        event.preventDefault();
        controller.overlay.closeGroup(_group);
        if (item == _current) return;
        _current = item;
        _input.value = item;
        controller.syncSelection();
        onCommit(item);
      });
      list.append(option);
    }
    controller.overlay.open(
      _group,
      list,
      anchor: _root,
      extraClass: 'dq-office-popup-list',
    );
  }
}
