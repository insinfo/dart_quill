/// Fontes de verdade no editor — opcionais, e agnósticas de plataforma.
///
/// ## O problema que esta camada resolve
///
/// O motor já sabia usar uma face real: com [LayoutFontSet] preenchido, o
/// compositor mede pela `hmtx` da própria fonte e o PDF a embute como
/// CID/Identity-H (`layout/fonts.dart`). O que faltava era **como a face
/// chega até lá**. Sem ela, três coisas discordam:
///
/// * o COMPOSITOR mede com a métrica compatível mais próxima (a Ecofont dos
///   documentos PGCTIC resolve para Calibri/Carlito);
/// * o BROWSER desenha com o que a máquina do usuário tiver instalado;
/// * o PDF desenha com uma standard-14 (Helvetica), ~7% mais larga.
///
/// Fornecendo a face, as três pontas passam a ser a MESMA fonte: a linha
/// quebra no mesmo lugar na tela, no PDF e no que o Word mostraria.
///
/// ## A estratégia: o pacote não busca nada
///
/// Nem rede, nem sistema de arquivos, nem `dart:html` — as três coisas
/// amarrariam a biblioteca a um ambiente. Quem busca é a APLICAÇÃO, por um
/// [OfficeFontLoader]: o editor descreve a fonte de que precisa
/// ([OfficeFontRequest]) e recebe bytes, ou `null` para "não tenho".
/// Um `null` é memorizado — o editor não pergunta duas vezes pela mesma face,
/// o que importa quando o loader faz rede.
///
/// A aplicação decide de onde vêm os bytes: um `fetch` de
/// `web/fonts/Carlito-Regular.ttf`, o asset bundle, IndexedDB, um CDN, um
/// pacote Dart de fontes. O exemplo `example/office_editor` traz um loader de
/// `fetch` em ~15 linhas.
///
/// ## O que a biblioteca faz com a face
///
/// 1. entrega ao compositor e ao renderer de PDF (via [fontSet]);
/// 2. registra no BROWSER (`@font-face` pela CSS Font Loading API, através da
///    abstração de DOM) — sem isso a projeção continuaria desenhando com
///    outra fonte, e medir com uma e desenhar com outra é pior do que não ter
///    a fonte;
/// 3. avisa quem monta o editor, que recompõe UMA vez quando faces novas
///    chegam.
///
/// ## As quatro portas
///
/// **1. Editor com loader** (o caso normal: só depois de abrir o DOCX se sabe
/// de que fontes ele precisa):
///
/// ```dart
/// OfficeWordEditor.mount(
///   host: host, adapter: adapter, document: doc,
///   options: OfficeWordEditorOptions(fontLoader: (request) async {
///     for (final family in {request.family, ...request.aliases}) {
///       final bytes = await meuFetch('fonts/$family${request.variantSuffix}.ttf');
///       if (bytes != null) return bytes;
///     }
///     return null; // não tenho — o editor segue com a métrica compatível
///   }),
/// );
/// ```
///
/// **2. Editor com faces já em memória** (a aplicação embute a fonte no
/// próprio bundle): `OfficeWordEditorOptions(fonts: LayoutFontSet([...]))`.
///
/// **3. DOCX → PDF sem editor**: as MESMAS faces nas duas pontas, senão a
/// linha quebra num lugar e é desenhada em outro.
///
/// ```dart
/// final fonts = LayoutFontSet([LayoutFontFace('Carlito', bytes)]);
/// final graph = LayoutComposer(setup: setup, fonts: fonts).compose(doc);
/// final pdf = OfficePdfService(title: nome, fonts: fonts).fromPageGraph(graph);
/// ```
///
/// **4. Delta → PDF** (`dart_quill_pdf.dart`, o exportador linear): o mesmo
/// acervo, convertido para o tipo dele — os campos são os mesmos.
///
/// ```dart
/// deltaToPdf(delta, options: PdfExportOptions(fontFaces: [
///   for (final face in library.faces)
///     PdfFontFace(face.family, face.bytes,
///         bold: face.bold, italic: face.italic),
/// ]));
/// ```
library;

import 'dart:async';
import 'dart:typed_data';

import '../../office/document/fonts/font_registry.dart';
import '../../platform/dom.dart';
import '../layout/fonts.dart';
import '../model/index.dart';

/// A face que o editor está pedindo.
final class OfficeFontRequest {
  const OfficeFontRequest({
    required this.family,
    required this.bold,
    required this.italic,
    this.aliases = const [],
  });

  /// A família como o DOCUMENTO a nomeia (`Ecofont_Spranq_eco_Sans`,
  /// `Calibri`, `Arial`).
  final String family;

  final bool bold;
  final bool italic;

  /// Famílias metricamente compatíveis, na ordem de preferência do
  /// `FontRegistry` (`Ecofont_Spranq_eco_Sans` → `calibri` → `carlito` →
  /// `arial`). O loader pode servir qualquer uma delas: quem monta o pacote
  /// de fontes raramente tem a face original, e servir a substituta correta é
  /// exatamente o que o Word faz.
  final List<String> aliases;

