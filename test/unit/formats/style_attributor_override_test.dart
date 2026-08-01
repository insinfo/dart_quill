/// Trocar o attributor de fonte/tamanho por CLASSE pelo de ESTILO.
///
/// `formats/font` e `formats/size` já estão ocupados pelos attributors de
/// classe depois de `initializeQuill()`, e `Quill.register` sem o flag de
/// sobrescrita IGNORA EM SILÊNCIO a nova definição — a aplicação achava que
/// tinha trocado e o documento continuava passando pela whitelist de três
/// nomes, perdendo fonte e tamanho.
@TestOn('vm')
library;

import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/formats/font.dart';
import 'package:dart_quill/src/formats/size.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  tearDown(() {
    Quill.registerPath('formats/font', FontClass.instance, overwrite: true);
    Quill.registerPath('formats/size', SizeClass.instance, overwrite: true);
    setFontWhitelist(['serif', 'monospace']);
    setSizeStyleWhitelist(['10px', '18px', '32px']);
  });

  String htmlWith(Delta delta) {
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.setContents(delta);
    return quill.root.innerHTML ?? '';
  }

  final delta = Delta()
    ..insert('x', {'font': 'Arial', 'size': '13px'})
    ..insert('\n');

  test('sem o flag de sobrescrita a troca é ignorada', () {
    Quill.register(FontStyleAttributor.instance);
    Quill.register(SizeStyle.instance);
    setFontWhitelist(['Arial']);
    setSizeStyleWhitelist(null);

    final html = htmlWith(delta);
    expect(html, isNot(contains('font-family')),
        reason: 'o attributor de classe continua no lugar ($html)');
    expect(html, isNot(contains('13px')));
  });

  test('com o flag a fonte e o tamanho do documento sobrevivem', () {
    Quill.register(FontStyleAttributor.instance, true);
    Quill.register(SizeStyle.instance, true);
    setFontWhitelist(['Arial']);
    setSizeStyleWhitelist(null);

    final html = htmlWith(delta);
    expect(html, contains('Arial'));
    expect(html, contains('13px'));
  });
}
