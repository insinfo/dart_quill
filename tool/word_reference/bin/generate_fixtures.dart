/// Gera as fixtures de referência PEDINDO AO WORD que as produza.
///
/// Cada fixture isola UMA capacidade que o editor promete (ou promete não
/// ter): borda de página, seção em paisagem, paradas de tabulação,
/// numeração multinível, cabeçalho de primeira página, colunas, numeração de
/// linhas. Sai um `.docx` (fixture de importação) e o `.pdf` que o Word
/// exportou dele (gabarito de paginação para `tool/pdf_reference_diff.dart`).
///
/// **Por que gerar em vez de escrever o XML à mão.** Um `w:pgBorders` que eu
/// escrevesse seria o que eu ACHO que o Word grava. O que interessa é o que
/// ele grava de verdade — inclusive os filhos que o editor não modela, a
/// ordem dos elementos e os padrões que ele completa sozinho. É a diferença
/// entre testar contra a especificação e testar contra o produto.
///
/// Uso (Windows, com Word instalado):
///
/// ```
/// cd tool/word_reference && dart pub get
/// dart run bin/generate_fixtures.dart                 # todas
/// dart run bin/generate_fixtures.dart page_borders    # uma
/// ```
library;

import 'dart:io';

import 'package:word_reference/com.dart';
import 'package:word_reference/word.dart';

/// Onde as fixtures ficam. Caminho relativo à RAIZ do repositório.
const String _outputDirectory = 'resources/word_reference';

typedef Fixture = void Function(WordSession session, String path);

final Map<String, Fixture> _fixtures = {
  'page_borders': _pageBorders,
  'watermark': _watermark,
  'sections_landscape': _sectionsLandscape,
  'tab_stops': _tabStops,
  'multilevel_numbering': _multilevelNumbering,
  'header_first_even': _headerFirstEven,
  'columns_two': _columnsTwo,
  'line_numbers': _lineNumbers,
};

void main(List<String> arguments) {
  if (!Platform.isWindows) {
    stderr.writeln('Este harness dirige o Word por COM: só roda no Windows.');
    exit(64);
  }
  final wanted = arguments.where((a) => !a.startsWith('--')).toList();
  final unknown = wanted.where((name) => !_fixtures.containsKey(name));
  if (unknown.isNotEmpty) {
    stderr.writeln('fixture desconhecida: ${unknown.join(', ')}');
    stderr.writeln('disponíveis: ${_fixtures.keys.join(', ')}');
    exit(64);
  }
  final selected = wanted.isEmpty ? _fixtures.keys.toList() : wanted;
  final root = _repositoryRoot();
  final directory = Directory('$root/$_outputDirectory')
    ..createSync(recursive: true);

  WordSession.run((session) {
    for (final name in selected) {
      final path = '${directory.path}/$name.docx';
      stdout.writeln('gerando $name…');
      _fixtures[name]!(session, path);
      stdout.writeln('  ${File(path).lengthSync()} bytes + PDF');
    }
  });
  stdout.writeln('\nfixtures em $_outputDirectory');
}

/// A raiz do repositório a partir do diretório do harness.
String _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 5; i++) {
    if (File('${directory.path}/pubspec.yaml').existsSync() &&
        Directory('${directory.path}/lib/src/document_engine').existsSync()) {
      return directory.path;
    }
    directory = directory.parent;
  }
  throw StateError('raiz do dart_quill não encontrada a partir de '
      '${Directory.current.path}');
}

// -- as fixtures --------------------------------------------------------------

/// Moldura de página dupla + as quatro arestas, o caso da aba Design.
void _pageBorders(WordSession session, String path) {
  final doc = session.newDocument();
  appendParagraph(doc, 'Documento com moldura de página.');
  appendParagraph(doc,
      'A moldura é do Word, não nossa: é ela que diz como o w:pgBorders '
      'real é gravado — inclusive os filhos que o editor não modela.');
  final all = sections(doc);
  final section = itemAt(all, 1);
  final borders = getDispatchProperty(section, 'Borders');
  try {
    for (final side in const [
      Wd.borderTop,
      Wd.borderLeft,
      Wd.borderBottom,
      Wd.borderRight,
    ]) {
      final border = itemAt(borders, side);
      try {
        setProperty(border, 'LineStyle', Wd.lineStyleDouble);
        setProperty(border, 'LineWidth', Wd.lineWidth225pt);
        setProperty(border, 'Color', 0x0000C0); // BGR: vermelho escuro
      } finally {
        releaseDispatcher(border);
      }
    }
  } finally {
    releaseDispatcher(borders);
    releaseDispatcher(section);
    releaseDispatcher(all);
  }
  saveDocxAndPdf(doc, path);
}

