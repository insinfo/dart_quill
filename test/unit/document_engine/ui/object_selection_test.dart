/// F3 — seleção de OBJETO: clicar numa imagem seleciona o NÓ, a moldura com
/// as oito alças aparece, o arrasto vira UMA transação de tamanho, e o
/// teclado age sobre o objeto (Delete apaga, setas escapam).
///
/// O que estes testes protegem é o contrato, não o desenho: o fake DOM não
/// tem geometria real (todo elemento mede o mesmo retângulo), então as
/// asserções são sobre o MODELO e sobre a existência/estrutura do adorno. A
/// geometria fica para o e2e em Chrome.
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();

  late DomAdapter adapter;
  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  /// Um PNG 4×2 válido (só o cabeçalho importa para a leitura de tamanho).
  Uint8List png(int width, int height) {
    final bytes = Uint8List(24);
    bytes.setAll(0, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    bytes.setAll(12, 'IHDR'.codeUnits);
    void writeUint32(int offset, int value) {
      bytes[offset] = (value >> 24) & 0xff;
      bytes[offset + 1] = (value >> 16) & 0xff;
      bytes[offset + 2] = (value >> 8) & 0xff;
      bytes[offset + 3] = value & 0xff;
    }

    writeUint32(16, width);
    writeUint32(20, height);
    return bytes;
  }

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode imageNode({int width = 1440, int height = 720}) =>
      schema.node('image', {
        'src': 'data:image/png;base64,AAAA',
        'width': width,
        'height': height,
      });

  /// Documento: parágrafo de texto, parágrafo com a imagem, parágrafo final.
  PMNode docWithImage({int width = 1440, int height = 720}) => schema.node(
      'doc',
      null,
      Fragment.from([
        paragraph('Antes da figura, texto suficiente para ocupar a linha.'),
        schema.node('paragraph', null,
            Fragment.from([imageNode(width: width, height: height)])),
        paragraph('Depois da figura.'),
      ]));

  OfficeWordEditor mount(PMNode document) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document,
        schema: schema,
        options: const OfficeWordEditorOptions(),
      );

  /// Posição do nó `image` no documento.
  int imagePosition(OfficeWordEditor editor) {
    var offset = 0;
    for (var i = 0; i < editor.state.doc.childCount; i++) {
      final block = editor.state.doc.child(i);
      if (block.type.name == 'paragraph' &&
          block.childCount == 1 &&
          block.child(0).type.name == 'image') {
        return offset + 1; // dentro do parágrafo, antes da imagem
      }
      offset += block.nodeSize;
    }
    throw StateError('imagem não encontrada no documento');
  }

  void selectImage(OfficeWordEditor editor) {
    final pos = imagePosition(editor);
    editor.view.dispatch(editor.state.tr
      ..setSelection(NodeSelection.create(editor.state.doc, pos)));
  }

  group('seleção de objeto', () {
    test('clicar na imagem projetada seleciona o NÓ, não um ponto de texto',
        () {
      final editor = mount(docWithImage());
      final image = host.querySelector('.dq-office-image');
      expect(image, isNotNull, reason: 'a imagem tem de estar projetada');

      // O fake DOM não propaga eventos; entregamos ao host o que o browser
      // entregaria por bubbling — o listener vive na superfície de páginas.
      final pages = host.querySelector('.dq-office-pages')! as FakeDomElement;
      pages.dispatchEvent(
          'pointerdown', FakeDomMouseEvent(type: 'pointerdown', target: image));

      final selection = editor.state.selection;
      expect(selection, isA<NodeSelection>());
      expect((selection as NodeSelection).node.type.name, 'image');
      expect(selection.from, imagePosition(editor));
    });

    test('a moldura com as oito alças aparece no overlay', () {
      final editor = mount(docWithImage());
      expect(host.querySelectorAll('.dq-office-objframe'), isEmpty);

      selectImage(editor);

      expect(host.querySelectorAll('.dq-office-objframe'), hasLength(1));
      final handles = host.querySelectorAll('.dq-office-objhandle');
      expect(handles, hasLength(8));
      expect(
        handles.map((handle) => handle.getAttribute('data-handle')).toSet(),
        {'nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'},
      );
    });

    test('a moldura some ao voltar para uma seleção de texto', () {
      final editor = mount(docWithImage());
      selectImage(editor);
      expect(host.querySelectorAll('.dq-office-objframe'), hasLength(1));

      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1)));

      expect(host.querySelectorAll('.dq-office-objframe'), isEmpty);
    });

    test('redimensionar grava UMA transação em twips e mantém a seleção', () {
      final editor = mount(docWithImage(width: 1440, height: 720));
      selectImage(editor);
      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject();
      expect(target, isNotNull);

      final before = editor.state.doc.childCount;
      // 1440 twips a 100% = 96 px; dobrar a largura em px dobra os twips.
      final pxPerTwip = editor.pxPerTwip;
      adorner.resizeTo(
        target!.pos,
        target.node,
        widthPx: 2880 * pxPerTwip,
        heightPx: 1440 * pxPerTwip,
      );

      final image = editor.state.doc.child(1).child(0);
      expect(image.type.name, 'image');
      expect(image.attrs['width'], 2880);
      expect(image.attrs['height'], 1440);
      expect(editor.state.doc.childCount, before,
          reason: 'redimensionar não pode mexer na estrutura do documento');
      expect(editor.state.selection, isA<NodeSelection>(),
          reason: 'o objeto continua selecionado depois de redimensionar');
    });

    test('undo desfaz o redimensionamento numa tacada', () {
      final editor = mount(docWithImage(width: 1440, height: 720));
      selectImage(editor);
      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject()!;
      adorner.resizeTo(target.pos, target.node,
          widthPx: 2880 * editor.pxPerTwip, heightPx: 1440 * editor.pxPerTwip);
      expect(editor.state.doc.child(1).child(0).attrs['width'], 2880);

      editor.runCommand('undo');

      expect(editor.state.doc.child(1).child(0).attrs['width'], 1440);
    });

    test('Delete apaga a figura e deixa o caret no lugar dela', () {
      final editor = mount(docWithImage());
      selectImage(editor);
      final pages = host.querySelector('.dq-office-pages')!;

      (pages as FakeDomElement).dispatchEvent('keydown',
          FakeDomKeyboardEvent(type: 'keydown', target: pages, key: 'Delete'));

      var images = 0;
      editor.state.doc.descendants((node, pos, parent, index) {
        if (node.type.name == 'image') images++;
        return true;
      });
      expect(images, 0);
      expect(editor.state.selection, isNot(isA<NodeSelection>()));
    });

    test('seta escapa do objeto para o texto vizinho', () {
      final editor = mount(docWithImage());
      selectImage(editor);
      final pages = host.querySelector('.dq-office-pages')! as FakeDomElement;

      pages.dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: pages, key: 'ArrowRight'));

      expect(editor.state.selection, isNot(isA<NodeSelection>()));
      expect(editor.state.selection.empty, isTrue,
          reason: 'sair do objeto deixa um caret, não uma seleção');
    });
  });

  group('inserir imagem', () {
    test('o tamanho vem do cabeçalho do arquivo, a 96 dpi', () {
      final editor = mount(
          schema.node('doc', null, Fragment.from([paragraph('destino')])));

      final applied = insertImage(editor, png(96, 48), fileName: 'a.png');

      // 96 px = 1440 twips (uma polegada); 48 px = 720.
      expect(applied.widthTwips, 1440);
      expect(applied.heightTwips, 720);
      final image = editor.state.doc
          .child(0)
          .children
          .firstWhere((node) => node.type.name == 'image');
      expect(image.attrs['width'], 1440);
      expect(image.attrs['height'], 720);
      expect(image.attrs['src'], startsWith('data:image/png;base64,'));
    });

    test('uma imagem maior que a área útil entra proporcional', () {
      final editor = mount(
          schema.node('doc', null, Fragment.from([paragraph('destino')])));
      final content = editor.pageSetup.contentWidthTwips;

      // 2000 px = 30.000 twips, muito além da área útil de um A4.
      final applied = insertImage(editor, png(2000, 1000), fileName: 'b.png');

      expect(applied.widthTwips, content);
      expect(applied.heightTwips, (content / 2).round(),
          reason: 'a proporção 2:1 do arquivo é preservada');
    });

    test('formato desconhecido não impede a inserção', () {
      final editor = mount(
          schema.node('doc', null, Fragment.from([paragraph('destino')])));

      final applied = insertImage(editor, Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'x.bin');

      expect(applied.widthTwips, greaterThan(0));
      expect(applied.heightTwips, greaterThan(0));
    });

    test('leitura de dimensões: PNG, GIF e JPEG', () {
      expect(imagePixelSize(png(120, 60))?.width, 120);
      expect(imagePixelSize(png(120, 60))?.height, 60);

      final gif = Uint8List.fromList([
        ...'GIF89a'.codeUnits,
        0x40, 0x00, // 64
        0x20, 0x00, // 32
      ]);
      expect(imagePixelSize(gif), (width: 64, height: 32));

      final jpeg = Uint8List.fromList([
        0xff, 0xd8, // SOI
        0xff, 0xe0, 0x00, 0x04, 0x00, 0x00, // APP0 curto, pulado por tamanho
        0xff, 0xff, // byte de preenchimento, como em arquivos reais
        0xff, 0xc0, 0x00, 0x11, 0x08, // SOF0, length 17, precisão 8
        0x00, 0x30, // altura 48
        0x00, 0x60, // largura 96
        0, 0, 0, 0, 0, 0, 0, 0,
      ]);
      expect(imagePixelSize(jpeg), (width: 96, height: 48));
    });
  });

  group('barra do objeto', () {
    test('selecionar objeto abre a barra DO OBJETO, não a de texto', () {
      final editor = mount(docWithImage());
      selectImage(editor);
      final canvas = host.querySelector('.dq-office-canvas') as FakeDomElement;
      canvas.dispatchEvent(
          'mouseup', FakeDomMouseEvent(type: 'mouseup', target: canvas));

      final bar = host.querySelector('.dq-office-quickbar');
      expect(bar, isNotNull);
      final titles = [
        for (final button in bar!.querySelectorAll('.dq-office-btn'))
          button.getAttribute('title')
      ];
      expect(titles, containsAll(['Centralizar objeto', 'Excluir objeto']));
      expect(titles, isNot(contains('Negrito (Ctrl+B)')),
          reason: 'a barra de TEXTO não se aplica a um objeto');
    });

    test('alinhar centraliza o parágrafo da imagem em linha', () {
      final editor = mount(docWithImage());
      selectImage(editor);

      setObjectAlign(editor, 'center');

      expect(editor.state.doc.child(1).attrs['align'], 'center');
      expect(editor.state.selection, isA<NodeSelection>(),
          reason: 'alinhar não pode perder o objeto selecionado');
    });

    test('excluir pelo botão remove o objeto', () {
      final editor = mount(docWithImage());
      selectImage(editor);

      deleteSelectedObject(editor);

      var images = 0;
      editor.state.doc.descendants((node, pos, parent, index) {
        if (node.type.name == 'image') images++;
        return true;
      });
      expect(images, 0);
    });
  });
}
