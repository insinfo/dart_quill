import '../platform/dom.dart';

class EmitterSource {
  const EmitterSource();
  static const String API = 'api';
  static const String SILENT = 'silent';
  static const String USER = 'user';
}

class EmitterEvents {
  static const String EDITOR_CHANGE = 'editor-change';
  static const String TEXT_CHANGE = 'text-change';
  static const String SELECTION_CHANGE = 'selection-change';
  static const String SCROLL_BLOT_MOUNT = 'scroll-blot-mount';
  static const String SCROLL_BLOT_UNMOUNT = 'scroll-blot-unmount';
  static const String SCROLL_EMBED_UPDATE = 'scroll-embed-update';
  static const String SCROLL_OPTIMIZE = 'scroll-optimize';
  static const String SCROLL_BEFORE_UPDATE = 'scroll-before-update';
  static const String SCROLL_UPDATE = 'scroll-update';
  static const String SCROLL_SELECTION_CHANGE = 'scroll-selection-change';
  static const String COMPOSITION_BEFORE_START = 'composition-before-start';
  static const String COMPOSITION_START = 'composition-start';
  static const String COMPOSITION_BEFORE_END = 'composition-before-end';
  static const String COMPOSITION_END = 'composition-end';
}

class Emitter {
  static EmitterEvents get events => EmitterEvents();
  static EmitterSource get sources => EmitterSource();

  final Map<String, List<Function>> _handlers = {};
  final Map<String, List<_DomListener>> _domListeners = {};

  void on(String event, Function handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void once(String event, Function handler) {
    void wrapper(
        [dynamic arg1 = _absent,
        dynamic arg2 = _absent,
        dynamic arg3 = _absent,
        dynamic arg4 = _absent]) {
      off(event, wrapper);
      _dispatch(handler, _collectArgs(arg1, arg2, arg3, arg4));
    }

    on(event, wrapper);
  }

  void off(String event, [Function? handler]) {
    if (handler == null) {
      _handlers.remove(event);
    } else {
      _handlers[event]?.remove(handler);
      if (_handlers[event]?.isEmpty ?? false) {
        _handlers.remove(event);
      }
    }
  }

  /// Sentinel distinguishing "argument not passed" from an explicit `null`,
  /// so events like SELECTION_CHANGE(range, oldRange: null, source) reach
  /// handlers with their full argument list (parity with eventemitter3).
  static const Object _absent = Object();

  void emit(String event,
      [dynamic data1 = _absent,
      dynamic data2 = _absent,
      dynamic data3 = _absent,
      dynamic data4 = _absent]) {
    final handlers = _handlers[event];
    if (handlers == null) return;

    final args = _collectArgs(data1, data2, data3, data4);
    for (final handler in List<Function>.from(handlers)) {
      _dispatch(handler, args);
    }
  }

  static List<dynamic> _collectArgs(
      dynamic d1, dynamic d2, dynamic d3, dynamic d4) {
    final args = <dynamic>[];
    for (final d in [d1, d2, d3, d4]) {
      if (identical(d, _absent)) break;
      args.add(d);
    }
    return args;
  }

  /// Invokes [handler] with as many of [args] as its signature accepts,
  /// trying the full list first and trimming from the end on arity mismatch.
  static void _dispatch(Function handler, List<dynamic> args) {
    for (var count = args.length; count >= 0; count--) {
      try {
        Function.apply(handler, args.sublist(0, count));
        return;
      } on NoSuchMethodError {
        if (count == 0) rethrow;
      }
    }
  }

  void listenDOM(String type, DomElement target, Function listener) {
    final listeners = _domListeners.putIfAbsent(type, () => <_DomListener>[]);
    listeners.add(_DomListener(node: target, handler: listener));
  }

  void handleDOM(String type, DomEvent event, [List<dynamic> args = const []]) {
    final listeners = _domListeners[type];
    if (listeners == null) {
      return;
    }
    final target = event.target;
    for (final entry in List<_DomListener>.from(listeners)) {
      if (entry.node == target || entry.node.contains(target)) {
        final positional = <dynamic>[event, ...args];
        Function.apply(entry.handler, positional);
      }
    }
  }
}

class _DomListener {
  _DomListener({required this.node, required this.handler});

  final DomElement node;
  final Function handler;
}
