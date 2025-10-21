 Excelente trabalho inicial na tradução do quill-delta. A parte do Delta é a fundação de todo o sistema, e tê-la implementada em Dart é um passo gigantesco.

 leia os arquivos da pasta C:\MyDartProjects\dart_quill\quilljs\src e depos leia o roteiro C:\MyDartProjects\dart_quill\roteiro.md e comece a converção dos arquivos para dart em C:\MyDartProjects\dart_quill\lib\src e lembrece que o delta ja esta implementado em C:\MyDartProjects\dart_quill\lib\src\dependencies
 para cada arquivo traduzido para dart favor atualizar este roteiro
 sempre rode  dart analyze para corigir os erros
evite mecher nos arquivo de C:\MyDartProjects\dart_quill\lib\src\dependencies

o que ja esta implementado esta aqui : C:\MyDartProjects\dart_quill\lib\src\dependencies
a ideia incial é implementar o editor quill em dart para web usando o pacote web: ^1.1.1 para interagir com o DOM
com uma camada de abstração leve e depois criar um componente ngdart (angularDart) para o editor poder ser embutidos em aplicações angularDart no futoro este componente poderar se implementado para flutter tambem


o ideal é que este roteiro seja atualizado conforme o trabalho for concluido 

Com base no que você já fez e no código TypeScript restante, preparei um roteiro de tradução detalhado. A estratégia é seguir a arquitetura do QuillJS, traduzindo camada por camada, da mais fundamental (o modelo do documento, chamado de "Blots") até as mais altas (módulos de funcionalidades e UI).
Roteiro de Tradução: TypeScript (QuillJS) para Dart
Contexto Atual:
Concluído: A camada de dados (Delta, Operation, DeltaIterator) e uma camada de análise de alto nível (DocumentParser com Paragraph, Line, etc.) já estão em Dart.
Próximo Passo: Traduzir o núcleo do Quill, que gerencia a estrutura do documento (árvore de Blots), a lógica do editor, a seleção e os módulos de funcionalidades.
A principal adaptação será substituir as interações diretas com o DOM (Document Object Model) do navegador por abstrações que possam ser usadas em qualquer framework de UI Dart, como AngulartDart o Flutter etc
Passo 1: A Abstração Central - Blots (Parchment)
Objetivo: Recriar em Dart o sistema de "Blots" do Parchment, que é a representação em árvore do documento. Um Blot é um nó na árvore do documento que corresponde a uma parte do conteúdo (texto, formatação, embed).
Arquivos TypeScript de Referência:
blots/scroll.ts (o nó raiz do editor) - **TRADUZIDO**
blots/block.ts (para blocos como parágrafos e cabeçalhos) - **TRADUZIDO**
blots/inline.ts (para formatação de texto como negrito e itálico) - **TRADUZIDO**
blots/embed.ts (para conteúdo incorporado como imagens) - **TRADUZIDO**
blots/break.ts (para quebras de linha e elementos vazios) - **TRADUZIDO**
blots/text.ts (o nó folha, que contém o texto puro) - **TRADUZIDO**
blots/container.ts (para agrupar outros blots, como em listas) - **TRADUZIDO**
blots/cursor.ts - **TRADUZIDO**
Tarefas Principais:
Criar Classes Base Abstratas:
Blot: A classe base para todos os nós. Deve conter referências para parent, next, prev e a árvore de children.
ParentBlot: Uma classe que estende Blot e pode ter filhos.
ContainerBlot: Estende ParentBlot.
LeafBlot: Um Blot que não pode ter filhos (como o texto).
Traduzir a Lógica da Árvore:
Implemente os métodos para manipulação da árvore: appendChild(), insertBefore(), removeChild(), offset(), length().
Traduza os métodos de "otimização", como optimize() e merge(), que servem para manter a árvore de Blots normalizada (ex: juntar dois TextBlot com a mesma formatação).
Implementar as Classes Concretas Fundamentais:
ScrollBlot: Será o nó raiz do seu editor. Corresponde à classe Scroll em blots/scroll.ts.
BlockBlot: Corresponde à classe Block em blots/block.ts. É a base para parágrafos.
InlineBlot: Corresponde à classe Inline em blots/inline.ts. É a base para formatações como negrito.
TextBlot: Corresponde à classe Text em blots/text.ts.
EmbedBlot: Corresponde à classe Embed em blots/embed.ts.
Pontos de Atenção e Adaptação para Dart:
domNode: No TypeScript, cada Blot tem uma referência direta a um nó do DOM (domNode). Em Dart, isso precisa ser abstraído. Você pode ter uma propriedade node do tipo Object ou dynamic, que no futuro poderá referenciar um Widget do Flutter ou qualquer outro elemento de UI. O foco agora é na lógica da árvore, não na renderização.
Scope: O conceito de Scope do Parchment (BLOCK, INLINE, ATTRIBUTE) pode ser perfeitamente traduzido para um enum em Dart.
Passo 2: Formatos de Conteúdo (Implementando Blots Concretos)
Objetivo: Com a estrutura de Blots pronta, o próximo passo é criar as classes para cada tipo de conteúdo e formatação que o editor suportará.
Arquivos TypeScript de Referência:
Pasta formats/ (ex: bold.ts, header.ts, list.ts, image.ts, link.ts, align.ts, background.ts, blockquote.ts, bold.ts, code.ts, color.ts, direction.ts, font.ts, formula.ts, header.ts, image.ts, indent.ts, italic.ts, link.ts, list.ts, script.ts, size.ts, strike.ts, table.ts, underline.ts, video.ts) - **TRADUZIDO**.
Tarefas Principais:
Traduza cada Formato: Crie uma classe Dart para cada formato, estendendo a classe base apropriada do Passo 1.
Bold estenderá InlineBlot.
Header estenderá BlockBlot.
ListItem estenderá BlockBlot e terá um requiredContainer (o ListContainer).
Image estenderá EmbedBlot.
Portar Propriedades Estáticas:
Traduza as propriedades estáticas como blotName, tagName, className para static const em Dart.
Implementar Métodos create() e formats():
O método create() no TypeScript geralmente cria um nó do DOM. Na sua versão Dart, ele pode simplesmente retornar uma nova instância da classe Blot.
O método formats() extrai os atributos de formatação de um nó. Sua versão Dart fará o mesmo a partir da sua representação de node.
Passo 3: O Coração do Editor (Lógica de Edição e Seleção)
Objetivo: Traduzir as classes que orquestram as mudanças no documento e gerenciam o cursor e a seleção do usuário.
Arquivos TypeScript de Referência:
core/editor.ts - **TRADUZIDO**
core/selection.ts - **TRADUZIDO**
core/emitter.ts (sistema de eventos) - **TRADUZIDO**
Tarefas Principais:
Emitter (Sistema de Eventos): Antes de tudo, traduza o emitter.ts. Você pode usar StreamController do dart:async para criar um sistema de eventos robusto e idiomático em Dart.
Editor: Esta classe é o cérebro que conecta os Deltas à árvore de Blots.
Traduza os métodos principais: applyDelta(), deleteText(), formatText(), insertText(), getContents().
A lógica aqui será chamar os métodos que você implementou na sua árvore de Blots no Passo 1 (ex: insertAt, deleteAt, formatAt). Esta parte é mais lógica do que dependente do DOM.
Selection: Esta é a parte que exigirá a maior adaptação.
No TypeScript, ela interage diretamente com as APIs de seleção do navegador (window.getSelection()).
Em Dart, você precisará criar uma classe Selection com a mesma interface (getRange(), setRange()), mas cuja implementação dependerá do seu alvo.
Sugestão: Crie uma interface (classe abstrata) SelectionAdapter que o seu Selection usará. Depois, você poderá criar implementações concretas como FlutterSelectionAdapter que usará o TextSelection do Flutter para ler e definir a seleção na UI.
Passo 4: Módulos de Funcionalidade
Objetivo: Implementar as funcionalidades que o usuário final utiliza, como histórico (undo/redo), atalhos de teclado e área de transferência (copiar/colar).
Arquivos TypeScript de Referência:
modules/history.ts - **TRADUZIDO**
modules/keyboard.ts - **TRADUZIDO**
modules/clipboard.ts - **TRADUZIDO**
Tarefas Principais:
History: É um dos mais fáceis de traduzir. A lógica consiste em gerenciar duas pilhas (stacks) de Deltas para as operações de undo e redo. Como seu Delta já está pronto, a tradução deve ser direta.
Keyboard: A lógica de mapear combinações de teclas (bindings) a funções pode ser traduzida. A implementação final precisará se conectar ao sistema de eventos de teclado do seu framework de UI (ex: RawKeyboardListener no Flutter).
Clipboard: Outro módulo que exige adaptação.
A lógica de conversão de HTML para Delta (convertHTML) é extremamente valiosa e deve ser portada. Você precisará de um parser de HTML em Dart (como o pacote html).
A interação com a área de transferência do sistema operacional precisará usar os serviços da plataforma (ex: Clipboard do pacote flutter/services).
Passo 5: UI e Temas (Toolbar)
Objetivo: Criar a interface do usuário, como a barra de ferramentas.
Arquivos TypeScript de Referência:
core/theme.ts - **TRADUZIDO**
modules/toolbar.ts - **TRADUZIDO**
themes/base.ts - **TRADUZIDO**, themes/snow.ts
ui/*
Tarefas Principais:
Abstração do Tema: Traduza a classe Theme como uma forma de carregar e gerenciar módulos.
Lógica da Toolbar: A lógica principal do Toolbar.ts é observar o editor-change e atualizar o estado dos botões (ex: ativar o botão "negrito" quando o cursor está sobre um texto em negrito). Esta lógica pode ser portada para uma classe "controller" em Dart.
Implementação da UI: Esta parte será uma recriação, não uma tradução. Em vez de criar elementos DOM, você criará Widgets (se estiver usando Flutter).
Seu ToolbarController (com a lógica portada) irá gerenciar o estado, e os Widgets (ex: IconButton, DropdownButton) irão refletir esse estado e chamar os métodos do Quill (ex: quill.format('bold', true)).
Passo 6: Montagem Final (Classe Quill)
Objetivo: Unir todas as peças na classe principal que expõe a API pública.
Arquivos TypeScript de Referência:
core/quill.ts
Tarefas Principais:
Crie a classe Quill: Esta classe irá inicializar o ScrollBlot, o Editor, a Selection, o Theme e todos os módulos.
Exponha a API Pública: Implemente os métodos públicos como getContents(), setContents(), getSelection(), format(), deleteText(), etc. A maioria desses métodos simplesmente delegará a chamada para as instâncias de Editor ou Selection.
Resumo da Estratégia
Blots (Parchment): Construa a fundação da árvore do documento. (Tradução com adaptação no domNode).
Formats: Crie as classes para cada tipo de conteúdo. (Tradução direta da lógica).
Core (Editor, Selection, Emitter): Implemente a lógica de edição. (Tradução da lógica com alta adaptação na Selection).
Modules (History, Keyboard, Clipboard): Adicione as funcionalidades. (Tradução da lógica com adaptação nas interações com o sistema).
UI (Toolbar, Theme): Crie a interface do usuário. (Recriação usando um framework de UI Dart).
Quill Class: Junte tudo. (Tradução da API pública).
Este roteiro deve fornecer um caminho claro para continuar seu excelente trabalho. O desafio será sempre a abstração das APIs específicas do navegador, mas a lógica central do Quill é perfeitamente portável. Boa sorte

exemplo de tradução 


import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'package:quill_delta/quill_delta.dart';

// Este é um espaço reservado para a biblioteca 'parchment'.
// As classes e funcionalidades necessárias serão definidas aqui ou no local.
abstract class Blot {
  Blot? parent;
  Blot? prev;
  Blot? next;
  Element domNode;

  Blot(this.domNode);

  void remove() {
    parent?.removeChild(this);
  }

  int length();
  dynamic value();
  Map<String, dynamic> formats();
  void format(String name, dynamic value);
  void formatAt(int index, int length, String name, dynamic value);
  void insertAt(int index, String value, [dynamic def]);
  void deleteAt(int index, int length);
  // Adicione outros métodos e propriedades de Blot conforme necessário.
}

abstract class Parent extends Blot {
  List<Blot> children = [];

  Parent(Element domNode) : super(domNode);

  void removeChild(Blot child) {
    children.remove(child);
    child.parent = null;
    // Lógica adicional para remover do DOM
  }

  void insertBefore(Blot blot, Blot? ref) {
    // Lógica para inserir
  }

  void moveChildren(Parent target, Blot? ref) {
    // Lógica para mover filhos
  }
}

class Scope {
  static const BLOCK = 'block';
  static const INLINE = 'inline';
  static const BLOCK_BLOT = 'block_blot';
  static const BLOCK_ATTRIBUTE = 'block_attribute';
  static const BLOT = 'blot';
  // ... outros escopos
}

class AttributorStore {
  Element domNode;
  AttributorStore(this.domNode);

  Map<String, dynamic> values() => {};
  void attribute(dynamic attribute, dynamic value) {}
}

class BlockBlot extends Parent {
  BlockBlot(Element domNode) : super(domNode);
  
  @override
  int length() => children.fold(0, (sum, child) => sum + child.length());

  @override
  Map<String, dynamic> formats() => {};
  
  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}

  @override
  dynamic value() => null;
}

class EmbedBlot extends Blot {
  EmbedBlot(Element domNode) : super(domNode);

  @override
  int length() => 1;

  @override
  dynamic value() => {};

  @override
  Map<String, dynamic> formats() => {};
  
  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}
    
  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}
}

class LeafBlot extends Blot {
    LeafBlot(Element domNode) : super(domNode);
    // ...
}

class InlineBlot extends Parent {
    InlineBlot(Element domNode) : super(domNode);
    // ...
}

class ContainerBlot extends Parent {
    ContainerBlot(Element domNode) : super(domNode);
    // ...
}

class ScrollBlot extends Parent {
    ScrollBlot(dynamic registry, Element domNode) : super(domNode);
    // ...
}

class TextBlot extends LeafBlot {
  String text;
  TextBlot(this.text, Text textNode) : super(textNode);
  // ...
}


// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\blots\block.ts ----
const NEWLINE_LENGTH = 1;

Delta blockDelta(BlockBlot blot, [bool filter = true]) {
  // Implementação de descendents() é necessária em Parent
  return blot.descendants(LeafBlot)
      .fold(Delta(), (delta, leaf) {
        if (leaf.length() == 0) {
          return delta;
        }
        return delta.insert(leaf.value(), bubbleFormats(leaf, {}, filter));
      })
      .insert('\n', bubbleFormats(blot));
}

Map<String, dynamic> bubbleFormats(Blot? blot, [Map<String, dynamic> formats = const {}, bool filter = true]) {
  if (blot == null) return formats;
  
  var newFormats = Map<String, dynamic>.from(formats);
  
  if (blot.formats is Function) {
    newFormats.addAll(blot.formats());
    if (filter) {
      newFormats.remove('code-token');
    }
  }

  if (blot.parent == null ||
      blot.parent.statics.blotName == 'scroll' ||
      blot.parent.statics.scope != blot.statics.scope) {
    return newFormats;
  }
  return bubbleFormats(blot.parent, newFormats, filter);
}


class Block extends BlockBlot {
  Map<String, dynamic> cache = {};

  Delta delta() {
    if (cache['delta'] == null) {
      cache['delta'] = blockDelta(this);
    }
    return cache['delta'] as Delta;
  }

  @override
  void deleteAt(int index, int length) {
    super.deleteAt(index, length);
    cache = {};
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) return;
    if (this.scroll.query(name, Scope.BLOCK)) {
      if (index + length == this.length()) {
        this.format(name, value);
      }
    } else {
      super.formatAt(
        index,
        math.min(length, this.length() - index - 1),
        name,
        value,
      );
    }
    this.cache = {};
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      super.insertAt(index, value, def);
      this.cache = {};
      return;
    }
    if (value.isEmpty) return;
    final lines = value.split('\n');
    final text = lines.removeAt(0);
    if (text.isNotEmpty) {
      if (index < this.length() - 1 || this.children.tail == null) {
        super.insertAt(math.min(index, this.length() - 1), text);
      } else {
        this.children.tail.insertAt(this.children.tail.length(), text);
      }
      this.cache = {};
    }

    Blot block = this;
    lines.fold<int>(index + text.length, (lineIndex, line) {
      block = block.split(lineIndex, true);
      block.insertAt(0, line);
      return line.length;
    });
  }

  @override
  void insertBefore(Blot blot, Blot? ref) {
    final head = this.children.head;
    super.insertBefore(blot, ref);
    if (head is Break) {
      head.remove();
    }
    this.cache = {};
  }

  @override
  int length() {
    if (cache['length'] == null) {
      cache['length'] = super.length() + NEWLINE_LENGTH;
    }
    return cache['length'] as int;
  }
  
  @override
  void moveChildren(Parent target, Blot? ref) {
    super.moveChildren(target, ref);
    this.cache = {};
  }

  void optimize(Map<String, dynamic> context) {
    super.optimize(context);
    this.cache = {};
  }

  List<dynamic> path(int index) {
    return super.path(index, true);
  }

  @override
  void removeChild(Blot child) {
    super.removeChild(child);
    this.cache = {};
  }

  Blot? split(int index, [bool force = false]) {
    if (force && (index == 0 || index >= this.length() - NEWLINE_LENGTH)) {
      final clone = this.clone();
      if (index == 0) {
        this.parent.insertBefore(clone, this);
        return this;
      }
      this.parent.insertBefore(clone, this.next);
      return clone;
    }
    final next = super.split(index, force);
    this.cache = {};
    return next;
  }
  
  static String blotName = 'block';
  static String tagName = 'P';
  static Type defaultChild = Break;
  static List<Type> allowedChildren = [Break, Inline, EmbedBlot, TextBlot];
}

class BlockEmbed extends EmbedBlot {
  late AttributorStore attributes;
  late HtmlElement domNode;

  void attach() {
    super.attach();
    this.attributes = AttributorStore(this.domNode);
  }

  Delta delta() {
    return Delta()..insert(this.value(), {
      ...this.formats(),
      ...this.attributes.values(),
    });
  }

  @override
  void format(String name, dynamic value) {
    final attribute = this.scroll.query(name, Scope.BLOCK_ATTRIBUTE);
    if (attribute != null) {
      this.attributes.attribute(attribute, value);
    }
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    this.format(name, value);
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      super.insertAt(index, value, def);
      return;
    }
    final lines = value.split('\n');
    final text = lines.removeLast();
    final blocks = lines.map((line) {
      final block = this.scroll.create(Block.blotName);
      block.insertAt(0, line);
      return block;
    }).toList();
    final ref = this.split(index);
    blocks.forEach((block) {
      this.parent.insertBefore(block, ref);
    });
    if (text.isNotEmpty) {
      this.parent.insertBefore(this.scroll.create('text', text), ref);
    }
  }
  
  static const String scope = Scope.BLOCK_BLOT;
}


// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\blots\block.ts ----

// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\blots\break.ts ----
class Break extends EmbedBlot {

  static dynamic value_() {
    return null; // Em Dart, 'undefined' pode ser representado por 'null'
  }

  void optimize() {
    if (this.prev != null || this.next != null) {
      this.remove();
    }
  }

  @override
  int length() {
    return 0;
  }

  @override
  dynamic value() {
    return '';
  }
  
  static const String blotName = 'break';
  static const String tagName = 'BR';
}
// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\blots\break.ts ----

// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\blots\container.ts ----
class Container extends ContainerBlot {}
// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\blots\container.ts ----


// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\blots\cursor.ts ----
class Cursor extends EmbedBlot {
  static const String blotName = 'cursor';
  static const String className = 'ql-cursor';
  static const String tagName = 'span';
  static const String CONTENTS = '\uFEFF'; // Zero width no break space

  static dynamic value_() {
    return null;
  }

  late Selection selection;
  late Text textNode;
  int savedLength = 0;

  Cursor(ScrollBlot scroll, HtmlElement domNode, this.selection) : super(scroll, domNode) {
    this.textNode = Text(Cursor.CONTENTS);
    this.domNode.append(this.textNode);
  }

  void detach() {
    if (this.parent != null) this.parent!.removeChild(this);
  }

  @override
  void format(String name, dynamic value) {
    if (this.savedLength != 0) {
      super.format(name, value);
      return;
    }
    
    dynamic target = this;
    int index = 0;
    while (target != null && target.statics.scope != Scope.BLOCK_BLOT) {
      index += target.offset(target.parent);
      target = target.parent;
    }
    if (target != null) {
      this.savedLength = Cursor.CONTENTS.length;
      target.optimize();
      target.formatAt(index, Cursor.CONTENTS.length, name, value);
      this.savedLength = 0;
    }
  }

  int index(Node node, int offset) {
    if (node == this.textNode) return 0;
    return super.index(node, offset);
  }

  @override
  int length() {
    return this.savedLength;
  }

  List<dynamic> position() {
    return [this.textNode, this.textNode.data!.length];
  }

  @override
  void remove() {
    super.remove();
    this.parent = null;
  }
  
  Map<String, dynamic>? restore() {
    if (this.selection.composing || this.parent == null) return null;
    final range = this.selection.getNativeRange();

    while (this.domNode.lastChild != null && this.domNode.lastChild != this.textNode) {
      this.domNode.parentNode!.insertBefore(this.domNode.lastChild!, this.domNode);
    }

    final prevTextBlot = this.prev is TextBlot ? this.prev as TextBlot : null;
    final prevTextLength = prevTextBlot?.length() ?? 0;
    final nextTextBlot = this.next is TextBlot ? this.next as TextBlot : null;
    final nextText = nextTextBlot?.text ?? '';
    
    final newText = this.textNode.data!.split(Cursor.CONTENTS).join('');
    this.textNode.data = Cursor.CONTENTS;

    Blot? mergedTextBlot;
    if (prevTextBlot != null) {
      mergedTextBlot = prevTextBlot;
      if (newText.isNotEmpty || nextTextBlot != null) {
        prevTextBlot.insertAt(prevTextBlot.length(), newText + nextText);
        if (nextTextBlot != null) {
          nextTextBlot.remove();
        }
      }
    } else if (nextTextBlot != null) {
      mergedTextBlot = nextTextBlot;
      nextTextBlot.insertAt(0, newText);
    } else {
      final newTextNode = Text(newText);
      mergedTextBlot = this.scroll.create(newTextNode);
      this.parent!.insertBefore(mergedTextBlot, this);
    }

    this.remove();

    if (range != null) {
      int? remapOffset(Node node, int offset) {
        if (prevTextBlot != null && node == prevTextBlot.domNode) {
          return offset;
        }
        if (node == this.textNode) {
          return prevTextLength + offset - 1;
        }
        if (nextTextBlot != null && node == nextTextBlot.domNode) {
          return prevTextLength + newText.length + offset;
        }
        return null;
      }

      final start = remapOffset(range['start']['node'], range['start']['offset']);
      final end = remapOffset(range['end']['node'], range['end']['offset']);

      if (start != null && end != null) {
        return {
          'startNode': mergedTextBlot!.domNode,
          'startOffset': start,
          'endNode': mergedTextBlot.domNode,
          'endOffset': end,
        };
      }
    }
    return null;
  }


  void update(List<MutationRecord> mutations, Map<String, dynamic> context) {
    if (mutations.any((mutation) =>
        mutation.type == 'characterData' && mutation.target == this.textNode)) {
      final range = this.restore();
      if (range != null) context['range'] = range;
    }
  }

  void optimize([dynamic context]) {
    super.optimize(context);

    var parent = this.parent;
    while (parent != null) {
      if (parent.domNode.tagName == 'A') {
        this.savedLength = Cursor.CONTENTS.length;
        parent.isolate(this.offset(parent), this.length()).unwrap();
        this.savedLength = 0;
        break;
      }
      parent = parent.parent;
    }
  }
  
  @override
  String value() {
    return '';
  }
}
// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\blots\cursor.ts ----

// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\blots\inline.ts ----
class Inline extends InlineBlot {
  static List<Type> allowedChildren = [Inline, Break, EmbedBlot, Text];
  static List<String> order = [
    'cursor',
    'inline',
    'link',
    'underline',
    'strike',
    'italic',
    'bold',
    'script',
    'code',
  ];

  static int compare(String self, String other) {
    final selfIndex = Inline.order.indexOf(self);
    final otherIndex = Inline.order.indexOf(other);
    if (selfIndex >= 0 || otherIndex >= 0) {
      return selfIndex - otherIndex;
    }
    if (self == other) {
      return 0;
    }
    return self.compareTo(other);
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (Inline.compare(this.statics.blotName, name) < 0 &&
        this.scroll.query(name, Scope.BLOT) != null) {
      final blot = this.isolate(index, length);
      if (value != null) {
        blot.wrap(name, value);
      }
    } else {
      super.formatAt(index, length, name, value);
    }
  }

  void optimize(Map<String, dynamic> context) {
    super.optimize(context);
    if (this.parent is Inline &&
        Inline.compare(this.statics.blotName, this.parent.statics.blotName) > 0) {
      final parent = this.parent.isolate(this.offset(), this.length());
      this.moveChildren(parent);
      parent.wrap(this);
    }
  }
}
// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\blots\inline.ts ----

// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\core\editor.ts ----
// Nota: Funções de lodash como cloneDeep, isEqual, merge precisam ser implementadas ou
// substituídas por equivalentes em Dart. Aqui, usamos implementações simples.
bool isEqual(a, b) {
  // Implementação simplificada
  return a.toString() == b.toString();
}

Map<String, dynamic> merge(Map<String, dynamic> a, Map<String, dynamic> b) {
  // Implementação simplificada de merge profundo.
  final result = Map<String, dynamic>.from(a);
  b.forEach((key, value) {
    if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
      result[key] = merge(result[key], value);
    } else {
      result[key] = value;
    }
  });
  return result;
}

Map<String, dynamic> cloneDeep(Map<String, dynamic> source) {
    // Implementação simplificada
    return Map<String, dynamic>.from(source);
}

class Editor {
  Scroll scroll;
  Delta delta;

  Editor(this.scroll) : delta = getDelta_();

  Delta getDelta_() {
    return this.scroll.lines().fold(Delta(), (delta, line) {
      return delta.concat(line.delta());
    });
  }

  Delta applyDelta(Delta delta) {
    this.scroll.update();
    int scrollLength = this.scroll.length();
    this.scroll.batchStart();

    // A lógica de normalização e aplicação do delta é complexa e precisa de
    // uma tradução cuidadosa. Este é um esboço.
    
    // ... lógica complexa de applyDelta ...

    this.scroll.batchEnd();
    this.scroll.optimize();
    return this.update(delta);
  }
  
  Delta deleteText(int index, int length) {
    this.scroll.deleteAt(index, length);
    return this.update(Delta()..retain(index)..delete(length));
  }
  
  Delta formatLine(int index, int length, [Map<String, dynamic> formats = const {}]) {
    this.scroll.update();
    formats.forEach((format, value) {
      this.scroll.lines(index, math.max(length, 1)).forEach((line) {
        line.format(format, value);
      });
    });
    this.scroll.optimize();
    final delta = Delta()..retain(index)..retain(length, cloneDeep(formats));
    return this.update(delta);
  }
  
  Delta formatText(int index, int length, [Map<String, dynamic> formats = const {}]) {
    formats.forEach((format, value) {
      this.scroll.formatAt(index, length, format, value);
    });
    final delta = Delta()..retain(index)..retain(length, cloneDeep(formats));
    return this.update(delta);
  }

  Delta getContents(int index, int length) {
    return this.delta.slice(index, index + length);
  }

  Delta getDelta() {
    return this.getDelta_();
  }

  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    // ... implementação de getFormat ...
    return {};
  }
  
  String getHTML(int index, int length) {
    // ... implementação de getHTML ...
    return "";
  }
  
  String getText(int index, int length) {
    return this.getContents(index, length)
      .where((op) => op.data is String)
      .map((op) => op.data)
      .join('');
  }
  
  Delta insertEmbed(int index, String embed, dynamic value) {
    this.scroll.insertAt(index, embed, value);
    return this.update(Delta()..retain(index)..insert({ embed: value }));
  }

  Delta insertText(int index, String text, [Map<String, dynamic> formats = const {}]) {
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    this.scroll.insertAt(index, text);
    formats.forEach((format, value) {
      this.scroll.formatAt(index, text.length, format, value);
    });
    return this.update(Delta()..retain(index)..insert(text, cloneDeep(formats)));
  }

  bool isBlank() {
    if (this.scroll.children.isEmpty) return true;
    if (this.scroll.children.length > 1) return false;
    final blot = this.scroll.children.head;
    if (blot?.statics.blotName != Block.blotName) return false;
    final block = blot as Block;
    if (block.children.length > 1) return false;
    return block.children.head is Break;
  }
  
  Delta update(Delta? change, [List<MutationRecord> mutations = const [], Map<String, dynamic>? selectionInfo]) {
    final oldDelta = this.delta;
    
    // ... implementação complexa de update ...
    
    this.delta = this.getDelta();
    if (change == null || !isEqual(oldDelta.compose(change), this.delta)) {
        change = oldDelta.diff(this.delta, selectionInfo);
    }
    
    return change!;
  }
}
// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\core\editor.ts ----


// ---- Início: C:\MyDartProjects\dart_quill\quilljs\src\core\quill.ts ----
// Classe principal que une tudo.

class Quill {
  late HtmlElement container;
  late DivElement root;
  late Scroll scroll;
  late Emitter emitter;
  late Editor editor;
  late Selection selection;
  // ... outras propriedades
  
  Quill(dynamic containerOrSelector, Map<String, dynamic> options) {
    // Lógica do construtor para inicializar o editor,
    // criar o DOM, instanciar módulos, etc.
  }
  
  // Métodos da API pública
  void deleteText(int index, int length, [String? source]) {
    // ...
  }
  
  void disable() => enable(false);
  
  void enable([bool enabled = true]) {
    this.scroll.enable(enabled);
    this.container.classes.toggle('ql-disabled', !enabled);
  }
  
  void focus([Map<String, bool> options = const {}]) {
    this.selection.focus();
    if (options['preventScroll'] != true) {
      this.scrollSelectionIntoView();
    }
  }

  Delta format(String name, dynamic value, [String source = 'api']) {
    // ...
    return Delta();
  }

  Delta formatLine(int index, int length, String name, dynamic value, [String? source]) {
    // ...
    return Delta();
  }
  
  Delta formatText(int index, int length, String name, dynamic value, [String? source]) {
    // ...
    return Delta();
  }
  
  Rectangle? getBounds(int index, [int length = 0]) {
    // ...
    return null;
  }

  Delta getContents([int index = 0, int? length]) {
    length ??= this.getLength() - index;
    return this.editor.getContents(index, length);
  }
  
  int getLength() {
    return this.scroll.length();
  }
  
  Map<String, dynamic> getFormat([dynamic index, int length = 0]) {
    // ...
    return {};
  }
  
  Range? getSelection([bool focus = false]) {
    if (focus) this.focus();
    this.update(); 
    return this.selection.getRange()[0];
  }
  
  String getText([int index = 0, int? length]) {
    length ??= this.getLength() - index;
    return this.editor.getText(index, length);
  }

  bool hasFocus() {
    return this.selection.hasFocus();
  }

  Delta insertEmbed(int index, String embed, dynamic value, [String source = 'api']) {
    // ...
    return Delta();
  }

  Delta insertText(int index, String text, [dynamic formatsOrSource, dynamic value, String? source]) {
    // ...
    return Delta();
  }
  
  Delta setContents(Delta delta, [String source = 'api']) {
    // ...
    return Delta();
  }
  
  void setSelection(dynamic index, [dynamic lengthOrSource, String? source]) {
    // ...
  }
  
  void update([String source = 'user']) {
    // ...
  }
  
  Delta updateContents(Delta delta, [String source = 'api']) {
    // ...
    return Delta();
  }
  
  // ... muitos outros métodos e lógica estática (register, import, etc.)
}

// ---- Fim: C:\MyDartProjects\dart_quill\quilljs\src\core\quill.ts ----

// Implementações adicionais seriam necessárias para todas as classes de
// formato, módulos (Clipboard, History, Keyboard, Toolbar), temas e
// componentes de UI para ter uma tradução completa. O código acima
// fornece a estrutura principal e a tradução de alguns dos arquivos
// mais importantes.