/// Marca-d'água "MINUTA" — no Word ela é um WordArt no cabeçalho.
void _watermark(WordSession session, String path) {
  final doc = session.newDocument();
  appendParagraph(doc, 'Documento marcado como MINUTA.');
  appendParagraph(doc,
      'A marca-d\'água do Word é uma forma no cabeçalho, não texto do corpo: '
      'é essa estrutura que a nossa exportação precisa reproduzir.');
  final all = sections(doc);
  final section = itemAt(all, 1);
  final headers = getDispatchProperty(section, 'Headers');
  final header = itemAt(headers, Wd.headerFooterPrimary);
  final shapes = getDispatchProperty(header, 'Shapes');
  try {
    final shape = invokeDispatchMethod(shapes, 'AddTextEffect', [
      Wd.textEffect1, // PresetTextEffect
      'MINUTA',
      'Calibri',
      72,
      false, // Bold
      false, // Italic
      0, // Left
      0, // Top
    ]);
    try {
      setProperty(shape, 'Name', 'PowerPlusWaterMarkObject');
      final fill = getDispatchProperty(shape, 'Fill');
      try {
        setProperty(fill, 'Visible', true);
        setProperty(fill, 'Transparency', 0);
        final foreColor = getDispatchProperty(fill, 'ForeColor');
        try {
          setProperty(foreColor, 'RGB', 0xC0C0C0);
        } finally {
          releaseDispatcher(foreColor);
        }
      } finally {
        releaseDispatcher(fill);
      }
      setProperty(shape, 'Rotation', 315);
      final wrap = getDispatchProperty(shape, 'WrapFormat');
      try {
        setProperty(wrap, 'Type', 3); // wdWrapNone
      } finally {
        releaseDispatcher(wrap);
      }
      // 0 = wdRelativeHorizontalPositionPage; centraliza na folha.
      setProperty(shape, 'RelativeHorizontalPosition', 1);
      setProperty(shape, 'RelativeVerticalPosition', 1);
      setProperty(shape, 'Left', -999995); // msoAlignCenter
      setProperty(shape, 'Top', -999995);
    } finally {
      releaseDispatcher(shape);
    }
  } finally {
    releaseDispatcher(shapes);
    releaseDispatcher(header);
    releaseDispatcher(headers);
    releaseDispatcher(section);
    releaseDispatcher(all);
  }
  saveDocxAndPdf(doc, path);
}

/// Duas seções: retrato e paisagem, com margens diferentes.
void _sectionsLandscape(WordSession session, String path) {
  final doc = session.newDocument();
  appendParagraph(doc, 'Primeira seção, retrato.');
  appendParagraph(doc, 'O w:sectPr fica no parágrafo que TERMINA a seção — '
      'ler ao contrário aplica a geometria errada ao documento inteiro.');
  final range = content(doc);
  try {
    invokeMethod(range, 'InsertParagraphAfter');
    final end = getIntProperty(range, 'End');
    final tail = invokeDispatchMethod(doc, 'Range', [end - 1, end - 1]);
    try {
      invokeMethod(tail, 'InsertBreak', [Wd.sectionBreakNextPage]);
    } finally {
      releaseDispatcher(tail);
    }
  } finally {
    releaseDispatcher(range);
  }
  appendParagraph(doc, 'Segunda seção, paisagem: o anexo do processo.');
  final all = sections(doc);
  try {
    final second = itemAt(all, 2);
    try {
      final setup = getDispatchProperty(second, 'PageSetup');
      try {
        setProperty(setup, 'Orientation', Wd.orientLandscape);
        setProperty(setup, 'TopMargin', 36); // 0,5"
        setProperty(setup, 'BottomMargin', 36);
      } finally {
        releaseDispatcher(setup);
      }
    } finally {
      releaseDispatcher(second);
    }
  } finally {
    releaseDispatcher(all);
  }
  saveDocxAndPdf(doc, path);
}

/// Paradas de tabulação dos quatro tipos, com e sem líder pontilhado.
void _tabStops(WordSession session, String path) {
  final doc = session.newDocument();
  appendParagraph(doc, 'Esquerda\tCentro\tDireita\t1.234,56');
  final all = paragraphs(doc);
  try {
    final last = itemAt(all, getIntProperty(all, 'Count'));
    try {
      final stops = getDispatchProperty(last, 'TabStops');
      try {
        invokeMethod(stops, 'ClearAll');
        // Posições em PONTOS, a unidade do modelo de objetos do Word.
        invokeMethod(stops, 'Add', [90, Wd.alignTabLeft, Wd.tabLeaderSpaces]);
        invokeMethod(stops, 'Add', [220, Wd.alignTabCenter, Wd.tabLeaderDots]);
        invokeMethod(stops, 'Add', [340, Wd.alignTabRight, Wd.tabLeaderDots]);
        invokeMethod(stops, 'Add', [460, Wd.alignTabDecimal, Wd.tabLeaderSpaces]);
      } finally {
        releaseDispatcher(stops);
      }
    } finally {
      releaseDispatcher(last);
    }
  } finally {
    releaseDispatcher(all);
  }
  saveDocxAndPdf(doc, path);
}

