/// Motor documental do modo avançado (EXPERIMENTAL — API instável).
///
/// Núcleo ProseMirror-like em Dart puro: árvore imutável validada por schema
/// (`model/`), transações e steps com mapping de posições (`transform/`),
/// estado com plugins (`state/`). Vendorizado do port existente em
/// `docx_rendering` com os testes derivados do upstream (334 casos).
///
/// A direção arquitetural completa está em
/// `doc/PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md` (§ Arquitetura consolidada):
/// editar em árvore ProseMirror-like, persistir como OfficeDocumentSnapshot,
/// interoperar via Delta, importar/exportar OOXML preservador e paginar com
/// um PageGraph único consumido pelo editor e pelo PDF.
///
/// Os nomes públicos definitivos (OfficeNode, OfficeSchema,
/// OfficeTransaction…) entram quando a fachada estabilizar; por ora este
/// entrypoint expõe o núcleo com os nomes do port para desenvolvimento.
library;

export 'src/document_engine/model/index.dart';
export 'src/document_engine/state/index.dart';
export 'src/document_engine/transform/index.dart';
