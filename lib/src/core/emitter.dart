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

  void emit(String event, [dynamic data1, dynamic data2, dynamic data3]) {
    final handlers = _handlers[event];
    if (handlers == null) return;

    for (var handler in handlers) {
      if (data3 != null) {
        handler(data1, data2, data3);
      } else if (data2 != null) {
        handler(data1, data2);
      } else if (data1 != null) {
        handler(data1);
      } else {
        handler();
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
