/// Gera a folha de ícones `office_word_icons.css` do OfficeWordEditor a
/// partir dos SVGs oficiais do ONLYOFFICE.
///
/// Cada classe `dq-icon-<nome>` recebe o SVG como `mask-image` (data URI) e
/// pinta com `currentColor`. Uma FONTE de ícones — o formato anterior — não
/// serve para este conjunto: 266 dos SVGs do ONLYOFFICE usam
/// `fill-rule="evenodd"`, que glifos TrueType não representam. Convertidos
/// em fonte, os furos dos contornos fechavam e os ícones de disposição do
/// texto (e vários outros) viravam blocos pretos. Como máscara, o browser
/// rasteriza o próprio SVG, e o desenho é exatamente o do ONLYOFFICE.
///
/// Uso:
///
/// ```
/// dart run tool/build_icon_css.dart [caminho-para-onlyoffice-ribbon-icons-full]
/// dart run tool/build_icon_css.dart --check   # CI: a folha está atualizada?
/// ```
///
/// O argumento aponta para o diretório `onlyoffice-ribbon-icons-full` (um
/// checkout dos ícones do repositório ONLYOFFICE/web-apps). Sem argumento,
/// usa o caminho local padrão do autor. Não há dependência de Node.
///
/// Licença dos ícones: CC BY-SA 4.0 (ONLYOFFICE). A atribuição vai no
/// cabeçalho do CSS gerado e em THIRD_PARTY.md.
library;

import 'dart:io';

