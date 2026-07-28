import '../platform/platform.dart';

/// Loads the editor stylesheets that ship with the package.
///
/// The CSS lives in `lib/assets/*.css` as **files**, not as Dart constants, and
/// is referenced with `<link rel="stylesheet">`. This mirrors upstream Quill —
/// its `.styl` sources are separate bundle entries extracted by
/// MiniCssExtractPlugin, so `quill.js` carries no CSS and consumers import
/// `quill/dist/quill.snow.css` — and it has two practical consequences:
///
/// * an application can edit the theme, override rules or swap in a completely
///   different stylesheet without recompiling or forking this package;
/// * a `const String` of CSS reachable from a public export is not removed by
///   dart2js tree-shaking, so embedding it would add ~37 KB to the JavaScript of
///   every application, including those that ship their own theme.
///
/// Using this class is optional: declaring the same `<link>` tags in the host
/// HTML works just as well.
class QuillAssets {
  QuillAssets._();

  /// Core rules shared by every theme.
  static const String coreStylesheet =
      'packages/dart_quill/assets/quill.core.css';
  static const String snowStylesheet =
      'packages/dart_quill/assets/quill.snow.css';
  static const String bubbleStylesheet =
      'packages/dart_quill/assets/quill.bubble.css';
  static const String tableBetterStylesheet =
      'packages/dart_quill/assets/quill-table-better.css';
  static const String limitlessStylesheet =
      'packages/dart_quill/assets/quill.limitless.css';
  static const String tablerIconsStylesheet =
      'packages/dart_quill/assets/icons/tabler/tabler-icons.css';

  static final Set<String> _injected = {};

  /// Loads the Snow theme stylesheet once per document.
  static void injectSnowTheme() =>
      injectStylesheet('ql-snow-css', snowStylesheet);

  /// Loads the Bubble theme stylesheet once per document.
  static void injectBubbleTheme() =>
      injectStylesheet('ql-bubble-css', bubbleStylesheet);

  /// Loads the table-better UI stylesheet once per document.
  static void injectTableBetterTheme() =>
      injectStylesheet('ql-table-better-css', tableBetterStylesheet);

  /// Loads the Snow theme, the Limitless integration layer and the Tabler icon
  /// font.
  static void injectFileTheme({bool tablerIcons = true}) {
    injectStylesheet('ql-snow-file', snowStylesheet);
    if (tablerIcons) {
      injectStylesheet('ql-tabler-icons', tablerIconsStylesheet);
    }
    injectStylesheet('ql-limitless-file', limitlessStylesheet);
  }

  /// Appends a `<link rel="stylesheet">` for [href], at most once per [id].
  static void injectStylesheet(String id, String href) {
    if (_injected.contains(id)) return;
    final document = domBindings.adapter.document;
    final head = document.querySelector('head') ?? document.body;
    final link = document.createElement('link');
    link.setAttribute('rel', 'stylesheet');
    link.setAttribute('href', href);
    link.setAttribute('data-quill-style', id);
    head.append(link);
    _injected.add(id);
  }

  /// Forgets which stylesheets were injected (tests).
  static void resetForTesting() => _injected.clear();
}
