/// Inserir → Link (Ctrl+K): a marca `link`, que já existia no schema
/// (`office/schema.dart`), finalmente com UI.
///
/// Três decisões que não são óbvias:
///
/// * **O alvo é o link INTEIRO, não a seleção.** Com o cursor no meio de um
///   hiperlink, o Word abre "Editar Hiperlink" e reescreve a coisa toda; se
///   agíssemos só sobre a seleção, o usuário produziria dois links vizinhos
///   com endereços diferentes sem perceber.
/// * **A aparência é aplicada junto.** O compositor resolve a marca `link`
///   para `ResolvedRunStyle.link` e o renderer projeta um `data-link`
///   (`layout/dom_renderer.dart:583`) — que não muda um pixel. Um link
///   invisível é um controle que mente: por isso a mesma transação aplica
///   também azul e sublinhado, que é exatamente o que o estilo de caractere
///   "Hiperlink" do Word faz no run. Como formatação direta, sobrevive ao
///   round-trip DOCX sem depender de o documento ter o estilo definido.
/// * **Esquemas executáveis são recusados.** `javascript:` e `data:` num
///   `href` viram XSS na aplicação que renderizar o documento fora daqui; o
///   editor não é o lugar de guardar essa arma carregada.
library;

import '../../model/index.dart';
import '../../state/index.dart';
import '../controller.dart';
import 'dialog.dart';

/// O azul do estilo "Hiperlink" do Word.
const String officeHyperlinkColor = '#0563C1';

/// Um hiperlink encontrado no documento: a faixa COMPLETA e o endereço.
typedef OfficeLinkRange = ({int from, int to, String href});

/// O hiperlink sob a seleção/caret, ou null.
///
/// A varredura é dentro do bloco de texto: a marca não atravessa parágrafo,
/// e percorrer os filhos do bloco dá a faixa exata sem resolver posição a
/// posição.
OfficeLinkRange? officeLinkAt(EditorState state) {
  final type = state.doc.type.schema.marks['link'];
  if (type == null) return null;
  final selection = state.selection;
  final resolved = state.doc.resolve(selection.from);
  final parent = resolved.parent;
  if (!parent.isTextblock) return null;
  final base = resolved.start();

  final children = <({int from, int to, Mark? link})>[];
  parent.forEach((node, offset, index) {
    Mark? link;
    for (final mark in node.marks) {
      if (mark.type == type) link = mark;
    }
    children.add(
        (from: base + offset, to: base + offset + node.nodeSize, link: link));
  });

  // Primeiro o filho que CONTÉM a posição; só depois o que a encosta. A
  // ordem importa no ponto exato entre um link e o texto seguinte: ali o
  // usuário está no link, não no que vem depois (a marca é `inclusive:
  // false`, então digitar ali já não entra no link).
  var hit = -1;
  for (var i = 0; i < children.length && hit < 0; i++) {
    final child = children[i];
    if (child.link == null) continue;
    if (selection.from > child.from && selection.from < child.to) hit = i;
  }
  for (var i = 0; i < children.length && hit < 0; i++) {
    final child = children[i];
    if (child.link == null) continue;
    if (selection.from == child.from || selection.from == child.to) hit = i;
  }
  if (hit < 0) return null;

  final mark = children[hit].link!;
  var from = children[hit].from;
  var to = children[hit].to;
  for (var i = hit - 1; i >= 0; i--) {
    final link = children[i].link;
    if (link == null || !link.eq(mark)) break;
    from = children[i].from;
  }
  for (var i = hit + 1; i < children.length; i++) {
    final link = children[i].link;
    if (link == null || !link.eq(mark)) break;
    to = children[i].to;
  }
  return (from: from, to: to, href: '${mark.attrs['href']}');
}

