/// Automação COM (IDispatch) — a ponte com o Microsoft Word.
///
/// **Proveniência:** copiado de `C:/MyDartProjects/access_to_dart`
/// (`tools/_com_automation.dart`, mesmo autor/mantenedor deste repositório),
/// com autorização explícita. Adaptações: só o que o harness do Word usa
/// permaneceu, e os comentários passaram a falar de Word em vez de Access.
///
/// O que ele resolve: `IDispatch` é a interface de automação que o Office
/// expõe, e chamar um método por ela exige montar `DISPPARAMS` com os
/// argumentos em ordem INVERSA — detalhe que, esquecido, produz "erro de
/// tipo no argumento 3" em vez de "os argumentos estão trocados".
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// `Dispatcher` é o handle de automação que atravessa toda a API deste
// harness; reexportá-lo evita que cada arquivo precise importar o win32 só
// para nomear o tipo que recebe.
export 'package:win32/win32.dart' show Dispatcher;

final _kernel32Toolhelp = DynamicLibrary.open('kernel32.dll');

final _createToolhelp32Snapshot = _kernel32Toolhelp.lookupFunction<
  IntPtr Function(Uint32 dwFlags, Uint32 th32ProcessId),
  int Function(int dwFlags, int th32ProcessId)>('CreateToolhelp32Snapshot');

final _process32First = _kernel32Toolhelp.lookupFunction<
  Int32 Function(IntPtr hSnapshot, Pointer<ProcessEntry32Ffi> lppe),
  int Function(int hSnapshot, Pointer<ProcessEntry32Ffi> lppe)>('Process32FirstW');

final _process32Next = _kernel32Toolhelp.lookupFunction<
  Int32 Function(IntPtr hSnapshot, Pointer<ProcessEntry32Ffi> lppe),
  int Function(int hSnapshot, Pointer<ProcessEntry32Ffi> lppe)>('Process32NextW');

const _th32csSnapProcess = 0x00000002;
const _maxPath = 260;

final class ProcessEntry32Ffi extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int cntUsage;

  @Uint32()
  external int th32ProcessID;

  @IntPtr()
  external int th32DefaultHeapID;

  @Uint32()
  external int th32ModuleID;

  @Uint32()
  external int cntThreads;

  @Uint32()
  external int th32ParentProcessID;

  @Int32()
  external int pcPriClassBase;

  @Uint32()
  external int dwFlags;

  @Array(_maxPath)
  external Array<Uint16> szExeFile;
}

void initializeComApartment() {
  final hr = CoInitializeEx(nullptr, COINIT.COINIT_APARTMENTTHREADED);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
    throw WindowsException(hr);
  }
}

Dispatcher createDispatcher(List<String> progIds) {
  Object? lastError;
  for (final progId in progIds) {
    try {
      final progIdPtr = progId.toNativeUtf16();
      final clsid = calloc<GUID>();
      final unknownPtr = calloc<COMObject>();
      final dispatchPtr = calloc<COMObject>();

      try {
        var hr = CLSIDFromProgID(progIdPtr, clsid);
        if (FAILED(hr)) {
          throw WindowsException(hr);
        }

        final iidIUnknown = convertToIID(IID_IUnknown);
        final iidDispatch = convertToIID(IID_IDispatch);
        try {
          hr = _coCreateUnknownWithFallback(clsid, iidIUnknown, unknownPtr);
          if (FAILED(hr)) {
            throw WindowsException(hr);
          }

          final unknown = IUnknown(unknownPtr);
          try {
            hr = unknown.queryInterface(iidDispatch, dispatchPtr.cast());
            if (FAILED(hr)) {
              throw WindowsException(hr);
            }
          } finally {
            unknown.detach();
            unknown.release();
          }
        } finally {
          free(iidIUnknown);
          free(iidDispatch);
        }

        free(unknownPtr);
        return Dispatcher(IDispatch(dispatchPtr));
      } finally {
        free(progIdPtr);
        free(clsid);
      }
    } catch (error) {
      lastError = error;
    }
  }

  throw StateError(
    'Nao foi possivel instanciar nenhum ProgID: ${progIds.join(', ')}. '
    'Ultimo erro: $lastError',
  );
}