  /// Sufixo convencional de arquivo para esta variante ("-Bold", "-Italic",
  /// "-BoldItalic", ""). Existe para o loader mais comum — o que monta um
  /// caminho — não precisar reimplementar a mesma escada de ifs.
  String get variantSuffix => bold && italic
      ? '-BoldItalic'
      : bold
          ? '-Bold'
          : italic
              ? '-Italic'
              : '-Regular';

  @override
  String toString() => 'OfficeFontRequest($family$variantSuffix)';
}

/// Como a aplicação entrega bytes de fonte ao editor.
///
/// Devolver `null` significa "não tenho esta face" — não é erro, e o editor
/// segue com a métrica compatível. Uma exceção lançada aqui também é tratada
/// como ausência: uma fonte que não baixou não pode derrubar o documento.
typedef OfficeFontLoader = Future<Uint8List?> Function(OfficeFontRequest request);

/// Uma combinação família+peso+estilo REALMENTE usada por um documento.
final class OfficeFontUsage {
  const OfficeFontUsage(this.family, {this.bold = false, this.italic = false});

  final String family;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is OfficeFontUsage &&
      other.family.toLowerCase() == family.toLowerCase() &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(family.toLowerCase(), bold, italic);

  @override
  String toString() =>
      'OfficeFontUsage($family${bold ? '+bold' : ''}${italic ? '+italic' : ''})';
}

/// As faces que um documento pede de verdade.
///
/// Perguntar por (família × 4 variantes) desperdiçaria requisições numa
/// biblioteca que faz rede; o documento diz exatamente de que precisa. A
/// varredura cobre marcas de run, a família resolvida no `attrs['style']` do
/// bloco e o conteúdo das CAIXAS DE TEXTO (que vive como JSON no atributo, e
/// é onde mora o timbre de muitos documentos oficiais).
Set<OfficeFontUsage> officeFontUsageOf(PMNode doc) {
  final usage = <OfficeFontUsage>{};
  void addFromStyle(Object? style) {
    if (style is! Map) return;
    final family = style['family'];
    if (family is String && family.trim().isNotEmpty) {
      usage.add(OfficeFontUsage(
        family.trim(),
        bold: style['bold'] == true,
        italic: style['italic'] == true,
      ));
    }
  }

  doc.descendants((node, pos, parent, index) {
    addFromStyle(node.attrs['style']);
    final textBoxDoc = node.attrs['textBoxDoc'];
    if (textBoxDoc is Map) _usageFromJson(textBoxDoc, usage);
    if (!node.isText) return true;
    String? family;
    var bold = false;
    var italic = false;
    for (final mark in node.marks) {
      switch (mark.type.name) {
        case 'font':
          final value = mark.attrs['value'];
          if (value is String && value.trim().isNotEmpty) {
            family = value.trim();
          }
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
      }
    }
    if (family != null) {
      usage.add(OfficeFontUsage(family, bold: bold, italic: italic));
    }
    return true;
  });
  return usage;
}

/// A mesma varredura sobre a projeção JSON de uma caixa de texto.
void _usageFromJson(Object? node, Set<OfficeFontUsage> usage) {
  if (node is List) {
    for (final child in node) {
      _usageFromJson(child, usage);
    }
    return;
  }
  if (node is! Map) return;
  final attrs = node['attrs'];
  if (attrs is Map) {
    final style = attrs['style'];
    if (style is Map) {
      final family = style['family'];
      if (family is String && family.trim().isNotEmpty) {
        usage.add(OfficeFontUsage(
          family.trim(),
          bold: style['bold'] == true,
          italic: style['italic'] == true,
        ));
      }
    }
  }
  final marks = node['marks'];
  if (marks is List) {
    String? family;
    var bold = false;
    var italic = false;
    for (final mark in marks) {
      if (mark is! Map) continue;
      switch (mark['type']) {
        case 'font':
          final value = mark['attrs'] is Map ? mark['attrs']['value'] : null;
          if (value is String && value.trim().isNotEmpty) family = value.trim();
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
      }
    }
    if (family != null) {
      usage.add(OfficeFontUsage(family, bold: bold, italic: italic));
    }
  }
  _usageFromJson(node['content'], usage);
}

/// O acervo de faces do editor: o que já está carregado, o que foi pedido e
/// não existe, e a ponte com o browser.
class OfficeFontLibrary {
  OfficeFontLibrary({
    List<LayoutFontFace> faces = const [],
    this.loader,
    this.adapter,
    this.onChanged,
  }) {
    for (final face in faces) {
      _faces.add(face);
      _loaded.add(_keyOf(face.family, bold: face.bold, italic: face.italic));
    }
    if (faces.isNotEmpty) _registerAll(faces);
  }

  /// Quem busca os bytes. Null = a aplicação não quis fontes reais, e o
  /// editor segue com as métricas compatíveis (o comportamento histórico).
  final OfficeFontLoader? loader;

  /// Por onde a face é registrada no browser. Null (VM/testes) apenas pula o
  /// registro — medir e embutir no PDF continuam funcionando.
  final DomAdapter? adapter;

