import '../../blots/abstract/blot.dart';
import '../logger.dart';

const _coreFormats = <String>{
  'block',
  'break',
  'cursor',
  'inline',
  'scroll',
  'text',
};

Registry createRegistryWithFormats(
  List<String> formats,
  Registry sourceRegistry,
  Logger debug,
) {
  final registry = Registry();

  for (final name in _coreFormats) {
    final entry = sourceRegistry.query(name, Scope.ANY);
    if (entry != null) {
      registry.register(entry);
    }
  }

  for (final name in formats) {
    var entry = sourceRegistry.query(name, Scope.ANY);
    if (entry == null) {
      final attributor = sourceRegistry.queryAttributor(name, Scope.ANY);
      if (attributor != null) {
        registry.registerAttributor(attributor);
        continue;
      }
      debug.error(
        'Cannot register "$name" specified in "formats" config. Are you sure it was registered?',
      );
      continue;
    }
    // Parity createRegistryWithFormats.ts:24-36 — follow the
    // requiredContainer chain so e.g. 'list' also registers
    // 'list-container'; guard against registration cycles.
    var iterations = 0;
    while (entry != null) {
      registry.register(entry);
      final containerName = entry.requiredContainerBlotName;
      entry = containerName == null
          ? null
          : sourceRegistry.query(containerName, Scope.ANY);

      iterations += 1;
      if (iterations > _maxRegisterIterations) {
        debug.error(
          'Cycle detected in registering blot requiredContainer: "$name"',
        );
        break;
      }
    }
  }

  return registry;
}

const int _maxRegisterIterations = 100;
