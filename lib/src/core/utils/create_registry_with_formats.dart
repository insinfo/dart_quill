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
    final entry = sourceRegistry.query(name, Scope.ANY);
    if (entry == null) {
      debug.error(
        'Cannot register "$name" specified in "formats" config. Are you sure it was registered?',
      );
      continue;
    }
    registry.register(entry);
  }

  return registry;
}