  /// Chamado quando faces NOVAS entraram: é o sinal para recompor.
  final void Function()? onChanged;

  final List<LayoutFontFace> _faces = [];
  final Set<String> _loaded = {};
  final Set<String> _missing = {};
  final Map<String, Future<void>> _inFlight = {};

  /// As faces para o compositor e para o renderer de PDF.
  LayoutFontSet get fontSet => LayoutFontSet(List.unmodifiable(_faces));

  List<LayoutFontFace> get faces => List.unmodifiable(_faces);
  bool get isEmpty => _faces.isEmpty;
  int get faceCount => _faces.length;

  /// Famílias que o loader disse não ter. Diagnóstico — é o que explica por
  /// que um documento continua sendo medido pela métrica compatível.
  Set<String> get missing => Set.unmodifiable(_missing);

  bool has(String family, {bool bold = false, bool italic = false}) =>
      _loaded.contains(_keyOf(family, bold: bold, italic: italic));

  /// Acrescenta uma face já em memória (o caminho síncrono: a aplicação que
  /// embute a fonte no próprio bundle).
  void addFace(LayoutFontFace face) {
    final key = _keyOf(face.family, bold: face.bold, italic: face.italic);
    if (!_loaded.add(key)) return;
    _faces.add(face);
    _registerAll([face]);
    onChanged?.call();
  }

  /// Garante as faces que [doc] realmente usa. Devolve quantas ENTRARAM.
  ///
  /// [extraDocuments] cobre cabeçalhos, rodapés e variantes — raízes próprias
  /// que não estão dentro do documento do corpo.
  Future<int> ensureForDocument(
    PMNode doc, {
    Iterable<PMNode> extraDocuments = const [],
  }) {
    final usage = officeFontUsageOf(doc);
    for (final extra in extraDocuments) {
      usage.addAll(officeFontUsageOf(extra));
    }
    return ensureAll(usage);
  }

  /// Garante uma lista de combinações. Devolve quantas faces novas entraram.
  Future<int> ensureAll(Iterable<OfficeFontUsage> usage) async {
    final load = loader;
    if (load == null) return 0;
    final pending = <Future<void>>[];
    var before = _faces.length;
    for (final item in usage) {
      final key = _keyOf(item.family, bold: item.bold, italic: item.italic);
      if (_loaded.contains(key) || _missing.contains(key)) continue;
      final existing = _inFlight[key];
      if (existing != null) {
        pending.add(existing);
        continue;
      }
      final future = _load(load, item, key);
      _inFlight[key] = future;
      pending.add(future);
    }
    if (pending.isEmpty) return 0;
    await Future.wait(pending);
    final added = _faces.length - before;
    before = _faces.length;
    if (added > 0) onChanged?.call();
    return added;
  }

  Future<void> _load(
      OfficeFontLoader load, OfficeFontUsage item, String key) async {
    try {
      final bytes = await load(OfficeFontRequest(
        family: item.family,
        bold: item.bold,
        italic: item.italic,
        aliases: officeFontAliasesOf(item.family),
      ));
      if (bytes == null || bytes.isEmpty) {
        // Memoriza a AUSÊNCIA: sem isto, um loader que faz rede repetiria a
        // requisição a cada recomposição do documento.
        _missing.add(key);
        return;
      }
      final face = LayoutFontFace(
        item.family,
        bytes,
        bold: item.bold,
        italic: item.italic,
      );
      // Um arquivo corrompido (ou um HTML de erro 404 servido como fonte) não
      // pode derrubar a abertura do documento: o parse é forçado aqui, dentro
      // do try, em vez de explodir depois na primeira medição.
      face.font;
      _loaded.add(key);
      _faces.add(face);
      _registerAll([face]);
    } catch (_) {
      _missing.add(key);
    } finally {
      // `remove` devolve o próprio Future que está terminando aqui; descartá-lo
      // é intencional — quem precisava dele já o está esperando em `ensureAll`.
      _inFlight.remove(key)?.ignore();
    }
  }

  void _registerAll(List<LayoutFontFace> faces) {
    final target = adapter;
    if (target == null) return;
    for (final face in faces) {
      // O registro no browser é assíncrono e best-effort: a projeção passa a
      // desenhar com a face assim que ela é aceita, e a medição já está certa
      // desde o instante em que os bytes chegaram. Por isso ele NÃO é
      // esperado — segurar a recomposição até o browser aceitar a fonte
      // atrasaria o documento por um detalhe de pintura.
      unawaited(target.registerFontFaceIfSupported(
        face.family,
        face.bytes,
        bold: face.bold,
        italic: face.italic,
      ));
    }
  }

  static String _keyOf(String family,
          {required bool bold, required bool italic}) =>
      '${family.trim().toLowerCase()}|${bold ? 'b' : ''}${italic ? 'i' : ''}';
}

/// A cadeia de famílias metricamente compatíveis conhecida pelo registro.
///
/// Exposta porque é o que permite a um loader simples servir Carlito quando o
/// documento pede a Ecofont — sem reimplementar a tabela de aliases.
List<String> officeFontAliasesOf(String family) =>
    FontRegistry.instance.fallbackFamilyStack(family);
