/// O catálogo de estilos DO DOCUMENTO (plano §3.7, fase F8).
///
/// A importação já resolve a cascata do Word para cada parágrafo e grava o
/// resultado em `attrs['style']` — mas o resultado é ANÔNIMO: o editor sabe
/// que aquele bloco tem 14 pt em Arial e não sabe que isso se chama
/// "Nível 01". A galeria da Página Inicial precisa do outro lado da moeda:
/// os estilos como ENTIDADES (nome, id, herança, prioridade) com as
/// propriedades resolvidas de cada um.
///
/// Três decisões travam este arquivo:
///
/// * **A resolução é a mesma do importador** (docDefaults → cadeia `basedOn`
///   da raiz para a folha), e as chaves do mapa resolvido são LITERALMENTE
///   as de `attrs['style']`. É o que permite aplicar um estilo da galeria
///   escrevendo o mapa no bloco: o compositor já sabe lê-lo, e nenhuma
///   segunda linguagem de apresentação nasce aqui.
/// * **Editar um estilo é um patch TEXTUAL no `styles.xml`**, elemento a
///   elemento. Reserializar a parte inteira a partir do nosso modelo perderia
///   `w:latentStyles`, `w:semiHidden`, `w:next`, rsids e os estilos que nem
///   representamos — num `styles.xml` real isso é ~78 KB de conteúdo alheio.
///   O patch troca só o `<w:jc>`/`<w:ind>`/`<w:spacing>`/`<w:rFonts>`/`<w:sz>`
///   /`<w:b>`/`<w:name>`/`<w:qFormat>` do estilo tocado; o resto do arquivo
///   sai byte a byte.
/// * **O catálogo só descreve o que o motor honra.** As propriedades
///   resolvidas de PARÁGRAFO entram em [OfficeStyleFormatting] (editáveis:
///   o compositor as lê de `attrs['style']` e a exportação as grava). Cor,
///   itálico e sublinhado ficam em [OfficeStylePreview] — servem ao cartão
///   da galeria, mas NÃO viram controle de diálogo, porque
///   `LayoutComposer._BlockStyle` não tem esses campos e um controle assim
///   mudaria o modelo sem mudar a tela.
library;

import '../../office/document/docx/model.dart';
import '../../office/document/docx/styles.dart';
import 'snapshot.dart';

/// As propriedades de um estilo que o editor pode EDITAR.
///
/// A lista não é um recorte de conveniência: cada campo foi conferido nas
/// duas pontas — `LayoutComposer._resolvedStyleOf` o lê de `attrs['style']`,
/// e [OfficeStyleCatalog.patchStylesXml] o grava no `styles.xml`. O que não
/// passa nos dois testes não entra aqui (ver o doc da biblioteca).
class OfficeStyleFormatting {
  const OfficeStyleFormatting({
    this.family,
    this.sizePt,
    this.bold,
    this.align,
    this.indentTwips,
    this.rightIndentTwips,
    this.firstLineIndentTwips,
    this.spaceBeforeTwips,
    this.spaceAfterTwips,
    this.lineTwips,
    this.lineRule,
  });

  final String? family;
  final double? sizePt;
  final bool? bold;

  /// `left` | `center` | `right` | `justify` (o vocabulário de `attrs`,
  /// não o do OOXML — a tradução mora no patch).
  final String? align;

  final int? indentTwips;
  final int? rightIndentTwips;

  /// Negativo = recuo pendente (`w:hanging`), como em `attrs['style']`.
  final int? firstLineIndentTwips;

  final int? spaceBeforeTwips;
  final int? spaceAfterTwips;

  /// Valor cru de `w:spacing/@line` com a regra em [lineRule].
  final int? lineTwips;
  final String? lineRule;