/// Aplica (ou reescreve) o hiperlink na faixa `[from, to)`.
///
/// Com [text] diferente do que está lá, o texto é TROCADO primeiro — é como
/// o Word trata o campo "Texto para exibição". Tudo numa transação: um
/// Ctrl+Z desfaz o link inteiro, texto e formatação.
void officeApplyLink(
  OfficeWordController c, {
  required int from,
  required int to,
  required String text,
  required String href,
}) {
  final type = c.schema.marks['link'];
  final target = officeNormalizeHref(href);
  if (type == null || target == null) return;
  final state = c.activeView.state;
  if (from < 0 || to > state.doc.content.size || from > to) return;

  final tr = state.tr;
  var end = to;
  final current = state.doc.textBetween(from, to);
  if (text != current) {
    if (text.isEmpty) return;
    // Sem storedMarks o texto novo herda a formatação de onde ele nasce, em
    // vez de a marca armada pela última digitação.
    tr.setStoredMarks(null);
    tr.insertText(text, from, to);
    end = from + text.length;
  }
  if (end <= from) return;

  tr.removeMark(from, end, type);
  tr.addMark(from, end, type.create({'href': target}));
  final underline = c.schema.marks['underline'];
  if (underline != null) tr.addMark(from, end, underline.create());
  final color = c.schema.marks['color'];
  if (color != null) {
    tr.addMark(from, end, color.create({'value': officeHyperlinkColor}));
  }
  tr.setSelection(TextSelection.create(tr.doc, from, end));
  c.dispatch(tr);
}

/// Remover Hiperlink: tira a marca e a aparência que ELA trouxe.
///
/// O sublinhado e o azul só saem quando são os do hiperlink — um link que o
/// usuário pintou de vermelho perde o link, não a cor que ele escolheu.
void officeRemoveLink(OfficeWordController c,
    {required int from, required int to}) {
  final type = c.schema.marks['link'];
  if (type == null || from >= to) return;
  final state = c.activeView.state;
  if (from < 0 || to > state.doc.content.size) return;
  final tr = state.tr..removeMark(from, to, type);
  final color = c.schema.marks['color'];
  if (color != null) {
    tr.removeMark(from, to, color.create({'value': officeHyperlinkColor}));
  }
  final underline = c.schema.marks['underline'];
  if (underline != null) {
    tr.removeMark(from, to, underline.create());
  }
  c.dispatch(tr);
}

/// Normaliza o que o usuário digitou; null significa RECUSADO.
///
/// "www.exemplo.com" e "contato@exemplo.com" são o que as pessoas escrevem —
/// e sem esquema o link não abre em lugar nenhum. Esquemas executáveis são
/// recusados por segurança (ver o cabeçalho desta biblioteca).
String? officeNormalizeHref(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final lower = value.toLowerCase();
  if (lower.startsWith('javascript:') ||
      lower.startsWith('data:') ||
      lower.startsWith('vbscript:')) {
    return null;
  }
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(value)) return value;
  if (value.startsWith('#') || value.startsWith('/')) return value;
  if (value.contains('@') && !value.contains(' ')) return 'mailto:$value';
  return 'https://$value';
}

/// O diálogo Ctrl+K. Nada é aplicado enquanto ele está aberto.
void openLinkDialog(OfficeWordController c) {
  c.syncSelection();
  final state = c.activeView.state;
  final existing = officeLinkAt(state);
  final selection = state.selection;
  final from = existing?.from ?? selection.from;
  final to = existing?.to ?? selection.to;
  final text = state.doc.textBetween(from, to);

  OfficeDialog(
    controller: c,
    title: existing == null ? 'Inserir Link' : 'Editar Link',
    fields: [
      OfficeDialogField(
        key: 'text',
        label: 'Texto para exibição',
        kind: 'text',
        value: text,
      ),
      OfficeDialogField(
        key: 'href',
        label: 'Endereço',
        kind: 'text',
        value: existing?.href ?? '',
        hint: existing == null
            ? 'Sem esquema, vale https:// (ou mailto: para um e-mail).'
            : 'Endereço em branco REMOVE o link, mantendo o texto.',
      ),
    ],
    onApply: (values) {
      final href = (values['href'] ?? '').trim();
      if (href.isEmpty) {
        if (existing != null) officeRemoveLink(c, from: from, to: to);
        return;
      }
      officeApplyLink(
        c,
        from: from,
        to: to,
        text: values['text'] ?? '',
        href: href,
      );
    },
  ).open();
}
