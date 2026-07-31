import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/formats/code.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/formats/code.spec.ts`.
///
/// The spec builds its registry from the CORE `Code`/`CodeBlock`/
/// `CodeBlockContainer`, so the entries are declared here instead of coming
/// from `registryWithFormats`: the library's default registry is the FULL
/// build, where `Syntax.register()` overwrites `code-block` with the syntax
/// blots (which report the language instead of `true` — the divergence
/// recorded in G10.9). Using the core blots keeps every assertion verbatim.
final List<RegistryEntry> _codeFormats = [
  RegistryEntry(
    blotName: Code.kBlotName,
    scope: Code.kScope,
    tagNames: const [Code.kTagName],
    create: ([dynamic value]) =>
        value is DomElement ? Code(value) : Code.create(),
  ),
  RegistryEntry(
    blotName: CodeBlockContainer.kBlotName,
    scope: CodeBlockContainer.kScope,
    tagNames: const [CodeBlockContainer.kTagName],
    classNames: const [CodeBlockContainer.kClassName],
    create: ([dynamic value]) => value is DomElement
        ? CodeBlockContainer(value)
        : CodeBlockContainer.create(),
  ),
  RegistryEntry(
    blotName: CodeBlock.kBlotName,
    scope: CodeBlock.kScope,
    tagNames: const [CodeBlock.kTagName],
    classNames: const [CodeBlock.kClassName],
    requiredContainerBlotName: CodeBlockContainer.kBlotName,
    create: ([dynamic value]) =>
        value is DomElement ? CodeBlock(value) : CodeBlock.create(),
  ),
];

Editor _createEditor(String html) {
  ensureQuillTestInitialized();
  final registry = createRegistry(_codeFormats);
  for (final path in ['formats/italic', 'formats/header']) {
    final definition = Quill.importDefinition(path);
    registry.register(definition as RegistryEntry);
  }
  return Editor(createScroll(html, registry: registry));
}

const String _open =
    '<div class="ql-code-block-container" spellcheck="false">';

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Code', () {
    test('format newline', () {
      final editor = _createEditor('<p><br></p>');
      editor.formatLine(0, 1, {'code-block': true});
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block"><br /></div>
          </div>
        '''),
      );
    });

    test('format lines', () {
      final editor = _createEditor('<p><em>0123</em></p><p>5678</p>');
      editor.formatLine(2, 5, {'code-block': true});
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'code-block': true})
          ..insert('5678')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">0123</div>
            <div class="ql-code-block">5678</div>
          </div>
        '''),
      );
    });

    test('remove format', () {
      final editor =
          _createEditor('$_open<div class="ql-code-block">0123</div></div>');
      editor.formatText(4, 1, 'code-block', false);
      expectDelta(editor.getDelta(), Delta()..insert('0123\n'));
      expect(editor.scroll.element, EqualHTML('<p>0123</p>'));
    });

    test('delete last', () {
      final editor = _createEditor(
        '<p>0123</p>$_open<div class="ql-code-block"><br></div></div>'
        '<p>5678</p>',
      );
      editor.deleteText(4, 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'code-block': true})
          ..insert('5678\n'),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">0123</div>
          </div>
          <p>5678</p>
        '''),
      );
    });

    test('delete merge before', () {
      final editor = _createEditor(
        '<h1>0123</h1>$_open<div class="ql-code-block">4567</div></div>',
      );
      editor.deleteText(4, 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01234567')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">01234567</div>
          </div>
        '''),
      );
    });

    test('delete merge after', () {
      final editor = _createEditor(
        '$_open<div class="ql-code-block">0123</div></div><h1>4567</h1>',
      );
      editor.deleteText(4, 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01234567')
          ..insert('\n', {'header': 1}),
      );
      expect(editor.scroll.element, EqualHTML('<h1>01234567</h1>'));
    });

    test('delete across before partial merge', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">34</div>
          <div class="ql-code-block">67</div>
        </div>
        <h1>90</h1>''');
      editor.deleteText(7, 3);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'code-block': true})
          ..insert('34')
          ..insert('\n', {'code-block': true})
          ..insert('60')
          ..insert('\n', {'header': 1}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">01</div>
            <div class="ql-code-block">34</div>
          </div>
          <h1>60</h1>
        '''),
      );
    });

    test('delete across before no merge', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">34</div>
        </div>
        <h1>6789</h1>''');
      editor.deleteText(3, 5);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'code-block': true})
          ..insert('89')
          ..insert('\n', {'header': 1}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">01</div>
          </div>
          <h1>89</h1>
        '''),
      );
    });

    test('delete across after', () {
      final editor = _createEditor('''
        <h1>0123</h1>
        $_open
          <div class="ql-code-block">56</div>
          <div class="ql-code-block">89</div>
        </div>''');
      editor.deleteText(2, 4);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('016')
          ..insert('\n', {'code-block': true})
          ..insert('89')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">016</div>
            <div class="ql-code-block">89</div>
          </div>
        '''),
      );
    });

    test('replace', () {
      final editor =
          _createEditor('$_open<div class="ql-code-block">0123</div></div>');
      editor.formatText(4, 1, 'header', 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'header': 1}),
      );
      expect(editor.scroll.element, EqualHTML('<h1>0123</h1>'));
    });

    test('replace multiple', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">23</div>
        </div>
      ''');
      editor.formatText(0, 6, 'header', 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'header': 1})
          ..insert('23')
          ..insert('\n', {'header': 1}),
      );
      expect(editor.scroll.element, EqualHTML('<h1>01</h1><h1>23</h1>'));
    });

    test('format imprecise bounds', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">23</div>
          <div class="ql-code-block">45</div>
        </div>
      ''');
      editor.formatText(1, 6, 'header', 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'header': 1})
          ..insert('23')
          ..insert('\n', {'header': 1})
          ..insert('45')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <h1>01</h1>
          <h1>23</h1>
          $_open
            <div class="ql-code-block">45</div>
          </div>
        '''),
      );
    });

    test('format without newline', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">23</div>
          <div class="ql-code-block">45</div>
        </div>
      ''');
      editor.formatText(3, 1, 'header', 1);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'code-block': true})
          ..insert('23')
          ..insert('\n', {'code-block': true})
          ..insert('45')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">01</div>
            <div class="ql-code-block">23</div>
            <div class="ql-code-block">45</div>
          </div>
        '''),
      );
    });

    test('format line', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">01</div>
          <div class="ql-code-block">23</div>
          <div class="ql-code-block">45</div>
        </div>
      ''');
      editor.formatLine(3, 1, {'header': 1});
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('01')
          ..insert('\n', {'code-block': true})
          ..insert('23')
          ..insert('\n', {'header': 1})
          ..insert('45')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">01</div>
          </div>
          <h1>23</h1>
          $_open
            <div class="ql-code-block">45</div>
          </div>
        '''),
      );
    });

    test('ignore formatAt', () {
      final editor =
          _createEditor('$_open<div class="ql-code-block">0123</div></div>');
      editor.formatText(1, 1, 'bold', true);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'code-block': true}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">0123</div>
          </div>
        '''),
      );
    });

    test('partial block modification applyDelta', () {
      final editor = _createEditor('''
        $_open
          <div class="ql-code-block">a</div>
          <div class="ql-code-block">b</div>
          <div class="ql-code-block"><br></div>
        </div>''');
      final delta = Delta()
        ..retain(3)
        ..insert('\n', {'code-block': true})
        ..delete(1)
        ..retain(1, {'code-block': null});
      editor.applyDelta(delta);
      expect(
        editor.scroll.element,
        EqualHTML('''
          $_open
            <div class="ql-code-block">a</div>
            <div class="ql-code-block">b</div>
          </div>
          <p><br /></p>
        '''),
      );
    });
  });
}