  OfficeStyleFormatting copyWith({
    String? family,
    double? sizePt,
    bool? bold,
    String? align,
    int? indentTwips,
    int? rightIndentTwips,
    int? firstLineIndentTwips,
    int? spaceBeforeTwips,
    int? spaceAfterTwips,
    int? lineTwips,
    String? lineRule,
  }) =>
      OfficeStyleFormatting(
        family: family ?? this.family,
        sizePt: sizePt ?? this.sizePt,
        bold: bold ?? this.bold,
        align: align ?? this.align,
        indentTwips: indentTwips ?? this.indentTwips,
        rightIndentTwips: rightIndentTwips ?? this.rightIndentTwips,
        firstLineIndentTwips: firstLineIndentTwips ?? this.firstLineIndentTwips,
        spaceBeforeTwips: spaceBeforeTwips ?? this.spaceBeforeTwips,
        spaceAfterTwips: spaceAfterTwips ?? this.spaceAfterTwips,
        lineTwips: lineTwips ?? this.lineTwips,
        lineRule: lineRule ?? this.lineRule,
      );

  /// O mesmo mapa PARCIAL que a importação grava em `attrs['style']`: as
  /// chaves ausentes herdam a heurística do compositor, exatamente como num
  /// bloco importado.
  Map<String, dynamic> toBlockStyle() => {
        if (family != null) 'family': family,
        if (sizePt != null) 'sizePt': sizePt,
        if (bold != null) 'bold': bold,
        if (align != null) 'align': align,
        if (indentTwips != null) 'indentTwips': indentTwips,
        if (rightIndentTwips != null) 'rightIndentTwips': rightIndentTwips,
        if (firstLineIndentTwips != null)
          'firstLineIndentTwips': firstLineIndentTwips,
        if (spaceBeforeTwips != null) 'spaceBeforeTwips': spaceBeforeTwips,
        if (spaceAfterTwips != null) 'spaceAfterTwips': spaceAfterTwips,
        if (lineTwips != null) 'lineTwips': lineTwips,
        if (lineRule != null) 'lineRule': lineRule,
      };
}

/// O que o CARTÃO da galeria desenha, além do editável.
///
/// Separado de propósito: itálico, sublinhado e cor descrevem fielmente o
/// estilo (o texto importado carrega essas marcas, então o preview não
/// mente), mas o compositor não os resolve a partir do bloco — por isso não
/// viram controle de edição.
class OfficeStylePreview {
  const OfficeStylePreview({
    this.family,
    this.sizePt,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
    this.align,
  });

  final String? family;
  final double? sizePt;
  final bool bold;
  final bool italic;
  final bool underline;

  /// `#RRGGBB`, ou null para automático.
  final String? color;

  final String? align;
}

/// Sentinela de [OfficeStyleDefinition.copyWith] — ver o doc de lá.
const Object _keep = Object();

/// Um estilo do documento, com a cascata já resolvida.
class OfficeStyleDefinition {
  const OfficeStyleDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.formatting,
    required this.preview,
    this.basedOn,
    this.uiPriority = 0,
    this.inGallery = false,
    this.isDefault = false,
  });

  /// `w:styleId` — a IDENTIDADE. É o que vai para `word.styleId` e o que a
  /// ribbon compara para acender o cartão; o nome é só rótulo e muda.
  final String id;

  /// `w:name/@w:val`, ou o próprio id quando o estilo não declara nome.
  final String name;

  /// `paragraph` | `character` | `table` | `numbering`.
  final String type;

  final String? basedOn;
  final int uiPriority;

  /// `w:qFormat` — o estilo aparece na galeria da faixa de opções.
  final bool inGallery;

  /// `w:default="1"` do seu tipo (o `Normal` de um DOCX típico).
  final bool isDefault;

  final OfficeStyleFormatting formatting;
  final OfficeStylePreview preview;

  /// [basedOn] usa um sentinela em vez de `null` porque `null` é um valor
  /// LEGÍTIMO aqui: "(nenhum)" no diálogo significa desligar a herança, e
  /// com o `??` habitual essa escolha seria silenciosamente ignorada.
  OfficeStyleDefinition copyWith({
    String? name,
    Object? basedOn = _keep,
    bool? inGallery,
    OfficeStyleFormatting? formatting,
    OfficeStylePreview? preview,
  }) =>
      OfficeStyleDefinition(
        id: id,
        name: name ?? this.name,
        type: type,
        basedOn: identical(basedOn, _keep) ? this.basedOn : basedOn as String?,
        uiPriority: uiPriority,
        inGallery: inGallery ?? this.inGallery,
        isDefault: isDefault,
        formatting: formatting ?? this.formatting,
        preview: preview ?? this.preview,
      );
}

