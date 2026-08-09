/// Gera a fonte de ícones `dq-office-icons` a partir dos SVGs oficiais do
/// ONLYOFFICE e escreve os assets finais do pacote:
///
///   * `lib/assets/fonts/dq-office-icons.{woff2,woff,ttf}`
///   * `lib/assets/office_word_icons.css`
///
/// Uso:
///
/// ```
/// dart run tool/build_icon_font.dart [caminho-para-onlyoffice-ribbon-icons-full]
/// ```
///
/// O argumento aponta para o diretório `onlyoffice-ribbon-icons-full` (um
/// checkout dos ícones do repositório ONLYOFFICE/web-apps). Sem argumento,
/// usa o caminho local padrão do autor.
///
/// Requisitos: Node.js no PATH (a fonte é montada com `npx svgtofont` —
/// o fantasticon tem um bug de glob no Windows e não encontra os SVGs).
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
};

const String cssHeader = '''
/*
 * dart_quill — fonte de icones da ribbon do OfficeWordEditor.
 * GERADO por tool/build_icon_font.dart — nao edite a mao.
 *
 * Asset OPCIONAL e substituivel: o componente so referencia classes
 * `dq-icon-*`; troque este stylesheet (e/ou a fonte em fonts/) por outro
 * que defina as mesmas classes e nada no codigo muda.
 *
 *   <link rel="stylesheet"
 *         href="packages/dart_quill/assets/office_word_icons.css">
 *
 * Fonte gerada com svgtofont a partir dos SVGs oficiais do ONLYOFFICE
 * (https://github.com/ONLYOFFICE/web-apps), cujos icones de GUI sao
 * licenciados sob Creative Commons Attribution-ShareAlike 4.0
 * International (CC BY-SA 4.0). Este arquivo e a fonte derivada permanecem
 * sob CC BY-SA 4.0; veja THIRD_PARTY.md.
 */

@font-face {
  font-family: 'dq-office-icons';
  src: url('fonts/dq-office-icons.woff2') format('woff2'),
       url('fonts/dq-office-icons.woff') format('woff'),
       url('fonts/dq-office-icons.ttf') format('truetype');
  font-weight: normal;
  font-style: normal;
  font-display: block;
}

.dq-icon {
  display: inline-block;
  font-family: 'dq-office-icons' !important;
  font-style: normal;
  font-weight: normal;
  font-size: 20px;
  line-height: 1;
  vertical-align: middle;
  speak: none;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Com a fonte carregada, o texto-fallback dos botoes some — exceto nos
   botoes ROTULADOS (grandes ou icone+rotulo, como no Word). */
.dq-office-btn:not(.dq-office-btn-labeled):has(.dq-icon) .dq-office-btn-text { display: none; }
''';

Future<void> main(List<String> args) async {
  final appsDir = Directory(args.isNotEmpty
      ? '${args.first}${Platform.pathSeparator}apps'
      : r'C:\MyDartProjects\docx_rendering\resources\onlyoffice_ribbon_icons'
          r'\onlyoffice-ribbon-icons-full\apps');
  if (!appsDir.existsSync()) {
    stderr.writeln('Diretório de ícones não encontrado: ${appsDir.path}');
    stderr.writeln('Passe o caminho de onlyoffice-ribbon-icons-full como '
        'argumento.');
    exit(1);
  }

  final root = File(Platform.script.toFilePath()).parent.parent.path;
  final work = Directory('$root${Platform.pathSeparator}build'
          '${Platform.pathSeparator}icon_font')
      .absolute;
  final svgDir = Directory('${work.path}${Platform.pathSeparator}svgs');
  final outDir = Directory('${work.path}${Platform.pathSeparator}out');
  if (work.existsSync()) work.deleteSync(recursive: true);
  svgDir.createSync(recursive: true);

  // 1) Seleciona e renomeia os SVGs oficiais.
  var copied = 0;
  for (final entry in icons.entries) {
    final src = File('${appsDir.path}${Platform.pathSeparator}'
        '${entry.value.replaceAll('/', Platform.pathSeparator)}');
    if (!src.existsSync()) {
      stderr.writeln('FALTA: ${entry.key} <- ${src.path}');
      exit(1);
    }
    src.copySync('${svgDir.path}${Platform.pathSeparator}${entry.key}.svg');
    copied++;
  }
  stdout.writeln('SVGs selecionados: $copied');

  // 2) Monta a fonte. svgtofont, não fantasticon: o fantasticon tem um bug
  //    de expansão de glob no Windows e não encontra os SVGs.
  final npx = Platform.isWindows ? 'npx.cmd' : 'npx';
  final result = await Process.run(
      npx,
      [
        '--yes',
        'svgtofont',
        '--sources',
        svgDir.path,
        '--output',
        outDir.path,
        '--fontName',
        'dq-office-icons',
      ],
      workingDirectory: work.path,
      runInShell: true);
  if (result.exitCode != 0) {
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }

  // 3) Copia as fontes para os assets do pacote.
  final fontsDir =
      Directory('$root${Platform.pathSeparator}lib${Platform.pathSeparator}'
          'assets${Platform.pathSeparator}fonts')
        ..createSync(recursive: true);
  for (final ext in ['woff2', 'woff', 'ttf']) {
    File('${outDir.path}${Platform.pathSeparator}dq-office-icons.$ext')
        .copySync('${fontsDir.path}${Platform.pathSeparator}'
            'dq-office-icons.$ext');
  }

  // 4) Extrai os codepoints do CSS do svgtofont e escreve o CSS do pacote.
  final generatedCss =
      File('${outDir.path}${Platform.pathSeparator}dq-office-icons.css')
          .readAsStringSync();
  final matches = RegExp(
          r'\.dq-office-icons-([a-z0-9-]+)::?before\s*\{\s*'
          r'content:\s*"\\([0-9a-fA-F]+)"')
      .allMatches(generatedCss)
      .toList();
  if (matches.length != icons.length) {
    stderr.writeln('Esperava ${icons.length} codepoints, achei '
        '${matches.length} — confira o CSS gerado em ${outDir.path}.');
    exit(1);
  }

  final buffer = StringBuffer(cssHeader);
  final pairs = [
    for (final m in matches) MapEntry(m.group(1)!, m.group(2)!)
  ]..sort((a, b) => a.key.compareTo(b.key));
  for (final pair in pairs) {
    buffer.writeln(
        '.dq-icon-${pair.key}:before { content: "\\${pair.value}"; }');
  }
  final cssFile = File('$root${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}assets${Platform.pathSeparator}'
      'office_word_icons.css');
  cssFile.writeAsStringSync(buffer.toString());

  stdout.writeln('OK: ${pairs.length} ícones -> ${cssFile.path}');
}
