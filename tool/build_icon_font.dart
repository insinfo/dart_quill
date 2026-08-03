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