/// O catálogo do documento aberto.
///
/// Mutável de propósito: criar/modificar/renomear um estilo atualiza o
/// catálogo em memória e registra a intenção de patch; a gravação do
/// `styles.xml` acontece na exportação, sobre o XML de origem.
class OfficeStyleCatalog {
  OfficeStyleCatalog._(this._byId, this._creationOrder);

  final Map<String, OfficeStyleDefinition> _byId;

  /// A ordem de declaração no `styles.xml`. Empates de `uiPriority` na
  /// galeria são desempatados por ela, não pelo hash do mapa — senão a
  /// galeria embaralharia a cada abertura do mesmo documento.
  final List<String> _creationOrder;

  /// Estilos alterados/criados nesta sessão, na ordem em que foram tocados.
  final List<String> _edited = [];

  /// Constrói o catálogo a partir do `styles.xml` já parseado.
  factory OfficeStyleCatalog.fromStyleSheet(WpStyleSheet sheet) {
    final byId = <String, OfficeStyleDefinition>{};
    final order = <String>[];
    for (final entry in sheet.byId.entries) {
      order.add(entry.key);
      byId[entry.key] = _definitionOf(sheet, entry.value);
    }
    return OfficeStyleCatalog._(byId, order);
  }

  factory OfficeStyleCatalog.fromStylesXml(String xml) =>
      OfficeStyleCatalog.fromStyleSheet(WpStyleSheet.parse(xml));

  /// O catálogo de um snapshot que carregue o `word/styles.xml` entre as
  /// partes opacas. Devolve null quando o snapshot foi importado com
  /// `includePackageResources: false` — é o caso do caminho rápido da UI,
  /// que passa o catálogo por fora em vez de reter o pacote inteiro.
  static OfficeStyleCatalog? fromSnapshot(OfficeDocumentSnapshot snapshot) {
    for (final part in snapshot.resources.opaqueParts) {
      if (part['uri'] == 'word/styles.xml' && part['data'] is String) {
        return OfficeStyleCatalog.fromStylesXml(part['data'] as String);
      }
    }
    return null;
  }

  Map<String, OfficeStyleDefinition> get byId => Map.unmodifiable(_byId);

  OfficeStyleDefinition? operator [](String? id) =>
      id == null ? null : _byId[id];

  bool get isEmpty => _byId.isEmpty;
  bool get isNotEmpty => _byId.isNotEmpty;

  /// Houve edição de estilo nesta sessão? A exportação só toca o
  /// `styles.xml` quando isto for verdadeiro.
  bool get hasEdits => _edited.isNotEmpty;

  /// O estilo `w:default="1"` de parágrafo — o "Normal" do documento.
  OfficeStyleDefinition? get defaultParagraphStyle {
    for (final id in _creationOrder) {
      final style = _byId[id];
      if (style != null && style.isDefault && style.type == 'paragraph') {
        return style;
      }
    }
    return null;
  }

  List<OfficeStyleDefinition> get paragraphStyles => [
        for (final id in _creationOrder)
          if (_byId[id]?.type == 'paragraph') _byId[id]!,
      ];

  /// Os cartões da galeria, na ordem do Word.
  ///
  /// Duas regras que vêm do Word e não do OOXML: só entram estilos de
  /// PARÁGRAFO com `w:qFormat`, e o estilo default entra SEMPRE. O default
  /// costuma tirar o `qFormat` do `w:latentStyles` (que não parseamos), e
  /// uma galeria sem "Normal" não teria caminho de volta ao corpo de texto.
  List<OfficeStyleDefinition> get gallery {
    final fallback = defaultParagraphStyle;
    // Só a CAUDA é ordenada: o default fica pregado em primeiro, como o
    // "Normal" do Word, e o resto segue `uiPriority` com a ordem de
    // declaração desempatando.
    final tail = <OfficeStyleDefinition>[
      for (final id in _creationOrder)
        if (_byId[id] case final style?)
          if (style.type == 'paragraph' &&
              style.inGallery &&
              style.id != fallback?.id)
            style,
    ]..sort((a, b) {
        final byPriority = a.uiPriority.compareTo(b.uiPriority);
        if (byPriority != 0) return byPriority;
        return _creationOrder
            .indexOf(a.id)
            .compareTo(_creationOrder.indexOf(b.id));
      });
    return [if (fallback != null) fallback, ...tail];
  }

