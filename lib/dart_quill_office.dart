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
/// A fachada pública usa os nomes Office* (`office/api.dart`); os nomes do
/// port interno também são exportados por ora, para desenvolvimento — código
/// novo deve preferir os Office*.
library;

export 'src/document_engine/model/index.dart';
export 'src/document_engine/office/api.dart';
export 'src/document_engine/office/ids.dart';
export 'src/document_engine/office/sha256.dart' show sha256, sha256Hex;
export 'src/document_engine/office/snapshot.dart';
export 'src/document_engine/state/index.dart';
export 'src/document_engine/transform/index.dart';
