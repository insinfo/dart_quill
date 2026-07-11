import '../platform/platform.dart';
import 'snow_css.dart';

export 'snow_css.dart' show quillSnowCss;

/// Injects embedded editor stylesheets into the current document so
/// consumers don't need to ship separate .css files.
class QuillAssets {
  QuillAssets._();

  static final Set<String> _injected = {};

  /// Injects the Snow theme stylesheet once per document.
  static void injectSnowTheme() => _injectCss('ql-snow-css', quillSnowCss);

  static void _injectCss(String id, String css) {
    if (_injected.contains(id)) return;
    final document = domBindings.adapter.document;
    final head = document.querySelector('head') ?? document.body;
    final style = document.createElement('style');
    style.setAttribute('data-quill-style', id);
    style.text = css;
    head.append(style);
    _injected.add(id);
  }
}
