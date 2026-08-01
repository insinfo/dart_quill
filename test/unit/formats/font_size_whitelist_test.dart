/// Fonte e tamanho de documento real precisam poder ser aceitos.
///
/// O upstream nasce com `['serif','monospace']` e três tamanhos em px — o que
/// descarta em silêncio o `Arial 10` de qualquer DOCX. A aplicação declara o
/// que aceita; sem isso o formato some ao abrir o arquivo.
@TestOn('vm')
library;

import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/formats/font.dart';
import 'package:dart_quill/src/formats/size.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  tearDown(() {
    // Os attributors sao singletons globais: devolve o padrao do upstream.
    setFontWhitelist(['serif', 'monospace']);
    setSizeStyleWhitelist(['10px', '18px', '32px']);
  });

  String htmlOf(Delta delta) {
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.scroll.registry.registerAttributor(FontStyleAttributor.instance);
    quill.scroll.registry.registerAttributor(SizeStyle.instance);
    quill.setContents(delta);
    return quill.root.innerHTML ?? '';
  }

  test('Arial é descartada com a whitelist padrão', () {
    final html = htmlOf(Delta()..insert('x', {'font': 'Arial'})..insert('\n'));
    expect(html, isNot(contains('Arial')),
        reason: 'este é o comportamento de origem, documentado');
  });

  test('Arial sobrevive depois de declarada', () {
    setFontWhitelist(['Arial', 'Calibri', 'Times New Roman']);
    final html = htmlOf(Delta()..insert('x', {'font': 'Arial'})..insert('\n'));
    expect(html, contains('Arial'));
  });

  test('tamanho do Word (o px que o importador gera) sobrevive sem whitelist',
      () {
    setSizeStyleWhitelist(null);
    final html = htmlOf(Delta()..insert('x', {'size': '13px'})..insert('\n'));
    expect(html, contains('13px'));
  });

  test('uma whitelist de tamanhos continua barrando o que não está nela', () {
    setSizeStyleWhitelist(['10pt', '12pt']);
    expect(htmlOf(Delta()..insert('x', {'size': '12pt'})..insert('\n')),
        contains('12pt'));
    expect(htmlOf(Delta()..insert('x', {'size': '99pt'})..insert('\n')),
        isNot(contains('99pt')));
  });
}