  /// O mapa de `attrs['style']` que um bloco recebe ao adotar [id].
  ///
  /// `wordStyleId` entra junto porque é o que o compositor usa para o
  /// espaçamento contextual e o que a ribbon lê para acender o cartão.
  Map<String, dynamic> blockStyleOf(String id) {
    final style = _byId[id];
    if (style == null) return {'wordStyleId': id};
    return {...style.formatting.toBlockStyle(), 'wordStyleId': id};
  }

  // -- mutação ---------------------------------------------------------------

  /// Grava (ou cria) a definição de um estilo. O id é imutável: renomear é
  /// [rename], que troca só o `w:name`.
  void upsert(OfficeStyleDefinition definition) {
    if (!_byId.containsKey(definition.id)) {
      _creationOrder.add(definition.id);
    }
    _byId[definition.id] = definition;
    _touch(definition.id);
  }

  void rename(String id, String name) {
    final style = _byId[id];
    if (style == null || name.trim().isEmpty || name == style.name) return;
    _byId[id] = style.copyWith(name: name.trim());
    _touch(id);
  }

  /// "Remover da Galeria" do Word: tira o `w:qFormat`, NÃO o estilo. Apagar
  /// a definição quebraria todo parágrafo que ainda a referencia.
  void setInGallery(String id, bool value) {
    final style = _byId[id];
    if (style == null || style.inGallery == value) return;
    _byId[id] = style.copyWith(inGallery: value);
    _touch(id);
  }

  void _touch(String id) {
    if (!_edited.contains(id)) _edited.add(id);
  }

  /// Um id de estilo novo derivado do nome, único no catálogo.
  ///
  /// O Word deriva o `styleId` do nome removendo tudo que não é
  /// alfanumérico (é por isso que "Título 1" virou `Ttulo1` nos DOCX
  /// brasileiros — o acento simplesmente cai). Reproduzir a regra é o que
  /// mantém o pacote reconhecível ao abrir no Word.
  String newIdFor(String name) {
    final base = name.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final seed = base.isEmpty ? 'Estilo' : base;
    if (!_byId.containsKey(seed)) return seed;
    for (var i = 1;; i++) {
      final candidate = '$seed$i';
      if (!_byId.containsKey(candidate)) return candidate;
    }
  }

  // -- patch do styles.xml ---------------------------------------------------

  /// Devolve o `styles.xml` com os estilos tocados atualizados.
  ///
  /// O que NÃO foi tocado sai caractere por caractere: o patch localiza o
  /// `<w:style …>…</w:style>` pelo `w:styleId` e reescreve só os elementos
  /// que o editor conhece. É a mesma disciplina do writer de `document.xml`
  /// — o que o modelo não representa não pode ser perdido no save.
  String patchStylesXml(String xml) {
    var result = xml;
    for (final id in _edited) {
      final style = _byId[id];
      if (style == null) continue;
      final span = _spanOfStyle(result, id);
      if (span == null) {
        result = _insertStyle(result, style);
      } else {
        result = result.replaceRange(
          span.$1,
          span.$2,
          _patchedStyleXml(result.substring(span.$1, span.$2), style),
        );
      }
    }
    return result;
  }

  /// Limites `[início, fim)` do elemento `<w:style>` de [id] em [xml].
  ///
  /// Varredura textual porque o alvo é a PRESERVAÇÃO: reparsear e
  /// reserializar o documento inteiro normalizaria aspas, espaços e
  /// namespaces de 78 KB de XML que ninguém pediu para mexer.
  static (int, int)? _spanOfStyle(String xml, String id) {
    final pattern = RegExp('<w:style(\\s[^>]*)?>');
    for (final match in pattern.allMatches(xml)) {
      final head = match.group(0)!;
      final styleId = RegExp('w:styleId="([^"]*)"').firstMatch(head)?.group(1);
      if (styleId != _xmlEscape(id) && styleId != id) continue;
      final close = xml.indexOf('</w:style>', match.end);
      if (close < 0) return null;
      return (match.start, close + '</w:style>'.length);
    }
    return null;
  }

