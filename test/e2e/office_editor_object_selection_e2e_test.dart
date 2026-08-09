/// F3 em CHROME real: a seleção de objeto só existe de verdade quando há
/// geometria — moldura no lugar certo, alças arrastáveis, e o tamanho
/// resultante chegando ao DOCX.
///
/// O teste de VM prova o contrato do modelo; aqui provamos o que o fake DOM
/// não pode: que a moldura cobre a imagem, que arrastar a alça sudeste
/// aumenta o objeto, e que o DOCX exportado carrega o novo tamanho.
@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  /// PNG 1×1 transparente — o menor arquivo válido, suficiente para o
  /// caminho de inserção (o tamanho vem do IHDR, que existe aqui).
  const onePixelPng =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  test('a moldura cobre a imagem e a alça redimensiona de verdade', () async {
    await app.reload();

    // O seletor de arquivo nativo não é dirigível por script: o exemplo
    // expõe o MESMO caminho de inserção do botão Imagens como gancho.
    final prepared = await app.page.evaluate<bool>('''() =>
        typeof window.dqOfficeInsertImage === 'function' ''');
    expect(prepared, isTrue,
        reason: 'o exemplo tem de expor o gancho de inserção para o e2e');

    await app.page.evaluate<void>(
        '''(src) => window.dqOfficeInsertImage(src, 1440, 720)''',
        args: [onePixelPng]);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final selected =
        await app.page.evaluate<Map<String, dynamic>>('''async () => {
      const image = document.querySelector(
          '.dq-office-page-content .dq-office-image');
      const rect = image.getBoundingClientRect();
      image.dispatchEvent(new PointerEvent('pointerdown', {
        bubbles: true,
        cancelable: true,
        clientX: rect.left + rect.width / 2,
        clientY: rect.top + rect.height / 2,
      }));
      await new Promise((resolve) => setTimeout(resolve, 200));
      const frame = document.querySelector('.dq-office-objframe');
      const frameRect = frame ? frame.getBoundingClientRect() : null;
      return {
        hasFrame: !!frame,
        handles: document.querySelectorAll('.dq-office-objhandle').length,
        imageLeft: rect.left,
        imageTop: rect.top,
        imageWidth: rect.width,
        frameLeft: frameRect ? frameRect.left : null,
        frameTop: frameRect ? frameRect.top : null,
        frameWidth: frameRect ? frameRect.width : null,
      };
    }''');

    expect(selected['hasFrame'], isTrue);
    expect(selected['handles'], 8);
    expect((selected['frameLeft'] as num) - (selected['imageLeft'] as num),
        closeTo(0, 2),
        reason: 'a moldura tem de cobrir a imagem, não flutuar ao lado');
    expect((selected['frameTop'] as num) - (selected['imageTop'] as num),
        closeTo(0, 2));
    expect((selected['frameWidth'] as num) - (selected['imageWidth'] as num),
        closeTo(0, 2));

    // Arrasta a alça sudeste 48 px para a direita e 24 para baixo.
    final resized =
        await app.page.evaluate<Map<String, dynamic>>('''async () => {
      const handle = document.querySelector('.dq-office-objhandle-se');
      const rect = handle.getBoundingClientRect();
      const x = rect.left + rect.width / 2;
      const y = rect.top + rect.height / 2;
      const canvas = document.querySelector('.dq-office-canvas');
      handle.dispatchEvent(new PointerEvent('pointerdown',
          {bubbles: true, cancelable: true, clientX: x, clientY: y}));
      canvas.dispatchEvent(new PointerEvent('pointermove',
          {bubbles: true, cancelable: true, clientX: x + 48, clientY: y + 24}));
      await new Promise((resolve) => setTimeout(resolve, 60));
      canvas.dispatchEvent(new PointerEvent('pointerup',
          {bubbles: true, cancelable: true, clientX: x + 48, clientY: y + 24}));
      await new Promise((resolve) => setTimeout(resolve, 250));
      const image = document.querySelector(
          '.dq-office-page-content .dq-office-image');
      const after = image.getBoundingClientRect();
      return {width: after.width, height: after.height};
    }''');

    // 1440 twips = 96 px; +48 px de arrasto ⇒ ~144 px.
    expect(resized['width'] as num, closeTo(144, 6),
        reason: 'a projeção tem de refletir o novo tamanho');
    expect(resized['height'] as num, greaterThan(48));

    // E o tamanho novo tem de sobreviver à exportação.
    final exported = await app.exportDocx(artifactName: 'object-resize');
    final snapshot = OfficeDocxCodec(schema: officeQuillSchema())
        .import(Uint8List.fromList(exported.readAsBytesSync()))
        .snapshot;
    final document = PMNode.fromJSON(officeQuillSchema(), snapshot.body);
    int? widthTwips;
    document.descendants((node, pos, parent, index) {
      if (node.type.name == 'image' && widthTwips == null) {
        widthTwips = (node.attrs['width'] as num?)?.toInt();
      }
      return true;
    });
    expect(widthTwips, isNotNull, reason: 'a imagem tem de estar no DOCX');
    expect(widthTwips!, greaterThan(1440),
        reason: 'o DOCX carrega o tamanho redimensionado, não o original');
  });
}
