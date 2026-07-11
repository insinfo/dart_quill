## Unreleased - 2026-07-11

### Added
- DOCX import/export API via `lib/dart_quill_docx.dart`, backed by the vendored OOXML stack in `lib/src/dependencies/canvas_editor/`.
- Delta <-> DOCX conversion helpers and demo buttons for opening and exporting `.docx`.
- `example/ngdart/` as a standalone AngularDart example package with its own `pubspec.yaml`, `web/main.dart`, and `web/index.html`.
- New browser and VM test coverage for core editor flows, including block attributors and table behavior.
- `example/ngdart` editor component wired to the public `dart_quill` package and the `package:web` DOM layer.

### Changed
- Migrated the browser/platform layer from `dart:html` to `package:web` plus `dart:js_interop`.
- Reworked `lib/src/platform/html_dom.dart` to provide the `Dom*` adapters on top of `package:web`.
- Expanded core Quill parity in `lib/src/blots/`, `lib/src/core/`, `lib/src/formats/`, and `lib/src/modules/`.
- Registered default formats, attributors, themes, and modules during `initializeQuill()`.
- Updated the editor bootstrap in `web/main.dart` to use the new DOM abstraction and the DOCX helpers.
- Consolidated the Angular example into `example/ngdart/` so the main package can stay runtime-light.
- Updated `analysis_options.yaml` and `.vscode/settings.json` to exclude reference sources from analysis and editor diagnostics.
- Removed obsolete merge scripts and the vendored `quilljs/` source tree from the active build path, keeping references under `referencias/`.

### Fixed
- Enter key behavior and selection placement in the Quill core.
- Block formatting/attributor handling so alignment, indent, direction, color, background, font, and size work again.
- `selection`, `editor`, `scroll`, and `keyboard` behavior to better match upstream Quill semantics.
- Several DOM wrapper and data transfer edge cases in the `package:web` migration.
- AngularDart example compilation issues caused by missing package wiring and invalid host element typing.

### Tests
- `dart analyze` is clean on the main package and the Angular example package.
- The Angular example builds successfully with `build_runner`.
- Existing unit and browser test coverage was expanded while fixing the core editor behavior.

### Notes
- The repository now follows the intended split between the runtime package and the examples:
  - `lib/` contains the Dart runtime/editor implementation.
  - `web/` contains the plain Dart web demo.
  - `example/ngdart/` contains the AngularDart demo.
- This changelog entry summarizes the current large refactor and porting pass rather than listing every file touched.