  static String _insertStyle(String xml, OfficeStyleDefinition style) {
    final close = xml.lastIndexOf('</w:styles>');
    final serialized = _styleXml(style);
    if (close < 0) return xml + serialized;
    return xml.replaceRange(close, close, serialized);
  }

  /// Reescreve, DENTRO do `<w:style>` original, apenas os elementos que o
  /// editor governa. Tudo o mais (w:next, w:link, w:semiHidden, w:rsid, o
  /// `w:numPr` do estilo…) continua onde estava.
  static String _patchedStyleXml(String source, OfficeStyleDefinition style) {
    var result = source;
    result = _upsertChild(
        result, 'w:name', '<w:name w:val="${_xmlEscape(style.name)}"/>');
    // A ordem dos filhos de `w:style` é normativa (CT_Style é uma
    // `xsd:sequence`): `w:basedOn` DEPOIS de `w:name`. Inserir no começo
    // produziria um arquivo que o Word recusa a abrir.
    result = _upsertChild(
      result,
      'w:basedOn',
      style.basedOn == null
          ? null
          : '<w:basedOn w:val="${_xmlEscape(style.basedOn!)}"/>',
      after: const ['w:name'],
    );
    result = _upsertChild(
      result,
      'w:qFormat',
      style.inGallery ? '<w:qFormat/>' : null,
      after: const ['w:uiPriority', 'w:basedOn', 'w:name'],
    );

    final pPr = _paragraphPropertiesXml(style.formatting);
    final rPr = _runPropertiesXml(style.formatting);
    result = _upsertProperties(result, 'w:pPr', pPr);
    result = _upsertProperties(result, 'w:rPr', rPr);
    return result;
  }

  /// Um `<w:style>` inteiro, para o estilo que não existia no arquivo.
  static String _styleXml(OfficeStyleDefinition style) {
    final buffer = StringBuffer()
      ..write('<w:style w:type="${_xmlEscape(style.type)}"')
      ..write(' w:styleId="${_xmlEscape(style.id)}">')
      ..write('<w:name w:val="${_xmlEscape(style.name)}"/>');
    if (style.basedOn != null) {
      buffer.write('<w:basedOn w:val="${_xmlEscape(style.basedOn!)}"/>');
    }
    if (style.uiPriority != 0) {
      buffer.write('<w:uiPriority w:val="${style.uiPriority}"/>');
    }
    if (style.inGallery) buffer.write('<w:qFormat/>');
    final pPr = _paragraphPropertiesXml(style.formatting);
    final rPr = _runPropertiesXml(style.formatting);
    if (pPr.isNotEmpty) buffer.write('<w:pPr>$pPr</w:pPr>');
    if (rPr.isNotEmpty) buffer.write('<w:rPr>$rPr</w:rPr>');
    buffer.write('</w:style>');
    return buffer.toString();
  }

  /// Os filhos de `w:pPr` que o editor governa (o resto do pPr original é
  /// preservado por [_upsertProperties]).
  static String _paragraphPropertiesXml(OfficeStyleFormatting f) {
    final buffer = StringBuffer();
    final spacing = <String>[
      if (f.spaceBeforeTwips != null) 'w:before="${f.spaceBeforeTwips}"',
      if (f.spaceAfterTwips != null) 'w:after="${f.spaceAfterTwips}"',
      if (f.lineTwips != null) 'w:line="${f.lineTwips}"',
      if (f.lineRule != null) 'w:lineRule="${_xmlEscape(f.lineRule!)}"',
    ];
    if (spacing.isNotEmpty) {
      buffer.write('<w:spacing ${spacing.join(' ')}/>');
    }
    final indent = <String>[
      if (f.indentTwips != null) 'w:left="${f.indentTwips}"',
      if (f.rightIndentTwips != null) 'w:right="${f.rightIndentTwips}"',
      // Negativo em `attrs['style']` é o pendente do OOXML, que tem
      // atributo PRÓPRIO — gravar um firstLine negativo faria o Word
      // ignorar o recuo em vez de pendurar a primeira linha.
      if (f.firstLineIndentTwips != null && f.firstLineIndentTwips! >= 0)
        'w:firstLine="${f.firstLineIndentTwips}"',
      if (f.firstLineIndentTwips != null && f.firstLineIndentTwips! < 0)
        'w:hanging="${-f.firstLineIndentTwips!}"',
    ];
    if (indent.isNotEmpty) buffer.write('<w:ind ${indent.join(' ')}/>');
    final jc = _ooxmlAlign(f.align);
    if (jc != null) buffer.write('<w:jc w:val="$jc"/>');
    return buffer.toString();
  }

