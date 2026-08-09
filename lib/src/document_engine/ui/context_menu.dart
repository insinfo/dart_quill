/// O menu de botão direito do editor.
///
/// Sem ele o usuário recebe o menu do BROWSER (Voltar, Recarregar, Inspecionar)
/// em cima de um documento — a interação mais visivelmente "não é um editor"
/// que existe. Aqui o menu é do documento: recortar/copiar/colar, os
/// diálogos de Fonte e Parágrafo, e os itens de tabela quando o cursor está
/// numa.
///
/// O conteúdo é CONTEXTUAL, como no Word: o que não se aplica não aparece
/// (itens de tabela fora de tabela) e o que não pode agora aparece
/// desabilitado (copiar sem seleção), em vez de sumir e mudar o menu de
/// lugar a cada clique.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'dialogs/font_dialog.dart';
import 'dialogs/paragraph_dialog.dart';
import 'menu.dart';
import 'ribbon_actions.dart' as actions;
import 'table_ops.dart' as table_ops;

const String officeContextMenuGroup = 'contextmenu';

class OfficeContextMenu {
  OfficeContextMenu(this.controller);

  final OfficeWordController controller;

  /// Abre o menu nas coordenadas do evento. Chamado pelo orquestrador no
  /// `contextmenu` do canvas, que também cancela o menu nativo.
  void openAt(num x, num y) {
    if (!controller.viewReady) return;
    controller.syncSelection();
    openMenuAt(controller, officeContextMenuGroup, x, y, entries());
  }

  /// As entradas do contexto atual — públicas para os testes e para uma
  /// aplicação que queira estendê-las.
  List<OfficeMenuEntry> entries() {
    final state = controller.view.state;
    final hasSelection = !state.selection.empty;
    final inTable = table_ops.tableDepthOf(state) != null;

    return [
      OfficeMenuEntry(
        label: 'Recortar',
        detail: 'Ctrl+X',
        icon: 'cut',
        enabled: hasSelection,
        onSelect: () => actions.cutSelection(controller),
      ),
      OfficeMenuEntry(
        label: 'Copiar',
        detail: 'Ctrl+C',
        icon: 'copy',
        enabled: hasSelection,
        onSelect: () => actions.copySelection(controller),
      ),
      OfficeMenuEntry(
        label: 'Colar',
        // O clipboard do SISTEMA exige permissão/gesto que um item de menu
        // não garante em todo browser; este item cola o recorte feito no
        // editor, e o rótulo diz isso em vez de falhar em silêncio.
        detail: 'Ctrl+V',
        icon: 'paste',
        enabled: actions.hasInternalClipboard,
        onSelect: () => actions.pasteInternal(controller),
      ),
      const OfficeMenuEntry.separator(),
      OfficeMenuEntry(
        label: 'Negrito',
        detail: 'Ctrl+B',
        icon: 'bold',
        onSelect: () => controller.runCommand('bold'),
      ),
      OfficeMenuEntry(
        label: 'Itálico',
        detail: 'Ctrl+I',
        icon: 'italic',
        onSelect: () => controller.runCommand('italic'),
      ),
      OfficeMenuEntry(
        label: 'Sublinhado',
        detail: 'Ctrl+U',
        icon: 'underline',
        onSelect: () => controller.runCommand('underline'),
      ),
      OfficeMenuEntry(
        label: 'Limpar Formatação',
        icon: 'clearstyle',
        onSelect: () => actions.clearFormatting(controller),
      ),
      const OfficeMenuEntry.separator(),
      OfficeMenuEntry(
        label: 'Fonte…',
        onSelect: () => openFontDialog(controller),
      ),
      OfficeMenuEntry(
        label: 'Parágrafo…',
        onSelect: () => openParagraphDialog(controller),
      ),
      const OfficeMenuEntry.separator(),
      OfficeMenuEntry(
        label: 'Aumentar Recuo',
        icon: 'incoffset',
        onSelect: () => actions.indentBy(controller, 720),
      ),
      OfficeMenuEntry(
        label: 'Diminuir Recuo',
        icon: 'decoffset',
        onSelect: () => actions.indentBy(controller, -720),
      ),
      if (inTable) ...[
        const OfficeMenuEntry.separator(),
        OfficeMenuEntry(
          label: 'Inserir Linha Acima',
          icon: 'addcell',
          onSelect: () => table_ops.tableInsertRow(
              controller.view.state, controller.dispatch, controller.schema,
              above: true),
        ),
        OfficeMenuEntry(
          label: 'Inserir Linha Abaixo',
          onSelect: () => table_ops.tableInsertRow(
              controller.view.state, controller.dispatch, controller.schema,
              above: false),
        ),
        OfficeMenuEntry(
          label: 'Inserir Coluna à Esquerda',
          onSelect: () => table_ops.tableInsertColumn(
              controller.view.state, controller.dispatch, controller.schema,
              before: true),
        ),
        OfficeMenuEntry(
          label: 'Inserir Coluna à Direita',
          onSelect: () => table_ops.tableInsertColumn(
              controller.view.state, controller.dispatch, controller.schema,
              before: false),
        ),
        OfficeMenuEntry(
          label: 'Excluir Linha',
          icon: 'delcell',
          onSelect: () => table_ops.tableDeleteRow(
              controller.view.state, controller.dispatch),
        ),
        OfficeMenuEntry(
          label: 'Excluir Coluna',
          onSelect: () => table_ops.tableDeleteColumn(
              controller.view.state, controller.dispatch),
        ),
        OfficeMenuEntry(
          label: 'Excluir Tabela',
          onSelect: () =>
              table_ops.tableDelete(controller.view.state, controller.dispatch),
        ),
      ],
    ];
  }
}

/// Instala o `contextmenu` em [surface]. Devolve o listener para o
/// orquestrador removê-lo no dispose.
DomEventListener installContextMenu(
  OfficeWordController controller,
  DomElement surface,
  OfficeContextMenu menu,
) {
  void handler(DomEvent event) {
    // Sem `preventDefault` o menu do browser aparece POR CIMA do nosso.
    event.preventDefault();
    final x = event is DomMouseEvent ? event.clientX : 0;
    final y = event is DomMouseEvent ? event.clientY : 0;
    menu.openAt(x, y);
  }

  surface.addEventListener('contextmenu', handler);
  return handler;
}