int _coCreateUnknownWithFallback(
  Pointer<GUID> clsid,
  Pointer<GUID> iidIUnknown,
  Pointer<COMObject> unknownPtr,
) {
  final contexts = <int>[
    CLSCTX.CLSCTX_LOCAL_SERVER,
    CLSCTX.CLSCTX_ALL,
  ];

  var lastHr = E_NOINTERFACE;
  for (final context in contexts) {
    final hr = CoCreateInstance(
      clsid,
      nullptr,
      context,
      iidIUnknown,
      unknownPtr.cast(),
    );
    if (SUCCEEDED(hr)) {
      return hr;
    }
    lastHr = hr;
  }

  return lastHr;
}

void setProperty(Dispatcher dispatcher, String name, Object? value) {
  final variant = _variantFromValue(value);
  try {
    dispatcher.set(name, variant);
  } finally {
    _disposeVariantPointer(variant);
  }
}

void invokeMethod(Dispatcher dispatcher, String method, [List<Object?> args = const []]) {
  final invocation = _InvocationArgs.fromValues(args);
  try {
    dispatcher.invoke(method, invocation.params);
  } finally {
    invocation.dispose();
  }
}

Dispatcher invokeDispatchMethod(
  Dispatcher dispatcher,
  String method, [
  List<Object?> args = const [],
]) {
  final result = _invokeForResult(dispatcher, method, args);
  try {
    return _dispatchFromVariant(result, method);
  } finally {
    _disposeVariantPointer(result);
  }
}

int invokeIntMethod(Dispatcher dispatcher, String method, [List<Object?> args = const []]) {
  final result = _invokeForResult(dispatcher, method, args);
  try {
    return _intFromVariant(result, method);
  } finally {
    _disposeVariantPointer(result);
  }
}

Dispatcher getDispatchProperty(Dispatcher dispatcher, String name) {
  final result = dispatcher.get(name);
  try {
    return _dispatchFromVariant(result, name);
  } finally {
    _disposeVariantPointer(result);
  }
}

int getIntProperty(Dispatcher dispatcher, String name) {
  final result = dispatcher.get(name);
  try {
    return _intFromVariant(result, name);
  } finally {
    _disposeVariantPointer(result);
  }
}

String getStringProperty(Dispatcher dispatcher, String name) {
  final result = dispatcher.get(name);
  try {
    if (result.ref.vt != VARENUM.VT_BSTR) {
      throw StateError(
        'O retorno de $name nao eh string. VT=${result.ref.vt}',
      );
    }
    return result.ref.bstrVal.toDartString();
  } finally {
    _disposeVariantPointer(result);
  }
}

void releaseDispatcher(Dispatcher? dispatcher) {
  if (dispatcher == null) {
    return;
  }

  try {
    dispatcher.dispose();
  } catch (_) {
  }
}

Set<int> snapshotProcessIdsByExecutable(String executableName) {
  final normalizedName = executableName.toUpperCase();
  final snapshot = _createToolhelp32Snapshot(_th32csSnapProcess, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
  }

  final entry = calloc<ProcessEntry32Ffi>()..ref.dwSize = sizeOf<ProcessEntry32Ffi>();
  final processIds = <int>{};

  try {
    var hasEntry = _process32First(snapshot, entry) != 0;
    while (hasEntry) {
      final exeName = <int>[];
      for (var index = 0; index < _maxPath; index++) {
        final codeUnit = entry.ref.szExeFile[index];
        if (codeUnit == 0) {
          break;
        }
        exeName.add(codeUnit);
      }
      final dartName = String.fromCharCodes(exeName).toUpperCase();
      if (dartName == normalizedName) {
        processIds.add(entry.ref.th32ProcessID);
      }
      hasEntry = _process32Next(snapshot, entry) != 0;
    }
    return processIds;
  } finally {
    free(entry);
    CloseHandle(snapshot);
  }
}