/// nome-final da classe (`dq-icon-<nome>`) -> caminho relativo do SVG dentro
/// de `apps/`.
const Map<String, String> icons = {
  // Página Inicial
  'undo': 'common/main/resources/img/toolbar/2.5x/btn-undo.svg',
  'redo': 'common/main/resources/img/toolbar/2.5x/btn-redo.svg',
  'copy': 'common/main/resources/img/toolbar/2.5x/btn-copy.svg',
  'cut': 'common/main/resources/img/toolbar/2.5x/btn-cut.svg',
  'paste': 'common/main/resources/img/toolbar/2.5x/btn-paste.svg',
  'bold': 'common/main/resources/img/toolbar/2.5x/btn-bold.svg',
  'italic': 'common/main/resources/img/toolbar/2.5x/btn-italic.svg',
  'underline': 'common/main/resources/img/toolbar/2.5x/btn-underline.svg',
  'strikeout': 'common/main/resources/img/toolbar/2.5x/btn-strikeout.svg',
  'superscript': 'common/main/resources/img/toolbar/2.5x/btn-superscript.svg',
  'subscript': 'common/main/resources/img/toolbar/2.5x/btn-subscript.svg',
  'align-left': 'common/main/resources/img/toolbar/2.5x/btn-align-left.svg',
  'align-center':
      'common/main/resources/img/toolbar/2.5x/btn-align-center.svg',
  'align-right': 'common/main/resources/img/toolbar/2.5x/btn-align-right.svg',
  'align-just': 'common/main/resources/img/toolbar/2.5x/btn-align-just.svg',
  'incfont': 'common/main/resources/img/toolbar/2.5x/btn-incfont.svg',
  'decfont': 'common/main/resources/img/toolbar/2.5x/btn-decfont.svg',
  'copystyle': 'common/main/resources/img/toolbar/2.5x/btn-copystyle.svg',
  'clearstyle': 'common/main/resources/img/toolbar/2.5x/btn-clearstyle.svg',
  'change-case': 'common/main/resources/img/toolbar/2.5x/btn-change-case.svg',
  'fontcolor': 'common/main/resources/img/toolbar/2.5x/btn-fontcolor.svg',
  'highlight': 'common/main/resources/img/toolbar/2.5x/btn-highlight.svg',
  'linespace': 'common/main/resources/img/toolbar/2.5x/btn-linespace.svg',
  'paracolor': 'common/main/resources/img/toolbar/2.5x/btn-paracolor.svg',
  'setmarkers': 'common/main/resources/img/toolbar/2.5x/btn-setmarkers.svg',
  'numbering': 'common/main/resources/img/toolbar/2.5x/btn-numbering.svg',
  'multilevels':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-multilevels.svg',
  'decoffset': 'common/main/resources/img/toolbar/2.5x/btn-decoffset.svg',
  'incoffset': 'common/main/resources/img/toolbar/2.5x/btn-incoffset.svg',
  // Inserir
  'inserttable':
      'common/main/resources/img/toolbar/2.5x/big/btn-inserttable.svg',
  'insertimage':
      'common/main/resources/img/toolbar/2.5x/big/btn-insertimage.svg',
  'insertshape':
      'common/main/resources/img/toolbar/2.5x/big/btn-insertshape.svg',
  'text': 'common/main/resources/img/toolbar/2.5x/btn-text.svg',
  'pagebreak': 'common/main/resources/img/toolbar/2.5x/big/btn-pagebreak.svg',
  'menu-header':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-menu-header.svg',
  // Layout
  'pageorient':
      'common/main/resources/img/toolbar/2.5x/big/btn-pageorient.svg',
  'pagemargins':
      'common/main/resources/img/toolbar/2.5x/big/btn-pagemargins.svg',
  'pagesize': 'common/main/resources/img/toolbar/2.5x/big/btn-pagesize.svg',
  'columns':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-to-columns.svg',
  // Tabela
  'addcell': 'common/main/resources/img/toolbar/2.5x/btn-addcell.svg',
  'delcell': 'common/main/resources/img/toolbar/2.5x/btn-delcell.svg',
  'merge-cells':
      'common/main/resources/img/toolbar/2.5x/btn-merge-cells.svg',
  'rows-and-columns':
      'common/main/resources/img/toolbar/2.5x/btn-rows-and-columns.svg',
  // Arquivo
  'save': 'common/main/resources/img/toolbar/2.5x/btn-save.svg',
  'print': 'common/main/resources/img/toolbar/2.5x/btn-print.svg',
  'download': 'common/main/resources/img/toolbar/2.5x/btn-download.svg',
  'print-preview':
      'common/main/resources/img/toolbar/2.5x/btn-print-preview.svg',
  // Edição e navegação
  'search': 'common/main/resources/img/toolbar/2.5x/btn-menu-search.svg',
  'replace': 'common/main/resources/img/toolbar/2.5x/btn-replace.svg',
  'word-count':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-word-count.svg',
  'paragraph-marks':
      'common/main/resources/img/toolbar/2.5x/btn-paragraph.svg',
  'select-tool':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-select-tool.svg',
  'hand-tool':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-hand-tool.svg',
  // Inserir (o resto da aba do Word)
  'hyperlink':
      'common/main/resources/img/toolbar/2.5x/btn-inserthyperlink.svg',
  'symbol': 'common/main/resources/img/toolbar/2.5x/big/btn-symbol.svg',
  'equation': 'common/main/resources/img/toolbar/2.5x/btn-equation.svg',
  'comment': 'common/main/resources/img/toolbar/2.5x/btn-add-comment.svg',
  'blankpage':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-blankpage.svg',
  'bookmark':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-bookmarks.svg',
  'cross-reference':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-cross-reference.svg',
  'caption':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-caption.svg',
  'contents':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-contents.svg',
  'textart': 'common/main/resources/img/toolbar/2.5x/big/btn-textart.svg',
  'dropcap':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-dropcap.svg',
  'field': 'documenteditor/main/resources/img/toolbar/2.5x/btn-field.svg',
  'insertchart':
      'common/main/resources/img/toolbar/2.5x/big/btn-insertchart.svg',
  // Cabeçalho, rodapé e numeração
  'editheader':
      'common/main/resources/img/toolbar/2.5x/big/btn-editheader.svg',
  'pagenum':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-pagenum.svg',
  'pagenum-bottom-center':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-page-number-bottom-center.svg',
  'pagenum-bottom-right':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-page-number-bottom-right.svg',
  'pagenum-top-center':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-page-number-top-center.svg',
  // Layout e Design
  'hyphenation':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-hyphenation.svg',
  'line-numbering':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-line-numbering.svg',
  'watermark':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-watermark.svg',
  'page-color':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-page-color.svg',
  'colorschemas':
      'common/main/resources/img/toolbar/2.5x/btn-colorschemas.svg',
  'columns-one': 'common/main/resources/img/toolbar/2.5x/btn-columns-one.svg',
  'columns-two': 'common/main/resources/img/toolbar/2.5x/btn-columns-two.svg',
  'columns-three':
      'common/main/resources/img/toolbar/2.5x/btn-columns-three.svg',
  'columns-left':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-columns-left.svg',
  'columns-right':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-columns-right.svg',
  // Bordas (tabela e parágrafo)
  'border-all': 'common/main/resources/img/toolbar/2.5x/btn-border-all.svg',
  'border-no': 'common/main/resources/img/toolbar/2.5x/btn-border-no.svg',
  'border-out': 'common/main/resources/img/toolbar/2.5x/btn-border-out.svg',
  'border-inside':
      'common/main/resources/img/toolbar/2.5x/btn-border-inside.svg',
  'border-top': 'common/main/resources/img/toolbar/2.5x/btn-border-top.svg',
  'border-bottom':
      'common/main/resources/img/toolbar/2.5x/btn-border-bottom.svg',
  'border-left': 'common/main/resources/img/toolbar/2.5x/btn-border-left.svg',
  'border-right':
      'common/main/resources/img/toolbar/2.5x/btn-border-right.svg',
  'border-insidehor':
      'common/main/resources/img/toolbar/2.5x/btn-border-insidehor.svg',
  'border-insidevert':
      'common/main/resources/img/toolbar/2.5x/btn-border-insidevert.svg',
  'border-style':
      'common/main/resources/img/toolbar/2.5x/btn-border-style.svg',
  // Tabela (Design e Layout)
  'distribute-rows':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-distribute-rows.svg',
  'distribute-columns':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-distribute-columns.svg',
  'table-to-text':
      'documenteditor/main/resources/img/toolbar/2.5x/btn-table-to-text.svg',
  'table-align-left':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-table-align-left.svg',
  'table-align-center':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-table-align-center.svg',
  'table-align-right':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-table-align-right.svg',
  'align-top': 'common/main/resources/img/toolbar/2.5x/btn-align-top.svg',
  'align-middle':
      'common/main/resources/img/toolbar/2.5x/btn-align-middle.svg',
  'align-bottom':
      'common/main/resources/img/toolbar/2.5x/btn-align-bottom.svg',
  // Objetos: disposição do texto, ordenação e proporção
  'wrap-inline':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-inline.svg',
  'wrap-square':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-square.svg',
  'wrap-tight':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-tight.svg',
  'wrap-through':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-through.svg',
  'wrap-topbottom':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-topbottom.svg',
  'wrap-behind':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-behind.svg',
  'wrap-infront':
      'documenteditor/main/resources/img/toolbar/2.5x/huge/btn-wrap-infront.svg',
  'img-wrap':
      'documenteditor/main/resources/img/toolbar/2.5x/big/btn-img-wrap.svg',
  'arrange-front':
      'common/main/resources/img/toolbar/2.5x/btn-arrange-front.svg',
  'arrange-back':
      'common/main/resources/img/toolbar/2.5x/btn-arrange-back.svg',
  'arrange-forward':
      'common/main/resources/img/toolbar/2.5x/btn-arrange-forward.svg',
  'arrange-backward':
      'common/main/resources/img/toolbar/2.5x/btn-arrange-backward.svg',
  'flip-hor': 'common/main/resources/img/toolbar/2.5x/btn-flip-hor.svg',
  'flip-vert': 'common/main/resources/img/toolbar/2.5x/btn-flip-vert.svg',
  'advanced-ratio':
      'common/main/resources/img/toolbar/2.5x/btn-advanced-ratio.svg',
  // Chrome do editor (quickbars, adornos)
  'close': 'common/main/resources/img/toolbar/2.5x/btn-close.svg',
  'select-all': 'common/main/resources/img/toolbar/2.5x/btn-select-all.svg',
  'menu-table': 'common/main/resources/img/toolbar/2.5x/btn-menu-table.svg',
};

