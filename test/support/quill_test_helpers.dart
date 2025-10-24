import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
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
Quill createTestQuill({String? initialHtml}) {
  ensureQuillTestInitialized();
  final doc = testAdapter.document;
  final container = doc.createElement('div');
  doc.body.append(container);
  final quill = Quill(container);
  if (initialHtml != null) {
    quill.clipboard.dangerouslyPasteHTML(initialHtml);
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
