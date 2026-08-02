/// Fase 2 — clipboard: recortar, copiar e colar pelo MODELO.
///
/// O invariante central é o round-trip interno: copiar um recorte e colá-lo
/// de volta tem de reconstruir a árvore EXATA, inclusive quando o recorte
/// começa e termina no meio de parágrafos. É o que separa um clipboard de
/// editor de um "copiar o texto que aparece".
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();
  const clipboard = OfficeClipboard();

  PMNode paragraph(String text, [List<Mark>? marks]) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text, marks)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  group('serialização', () {
    test('o HTML carrega o recorte para a volta sem perda', () {
      final slice = Slice(Fragment.from([paragraph('alpha')]), 0, 0);
      final payload = clipboard.serialize(slice);
      expect(payload.html, contains(officeSliceAttribute));
      expect(payload.text, 'alpha');
    });

    test('marcas viram tags reconhecíveis por outros programas', () {
      final bold = schema.marks['bold']!.create();
      final slice =
          Slice(Fragment.from([paragraph('forte', [bold])]), 0, 0);
      expect(clipboard.serialize(slice).html, contains('<strong>forte'));
    });

    test('link leva o href', () {
      final link = schema.marks['link']!.create({'href': 'https://x.dev'});
      final slice = Slice(Fragment.from([paragraph('ir', [link])]), 0, 0);
      expect(clipboard.serialize(slice).html, contains('href="https://x.dev"'));
    });

    test('heading vira h1..h6', () {
      final slice = Slice(
          Fragment.from([
            schema.node('heading', {'level': 2}, Fragment.from([schema.text('t')]))
          ]),
          0,
          0);
      expect(clipboard.serialize(slice).html, contains('<h2>t</h2>'));
    });

    test('texto com < e & é escapado', () {
      final slice = Slice(Fragment.from([paragraph('a < b & c')]), 0, 0);
      final html = clipboard.serialize(slice).html;
      expect(html, contains('a &lt; b &amp; c'));
      expect(clipboard.serialize(slice).text, 'a < b & c');
    });

    test('vários blocos viram várias linhas no texto puro', () {
      final slice = Slice(
          Fragment.from([paragraph('um'), paragraph('dois')]), 0, 0);
      expect(clipboard.serialize(slice).text, 'um\ndois');
    });
  });

  group('round-trip interno', () {
    Slice roundTrip(Slice slice) {
      final payload = clipboard.serialize(slice);
      return clipboard.parse(
          html: payload.html, text: payload.text, schema: schema)!;
    }

    test('bloco inteiro volta idêntico', () {
      final slice = Slice(
          Fragment.from([paragraph('alpha'), paragraph('beta')]), 0, 0);
      expect(roundTrip(slice).toJSON(), slice.toJSON());
    });

    test('as MARCAS sobrevivem', () {
      final bold = schema.marks['bold']!.create();
      final italic = schema.marks['italic']!.create();
      final slice = Slice(
          Fragment.from([
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.text('a', [bold]),
                  schema.text('b', [italic]),
                ]))
          ]),
          0,
          0);
      expect(roundTrip(slice).toJSON(), slice.toJSON());
    });

    test('recorte com bordas ABERTAS volta aberto', () {
      // Meio de um parágrafo até o meio do seguinte: openStart/openEnd = 1.
      final doc = docOf([paragraph('primeiro'), paragraph('segundo')]);
      final selection = TextSelection.create(doc, 4, 14);
      final slice = selection.content();
      expect(slice.openStart, 1);
      expect(slice.openEnd, 1);

      final back = roundTrip(slice);
      expect(back.openStart, slice.openStart,
          reason: 'colar meio parágrafo não pode virar bloco novo');
      expect(back.openEnd, slice.openEnd);
      expect(back.toJSON(), slice.toJSON());
    });

    test('atributos de bloco sobrevivem', () {
      final slice = Slice(
          Fragment.from([
            schema.node('heading', {'level': 3},
                Fragment.from([schema.text('titulo')]))
          ]),
          0,
          0);
      final back = roundTrip(slice);
      expect(back.content.child(0).attrs['level'], 3);
    });

    test('recorte corrompido cai para a leitura de HTML, não explode', () {
      final html = '<div $officeSliceAttribute="{lixo{">'
          '<p>ainda legivel</p></div>';
      final slice = clipboard.parse(html: html, schema: schema);
      expect(slice, isNotNull);
      expect(slice!.content.child(0).textContent, 'ainda legivel');
    });
  });

  group('HTML externo', () {
    Slice parseHtml(String html) =>
        clipboard.parse(html: html, schema: schema)!;

    test('parágrafos e headings viram os nós certos', () {
      final slice = parseHtml('<h1>Titulo</h1><p>Corpo</p>');
      expect(slice.content.child(0).type.name, 'heading');
      expect(slice.content.child(0).attrs['level'], 1);
      expect(slice.content.child(1).type.name, 'paragraph');
    });

    test('b/i/u/s viram as marcas do schema', () {
      final slice = parseHtml('<p><b>a</b><i>b</i><u>c</u><s>d</s></p>');
      final names = [
        for (var i = 0; i < slice.content.child(0).childCount; i++)
          slice.content.child(0).child(i).marks.single.type.name
      ];
      expect(names, ['bold', 'italic', 'underline', 'strike']);
    });

    test('marcas aninhadas se acumulam', () {
      final slice = parseHtml('<p><b><i>ambos</i></b></p>');
      final names =
          slice.content.child(0).child(0).marks.map((m) => m.type.name);
      expect(names, containsAll(['bold', 'italic']));
    });

    test('link sem href não vira marca (não inventa destino)', () {
      final slice = parseHtml('<p><a>sem destino</a></p>');
      expect(slice.content.child(0).child(0).marks, isEmpty);
    });

    test('container desconhecido é atravessado, não descartado', () {
      final slice = parseHtml('<div><section><p>fundo</p></section></div>');
      expect(slice.content.child(0).textContent, 'fundo');
    });

    test('texto solto vira parágrafo em vez de conteúdo órfão', () {
      final slice = parseHtml('<div>solto</div>');
      expect(slice.content.child(0).type.name, 'paragraph');
      expect(slice.content.child(0).textContent, 'solto');
    });

    test('blockquote e pre são reconhecidos', () {
      final slice = parseHtml('<blockquote>c</blockquote><pre>d</pre>');
      expect(slice.content.child(0).type.name, 'blockquote');
      expect(slice.content.child(1).type.name, 'codeBlock');
    });
  });

  group('texto puro', () {
    test('cada linha vira um parágrafo', () {
      final slice = clipboard.parse(text: 'um\ndois\ntres', schema: schema)!;
      expect(slice.content.childCount, 3);
      expect(slice.content.child(2).textContent, 'tres');
    });

    test('CRLF do Windows não deixa \\r no texto', () {
      final slice = clipboard.parse(text: 'um\r\ndois', schema: schema)!;
      expect(slice.content.child(0).textContent, 'um');
      expect(slice.content.child(1).textContent, 'dois');
    });

    test('nada aproveitável devolve null em vez de bloco vazio', () {
      expect(clipboard.parse(schema: schema), isNull);
      expect(clipboard.parse(html: '', text: '', schema: schema), isNull);
    });
  });

  group('na view', () {
    late DomAdapter adapter;
    late DomElement host;
    OfficeEditorView? view;

    setUpAll(initializeFakeDom);

    setUp(() {
      adapter = testAdapter;
      host = adapter.document.createElement('div');
      adapter.document.body.append(host);
    });

    tearDown(() {
      view?.dispose();
      view = null;
      host.remove();
    });

    OfficeEditorView mount(List<PMNode> blocks) => view =
        OfficeEditorView.withExtensions(
            host: host,
            doc: docOf(blocks),
            adapter: adapter,
            extensions: officeDefaultExtensions(schema));

    void select(int from, int to) {
      const map = OfficeDomPositionMap();
      final start = map.domPositionFor(host, from)!;
      final end = map.domPositionFor(host, to)!;
      adapter.setSelectionByNodes(
          start.node, start.offset, end.node, end.offset);
    }

    FakeDomClipboardEvent fire(String type, {FakeDomDataTransfer? data}) {
      final event = FakeDomClipboardEvent(
          type: type, target: host, clipboardData: data ?? FakeDomDataTransfer());
      (host as FakeDomElement).dispatchEvent(type, event);
      return event;
    }

    String textOf(OfficeEditorView view) => view.state.doc
        .textBetween(0, view.state.doc.content.size, blockSeparator: ' ');

    test('copiar escreve texto e HTML na área de transferência', () {
      mount([paragraph('copie isto')]);
      select(1, 1 + 10);
      final data = FakeDomDataTransfer();
      fire('copy', data: data);

      expect(data.getData('text/plain'), 'copie isto');
      expect(data.getData('text/html'), contains(officeSliceAttribute));
    });

    test('copiar NÃO altera o documento', () {
      final view = mount([paragraph('intacto')]);
      select(1, 1 + 7);
      fire('copy');
      expect(textOf(view), 'intacto');
    });

    test('recortar escreve E apaga', () {
      final view = mount([paragraph('um dois')]);
      select(1, 1 + 3);
      final data = FakeDomDataTransfer();
      fire('cut', data: data);

      expect(data.getData('text/plain'), 'um ');
      expect(textOf(view), 'dois');
    });

    test('copiar sem seleção não cancela o evento', () {
      mount([paragraph('nada')]);
      select(1, 1);
      expect(fire('copy').defaultPrevented, isFalse);
    });

    test('colar texto puro entra pelo modelo', () {
      final view = mount([paragraph('antes ')]);
      select(1 + 6, 1 + 6);
      final data = FakeDomDataTransfer()..setData('text/plain', 'colado');
      fire('paste', data: data);

      expect(textOf(view), contains('antes colado'));
      expect(host.textContent, contains('antes colado'));
    });

    test('colar HTML preserva as marcas', () {
      final view = mount([paragraph('x')]);
      select(1 + 1, 1 + 1);
      final data = FakeDomDataTransfer()
        ..setData('text/html', '<p><b>negrito</b></p>');
      fire('paste', data: data);

      expect(textOf(view), contains('negrito'));
      final marks = view.state.doc.child(0).lastChild?.marks ?? const [];
      expect(marks.map((m) => m.type.name), contains('bold'));
    });

    test('colar é SEMPRE cancelado — o browser nunca escreve na projeção', () {
      mount([paragraph('base')]);
      select(1, 1);
      expect(fire('paste').defaultPrevented, isTrue);
    });

    test('copiar → colar dentro do editor duplica o trecho', () {
      final view = mount([paragraph('dobro')]);
      select(1, 1 + 5);
      final data = FakeDomDataTransfer();
      fire('copy', data: data);

      select(1 + 5, 1 + 5);
      fire('paste', data: data);
      expect(textOf(view), 'dobrodobro');
    });

    test('colar substitui a seleção', () {
      final view = mount([paragraph('um dois tres')]);
      select(1 + 3, 1 + 7); // "dois"
      final data = FakeDomDataTransfer()..setData('text/plain', 'X');
      fire('paste', data: data);
      expect(textOf(view), 'um X tres');
    });

    test('colar entra no histórico e o undo desfaz', () {
      final view = mount([paragraph('base')]);
      select(1 + 4, 1 + 4);
      final data = FakeDomDataTransfer()..setData('text/plain', '+extra');
      fire('paste', data: data);
      expect(textOf(view), 'base+extra');

      (host as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: host, key: 'z', ctrlKey: true));
      expect(textOf(view), 'base');
    });
  });
}