  static String _runPropertiesXml(OfficeStyleFormatting f) {
    final buffer = StringBuffer();
    if (f.family != null) {
      final escaped = _xmlEscape(f.family!);
      // ascii E hAnsi: o Word usa o segundo para o texto latino de
      // documentos gerados fora dele; escrever só um deixa metade das
      // máquinas com a fonte antiga.
      buffer.write('<w:rFonts w:ascii="$escaped" w:hAnsi="$escaped"/>');
    }
    if (f.bold != null) {
      buffer.write(f.bold! ? '<w:b/>' : '<w:b w:val="0"/>');
    }
    if (f.sizePt != null) {
      final half = (f.sizePt! * 2).round();
      // `w:szCs` acompanha: sem ele o Word mostra o corpo antigo em
      // qualquer trecho marcado como script complexo.
      buffer.write('<w:sz w:val="$half"/><w:szCs w:val="$half"/>');
    }
    return buffer.toString();
  }

  static String? _ooxmlAlign(String? align) => switch (align) {
        'center' => 'center',
        'right' => 'right',
        'justify' => 'both',
        'left' => 'left',
        _ => null,
      };

  /// Substitui (ou insere) um filho SIMPLES do `<w:style>`.
  ///
  /// [replacement] nulo REMOVE o elemento — é como "Remover da Galeria"
  /// apaga o `<w:qFormat/>`. [after] lista, do mais próximo ao mais
  /// distante, os irmãos depois dos quais o elemento NOVO pode entrar sem
  /// quebrar a sequência normativa de `CT_Style`; nenhum deles existindo, a
  /// inserção recua para logo após a tag de abertura, que é a posição
  /// correta do primeiro filho.
  static String _upsertChild(String source, String tag, String? replacement,
      {List<String> after = const []}) {
    final existing = _childSpan(source, tag);
    if (existing != null) {
      return source.replaceRange(existing.$1, existing.$2, replacement ?? '');
    }
    if (replacement == null) return source;
    for (final sibling in after) {
      final anchor = _childSpan(source, sibling)?.$2;
      if (anchor != null) {
        return source.replaceRange(anchor, anchor, replacement);
      }
    }
    final head = source.indexOf('>');
    if (head < 0) return source;
    return source.replaceRange(head + 1, head + 1, replacement);
  }

  /// Funde os filhos governados por nós dentro de `w:pPr`/`w:rPr`,
  /// preservando os demais filhos do contêiner original.
  ///
  /// A fusão só ESCREVE — nunca apaga um filho que não geramos. Um `w:jc`
  /// com valor que não modelamos (`distribute`) ou um `w:numPr` do estilo
  /// continuam onde estavam; apagar por omissão transformaria "não
  /// representamos isso" em "o usuário removeu isso".
  static String _upsertProperties(String source, String tag, String children) {
    if (children.isEmpty) return source;
    final existing = _childSpan(source, tag);
    if (existing == null) {
      // A ordem dos filhos de `w:style` é normativa: `w:pPr` antes de
      // `w:rPr`. Inserir os dois no fim inverteria a ordem e o Word
      // recusaria o arquivo.
      final anchor = tag == 'w:pPr'
          ? _childSpan(source, 'w:rPr')?.$1 ?? source.lastIndexOf('</w:style>')
          : source.lastIndexOf('</w:style>');
      if (anchor < 0) return source;
      return source.replaceRange(anchor, anchor, '<$tag>$children</$tag>');
    }
    final block = source.substring(existing.$1, existing.$2);
    final closeTag = '</$tag>';
    final selfClosing = !block.endsWith(closeTag);
    var inner = selfClosing
        ? ''
        : block.substring(
            block.indexOf('>') + 1, block.length - closeTag.length);
    for (final child in _governedChildren(children)) {
      inner = _upsertLeaf(inner, child.$1, child.$2);
    }
    return source.replaceRange(existing.$1, existing.$2, '<$tag>$inner</$tag>');
  }

