/// Fachada pública do motor documental — os nomes Office*.
///
/// A API pública não expõe nomes ProseMirror/Tiptap: alias de tipo para o
/// núcleo interno, o que desacopla a evolução de `document_engine/` da API
/// JavaScript original. Código novo consome ESTES nomes; os internos ficam
/// livres para mudar.
library;

import '../model/index.dart';
import '../state/index.dart';
import '../transform/index.dart';

/// Nó imutável da árvore (ProseMirror-like).
typedef OfficeNode = PMNode;

/// Sequência imutável de nós irmãos.
typedef OfficeFragment = Fragment;

/// Marca inline (bold, itálico, link…).
typedef OfficeMark = Mark;

/// Fatia de documento com profundidades abertas (clipboard/replace).
typedef OfficeSlice = Slice;

/// Posição resolvida na árvore.
typedef OfficeResolvedPos = ResolvedPos;

/// Esquema que valida a árvore.
typedef OfficeSchema = Schema;
typedef OfficeNodeType = NodeType;
typedef OfficeMarkType = MarkType;
typedef OfficeNodeSpec = NodeSpec;
typedef OfficeMarkSpec = MarkSpec;

/// Estado do editor (documento + seleção + plugins).
typedef OfficeState = EditorState;
typedef OfficeStateConfig = EditorStateConfig;

/// Transação (transform + seleção + metadados).
typedef OfficeTransaction = Transaction;

/// Transform e steps estruturais com mapping de posições.
typedef OfficeTransform = Transform;
typedef OfficeStep = Step;
typedef OfficeStepMap = StepMap;
typedef OfficeMapping = Mapping;

/// Seleções.
typedef OfficeSelection = Selection;
typedef OfficeTextSelection = TextSelection;
typedef OfficeNodeSelection = NodeSelection;
typedef OfficeAllSelection = AllSelection;

/// Plugins.
typedef OfficePlugin<T> = Plugin<T>;
typedef OfficePluginSpec<T> = PluginSpec<T>;
typedef OfficePluginKey<T> = PluginKey<T>;
