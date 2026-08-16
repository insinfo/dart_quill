/// Prova que o harness consegue DIRIGIR a UI do Word: teclado, mouse e
/// captura.
///
/// Existe porque as três coisas falham em silêncio de jeitos diferentes —
/// `SendInput` recusado por UIPI devolve zero, o teclado vai para a janela
/// errada quando o foco não trocou, e a captura sai preta quando a janela
/// nunca foi desenhada. Rodar isto responde "o ambiente permite?" antes de
/// alguém escrever um roteiro de UI em cima.
///
/// O ciclo: abre um documento novo → traz para a frente → digita pelo
/// TECLADO → confirma pelo MODELO (COM) que o texto chegou → clica com o
/// mouse dentro da página → captura a janela.
///
/// ```
/// dart run bin/ui_probe.dart
/// ```
library;

import 'dart:io';

import 'package:win32/win32.dart' show VIRTUAL_KEY;
import 'package:word_reference/com.dart';
import 'package:word_reference/word.dart';

const String _outputDirectory = 'doc/referencias-ui';
const String _probeText = 'Teclado sintético: ação, ç e — travessão.';

void main() {
  if (!Platform.isWindows) {
    stderr.writeln('Este harness dirige o Word por COM: só roda no Windows.');
    exit(64);
  }

  WordSession.run((session) {
    setProperty(session.app, 'Visible', true);
    final doc = session.newDocument();
    try {
      final window = findWindowOfProcess('OpusApp', session.ownProcessIds);
      if (window == 0) {
        throw StateError('janela do Word desta sessão não encontrada');
      }
      if (!focusWindow(window)) {
        stderr.writeln('AVISO: a janela não veio para primeiro plano. '
            'O teclado sintético vai para quem estiver com o foco — '
            'abortando antes de digitar na janela de outro programa.');
        exit(70);
      }

      final bounds = windowBounds(window);
      // 1. MOUSE primeiro: o clique dentro da página é o que dá FOCO DE
      //    TECLADO à superfície do documento. Uma janela pode estar em
      //    primeiro plano com o foco em outro painel (a faixa, o painel de
      //    navegação), e aí o texto digitado não vai para o documento — foi
      //    o que aconteceu na primeira versão desta sonda.
      whileFocused(window, () {
        clickMouse(
          x: bounds.left + bounds.width ~/ 2,
          y: bounds.top + bounds.height ~/ 3,
        );
      });
      sleep(const Duration(milliseconds: 250));
      stdout.writeln('mouse: OK (clique aceito pelo Windows)');

      // 2. TECLADO: texto com acentos e travessão, que só sai certo por
      //    KEYEVENTF_UNICODE (um mapeamento por tecla dependeria do layout).
      //    A guarda conferre o foco imediatamente antes de cada lote.
      whileFocused(window, () => sendText(_probeText));
      whileFocused(window, () => sendKey(VIRTUAL_KEY.VK_RETURN));
      whileFocused(window, () => sendText('Segunda linha.'));
      // Ctrl+Home: o atalho volta o cursor ao início, e prova que o
      // MODIFICADOR também chega.
      whileFocused(
        window,
        () => sendKey(VIRTUAL_KEY.VK_HOME,
            modifiers: const KeyModifiers(ctrl: true)),
      );
      sleep(const Duration(milliseconds: 400));

      // 3. Confirmação pelo MODELO, não pela tela: se o texto está no
      //    documento, o teclado chegou ao Word e não a outro programa.
      final range = content(doc);
      final text = getStringProperty(range, 'Text');
      releaseDispatcher(range);
      final ok = text.contains(_probeText);
      stdout.writeln(ok
          ? 'teclado: OK (o texto chegou ao documento)'
          : 'teclado: FALHOU — o documento contém "${text.trim()}"');

      // 4. CAPTURA da janela.
      final directory = Directory('${_repositoryRoot()}/$_outputDirectory')
        ..createSync(recursive: true);
      final target = '${directory.path}/ui-probe-word.bmp';
      captureWindowToBmp(window, target);
      stdout.writeln('captura: $_outputDirectory/ui-probe-word.bmp '
          '(${File(target).lengthSync()} bytes)');

      if (!ok) exit(70);
    } finally {
      // 0 = wdDoNotSaveChanges: a sonda não deixa arquivo para trás.
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