void terminateProcessesByExecutableName(
  String executableName, {
  int timeoutMs = 8000,
  int pollIntervalMs = 250,
  int quietPeriodMs = 1500,
}) {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  DateTime? emptySince;

  while (true) {
    final processIds = snapshotProcessIdsByExecutable(executableName);
    if (processIds.isEmpty) {
      emptySince ??= DateTime.now();
      if (DateTime.now().difference(emptySince).inMilliseconds >= quietPeriodMs) {
        return;
      }
    } else {
      emptySince = null;

      for (final pid in processIds) {
        terminateProcessById(pid);
      }
    }

    if (DateTime.now().isAfter(deadline)) {
      return;
    }

    sleep(Duration(milliseconds: pollIntervalMs));
  }
}

void terminateProcessById(int processId) {
  final desiredAccess = PROCESS_ACCESS_RIGHTS.PROCESS_TERMINATE |
      PROCESS_ACCESS_RIGHTS.PROCESS_QUERY_LIMITED_INFORMATION |
      PROCESS_ACCESS_RIGHTS.PROCESS_SYNCHRONIZE;
  final processHandle = OpenProcess(desiredAccess, FALSE, processId);
  if (processHandle == 0) {
    final error = GetLastError();
    stderr.writeln('OpenProcess falhou para PID $processId. GetLastError=$error');
    return;
  }

  try {
    final waitBefore = WaitForSingleObject(processHandle, 2000);
    if (waitBefore == WAIT_EVENT.WAIT_OBJECT_0) {
      stdout.writeln('PID $processId ja havia encerrado.');
      return;
    }

    final ok = TerminateProcess(processHandle, 0);
    if (ok == 0) {
      final error = GetLastError();
      stderr.writeln('TerminateProcess falhou para PID $processId. GetLastError=$error');
      return;
    }

    final waitAfter = WaitForSingleObject(processHandle, 5000);
    if (waitAfter != WAIT_EVENT.WAIT_OBJECT_0) {
      stderr.writeln(
        'PID $processId nao confirmou encerramento apos kill. wait=$waitAfter',
      );
    } else {
      stdout.writeln('PID $processId encerrado com sucesso.');
    }
  } finally {
    CloseHandle(processHandle);
  }
}

Pointer<VARIANT> _invokeForResult(
  Dispatcher dispatcher,
  String method,
  List<Object?> args,
) {
  final invocation = _InvocationArgs.fromValues(args);
  final result = calloc<VARIANT>();
  VariantInit(result);

  try {
    dispatcher.invoke(method, invocation.params, result);
    return result;
  } catch (_) {
    _disposeVariantPointer(result);
    rethrow;
  } finally {
    invocation.dispose();
  }
}

Dispatcher _dispatchFromVariant(Pointer<VARIANT> variant, String memberName) {
  final vt = variant.ref.vt;
  if (vt != VARENUM.VT_DISPATCH) {
    throw StateError(
      'O retorno de $memberName nao eh um IDispatch. VT=$vt',
    );
  }

  final dispatch = variant.ref.pdispVal;
  dispatch.addRef();
  return Dispatcher(dispatch);
}

int _intFromVariant(Pointer<VARIANT> variant, String memberName) {
  switch (variant.ref.vt) {
    case VARENUM.VT_I2:
      return variant.ref.iVal;
    case VARENUM.VT_I4:
      return variant.ref.lVal;
    case VARENUM.VT_UI2:
      return variant.ref.uiVal;
    case VARENUM.VT_UI4:
      return variant.ref.ulVal;
    default:
      throw StateError(
        'O retorno de $memberName nao eh inteiro. VT=${variant.ref.vt}',
      );
  }
}

Pointer<VARIANT> _variantFromValue(Object? value) {
  final variant = calloc<VARIANT>();
  VariantInit(variant);
  _writeVariantValue(variant, value);
  return variant;
}

