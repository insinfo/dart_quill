import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/clipboard.dart';
import 'package:test/test.dart';
import 'test_helpers.dart';

bool _quillTestInitialized = false;

/// Ensures the fake DOM adapter and Quill defaults are registered once.
void ensureQuillTestInitialized() {
  if (_quillTestInitialized) {
    return;
  }
  initializeFakeDom();
  initializeQuill();
  _quillTestInitialized = true;
}

/// Creates a fresh Quill instance backed by the fake DOM.
/// Optionally seeds the editor with HTML content via clipboard paste.
Quill createTestQuill({
  String? initialHtml,
  ClipboardOptions? clipboardOptions,
  Map<String, dynamic>? modules,
  String? theme,
}) {
  ensureQuillTestInitialized();
  final doc = testAdapter.document;
  final container = doc.createElement('div');
  doc.body.append(container);
  final mergedModules = <String, dynamic>{};
  if (modules != null) {
    mergedModules.addAll(modules);
  }
  if (clipboardOptions != null) {
    mergedModules['clipboard'] = clipboardOptions;
  }
  ThemeOptions? themeOptions;
  if (mergedModules.isNotEmpty || theme != null) {
    themeOptions = ThemeOptions(
      theme: theme,
      modules: mergedModules,
    );
  }
  final quill = themeOptions != null
      ? Quill(container, options: themeOptions)
      : Quill(container);
  if (initialHtml != null) {
    quill.clipboard.dangerouslyPasteHTML(initialHtml);
    quill.history.clear();
    quill.history.cutoff();
    quill.selection.clear();
  }
  addTearDown(() {
    quill.container.remove();
  });
  return quill;
}

/// Utility matcher for Delta comparisons.
void expectDelta(Delta actual, Delta expected) {
  expect(actual.toJson(), equals(expected.toJson()));
}
