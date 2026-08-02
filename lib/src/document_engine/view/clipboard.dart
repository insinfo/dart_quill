/// Clipboard do modo avançado — recortar, copiar e colar pelo MODELO.
///
/// Duas rotas deliberadamente diferentes:
///
/// * **interna** — o HTML que copiamos carrega o `Slice` serializado num
///   atributo. Colar de volta reconstrói a árvore EXATA, com marcas,
///   atributos e as bordas abertas do recorte. É o único jeito de copiar
///   meio parágrafo e colar meio parágrafo sem inventar estrutura.
/// * **externa** — HTML de outro programa é interpretado contra o schema,
///   e texto puro vira parágrafos. Aqui há perda por definição, e o que
///   não sabemos representar é DESCARTADO em vez de virar lixo estrutural.
///
/// O parsing usa `package:html` (já na allowlist) em vez do DOM do browser:
/// é o mesmo resultado em VM e em Chrome, então a mesma suíte cobre os dois
/// — e colar não depende de montar nada na projeção.
library;

import 'dart:convert';

import 'package:html/dom.dart' as h;
import 'package:html/parser.dart' as html_parser;

import '../model/index.dart';

/// O atributo que carrega o recorte serializado no HTML copiado.
const String officeSliceAttribute = 'data-dq-office-slice';

/// O que vai para a área de transferência.
class OfficeClipboardPayload {
  const OfficeClipboardPayload({required this.text, required this.html});

  final String text;
  final String html;
}

class OfficeClipboard {
  const OfficeClipboard();

  // -- modelo → área de transferência ---------------------------------------

  OfficeClipboardPayload serialize(Slice slice) {
    final text = slice.content.textBetween(
        0, slice.content.size, blockSeparator: '\n');
    final buffer = StringBuffer()
      ..write('<div $officeSliceAttribute="')
      ..write(_escapeAttribute(jsonEncode(slice.toJSON())))
      ..write('">');
    for (var i = 0; i < slice.content.childCount; i++) {
      _writeNode(buffer, slice.content.child(i));
    }
    buffer.write('</div>');
    return OfficeClipboardPayload(text: text, html: buffer.toString());
  }

  void _writeNode(StringBuffer buffer, PMNode node) {
    if (node.isText) {
      _writeText(buffer, node);
      return;
    }
    final tag = _blockTag(node);
    buffer.write('<$tag>');
    for (var i = 0; i < node.childCount; i++) {
      _writeNode(buffer, node.child(i));
    }
    buffer.write('</$tag>');
  }

  void _writeText(StringBuffer buffer, PMNode node) {
    final open = <String>[];
    for (final mark in node.marks) {
      final tag = _markTag(mark);
      if (tag == null) continue;
      if (mark.type.name == 'link') {
        buffer.write('<a href="${_escapeAttribute('${mark.attrs['href']}')}">');
      } else {
        buffer.write('<$tag>');
      }
      open.add(tag);
    }
    buffer.write(_escapeText(node.text ?? ''));
    for (final tag in open.reversed) {
      buffer.write('</$tag>');
    }
  }

  static String _blockTag(PMNode node) => switch (node.type.name) {
        'heading' => 'h${node.attrs['level'] ?? 1}',
        'blockquote' => 'blockquote',
        'codeBlock' => 'pre',
        'listItem' => 'li',
        _ => 'p',
      };

  static String? _markTag(Mark mark) => switch (mark.type.name) {
        'bold' => 'strong',
        'italic' => 'em',
        'underline' => 'u',
        'strike' => 's',
        'code' => 'code',
        'link' => 'a',
        _ => null,
      };

  // -- área de transferência → modelo ---------------------------------------

  /// Interpreta o que veio da área de transferência.
  ///
  /// Devolve null quando não há nada aproveitável — o chamador então não
  /// gera transação, em vez de inserir um bloco vazio.
  Slice? parse({String? html, String? text, required Schema schema}) {
    if (html != null && html.isNotEmpty) {
      final internal = _parseInternal(html, schema);
      if (internal != null) return internal;
      final external = _parseHtml(html, schema);
      if (external != null) return external;
    }
    if (text != null && text.isNotEmpty) return _parseText(text, schema);
    return null;
  }

  /// A rota sem perda: o recorte que nós mesmos serializamos.
  Slice? _parseInternal(String html, Schema schema) {
    final document = html_parser.parse(html);
    final holder = document.querySelector('[$officeSliceAttribute]');
    final raw = holder?.attributes[officeSliceAttribute];
    if (raw == null || raw.isEmpty) return null;
    try {
      return Slice.fromJSON(schema, jsonDecode(raw));
    } catch (_) {
      // Recorte de outra versão do schema, ou corrompido pelo caminho: cai
      // para a interpretação de HTML em vez de falhar a colagem inteira.
      return null;
    }
  }

