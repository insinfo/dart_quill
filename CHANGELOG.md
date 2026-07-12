## Unreleased - 2026-07-11

### Added
- `CellSelectionController` opt-in com âncora por clique e extensão por
  `Shift`-click, usando as coordenadas lógicas do table-better.
- Núcleo `CellSelection` do table-better com retângulo lógico normalizado,
  expansão de `rowspan`/`colspan` e marcação das células selecionadas.
- `TableClipboard.getTableDelta`/`onPaste` para colagem contextual dentro de
  células, com proteção contra aninhamento de tabelas temporárias.
- `quill-table-better` clipboard matchers for `table`, `tr`, `td`/`th` and
  `col`, preserving table attributes, header cells, column spans/widths and
  internal cell IDs.
- Opt-in `TableClipboard`, `registerTableBetter()` wiring and the public
  `dart_quill_table_better.dart` entrypoint without changing stock clipboard
  behavior.
- Horizontal cell merge/split actions with persisted `colspan` and logical-column-aware table balancing.
- Puppeteer coverage for merge/split and for the plain-Dart demo's bundled Tabler icon theme.
- Shelf/Webdev-backed Puppeteer E2E coverage for the table grid and contextual toolbar, including computed-style assertions against Limitless CSS interference.
- A quill-table-better-style 10 × 10 table picker with progressive hover selection and a live rows × columns label.
- A contextual mini-toolbar positioned above the active table cell, with Tabler controls for row/column insertion and deletion.
- `ImageResize` module with a Word-inspired selection overlay, eight resize handles, minimum-size enforcement, corner aspect-ratio preservation, and inline/left/center/right text-layout controls.
- Persistent image geometry/layout metadata (`width`, `height`, `data-image-wrap`, and anchor attributes) on image embeds.
- Table toolbar actions for inserting rows/columns on each side and deleting the current row, column, or table.
- Tabler `float-*`, row/column insertion/removal, and table icons from the bundled `lib/assets/icons/tabler` font for the new controls.
- A default 3 × 3 table insertion control in the Snow toolbar and AngularDart example; the basic `Table` API is now publicly exported.
- Portuguese `title` tooltips and accessible labels for generated toolbar buttons and selects.
- File-based Snow and Limitless integration styles under `lib/assets/`.
- Optional Tabler Icons webfont toolbar through `QuillIconTheme.tabler`, while preserving SVG icons as the default.
- Browser coverage that verifies both the legacy SVG and Tabler icon modes.
- DOCX import/export API via `lib/dart_quill_docx.dart`, backed by the vendored OOXML stack in `lib/src/dependencies/canvas_editor/`.
- Delta <-> DOCX conversion helpers and demo buttons for opening and exporting `.docx`.
- `example/ngdart/` as a standalone AngularDart example package with its own `pubspec.yaml`, `web/main.dart`, and `web/index.html`.
- New browser and VM test coverage for core editor flows, including block attributors and table behavior.
- `example/ngdart` editor component wired to the public `dart_quill` package and the `package:web` DOM layer.

### Changed
- Updated the root `web/` demo to load bundled Snow, Limitless integration, and Tabler icon assets through `packages/dart_quill/assets/`.
- Enabled `QuillIconTheme.tabler` in the plain-Dart demo so it matches the AngularDart example.
- Excluded generated `build/**` output from static analysis.
- Replaced the permanently visible table action buttons with a single table dropdown and contextual cell toolbar, matching the interaction model of the reference `quill-table-better` plugin.
- Enabled the image resize module by default and added table actions to the plain Dart and AngularDart demo toolbars.
- Enabled the basic table module in the default module set.
- Restored `referencias/` visibility in the VS Code Explorer while keeping it excluded from Dart analysis and workspace search.
- Updated `example/ngdart/` to load the Limitless `all.min.css`, Inter, static Quill styles, and Tabler icons in the same layered order used by the Canvas Editor example.
- Migrated the browser/platform layer from `dart:html` to `package:web` plus `dart:js_interop`.
- Reworked `lib/src/platform/html_dom.dart` to provide the `Dom*` adapters on top of `package:web`.
- Expanded core Quill parity in `lib/src/blots/`, `lib/src/core/`, `lib/src/formats/`, and `lib/src/modules/`.
- Registered default formats, attributors, themes, and modules during `initializeQuill()`.
- Updated the editor bootstrap in `web/main.dart` to use the new DOM abstraction and the DOCX helpers.
- Consolidated the Angular example into `example/ngdart/` so the main package can stay runtime-light.
- Updated `analysis_options.yaml` and `.vscode/settings.json` to exclude reference sources from analysis and editor diagnostics.
- Removed obsolete merge scripts and the vendored `quilljs/` source tree from the active build path, keeping references under `referencias/`.

### Fixed
- Reset contextual image and table buttons to Quill's icon-only 28 × 28 presentation, preventing native/Limitless button borders, backgrounds, padding, and shadows from leaking into floating toolbars.
- Contextual table toolbar visibility now follows the active table cell reliably after insertion and browser selection updates.
- Multi-line block formatting now matches Quill 2.0.3: alignment and list actions apply to every selected line instead of only the first.
- Clear formatting now removes both inline styles and block formats such as bullet/ordered lists across the whole selection.
- Clearing a list now unwraps list items into sibling paragraphs instead of producing invalid `<ul><p>...</p></ul>` markup.
- Toolbar actions preserve the saved multi-line range when focus moves to a button or picker.
- Removed duplicate Snow CSS loading from the Limitless example because `all.min.css` already ships Quill rules; the integration stylesheet now normalizes toolbar groups, buttons, pickers, dropdowns, editor sizing, and responsive wrapping.
- Replaced the remaining SVG picker arrows with Tabler `ti-selector` markup whenever `QuillIconTheme.tabler` is active, ensuring an editor instance uses one icon system only.
- Enter key behavior and selection placement in the Quill core.
- Block formatting/attributor handling so alignment, indent, direction, color, background, font, and size work again.
- `selection`, `editor`, `scroll`, and `keyboard` behavior to better match upstream Quill semantics.
- Several DOM wrapper and data transfer edge cases in the `package:web` migration.
- AngularDart example compilation issues caused by missing package wiring and invalid host element typing.

### Tests
- 204 unit tests and 3 Puppeteer E2E scenarios passing after the merge/split port.
- Port/audit source expanded to `referencias/quilljs/test` for upstream unit, E2E, and fuzz scenarios.
- 203 unit tests and 2 Puppeteer E2E tests passing; AngularDart analysis/build also clean.
- Added unit coverage for image selection, all eight handles, persisted layout metadata, resizing, and minimum dimensions.
- AngularDart production build succeeds with 163 outputs after the image/table additions.
- Full VM suite: 201 tests passing (2026-07-11).
- Added regression coverage for multi-line alignment/list formatting and clearing mixed bold/list formatting.
- `dart test`: 197 tests passing; `dart analyze`: clean (2026-07-11).
- `dart analyze` is clean on the main package and the Angular example package.
- The Angular example builds successfully with `build_runner`.
- Existing unit and browser test coverage was expanded while fixing the core editor behavior.

### Notes
- The repository now follows the intended split between the runtime package and the examples:
  - `lib/` contains the Dart runtime/editor implementation.
  - `web/` contains the plain Dart web demo.
  - `example/ngdart/` contains the AngularDart demo.
- This changelog entry summarizes the current large refactor and porting pass rather than listing every file touched.