void _writeVariantValue(Pointer<VARIANT> variant, Object? value) {
  if (value == null) {
    variant.ref.vt = VARENUM.VT_EMPTY;
    return;
  }

  if (value is String) {
    final bstr = BSTR.fromString(value);
    variant.ref
      ..vt = VARENUM.VT_BSTR
      ..bstrVal = bstr.ptr;
    return;
  }

  if (value is bool) {
    variant.ref
      ..vt = VARENUM.VT_BOOL
      ..boolVal = value;
    return;
  }

  if (value is int) {
    variant.ref
      ..vt = VARENUM.VT_I4
      ..lVal = value;
    return;
  }

  if (value is Dispatcher) {
    value.dispatch.addRef();
    variant.ref
      ..vt = VARENUM.VT_DISPATCH
      ..pdispVal = value.dispatch;
    return;
  }

  throw ArgumentError('Tipo de argumento COM nao suportado: ${value.runtimeType}');
}

void _disposeVariantPointer(Pointer<VARIANT> variant) {
  VariantClear(variant);
  free(variant);
}

final class _InvocationArgs {
  _InvocationArgs._(this.params, this.variants, this.namedArg);

  final Pointer<DISPPARAMS> params;
  final Pointer<VARIANT> variants;
  final Pointer<Int32> namedArg;

  factory _InvocationArgs.fromValues(List<Object?> values) {
    final params = calloc<DISPPARAMS>();
    if (values.isEmpty) {
      params.ref
        ..rgvarg = nullptr
        ..rgdispidNamedArgs = nullptr
        ..cArgs = 0
        ..cNamedArgs = 0;
      return _InvocationArgs._(params, nullptr, nullptr);
    }

    final variants = calloc<VARIANT>(values.length);
    for (var index = 0; index < values.length; index++) {
      final reversedIndex = values.length - 1 - index;
      final variant = variants + index;
      VariantInit(variant);
      _writeVariantValue(variant, values[reversedIndex]);
    }

    params.ref
      ..rgvarg = variants
      ..rgdispidNamedArgs = nullptr
      ..cArgs = values.length
      ..cNamedArgs = 0;

    return _InvocationArgs._(params, variants, nullptr);
  }

  void dispose() {
    if (variants != nullptr) {
      for (var index = 0; index < params.ref.cArgs; index++) {
        VariantClear(variants + index);
      }
      free(variants);
    }
    if (namedArg != nullptr) {
      free(namedArg);
    }
    free(params);
  }
}

// ===========================================================================
// Interação com a UI: foco, teclado, mouse e captura de tela
// ===========================================================================
//
// COM dirige o MODELO do Word (documentos, seções, formas). O que ele não
// alcança é o CHROME — abrir a faixa Design, ver onde o Word põe a galeria
// de marca-d'água, conferir que um controle existe. Para isso é preciso
// falar com a JANELA, e é o que esta metade do arquivo faz.
//
// A ordem importa, e ela é a fonte dos dois modos de falha que já
// apareceram aqui: sem FOCO real a janela não desenha (PrintWindow devolve
// preto) e o teclado sintético vai parar em outro programa. Por isso
// [focusWindow] usa AttachThreadInput em vez de um SetForegroundWindow
// solto — o Windows recusa a troca de foreground pedida por um processo em
// segundo plano, a menos que ele esteja ligado à fila de entrada da janela
// alvo.

/// Traz [window] para a frente de VERDADE. Devolve se conseguiu.
bool focusWindow(int window) {
  if (window == 0) return false;
  final foreground = GetForegroundWindow();
  final targetThread = GetWindowThreadProcessId(window, nullptr);
  final currentThread = GetCurrentThreadId();
  final foregroundThread =
      foreground == 0 ? 0 : GetWindowThreadProcessId(foreground, nullptr);

  final attachments = <int>{targetThread, foregroundThread}
    ..remove(currentThread)
    ..remove(0);
  for (final thread in attachments) {
    AttachThreadInput(currentThread, thread, TRUE);
  }
  try {
    ShowWindow(window, SHOW_WINDOW_CMD.SW_RESTORE);
    BringWindowToTop(window);
    SetForegroundWindow(window);
    SetActiveWindow(window);
  } finally {
    for (final thread in attachments) {
      AttachThreadInput(currentThread, thread, FALSE);
    }
  }
  // Um quadro para o compositor desenhar: capturar imediatamente devolve a
  // janela pela metade.
  sleep(const Duration(milliseconds: 350));
  return GetForegroundWindow() == window;
}