  /// Quebra o XML gerado em pares `(tag, xml)` — é o que permite fundir
  /// elemento a elemento em vez de trocar o bloco inteiro.
  static List<(String, String)> _governedChildren(String xml) {
    final result = <(String, String)>[];
    for (final match in RegExp('<(w:[A-Za-z]+)[^>]*?/>').allMatches(xml)) {
      result.add((match.group(1)!, match.group(0)!));
    }
    return result;
  }

  static String _upsertLeaf(String inner, String tag, String replacement) {
    final existing = _childSpan(inner, tag);
    if (existing != null) {
      return inner.replaceRange(existing.$1, existing.$2, replacement);
    }
    return inner + replacement;
  }

  /// Limites do primeiro filho `<tag …/>` ou `<tag …>…</tag>` em [source].
  static (int, int)? _childSpan(String source, String tag) {
    final match = RegExp('<$tag(\\s[^>]*)?(/?)>').firstMatch(source);
    if (match == null) return null;
    if (match.group(2) == '/') return (match.start, match.end);
    final close = source.indexOf('</$tag>', match.end);
    if (close < 0) return (match.start, match.end);
    return (match.start, close + '</$tag>'.length);
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // -- resolução da cascata --------------------------------------------------

  static OfficeStyleDefinition _definitionOf(
      WpStyleSheet sheet, WpStyle style) {
    // docDefaults primeiro, depois a cadeia `basedOn` da RAIZ para a folha:
    // a ordem é normativa e inverter faria o estilo-base sobrescrever o
    // derivado (um "Nível 01" baseado em "Título 1" sairia com o corpo do
    // pai).
    WpParagraphProperties? pPr = sheet.docDefaultsParagraph;
    WpRunProperties? rPr = sheet.docDefaultsRun;
    for (final link in sheet.chainOf(style.id)) {
      final p = link.paragraphProperties;
      if (p != null) pPr = pPr == null ? p : pPr.mergedWith(p);
      final r = link.runProperties;
      if (r != null) rPr = rPr == null ? r : rPr.mergedWith(r);
    }

    final indent = pPr?.indent;
    final spacing = pPr?.spacing;
    final firstLine = indent?.hangingTwips != null
        ? -indent!.hangingTwips!
        : indent?.firstLineTwips;
    final family = rPr?.fontAscii ?? rPr?.fontHAnsi;
    final sizePt =
        rPr?.sizeHalfPoints == null ? null : rPr!.sizeHalfPoints! / 2.0;
    final align = _blockAlign(pPr?.jc);

    return OfficeStyleDefinition(
      id: style.id,
      name:
          style.name?.trim().isNotEmpty == true ? style.name!.trim() : style.id,
      type: style.type,
      basedOn: style.basedOn,
      uiPriority: style.uiPriority,
      inGallery: style.qFormat,
      isDefault: style.isDefault,
      formatting: OfficeStyleFormatting(
        family: family,
        sizePt: sizePt,
        bold: rPr?.bold,
        align: align,
        indentTwips: indent?.leftTwips,
        rightIndentTwips: indent?.rightTwips,
        firstLineIndentTwips: firstLine,
        spaceBeforeTwips: spacing?.beforeTwips,
        spaceAfterTwips: spacing?.afterTwips,
        lineTwips: spacing?.line,
        lineRule: spacing?.lineRule,
      ),
      preview: OfficeStylePreview(
        family: family,
        sizePt: sizePt,
        bold: rPr?.bold ?? false,
        italic: rPr?.italic ?? false,
        underline: rPr?.underline != null && rPr!.underline != 'none',
        color:
            rPr?.color == null || rPr!.color == 'auto' ? null : '#${rPr.color}',
        align: align,
      ),
    );
  }

  static String? _blockAlign(String? jc) => switch (jc) {
        'center' => 'center',
        'right' || 'end' => 'right',
        'both' || 'justify' => 'justify',
        'left' || 'start' => 'left',
        _ => null,
      };
}
