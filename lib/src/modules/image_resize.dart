import 'dart:math' as math;

import '../core/module.dart';
import '../core/quill.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

enum ImageWrap { inline, left, center, right }

class ImageResizeOptions {
  const ImageResizeOptions({this.minimumSize = 24, this.preserveRatio = true});

  factory ImageResizeOptions.fromConfig(dynamic config) {
    if (config is ImageResizeOptions) return config;
    if (config is Map) {
      return ImageResizeOptions(
        minimumSize: (config['minimumSize'] as num?)?.toDouble() ?? 24,
        preserveRatio: config['preserveRatio'] is bool
            ? config['preserveRatio'] as bool
            : true,
      );
    }
    return const ImageResizeOptions();
  }

  final double minimumSize;
  final bool preserveRatio;
}

/// Word-like image selection and resizing controls.
///
/// Geometry is stored on the image embed (`width`, `height`, `data-image-wrap`
/// and anchor attributes), so it remains part of the editor document instead
/// of being transient overlay state.
class ImageResize extends Module<ImageResizeOptions> {
  ImageResize(Quill quill, ImageResizeOptions options) : super(quill, options) {
    _overlay = quill.addContainer('ql-image-resize-overlay');
    _configureOverlay();
    quill.root.addEventListener('click', _onRootClick);
    quill.root.addEventListener('scroll', (_) => refresh());
    quill.container.addEventListener('click', _onOverlayClick);
    quill.container.addEventListener('mousedown', _onResizeMouseDown);
    quill.container.ownerDocument.body.addEventListener('mousemove', _onMove);
    quill.container.ownerDocument.body.addEventListener('mouseup', _onUp);
  }

  late final DomElement _overlay;
  DomElement? selectedImage;
  String? _activeHandle;
  double _startX = 0;
  double _startY = 0;
  double _startWidth = 0;
  double _startHeight = 0;

  void _configureOverlay() {
    _overlay.style.cssText =
        'display:none;position:absolute;z-index:1000;box-sizing:border-box;'
        'border:2px solid #2b7cff;pointer-events:none;';
    for (final direction in const [
      'nw',
      'n',
      'ne',
      'e',
      'se',
      's',
      'sw',
      'w'
    ]) {
      final handle = quill.container.ownerDocument.createElement('span');
      handle.classes.add('ql-image-resize-handle');
      handle.setAttribute('data-handle', direction);
      handle.setAttribute('title', 'Redimensionar imagem');
      handle.style.cssText = _handleStyle(direction);
      _overlay.append(handle);
    }
    final toolbar = quill.container.ownerDocument.createElement('span');
    toolbar.classes.add('ql-image-layout-toolbar');
    toolbar.style.cssText =
        'position:absolute;left:0;top:-34px;display:flex;gap:0;padding:2px;'
        'background:#fff;border:1px solid #bbb;border-radius:4px;'
        'box-shadow:0 2px 6px rgba(0,0,0,.18);pointer-events:auto;';
    for (final entry in const {
      'inline': ('Em linha com o texto', 'float-none'),
      'left': ('Alinhar à esquerda com quebra de texto', 'float-left'),
      'center': ('Centralizar imagem', 'float-center'),
      'right': ('Alinhar à direita com quebra de texto', 'float-right'),
    }.entries) {
      final button = quill.container.ownerDocument.createElement('button');
      button.setAttribute('type', 'button');
      button.setAttribute('data-image-wrap', entry.key);
      button.setAttribute('title', entry.value.$1);
      button.setAttribute('aria-label', entry.value.$1);
      button.classes.add('ql-image-layout-button');
      button.style.cssText = _contextButtonStyle;
      button.innerHTML =
          '<i class="ti ti-${entry.value.$2}" aria-hidden="true"></i>';
      _layoutButtons.add(button);
      toolbar.append(button);
    }
    _overlay.append(toolbar);
  }

  static const String _contextButtonStyle =
      'appearance:none;-webkit-appearance:none;width:28px;height:28px;'
      'min-width:28px;min-height:28px;margin:0;padding:3px;border:0;'
      'border-radius:2px;background:transparent;box-shadow:none;outline:none;'
      'display:inline-flex;align-items:center;justify-content:center;'
      'color:#444;font-size:18px;line-height:1;cursor:pointer;';

  final List<DomElement> _layoutButtons = [];

  String _handleStyle(String direction) {
    final positions = <String, String>{
      'nw': 'left:-6px;top:-6px;cursor:nwse-resize',
      'n': 'left:50%;top:-6px;cursor:ns-resize',
      'ne': 'right:-6px;top:-6px;cursor:nesw-resize',
      'e': 'right:-6px;top:50%;cursor:ew-resize',
      'se': 'right:-6px;bottom:-6px;cursor:nwse-resize',
      's': 'left:50%;bottom:-6px;cursor:ns-resize',
      'sw': 'left:-6px;bottom:-6px;cursor:nesw-resize',
      'w': 'left:-6px;top:50%;cursor:ew-resize',
    };
    return 'position:absolute;width:10px;height:10px;background:#fff;'
        'border:2px solid #2b7cff;box-sizing:border-box;pointer-events:auto;'
        '${positions[direction]}';
  }