/// A janela de topo da classe [className] que pertence a [processIds].
///
/// Pelo PROCESSO, não pelo título: `Application.Caption` do Word devolve só
/// "Word" enquanto a janela se chama "arquivo.docx - Word", e casar por
/// título erra sempre. `FindWindowEx` com pai nulo percorre as janelas de
/// topo daquela classe sem precisar de callback.
int findWindowOfProcess(String className, Set<int> processIds) {
  final classNamePtr = className.toNativeUtf16();
  try {
    var candidate = FindWindowEx(NULL, NULL, classNamePtr, nullptr);
    while (candidate != 0) {
      final owner = calloc<Uint32>();
      try {
        GetWindowThreadProcessId(candidate, owner);
        if (processIds.contains(owner.value)) return candidate;
      } finally {
        free(owner);
      }
      candidate = FindWindowEx(NULL, candidate, classNamePtr, nullptr);
    }
  } finally {
    free(classNamePtr);
  }
  return 0;
}

// -- teclado ----------------------------------------------------------------

/// Modificadores de um atalho.
final class KeyModifiers {
  const KeyModifiers({
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.win = false,
  });

  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool win;

  List<int> get virtualKeys => [
        if (ctrl) VIRTUAL_KEY.VK_CONTROL,
        if (alt) VIRTUAL_KEY.VK_MENU,
        if (shift) VIRTUAL_KEY.VK_SHIFT,
        if (win) VIRTUAL_KEY.VK_LWIN,
      ];
}

/// A janela em primeiro plano AGORA.
int foregroundWindow() => GetForegroundWindow();

/// Executa [body] só enquanto [window] estiver em primeiro plano.
///
/// É a guarda que faltava na primeira versão da sonda: `SendInput` entrega o
/// evento a QUEM TIVER O FOCO no instante da chamada, não à janela que o
/// script tinha em mente. Se outro programa recuperou o foco no meio do
/// caminho — o que acontece o tempo todo numa máquina em uso —, digitar sem
/// conferir escreve na janela alheia. Aqui a checagem é imediatamente antes
/// de cada lote, e a falha é ruidosa.
void whileFocused(int window, void Function() body) {
  if (GetForegroundWindow() != window && !focusWindow(window)) {
    throw StateError(
      'a janela alvo não está em primeiro plano; a entrada sintética foi '
      'ABORTADA para não ser digitada em outro programa.',
    );
  }
  body();
}

/// Pressiona e solta [virtualKey] com [modifiers] (`VIRTUAL_KEY.VK_*`).
///
/// Solta na ordem INVERSA da que pressionou, como um teclado real: liberar o
/// Ctrl antes da tecla deixaria o Word processando a tecla sozinha.
void sendKey(int virtualKey, {KeyModifiers modifiers = const KeyModifiers()}) {
  final held = modifiers.virtualKeys;
  for (final key in held) {
    _sendKeyboardEvent(key, down: true);
  }
  _sendKeyboardEvent(virtualKey, down: true);
  _sendKeyboardEvent(virtualKey, down: false);
  for (final key in held.reversed) {
    _sendKeyboardEvent(key, down: false);
  }
}

/// Digita [text] literalmente.
///
/// Vai por `KEYEVENTF_UNICODE`, não por código de tecla: um mapeamento por
/// tecla dependeria do layout do teclado da máquina (um "ç" não existe no
/// layout americano), e o harness precisa produzir o MESMO texto em qualquer
/// instalação.
void sendText(String text) {
  for (final unit in text.codeUnits) {
    _sendUnicodeUnit(unit, down: true);
    _sendUnicodeUnit(unit, down: false);
  }
}