/// Numeração multinível 1. / 1.1 / 1.1.1 — a lacuna conhecida do compositor.
void _multilevelNumbering(WordSession session, String path) {
  final doc = session.newDocument();
  for (final (text, level) in const [
    ('Objeto', 1),
    ('Justificativa', 2),
    ('Detalhamento', 3),
    ('Segunda justificativa', 2),
    ('Segundo objeto', 1),
  ]) {
    appendParagraph(doc, text);
    final all = paragraphs(doc);
    try {
      final last = itemAt(all, getIntProperty(all, 'Count'));
      try {
        setProperty(last, 'LeftIndent', (level - 1) * 18);
        final format = getDispatchProperty(last, 'Format');
        try {
          setProperty(format, 'OutlineLevel', level);
        } finally {
          releaseDispatcher(format);
        }
      } finally {
        releaseDispatcher(last);
      }
    } finally {
      releaseDispatcher(all);
    }
  }
  // A galeria de listas do Word: o esquema numerado multinível.
  final range = content(doc);
  try {
    final listFormat = getDispatchProperty(range, 'ListFormat');
    try {
      final galleries = getDispatchProperty(session.app, 'ListGalleries');
      try {
        final gallery = itemAt(galleries, Wd.listOutlineNumbering);
        try {
          final templates = getDispatchProperty(gallery, 'ListTemplates');
          try {
            final template = itemAt(templates, 5);
            try {
              invokeMethod(listFormat, 'ApplyListTemplate', [template]);
            } finally {
              releaseDispatcher(template);
            }
          } finally {
            releaseDispatcher(templates);
          }
        } finally {
          releaseDispatcher(gallery);
        }
      } finally {
        releaseDispatcher(galleries);
      }
    } finally {
      releaseDispatcher(listFormat);
    }
  } finally {
    releaseDispatcher(range);
  }
  saveDocxAndPdf(doc, path);
}

/// Cabeçalho diferente na primeira página e em páginas pares/ímpares.
void _headerFirstEven(WordSession session, String path) {
  final doc = session.newDocument();
  for (var i = 1; i <= 3; i++) {
    appendParagraph(doc, 'Página $i do documento de referência.');
    if (i < 3) {
      final range = content(doc);
      try {
        final end = getIntProperty(range, 'End');
        final tail = invokeDispatchMethod(doc, 'Range', [end - 1, end - 1]);
        try {
          invokeMethod(tail, 'InsertBreak', [Wd.pageBreak]);
        } finally {
          releaseDispatcher(tail);
        }
      } finally {
        releaseDispatcher(range);
      }
    }
  }
  final setup = getDispatchProperty(doc, 'PageSetup');
  try {
    setProperty(setup, 'DifferentFirstPageHeaderFooter', true);
    setProperty(setup, 'OddAndEvenPagesHeaderFooter', true);
  } finally {
    releaseDispatcher(setup);
  }
  final all = sections(doc);
  final section = itemAt(all, 1);
  final headers = getDispatchProperty(section, 'Headers');
  try {
    for (final (index, text) in const [
      (Wd.headerFooterFirstPage, 'CABEÇALHO DA PRIMEIRA PÁGINA'),
      (Wd.headerFooterPrimary, 'Cabeçalho padrão (ímpares)'),
      (Wd.headerFooterEvenPages, 'Cabeçalho de página par'),
    ]) {
      final header = itemAt(headers, index);
      try {
        final range = getDispatchProperty(header, 'Range');
        try {
          invokeMethod(range, 'InsertAfter', [text]);
        } finally {
          releaseDispatcher(range);
        }
      } finally {
        releaseDispatcher(header);
      }
    }
  } finally {
    releaseDispatcher(headers);
    releaseDispatcher(section);
    releaseDispatcher(all);
  }
  saveDocxAndPdf(doc, path);
}

/// Duas colunas com linha separadora — o fluxo de jornal do §2.13.
void _columnsTwo(WordSession session, String path) {
  final doc = session.newDocument();
  for (var i = 1; i <= 12; i++) {
    appendParagraph(doc,
        'Parágrafo $i em duas colunas. A coluna enche até o rodapé e o texto '
        'continua no topo da coluna ao lado, na MESMA página.');
  }
  final setup = getDispatchProperty(doc, 'PageSetup');
  try {
    final columns = getDispatchProperty(setup, 'TextColumns');
    try {
      invokeMethod(columns, 'SetCount', [2]);
      setProperty(columns, 'LineBetween', true);
      setProperty(columns, 'Spacing', 36);
    } finally {
      releaseDispatcher(columns);
    }
  } finally {
    releaseDispatcher(setup);
  }
  saveDocxAndPdf(doc, path);
}

/// Numeração de linhas de 5 em 5 — item ❌ da aba Layout.
void _lineNumbers(WordSession session, String path) {
  final doc = session.newDocument();
  for (var i = 1; i <= 30; i++) {
    appendParagraph(doc, 'Linha numerada $i do documento de referência.');
  }
  final setup = getDispatchProperty(doc, 'PageSetup');
  try {
    final numbering = getDispatchProperty(setup, 'LineNumbering');
    try {
      setProperty(numbering, 'Active', true);
      setProperty(numbering, 'CountBy', 5);
      setProperty(numbering, 'RestartMode', Wd.numberRestartContinuous);
      setProperty(numbering, 'DistanceFromText', 18);
    } finally {
      releaseDispatcher(numbering);
    }
  } finally {
    releaseDispatcher(setup);
  }
  saveDocxAndPdf(doc, path);
}