const String cssHeader = '''
/*
 * dart_quill — icones da ribbon do OfficeWordEditor.
 * GERADO por tool/build_icon_css.dart — nao edite a mao.
 *
 * Asset OPCIONAL e substituivel: o componente so referencia classes
 * `dq-icon-*`; troque este stylesheet por outro que defina as mesmas
 * classes e nada no codigo muda.
 *
 *   <link rel="stylesheet"
 *         href="packages/dart_quill/assets/office_word_icons.css">
 *
 * Cada icone e o SVG oficial do ONLYOFFICE embutido como mask-image e
 * pintado com currentColor (o SVG usa fill-rule evenodd, que uma fonte de
 * icones nao representa). Icones de GUI do ONLYOFFICE
 * (https://github.com/ONLYOFFICE/web-apps), licenciados sob Creative
 * Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0). Este
 * arquivo e obra derivada e permanece sob CC BY-SA 4.0; veja THIRD_PARTY.md.
 */

.dq-icon {
  display: inline-block;
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  vertical-align: middle;
  background-color: currentColor;
  -webkit-mask-image: var(--dq-icon);
  mask-image: var(--dq-icon);
  -webkit-mask-repeat: no-repeat;
  mask-repeat: no-repeat;
  -webkit-mask-position: center;
  mask-position: center;
  -webkit-mask-size: contain;
  mask-size: contain;
}

/* Com a folha carregada, o texto-fallback dos botoes some — exceto nos
   botoes ROTULADOS (grandes ou icone+rotulo, como no Word). */
.dq-office-btn:not(.dq-office-btn-labeled):has(.dq-icon) .dq-office-btn-text { display: none; }
''';

Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final appsDir = Directory(positional.isNotEmpty
      ? '${positional.first}${Platform.pathSeparator}apps'
      : r'C:\MyDartProjects\docx_rendering\resources\onlyoffice_ribbon_icons'
          r'\onlyoffice-ribbon-icons-full\apps');
  if (!appsDir.existsSync()) {
    stderr.writeln('Diretório de ícones não encontrado: ${appsDir.path}');
    stderr.writeln('Passe o caminho de onlyoffice-ribbon-icons-full como '
        'argumento.');
    exit(1);
  }

  final root = File(Platform.script.toFilePath()).parent.parent.path;
  final buffer = StringBuffer(cssHeader);
  final names = icons.keys.toList()..sort();
  for (final name in names) {
    final src = File('${appsDir.path}${Platform.pathSeparator}'
        '${icons[name]!.replaceAll('/', Platform.pathSeparator)}');
    if (!src.existsSync()) {
      stderr.writeln('FALTA: $name <- ${src.path}');
      exit(1);
    }
    buffer.writeln(
        '.dq-icon-$name { --dq-icon: url("${dataUri(src.readAsStringSync())}"); }');
  }

  final cssFile = File('$root${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}assets${Platform.pathSeparator}'
      'office_word_icons.css');
  final generated = buffer.toString();
  if (check) {
    final current = cssFile.existsSync() ? cssFile.readAsStringSync() : '';
    if (current.replaceAll('\r\n', '\n') != generated) {
      stderr.writeln('office_word_icons.css está desatualizado: rode '
          '`dart run tool/build_icon_css.dart`.');
      exit(1);
    }
    stdout.writeln('OK: office_word_icons.css atualizado (${names.length} '
        'ícones).');
    return;
  }
  cssFile.writeAsStringSync(generated);
  stdout.writeln('OK: ${names.length} ícones -> ${cssFile.path}');
}

/// O SVG como data URI para CSS: sem declaração XML, sem quebras de linha e
/// com os caracteres que quebrariam a `url("...")` percent-encoded. A cor de
/// preenchimento é irrelevante — só o alfa da máscara conta.
String dataUri(String svg) {
  var body = svg
      .replaceAll(RegExp(r'<\?xml[^>]*\?>'), '')
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('> <', '><')
      .trim();
  body = body
      .replaceAll('%', '%25')
      .replaceAll('"', "'")
      .replaceAll('#', '%23')
      .replaceAll('<', '%3C')
      .replaceAll('>', '%3E')
      .replaceAll('{', '%7B')
      .replaceAll('}', '%7D');
  return 'data:image/svg+xml,$body';
}
