@TestOn('vm')
library;

/// `htmlToDelta` — HTML → Delta, o par de `deltaToHtml`.
///
/// O que este conversor faz que o caminho de colagem do editor não faz: roda
/// **sem DOM e sem editor**, o que é o que o backend precisa para importar um
/// documento vindo de fora.
///
/// O grupo de round-trip é o que dá valor real: cada formato tem de sobreviver
/// à ida e à volta. Um conversor pode gerar HTML bonito e ainda assim perder o
/// formato ao reimportar — e é aí que o documento do usuário se degrada, uma
/// conversão de cada vez.
import 'package:dart_quill/dart_quill_html.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

/// Atributos do primeiro op cujo texto contém [needle].
Map<String, dynamic>? _attrsOf(Delta delta, String needle) {
  for (final op in delta.toList()) {
    final data = op.data;
    if (data is String && data.contains(needle)) return op.attributes;
  }
  return null;
}

String _textOf(Delta delta) => delta
    .toList()
    .map((op) => op.data)
    .whereType<String>()
    .join();

void main() {
  group('formatos inline', () {
    test('negrito, itálico e sublinhado', () {
      final delta = htmlToDelta('<p><strong>a</strong><em>b</em><u>c</u></p>');

      expect(_attrsOf(delta, 'a')?['bold'], isTrue);
      expect(_attrsOf(delta, 'b')?['italic'], isTrue);
      expect(_attrsOf(delta, 'c')?['underline'], isTrue);
    });

    test('link vira o atributo link', () {
      final delta = htmlToDelta('<p><a href="https://example.com">x</a></p>');
      expect(_attrsOf(delta, 'x')?['link'], 'https://example.com');
    });

    test('cor inline é reconhecida', () {
      final delta =
          htmlToDelta('<p><span style="color: rgb(255, 0, 0);">x</span></p>');
      expect(_attrsOf(delta, 'x')?['color'], isNotNull);
    });
  });

  group('formatos de bloco', () {
    test('cabeçalho', () {
      final delta = htmlToDelta('<h2>Título</h2>');
      expect(delta.toList().any((op) => op.attributes?['header'] == 2), isTrue);
    });

    test('lista com marcador', () {
      final delta = htmlToDelta('<ul><li>um</li><li>dois</li></ul>');
      final listOps =
          delta.toList().where((op) => op.attributes?['list'] == 'bullet');
      expect(listOps.length, 2);
    });

    test('citação', () {
      final delta = htmlToDelta('<blockquote>citado</blockquote>');
      expect(
          delta.toList().any((op) => op.attributes?['blockquote'] == true),
          isTrue);
    });
  });

  group('robustez', () {
    test('HTML vazio não explode', () {
      expect(() => htmlToDelta(''), returnsNormally);
    });

    test('tags desconhecidas não derrubam a conversão', () {
      final delta = htmlToDelta('<p>antes<custom-tag>x</custom-tag>depois</p>');
      expect(_textOf(delta), contains('antes'));
      expect(_textOf(delta), contains('depois'));
    });

    test('HTML malformado é tolerado', () {
      expect(() => htmlToDelta('<p><strong>sem fechar'), returnsNormally);
      expect(_textOf(htmlToDelta('<p><strong>sem fechar')),
          contains('sem fechar'));
    });

    test('entidades HTML voltam a ser texto', () {
      expect(_textOf(htmlToDelta('<p>a &amp; b &lt;c&gt;</p>')),
          contains('a & b <c>'));
    });
  });

  group('round-trip delta → html → delta', () {
    /// Converte para HTML e de volta, devolvendo o Delta final.
    Delta roundTrip(Delta delta) => htmlToDelta(deltaToHtml(delta));

    test('texto puro sobrevive', () {
      final original = Delta()..insert('texto simples\n');
      expect(_textOf(roundTrip(original)), contains('texto simples'));
    });

    test('negrito sobrevive', () {
      final original = Delta()
        ..insert('forte', {'bold': true})
        ..insert('\n');
      expect(_attrsOf(roundTrip(original), 'forte')?['bold'], isTrue);
    });

    test('itálico sobrevive', () {
      final original = Delta()
        ..insert('inclinado', {'italic': true})
        ..insert('\n');
      expect(_attrsOf(roundTrip(original), 'inclinado')?['italic'], isTrue);
    });

    test('link sobrevive com a URL intacta', () {
      final original = Delta()
        ..insert('portal', {'link': 'https://example.com/a?b=1'})
        ..insert('\n');
      expect(_attrsOf(roundTrip(original), 'portal')?['link'],
          'https://example.com/a?b=1');
    });

    test('cabeçalho sobrevive', () {
      final original = Delta()
        ..insert('Título')
        ..insert('\n', {'header': 1});
      expect(roundTrip(original).toList().any((op) => op.attributes?['header'] == 1),
          isTrue);
    });

    test('lista sobrevive', () {
      final original = Delta()
        ..insert('item')
        ..insert('\n', {'list': 'bullet'});
      expect(
          roundTrip(original)
              .toList()
              .any((op) => op.attributes?['list'] == 'bullet'),
          isTrue);
    });

    test('acentuação e travessão sobrevivem', () {
      final original = Delta()..insert('ação — coração, çedilha\n');
      expect(_textOf(roundTrip(original)), contains('ação — coração, çedilha'));
    });

    test('o que era escapado volta como texto, não como markup', () {
      final original = Delta()..insert('1 < 2 & 3 > 2\n');
      final back = _textOf(roundTrip(original));

      expect(back, contains('1 < 2'));
      expect(back, contains('& 3'));
      expect(back, isNot(contains('&amp;')),
          reason: 'entidade escapada duas vezes é corrupção de dado');
    });
  });
}