  Slice? _parseHtml(String html, Schema schema) {
    final body = html_parser.parse(html).body;
    if (body == null) return null;
    final blocks = <PMNode>[];
    _collectBlocks(body, schema, blocks, const []);
    if (blocks.isEmpty) return null;
    return _openSlice(blocks);
  }

  /// Percorre a árvore HTML acumulando BLOCOS.
  ///
  /// Um elemento inline encontrado solto (texto direto no body, um `<span>`
  /// no meio) vira parágrafo: colar sempre produz estrutura válida para o
  /// schema, nunca texto órfão que o editor não saberia posicionar.
  void _collectBlocks(
    h.Node node,
    Schema schema,
    List<PMNode> blocks,
    List<Mark> marks,
  ) {
    final pending = <PMNode>[];

    void flushInline() {
      if (pending.isEmpty) return;
      // CÓPIA: Fragment.from guarda a lista recebida, e limpar `pending`
      // esvaziaria o fragmento já construído (com o tamanho antigo).
      blocks.add(
          schema.node('paragraph', null, Fragment.from(List.of(pending))));
      pending.clear();
    }

    for (final child in node.nodes) {
      if (child is h.Text) {
        final text = child.text;
        if (text.trim().isEmpty && pending.isEmpty) continue;
        pending.add(schema.text(text, marks));
        continue;
      }
      if (child is! h.Element) continue;

      final tag = child.localName?.toLowerCase() ?? '';
      final mark = _markFor(tag, child, schema);
      if (mark != null) {
        pending.addAll(_inlineOf(child, schema, [...marks, mark]));
        continue;
      }

      final block = _blockNameFor(tag);
      if (block == null) {
        // Container desconhecido (div, section, table...): desce nele em vez
        // de descartar o conteúdo.
        flushInline();
        _collectBlocks(child, schema, blocks, marks);
        continue;
      }

      flushInline();
      final inline = _inlineOf(child, schema, marks);
      if (inline.isEmpty && block != 'paragraph') continue;
      blocks.add(schema.node(
        block,
        _attrsFor(block, tag),
        Fragment.from(inline),
      ));
    }
    flushInline();
  }

  List<PMNode> _inlineOf(h.Node node, Schema schema, List<Mark> marks) {
    final result = <PMNode>[];
    for (final child in node.nodes) {
      if (child is h.Text) {
        if (child.text.isEmpty) continue;
        result.add(schema.text(child.text, marks));
        continue;
      }
      if (child is! h.Element) continue;
      final tag = child.localName?.toLowerCase() ?? '';
      final mark = _markFor(tag, child, schema);
      result.addAll(
          _inlineOf(child, schema, mark == null ? marks : [...marks, mark]));
    }
    return result;
  }

  static Mark? _markFor(String tag, h.Element element, Schema schema) {
    final name = switch (tag) {
      'strong' || 'b' => 'bold',
      'em' || 'i' => 'italic',
      'u' => 'underline',
      's' || 'strike' || 'del' => 'strike',
      'code' => 'code',
      'a' => 'link',
      _ => null,
    };
    if (name == null) return null;
    final type = schema.marks[name];
    if (type == null) return null;
    if (name == 'link') {
      final href = element.attributes['href'];
      if (href == null || href.isEmpty) return null;
      return type.create({'href': href});
    }
    return type.create();
  }

  static String? _blockNameFor(String tag) => switch (tag) {
        'p' => 'paragraph',
        'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => 'heading',
        'blockquote' => 'blockquote',
        'pre' => 'codeBlock',
        'li' => 'listItem',
        _ => null,
      };

  static Map<String, dynamic>? _attrsFor(String block, String tag) {
    if (block != 'heading') return null;
    return {'level': int.tryParse(tag.substring(1)) ?? 1};
  }

  Slice _parseText(String text, Schema schema) {
    final blocks = <PMNode>[];
    for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
      blocks.add(schema.node('paragraph', null,
          line.isEmpty ? Fragment.empty : Fragment.from([schema.text(line)])));
    }
    return _openSlice(blocks);
  }

  /// Abre as bordas quando todo o conteúdo é bloco de texto.
  ///
  /// É o que faz colar no MEIO de um parágrafo continuar o parágrafo em vez
  /// de parti-lo em dois: um recorte fechado carrega as fronteiras dos
  /// blocos junto, e o resultado seria "antes" + novo bloco + "depois". Com
  /// as bordas abertas, a primeira linha funde no bloco atual e a última
  /// funde com o que vinha depois — o comportamento do Word.
  static Slice _openSlice(List<PMNode> blocks) {
    final mergeable = blocks.every((block) => block.isTextblock);
    final fragment = Fragment.from(blocks);
    return mergeable ? Slice(fragment, 1, 1) : Slice(fragment, 0, 0);
  }

  // -- escaping --------------------------------------------------------------

  static String _escapeText(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _escapeAttribute(String value) =>
      _escapeText(value).replaceAll('"', '&quot;');
}
