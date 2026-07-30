import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/formats/abstract/attributor.dart';
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

/// Builds a [Registry] with the base blots plus the formats named by their
/// Quill import paths, e.g. `registryWithFormats(['formats/header'])`.
///
/// This is the Dart counterpart of the upstream test factory's
/// `createRegistry([Header, Bold])`: the definitions come from the SAME
/// registration the library ships (`Quill.importDefinition`), so a port test
/// exercises the real format instead of a hand-built stand-in.
Registry registryWithFormats(List<String> paths) {
  ensureQuillTestInitialized();
  final registry = createRegistry();
  for (final path in paths) {
    final definition = Quill.importDefinition(path);
    if (definition is RegistryEntry) {
      registry.register(definition);
    } else if (definition is Attributor) {
      registry.registerAttributor(definition);
    } else {
      throw StateError('Unknown format definition for "$path": $definition');
    }
  }
  return registry;
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
