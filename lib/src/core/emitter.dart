class EmitterSource {
  static const String USER = 'user';
}

class EmitterEvents {
  static const String SCROLL_BLOT_MOUNT = 'scroll-blot-mount';
  static const String SCROLL_BLOT_UNMOUNT = 'scroll-blot-unmount';
  static const String SCROLL_EMBED_UPDATE = 'scroll-embed-update';
  static const String SCROLL_OPTIMIZE = 'scroll-optimize';
  static const String SCROLL_BEFORE_UPDATE = 'scroll-before-update';
  static const String SCROLL_UPDATE = 'scroll-update';
  static const String SCROLL_SELECTION_CHANGE = 'scroll-selection-change';
}

class Emitter {
  static EmitterEvents get events => EmitterEvents();
  static EmitterSource get sources => EmitterSource();

  final Map<String, List<Function>> _handlers = {};

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
}