void _sendKeyboardEvent(int virtualKey, {required bool down}) {
  final input = calloc<INPUT>();
  try {
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki
      ..wVk = virtualKey
      ..wScan = 0
      ..dwFlags = down ? 0 : KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP
      ..time = 0
      ..dwExtraInfo = 0;
    _dispatchInput(input);
  } finally {
    free(input);
  }
}

void _sendUnicodeUnit(int codeUnit, {required bool down}) {
  final input = calloc<INPUT>();
  try {
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki
      ..wVk = 0
      ..wScan = codeUnit
      ..dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_UNICODE |
          (down ? 0 : KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP)
      ..time = 0
      ..dwExtraInfo = 0;
    _dispatchInput(input);
  } finally {
    free(input);
  }
}

// -- mouse ------------------------------------------------------------------

/// Botão do mouse.
enum MouseButton { left, right, middle }

/// Move o ponteiro para ([x], [y]) em pixels de TELA.
///
/// `MOUSEEVENTF_ABSOLUTE` trabalha numa grade normalizada de 0..65535 sobre
/// a tela primária; converter aqui evita que cada chamador redescubra a
/// conta — e errá-la é o motivo clássico de o clique cair no canto.
void moveMouse(int x, int y) {
  final width = GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN);
  final height = GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSCREEN);
  if (width <= 1 || height <= 1) return;
  final input = calloc<INPUT>();
  try {
    input.ref.type = INPUT_TYPE.INPUT_MOUSE;
    input.ref.mi
      ..dx = (x * 65535 / (width - 1)).round()
      ..dy = (y * 65535 / (height - 1)).round()
      ..mouseData = 0
      ..dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_MOVE |
          MOUSE_EVENT_FLAGS.MOUSEEVENTF_ABSOLUTE
      ..time = 0
      ..dwExtraInfo = 0;
    _dispatchInput(input);
  } finally {
    free(input);
  }
}

/// Clica no ponto atual — ou em ([x], [y]), quando informados.
void clickMouse({
  int? x,
  int? y,
  MouseButton button = MouseButton.left,
  int times = 1,
}) {
  if (x != null && y != null) {
    moveMouse(x, y);
    // O Word ignora um clique que chega no mesmo tick do movimento.
    sleep(const Duration(milliseconds: 60));
  }
  final (down, up) = switch (button) {
    MouseButton.left => (
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTDOWN,
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTUP
      ),
    MouseButton.right => (
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_RIGHTDOWN,
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_RIGHTUP
      ),
    MouseButton.middle => (
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_MIDDLEDOWN,
        MOUSE_EVENT_FLAGS.MOUSEEVENTF_MIDDLEUP
      ),
  };
  for (var i = 0; i < times; i++) {
    _sendMouseEvent(down);
    _sendMouseEvent(up);
    if (i + 1 < times) sleep(const Duration(milliseconds: 60));
  }
}

/// Arrasta de ([fromX], [fromY]) até ([toX], [toY]).
///
/// Com passos intermediários de propósito: um salto de um ponto ao outro não
/// gera `mousemove` no caminho, e toda alça de redimensionamento — a do Word
/// e a do nosso editor — decide o gesto justamente nesses eventos.
void dragMouse(int fromX, int fromY, int toX, int toY, {int steps = 12}) {
  moveMouse(fromX, fromY);
  sleep(const Duration(milliseconds: 60));
  _sendMouseEvent(MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTDOWN);
  for (var i = 1; i <= steps; i++) {
    moveMouse(
      fromX + ((toX - fromX) * i / steps).round(),
      fromY + ((toY - fromY) * i / steps).round(),
    );
    sleep(const Duration(milliseconds: 16));
  }
  _sendMouseEvent(MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTUP);
}

