import 'dart:async';

import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/blots/inline.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/logger.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/utils/create_registry_with_formats.dart';
import 'package:dart_quill/src/formats/abstract/attributor.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

/// Port of
/// `referencias/quilljs/test/unit/core/utils/createRegistryWithFormats.spec.ts`.
Registry _globalSourceRegistry() {
  final registry = Registry();
  for (final definition in Quill.registeredDefinitions.values) {
    if (definition is RegistryEntry) {
      registry.register(definition);
    } else if (definition is Attributor) {
      registry.registerAttributor(definition);
    }
  }
  return registry;
}

List<String> _capturePrints(void Function() callback) {
  final messages = <String>[];
  runZoned(callback,
      zoneSpecification: ZoneSpecification(print: (_, __, ___, message) {
    messages.add(message);
  }));
  return messages;
}

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    initializeQuill();
  });

  final debug = logger('test');

  group('createRegistryWithFormats', () {
    test('register core formats', () {
      final registry =
          createRegistryWithFormats([], _globalSourceRegistry(), debug);
      expect(registry.query('cursor', Scope.ANY), isNotNull);
      expect(registry.query('bold', Scope.ANY), isNull);
    });

    test('register specified formats', () {
      final registry =
          createRegistryWithFormats(['bold'], _globalSourceRegistry(), debug);
      expect(registry.query('cursor', Scope.ANY), isNotNull);
      expect(registry.query('bold', Scope.ANY), isNotNull);
    });

    test('register required container', () {
      final source = Registry();
      final required = RegistryEntry(
        blotName: 'my-required-container',
        scope: Scope.INLINE_BLOT,
        create: ([dynamic value]) => Inline.create(),
      );
      final child = RegistryEntry(
        blotName: 'my-child',
        scope: Scope.INLINE_BLOT,
        requiredContainerBlotName: required.blotName,
        create: ([dynamic value]) => Inline.create(),
      );
      // Dart registry metadata names the required definition; registering the
      // definition in the source is the counterpart of the TS class reference.
      source
        ..register(required)
        ..register(child);

      final registry = createRegistryWithFormats(['my-child'], source, debug);
      expect(registry.query('my-child', Scope.ANY), isNotNull);
      expect(registry.query('my-required-container', Scope.ANY), isNotNull);
    });

    test('infinite loop', () {
      final source = Registry();
      source.register(RegistryEntry(
        blotName: 'infinite-blot',
        scope: Scope.INLINE_BLOT,
        requiredContainerBlotName: 'infinite-blot',
        create: ([dynamic value]) => Inline.create(),
      ));

      late Registry registry;
      final messages = _capturePrints(() {
        registry = createRegistryWithFormats(['infinite-blot'], source, debug);
      });
      expect(registry.query('infinite-blot', Scope.ANY), isNotNull);
      expect(messages.join('\n'), contains('Cycle detected'));
    });

    test('report missing formats', () {
      late Registry registry;
      final messages = _capturePrints(() {
        registry = createRegistryWithFormats(
            ['my-unknown'], _globalSourceRegistry(), debug);
      });
      expect(registry.query('my-unknown', Scope.ANY), isNull);
      expect(messages.join('\n'), contains('my-unknown'));
    });
  });
}
