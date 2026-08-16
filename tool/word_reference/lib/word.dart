/// O Microsoft Word como ORÁCULO.
///
/// O plano de paridade de UI diz por que este harness existe: nenhuma
/// descrição de comportamento do Word é tão confiável quanto o próprio Word.
/// Em vez de deduzir de screenshots o que ele faz com uma borda de página,
/// uma numeração multinível ou uma seção em paisagem, este arquivo **pede ao
/// Word que produza o documento** e o exporta em DOCX e em PDF. O DOCX vira
/// fixture de importação; o PDF vira o gabarito com que
/// `tool/pdf_reference_diff.dart` compara a nossa paginação.
///
/// Três decisões que a automação exigiu:
///
/// * **`Visible = false` e `DisplayAlerts = 0`.** Uma caixa de diálogo do
///   Word (recuperação de arquivo, fonte ausente) trava o processo COM sem
///   nenhuma mensagem do lado Dart — o script ficaria pendurado para sempre.
/// * **Cada fixture nasce de um documento NOVO.** Reaproveitar a instância
///   entre fixtures herdaria estilos, seções e a última formatação aplicada,
///   e a fixture deixaria de descrever só a feature que ela promete.
/// * **`Quit` no `finally`, sempre.** Um `WINWORD.EXE` órfão segura o
///   arquivo e a próxima execução falha ao gravar — o modo de falha mais
///   irritante de automação de Office.
library;

import 'dart:io';

import 'com.dart';

/// Constantes do modelo de objetos do Word usadas aqui (`wd*`).
abstract final class Wd {
  // Formatos de arquivo.
  static const int formatDocumentDefault = 16; // .docx
  static const int exportFormatPdf = 17;

  // Orientação e unidades.
  static const int orientPortrait = 0;
  static const int orientLandscape = 1;

  // Quebras.
  static const int sectionBreakNextPage = 2;
  static const int pageBreak = 7;

  // Bordas.
  static const int borderLeft = -2;
  static const int borderRight = -4;
  static const int borderTop = -1;
  static const int borderBottom = -3;
  static const int lineStyleSingle = 1;
  static const int lineStyleDouble = 7;
  static const int lineWidth225pt = 18;

  // Tabulação.
  static const int alignTabLeft = 0;
  static const int alignTabCenter = 1;
  static const int alignTabRight = 2;
  static const int alignTabDecimal = 3;
  static const int tabLeaderSpaces = 0;
  static const int tabLeaderDots = 1;

  // Cabeçalho/rodapé.
  static const int headerFooterPrimary = 1;
  static const int headerFooterFirstPage = 2;
  static const int headerFooterEvenPages = 3;

  // Numeração de linha.
  static const int numberRestartContinuous = 0;

  // Listas. `wdListGalleryType`: 1 = marcadores, 2 = números, 3 = numeração
  // MULTINÍVEL. O 4 (que parece o próximo da série) não existe, e o Word
  // responde com "o membro solicitado da coleção não existe".
  static const int listOutlineNumbering = 3;

  // Efeito de texto (a marca-d'água do Word é um WordArt no cabeçalho).
  static const int textEffect1 = 0;
}

/// Uma sessão do Word. Use [run] para garantir o encerramento.
final class WordSession {
  WordSession._(this.app, this.ownProcessIds);

  final Dispatcher app;

  /// Os PIDs de `WINWORD.EXE` que NASCERAM com esta sessão.
  ///
  /// Serve a dois propósitos, e os dois são sobre não invadir a máquina de
  /// quem roda o harness: encerrar só o que abrimos, e achar a janela DESTA
  /// instância quando o usuário já tem o Word aberto com outro documento.
  final Set<int> ownProcessIds;

