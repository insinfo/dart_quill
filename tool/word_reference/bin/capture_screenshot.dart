/// Abre um DOCX no Word e captura a JANELA — a comparação visual manual do
/// §5 do plano de paridade de UI.
///
/// Não é teste automatizado, e o plano é explícito quanto a isso: fidelidade
/// pixel a pixel não é meta. O que a captura serve é responder "o Word põe
/// esse controle onde?" sem depender de screenshot tirado à mão, que envelhece
/// e ninguém sabe de que versão veio.
///
/// A imagem sai em BMP porque o formato é escrito em ~40 linhas sem nenhum
/// codec: a alternativa (PNG) exigiria deflate + CRC aqui dentro para nada —
/// a captura é insumo de olho humano, não de repositório.
///
/// ```
/// dart run bin/capture_screenshot.dart caminho.docx [--zoom=100] [--page=1]
/// ```
library;

import 'dart:io';

import 'package:word_reference/com.dart';
import 'package:word_reference/word.dart';

const String _outputDirectory = 'doc/referencias-ui';

void main(List<String> arguments) {
  if (!Platform.isWindows) {
    stderr.writeln('Este harness dirige o Word por COM: só roda no Windows.');
    exit(64);
  }
  final paths = arguments.where((a) => !a.startsWith('--')).toList();
  if (paths.isEmpty) {
    stderr.writeln('uso: dart run bin/capture_screenshot.dart <arquivo.docx>');
    exit(64);
  }
  var zoom = 100;
  for (final argument in arguments) {
    if (argument.startsWith('--zoom=')) {
      zoom = int.parse(argument.substring('--zoom='.length));
    }
  }

  final source = File(paths.first).absolute;
  if (!source.existsSync()) {
    stderr.writeln('não encontrado: ${source.path}');
    exit(66);
  }

  WordSession.run((session) {
    // VISÍVEL: a captura é da janela desenhada; um Word invisível não tem
    // pixels para copiar.
    setProperty(session.app, 'Visible', true);
    final doc = session.open(source.path);
    try {
      final window = getDispatchProperty(session.app, 'ActiveWindow');
      try {
        invokeMethod(window, 'Activate');
        final view = getDispatchProperty(window, 'View');
        try {
          setProperty(view, 'Type', 3); // wdPrintView
          final viewZoom = getDispatchProperty(view, 'Zoom');
          try {
            setProperty(viewZoom, 'Percentage', zoom);
          } finally {
            releaseDispatcher(viewZoom);
          }
        } finally {
          releaseDispatcher(view);
        }
        // O Word ainda está desenhando quando o COM devolve; sem esta pausa
        // a captura sai com a janela pela metade.
        sleep(const Duration(milliseconds: 1200));

        final directory = Directory('${_repositoryRoot()}/$_outputDirectory')
          ..createSync(recursive: true);
        final name = source.uri.pathSegments.last.replaceAll('.docx', '');
        final target = '${directory.path}/$name-word.bmp';
        // Pelo PROCESSO desta instância, nunca pela janela em primeiro
        // plano: um processo em segundo plano não rouba o foco no Windows,
        // então `GetForegroundWindow` devolveria a janela de quem está
        // usando a máquina — e a captura sairia com a tela alheia. (Foi o
        // que aconteceu na primeira versão deste script.)
        final handle = findWindowOfProcess('OpusApp', session.ownProcessIds);
        if (handle == 0) {
          throw StateError('janela do Word desta sessão não encontrada');
        }
        captureWindowToBmp(handle, target);
        stdout.writeln('captura: $_outputDirectory/$name-word.bmp');
      } finally {
        releaseDispatcher(window);
      }
    } finally {
      invokeMethod(doc, 'Close', [0]);
      releaseDispatcher(doc);
    }
  });
}

String _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 5; i++) {
    if (File('${directory.path}/pubspec.yaml').existsSync() &&
        Directory('${directory.path}/lib/src/document_engine').existsSync()) {
      return directory.path;
    }
    directory = directory.parent;
  }
  throw StateError('raiz do dart_quill nao encontrada');
}