/// Roda a roda do mouse ([notches] positivo = para cima).
void scrollMouse(int notches) {
  final input = calloc<INPUT>();
  try {
    input.ref.type = INPUT_TYPE.INPUT_MOUSE;
    input.ref.mi
      ..dx = 0
      ..dy = 0
      ..mouseData = notches * 120 // WHEEL_DELTA
      ..dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_WHEEL
      ..time = 0
      ..dwExtraInfo = 0;
    _dispatchInput(input);
  } finally {
    free(input);
  }
}

void _sendMouseEvent(int flags) {
  final input = calloc<INPUT>();
  try {
    input.ref.type = INPUT_TYPE.INPUT_MOUSE;
    input.ref.mi
      ..dx = 0
      ..dy = 0
      ..mouseData = 0
      ..dwFlags = flags
      ..time = 0
      ..dwExtraInfo = 0;
    _dispatchInput(input);
  } finally {
    free(input);
  }
}

void _dispatchInput(Pointer<INPUT> input) {
  final sent = SendInput(1, input, sizeOf<INPUT>());
  if (sent != 1) {
    throw StateError('SendInput recusado (UIPI/elevação?): '
        'GetLastError=${GetLastError()}');
  }
}

// -- captura ----------------------------------------------------------------

/// A área de uma janela, em coordenadas de tela.
({int left, int top, int width, int height}) windowBounds(int window) {
  final rect = calloc<RECT>();
  try {
    if (GetWindowRect(window, rect) == 0) {
      throw StateError('GetWindowRect falhou para $window');
    }
    return (
      left: rect.ref.left,
      top: rect.ref.top,
      width: rect.ref.right - rect.ref.left,
      height: rect.ref.bottom - rect.ref.top,
    );
  } finally {
    free(rect);
  }
}

/// Captura [window] e grava um BMP de 32 bits em [path].
///
/// Tenta `PrintWindow` (que copia a janela mesmo parcialmente coberta) e, se
/// ele devolver preto — acontece com janelas que a composição do Windows
/// nunca desenhou —, cai para a cópia da TELA. Esse fallback só é legítimo
/// porque [requireForeground] obriga a janela a estar realmente em primeiro
/// plano: sem isso o retângulo conteria a janela de OUTRO programa, e o
/// harness gravaria a tela de quem está usando a máquina. Foi o que a
/// primeira versão deste arquivo fez, e a imagem foi descartada.
void captureWindowToBmp(
  int window,
  String path, {
  bool requireForeground = true,
}) {
  if (window == 0) throw StateError('janela inválida');
  if (requireForeground && !focusWindow(window)) {
    throw StateError(
      'não foi possível trazer a janela para primeiro plano. A captura foi '
      'ABORTADA de propósito: copiar a tela nessa situação gravaria a janela '
      'de outro programa.',
    );
  }
  final bounds = windowBounds(window);
  if (bounds.width <= 0 || bounds.height <= 0) {
    throw StateError('janela sem área visível');
  }

  final screenDc = GetDC(NULL);
  final memoryDc = CreateCompatibleDC(screenDc);
  final bitmap = CreateCompatibleBitmap(screenDc, bounds.width, bounds.height);
  final previous = SelectObject(memoryDc, bitmap);
  try {
    // 2 = PW_RENDERFULLCONTENT.
    final printed = PrintWindow(window, memoryDc, 2);
    if (printed == 0 ||
        _isBlankBitmap(memoryDc, bitmap, bounds.width, bounds.height)) {
      BitBlt(memoryDc, 0, 0, bounds.width, bounds.height, screenDc,
          bounds.left, bounds.top, ROP_CODE.SRCCOPY);
    }
    _writeBmp(path, memoryDc, bitmap, bounds.width, bounds.height);
  } finally {
    SelectObject(memoryDc, previous);
    DeleteObject(bitmap);
    DeleteDC(memoryDc);
    ReleaseDC(NULL, screenDc);
  }
}