  /// Abre o Word, executa [body] e SEMPRE encerra o processo QUE ELE ABRIU.
  ///
  /// A distinção não é preciosismo: quem roda este harness quase sempre tem
  /// o Word aberto com o próprio documento (é a máquina de quem escreve os
  /// documentos de referência). Um `terminateProcessesByExecutableName` cego
  /// mataria essa sessão e o trabalho não salvo junto. Por isso os PIDs são
  /// fotografados ANTES, e só o que nasceu depois pode ser encerrado à
  /// força — e mesmo assim apenas se o `Quit` educado não bastar.
  static T run<T>(T Function(WordSession session) body) {
    initializeComApartment();
    final before = snapshotProcessIdsByExecutable('WINWORD.EXE');
    final app = createDispatcher(const ['Word.Application']);
    final session = WordSession._(
      app,
      snapshotProcessIdsByExecutable('WINWORD.EXE').difference(before),
    );
    try {
      setProperty(app, 'Visible', false);
      // 0 = wdAlertsNone. Sem isto, qualquer diálogo trava a automação.
      setProperty(app, 'DisplayAlerts', 0);
      return body(session);
    } finally {
      try {
        invokeMethod(app, 'Quit', [0]);
      } catch (_) {
        // Word já encerrado ou em estado inválido: o kill abaixo resolve.
      }
      releaseDispatcher(app);
      sleep(const Duration(milliseconds: 400));
      final ours = snapshotProcessIdsByExecutable('WINWORD.EXE')
          .difference(before);
      for (final pid in ours) {
        terminateProcessById(pid);
      }
    }
  }

  /// Cria um documento vazio.
  Dispatcher newDocument() {
    final documents = getDispatchProperty(app, 'Documents');
    try {
      return invokeDispatchMethod(documents, 'Add');
    } finally {
      releaseDispatcher(documents);
    }
  }

  /// Abre um DOCX existente.
  Dispatcher open(String path) {
    final documents = getDispatchProperty(app, 'Documents');
    try {
      return invokeDispatchMethod(documents, 'Open', [
        File(path).absolute.path,
      ]);
    } finally {
      releaseDispatcher(documents);
    }
  }
}

/// Grava o documento como `.docx` e exporta o PDF ao lado.
///
/// Os dois no MESMO passo de propósito: um PDF gerado de outra execução
/// poderia descrever um documento diferente do `.docx` que ficou no disco, e
/// o gabarito deixaria de ser gabarito.
void saveDocxAndPdf(Dispatcher doc, String docxPath) {
  final docx = File(docxPath).absolute.path;
  final pdf = docx.replaceFirst(RegExp(r'\.docx$'), '.pdf');
  for (final path in [docx, pdf]) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
  Directory(File(docx).parent.path).createSync(recursive: true);
  invokeMethod(doc, 'SaveAs2', [docx, Wd.formatDocumentDefault]);
  invokeMethod(doc, 'ExportAsFixedFormat', [pdf, Wd.exportFormatPdf]);
  invokeMethod(doc, 'Close', [0]);
  releaseDispatcher(doc);
}

// -- açúcar sobre o modelo de objetos ----------------------------------------

Dispatcher content(Dispatcher doc) => getDispatchProperty(doc, 'Content');

Dispatcher paragraphs(Dispatcher doc) => getDispatchProperty(doc, 'Paragraphs');

Dispatcher sections(Dispatcher doc) => getDispatchProperty(doc, 'Sections');

Dispatcher itemAt(Dispatcher collection, int index) =>
    invokeDispatchMethod(collection, 'Item', [index]);

/// Acrescenta um parágrafo com [text] e, opcionalmente, um estilo nomeado.
///
/// O estilo é aplicado por NOME em português quando disponível e cai no nome
/// em inglês: o Word rejeita `Heading 1` numa instalação pt-BR e vice-versa,
/// e um script que assume um dos dois só funciona na máquina de quem o
/// escreveu.
void appendParagraph(Dispatcher doc, String text, {List<String> style = const []}) {
  final range = content(doc);
  try {
    invokeMethod(range, 'InsertParagraphAfter');
    final refreshed = content(doc);
    try {
      invokeMethod(refreshed, 'InsertAfter', [text]);
    } finally {
      releaseDispatcher(refreshed);
    }
  } finally {
    releaseDispatcher(range);
  }
  if (style.isEmpty) return;
  final all = paragraphs(doc);
  try {
    final count = getIntProperty(all, 'Count');
    final last = itemAt(all, count);
    try {
      for (final name in style) {
        try {
          setProperty(last, 'Style', name);
          return;
        } catch (_) {
          // Próximo nome da lista (pt-BR × en-US).
        }
      }
    } finally {
      releaseDispatcher(last);
    }
  } finally {
    releaseDispatcher(all);
  }
}
