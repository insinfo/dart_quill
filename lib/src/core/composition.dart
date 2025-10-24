import 'dart:async';

import '../blots/embed.dart';
import '../blots/scroll.dart';
import '../platform/dom.dart';
import 'emitter.dart';

class Composition {
  Composition(this.scroll, this.emitter) {
    _setupListeners();
  }

  final Scroll scroll;
  final Emitter emitter;
  bool isComposing = false;

  void _setupListeners() {
    scroll.element
        .addEventListener('compositionstart', _handleCompositionStart);
    scroll.element.addEventListener('compositionend', (event) {
      if (!isComposing) {
        return;
      }
      Future.microtask(() => _handleCompositionEnd(event));
    });
  }

  void _handleCompositionStart(DomEvent event) {
    if (isComposing) {
      return;
    }
    final target = event.target;
    final blot = target != null ? scroll.find(target, bubble: true).key : null;
    if (blot != null && blot is! Embed) {
      emitter.emit(EmitterEvents.COMPOSITION_BEFORE_START, event);
      scroll.batchStart();
      emitter.emit(EmitterEvents.COMPOSITION_START, event);
      isComposing = true;
    }
  }

  void _handleCompositionEnd(DomEvent event) {
    if (!isComposing) {
      return;
    }
    emitter.emit(EmitterEvents.COMPOSITION_BEFORE_END, event);
    scroll.batchEnd();
    emitter.emit(EmitterEvents.COMPOSITION_END, event);
    isComposing = false;
  }
}