/// Captura a TELA inteira — o "print screen" — em [path].
void captureScreenToBmp(String path) {
  final width = GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN);
  final height = GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSCREEN);
  final screenDc = GetDC(NULL);
  final memoryDc = CreateCompatibleDC(screenDc);
  final bitmap = CreateCompatibleBitmap(screenDc, width, height);
  final previous = SelectObject(memoryDc, bitmap);
  try {
    BitBlt(memoryDc, 0, 0, width, height, screenDc, 0, 0, ROP_CODE.SRCCOPY);
    _writeBmp(path, memoryDc, bitmap, width, height);
  } finally {
    SelectObject(memoryDc, previous);
    DeleteObject(bitmap);
    DeleteDC(memoryDc);
    ReleaseDC(NULL, screenDc);
  }
}

/// A captura saiu inteiramente preta?
///
/// `PrintWindow` devolve SUCESSO e mesmo assim entrega preto em janelas que
/// a composição nunca desenhou; gravar isso em silêncio é o pior resultado
/// possível para um insumo de comparação visual. A amostragem é esparsa —
/// varrer 8 MB para responder "é tudo preto?" custaria mais que a captura.
bool _isBlankBitmap(int deviceContext, int bitmap, int width, int height) {
  final info = _bitmapInfo(width, height);
  final bytes = width * height * 4;
  final pixels = calloc<Uint8>(bytes);
  try {
    if (GetDIBits(deviceContext, bitmap, 0, height, pixels, info,
            DIB_USAGE.DIB_RGB_COLORS) ==
        0) {
      return true;
    }
    final data = pixels.asTypedList(bytes);
    for (var i = 0; i + 2 < bytes; i += 4 * 997) {
      if (data[i] != 0 || data[i + 1] != 0 || data[i + 2] != 0) return false;
    }
    return true;
  } finally {
    free(pixels);
    free(info);
  }
}

Pointer<BITMAPINFO> _bitmapInfo(int width, int height) {
  final info = calloc<BITMAPINFO>();
  info.ref.bmiHeader
    ..biSize = sizeOf<BITMAPINFOHEADER>()
    ..biWidth = width
    // Negativo = linhas de cima para baixo, que é a ordem em que o BMP é
    // gravado sem inverter nada à mão.
    ..biHeight = -height
    ..biPlanes = 1
    ..biBitCount = 32
    ..biCompression = BI_COMPRESSION.BI_RGB;
  return info;
}

/// BMP de 32 bits — o formato que se escreve sem nenhum codec.
///
/// PNG exigiria deflate + CRC aqui dentro para nada: a captura é insumo de
/// olho humano, não artefato do repositório.
void _writeBmp(
    String path, int deviceContext, int bitmap, int width, int height) {
  final info = _bitmapInfo(width, height);
  final pixelBytes = width * height * 4;
  final pixels = calloc<Uint8>(pixelBytes);
  try {
    if (GetDIBits(deviceContext, bitmap, 0, height, pixels, info,
            DIB_USAGE.DIB_RGB_COLORS) ==
        0) {
      throw StateError('GetDIBits falhou');
    }
    const fileHeaderSize = 14;
    const infoHeaderSize = 40;
    final header = ByteData(fileHeaderSize + infoHeaderSize);
    header.setUint8(0, 0x42); // 'B'
    header.setUint8(1, 0x4d); // 'M'
    header.setUint32(
        2, fileHeaderSize + infoHeaderSize + pixelBytes, Endian.little);
    header.setUint32(10, fileHeaderSize + infoHeaderSize, Endian.little);
    header.setUint32(14, infoHeaderSize, Endian.little);
    header.setInt32(18, width, Endian.little);
    header.setInt32(22, -height, Endian.little);
    header.setUint16(26, 1, Endian.little);
    header.setUint16(28, 32, Endian.little);
    final output = BytesBuilder()
      ..add(header.buffer.asUint8List())
      ..add(pixels.asTypedList(pixelBytes));
    File(path).writeAsBytesSync(output.takeBytes());
  } finally {
    free(pixels);
    free(info);
  }
}