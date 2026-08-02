/// O schema Office do PERFIL QUILL (Fase 3) — os nós e marcas necessários
/// para representar sem perda qualquer Delta do Quill 2.0.3 + table-better.
///
/// Não é o schema Word completo (seções, headers/footers, fields entram na
/// Fase 4/6); é a base que faz a alternância Quill↔Office funcionar desde
/// já. Duas decisões de desenho:
///
/// * todo nó de BLOCO declara o atributo `id` (nullable com default) — o
///   [officeIdsPlugin] cunha os valores; specs sem default tornariam o nó
///   não-gerável ("dead end" no content expression);
/// * o desconhecido tem rota de escape TOTAL: atributos de linha não
///   mapeados viajam em `extra`, embeds desconhecidos viram o nó `opaque` e
///   atributos inline não mapeados viram a marca `opaque` — importar nunca
///   perde dado, e cada uso das rotas gera entrada no compatibility report.
library;

import '../model/index.dart';
import 'ids.dart';

AttributeSpec _id() => AttributeSpec(defaultValue: null, hasDefault: true);
AttributeSpec _opt() => AttributeSpec(defaultValue: null, hasDefault: true);

/// `style` carrega a apresentação JÁ RESOLVIDA do bloco —
/// `{'sizePt': 14.0, 'bold': true, 'family': 'Arial', 'spaceBeforeTwips': …}`.
///
/// É diferente de `extra`, que preserva atributos que não sabemos ler:
/// `style` é consumido pelo LAYOUT. Ele existe porque a cascata do Word
/// (docDefaults → basedOn → estilo → formatação direta) precisa ser
/// resolvida uma vez, na importação, e não reinterpretada a cada
/// recomposição. Sem ele o composer usaria uma escala fixa por nível de
/// heading, e um documento cujo "Título 1" tem 14 pt sairia com 24.

/// Constrói o schema do perfil Quill.
Schema officeQuillSchema() {
  return Schema(SchemaSpec(
    nodes: {
      'doc': NodeSpec(content: 'block+'),
      'paragraph': NodeSpec(
        content: 'inline*',
        group: 'block',
        attrs: {
          officeIdAttribute: _id(),
          'align': _opt(),
          'indent': _opt(),
          'direction': _opt(),
          // Atributos de linha não mapeados (mapa), preservados verbatim.
          'style': _opt(),
          'extra': _opt(),
        },
      ),
      'heading': NodeSpec(
        content: 'inline*',
        group: 'block',
        defining: true,
        attrs: {
          officeIdAttribute: _id(),
          'level': AttributeSpec(defaultValue: 1),
          'align': _opt(),
          'style': _opt(),
          'extra': _opt(),
        },
      ),
      'blockquote': NodeSpec(
        content: 'inline*',
        group: 'block',
        defining: true,
        attrs: {officeIdAttribute: _id(), 'extra': _opt()},
      ),
      'codeBlock': NodeSpec(
        content: 'text*',
        group: 'block',
        code: true,
        defining: true,
        marks: '',
        attrs: {
          officeIdAttribute: _id(),
          'language': _opt(),
          'style': _opt(),
          'extra': _opt(),
        },
      ),
      'listItem': NodeSpec(
        content: 'inline*',
        group: 'block',
        attrs: {
          officeIdAttribute: _id(),
          // 'ordered' | 'bullet' | 'checked' | 'unchecked' — o modelo do
          // Quill 2 (formato no item, não no container) é mantido: casa com
          // o Delta e evita re-agrupar containers na importação.
          'kind': AttributeSpec(defaultValue: 'bullet'),
          'indent': _opt(),
          'align': _opt(),
          'style': _opt(),
          'extra': _opt(),
        },
      ),
      'table': NodeSpec(
        content: 'tableRow+',
        group: 'block',
        isolating: true,
        attrs: {
          officeIdAttribute: _id(),
          // Atributos da âncora table-temporary, verbatim (data-class,
          // style, border, cellspacing...).
          'anchor': _opt(),
          // Larguras de coluna (lista, dos ops table-col), verbatim.
          'colWidths': _opt(),
        },
      ),
      'tableRow': NodeSpec(
        content: 'tableCell+',
        attrs: {officeIdAttribute: _id(), 'rowId': _opt()},
      ),
      'tableCell': NodeSpec(
        content: 'block+',
        isolating: true,
        attrs: {
          officeIdAttribute: _id(),
          'cellId': _opt(),
          // Mapa table-cell/table-th verbatim (data-row, width, style,
          // rowspan, colspan...).
          'cell': _opt(),
          // 'td' | 'th'
          'tag': AttributeSpec(defaultValue: 'td'),
        },
      ),
      'image': NodeSpec(
        inline: true,
        group: 'inline',
        draggable: true,
        attrs: {
          'src': AttributeSpec(),
          'width': _opt(),
          'height': _opt(),
          'style': _opt(),
          'extra': _opt(),
        },
      ),
      'video': NodeSpec(
        inline: true,
        group: 'inline',
        attrs: {'src': AttributeSpec(), 'extra': _opt()},
      ),
      'formula': NodeSpec(
        inline: true,
        group: 'inline',
        attrs: {'value': AttributeSpec(), 'extra': _opt()},
      ),
      'headerImage': NodeSpec(
        group: 'block',
        atom: true,
        attrs: {officeIdAttribute: _id(), 'src': AttributeSpec()},
      ),
      // Embed de BLOCO desconhecido: o insert inteiro, verbatim.
      'opaque': NodeSpec(
        group: 'block',
        atom: true,
        attrs: {officeIdAttribute: _id(), 'insert': AttributeSpec()},
      ),
      // Embed INLINE desconhecido.
      'opaqueInline': NodeSpec(
        inline: true,
        group: 'inline',
        atom: true,
        attrs: {'insert': AttributeSpec()},
      ),
      'text': NodeSpec(group: 'inline'),
    },
    marks: {
      'bold': MarkSpec(),
      'italic': MarkSpec(),
      'underline': MarkSpec(),
      'strike': MarkSpec(),
      'code': MarkSpec(code: true),
      'script': MarkSpec(attrs: {'value': AttributeSpec()}), // sub | super
      'color': MarkSpec(attrs: {'value': AttributeSpec()}),
      'background': MarkSpec(attrs: {'value': AttributeSpec()}),
      'font': MarkSpec(attrs: {'value': AttributeSpec()}),
      'size': MarkSpec(attrs: {'value': AttributeSpec()}),
      'link': MarkSpec(
        attrs: {'href': AttributeSpec()},
        inclusive: false,
      ),
      // Atributos inline não mapeados: `{nome: valor, ...}` verbatim.
      'opaqueAttrs': MarkSpec(attrs: {'attrs': AttributeSpec()}),
    },
  ));
}