  void _onRootClick(DomEvent event) {
    final target = event.target;
    if (target is DomElement && target.tagName.toLowerCase() == 'img') {
      select(target);
    } else {
      hide();
    }
  }

  void _onOverlayClick(DomEvent event) {
    var target = event.target;
    if (target is DomElement && !target.hasAttribute('data-image-wrap')) {
      target = target.parentNode;
    }
    if (target is! DomElement) return;
    final wrap = target.getAttribute('data-image-wrap');
    if (wrap != null) {
      applyWrapName(wrap);
      event.preventDefault();
      return;
    }
  }

  void _onResizeMouseDown(DomEvent event) {
    final target = event.target;
    if (target is! DomElement) return;
    final handle = target.getAttribute('data-handle');
    if (handle != null) _beginResize(handle, event);
  }

  void _beginResize(String handle, DomEvent event) {
    final image = selectedImage;
    if (image == null) return;
    final bounds = domBindings.adapter.getElementBounds(image);
    if (bounds == null) return;
    _activeHandle = handle;
    final raw = event.rawEvent as dynamic;
    _startX = (raw.clientX as num?)?.toDouble() ?? 0;
    _startY = (raw.clientY as num?)?.toDouble() ?? 0;
    _startWidth = (bounds['width'] as num).toDouble();
    _startHeight = (bounds['height'] as num).toDouble();
    event.preventDefault();
  }

  void _onMove(DomEvent event) {
    final handle = _activeHandle;
    final image = selectedImage;
    if (handle == null || image == null) return;
    final raw = event.rawEvent as dynamic;
    final dx = ((raw.clientX as num?)?.toDouble() ?? _startX) - _startX;
    final dy = ((raw.clientY as num?)?.toDouble() ?? _startY) - _startY;
    var width = _startWidth;
    var height = _startHeight;
    if (handle.contains('e')) width += dx;
    if (handle.contains('w')) width -= dx;
    if (handle.contains('s')) height += dy;
    if (handle.contains('n')) height -= dy;
    if (options.preserveRatio && handle.length == 2 && _startHeight > 0) {
      final ratio = _startWidth / _startHeight;
      if (dx.abs() >= dy.abs()) {
        height = width / ratio;
      } else {
        width = height * ratio;
      }
    }
    resizeTo(width, height);
    event.preventDefault();
  }

  void _onUp(DomEvent _) {
    _activeHandle = null;
  }

  void select(DomElement image) {
    selectedImage = image;
    image.classes.add('ql-image-selected');
    refresh();
  }

  void hide() {
    selectedImage?.classes.remove('ql-image-selected');
    selectedImage = null;
    _activeHandle = null;
    _overlay.style.display = 'none';
  }

  void refresh() {
    final image = selectedImage;
    if (image == null) return;
    final bounds = domBindings.adapter
        .getElementBounds(image, relativeTo: quill.container);
    if (bounds == null) return;
    _overlay.style
      ..display = 'block'
      ..left = '${bounds['left']}px'
      ..top = '${bounds['top']}px'
      ..width = '${bounds['width']}px'
      ..height = '${bounds['height']}px';
  }

  void resizeTo(double width, double height) {
    final image = selectedImage;
    if (image == null) return;
    final safeWidth = math.max(options.minimumSize, width).round();
    final safeHeight = math.max(options.minimumSize, height).round();
    image
      ..setAttribute('width', '$safeWidth')
      ..setAttribute('height', '$safeHeight');
    refresh();
  }

  void applyWrap(ImageWrap wrap) => applyWrapName(wrap.name);

  void applyWrapName(String wrap) {
    final image = selectedImage;
    if (image == null) return;
    const allowed = {'inline', 'left', 'center', 'right'};
    final mode = allowed.contains(wrap) ? wrap : 'inline';
    image
      ..setAttribute('data-image-wrap', mode)
      ..setAttribute('data-anchor', mode == 'inline' ? 'inline' : 'paragraph');
    switch (mode) {
      case 'left':
        image.style.cssText =
            'float:left;display:block;margin:0 12px 8px 0;max-width:100%;';
        break;
      case 'right':
        image.style.cssText =
            'float:right;display:block;margin:0 0 8px 12px;max-width:100%;';
        break;
      case 'center':
        image.style.cssText =
            'float:none;display:block;margin:8px auto;max-width:100%;';
        break;
      default:
        image.style.cssText =
            'float:none;display:inline-block;margin:0;max-width:100%;';
    }
    for (final button in _layoutButtons) {
      final active = button.getAttribute('data-image-wrap') == mode;
      button.classes.toggle('ql-active', active);
      button.style
          .setProperty('background-color', active ? '#dbeafe' : 'transparent');
      button.style.setProperty('color', active ? '#1264d1' : '#444');
    }
    refresh();
  }
}
