import 'package:dart_quill/dart_quill.dart' as dq;
import 'package:test/test.dart';

import '../support/quill_test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  test('all upstream attributor namespace variants coexist', () {
    final expected = <String, dq.Attributor>{
      'attributors/attribute/direction': dq.DirectionAttribute.instance,
      'attributors/class/align': dq.AlignClass.instance,
      'attributors/class/background': dq.BackgroundClass.instance,
      'attributors/class/color': dq.ColorClass.instance,
      'attributors/class/direction': dq.DirectionClass.instance,
      'attributors/class/font': dq.FontClass.instance,
      'attributors/class/size': dq.SizeClass.instance,
      'attributors/style/align': dq.AlignStyle.instance,
      'attributors/style/background': dq.BackgroundStyle.instance,
      'attributors/style/color': dq.ColorStyle.instance,
      'attributors/style/direction': dq.DirectionStyle.instance,
      'attributors/style/font': dq.FontStyleAttributor.instance,
      'attributors/style/size': dq.SizeStyle.instance,
    };

    for (final entry in expected.entries) {
      expect(
        dq.Quill.importDefinition(entry.key),
        same(entry.value),
        reason: entry.key,
      );
    }
    expect(
      dq.Quill.importDefinition('attributors/class/align'),
      isNot(same(dq.Quill.importDefinition('attributors/style/align'))),
    );
  });

  test('format aliases select the intended default attributors', () {
    expect(dq.Quill.importDefinition('formats/align'),
        same(dq.AlignClass.instance));
    expect(dq.Quill.importDefinition('formats/direction'),
        same(dq.DirectionClass.instance));
    expect(dq.Quill.importDefinition('formats/background'),
        same(dq.BackgroundStyle.instance));
    expect(dq.Quill.importDefinition('formats/color'),
        same(dq.ColorStyle.instance));
    expect(
        dq.Quill.importDefinition('formats/font'), same(dq.FontClass.instance));
    expect(
        dq.Quill.importDefinition('formats/size'), same(dq.SizeClass.instance));
  });

  test('Table.register installs the basic table hierarchy idempotently', () {
    dq.Table.register();
    final firstRegistrations = <String, dynamic>{
      for (final name in const [
        'table-container',
        'table-body',
        'table-row',
        'table',
      ])
        name: dq.Quill.importDefinition('formats/$name'),
    };

    dq.Table.register();

    for (final entry in firstRegistrations.entries) {
      expect(entry.value, isA<dq.RegistryEntry>(), reason: entry.key);
      expect(
        dq.Quill.importDefinition('formats/${entry.key}'),
        same(entry.value),
        reason: entry.key,
      );
    }
  });

  test('public entrypoint exposes extension-facing core API', () {
    final publicTypes = <Type>[
      dq.Attributor,
      dq.Blot,
      dq.Block,
      dq.Clipboard,
      dq.Emitter,
      dq.History,
      dq.Input,
      dq.Keyboard,
      dq.Module,
      dq.Picker,
      dq.Range,
      dq.Registry,
      dq.Theme,
      dq.TableContext,
      dq.Toolbar,
      dq.Tooltip,
    ];

    expect(publicTypes, hasLength(16));
  });
}
