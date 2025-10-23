import '../core/quill.dart';

/// Base class for all Quill modules.
abstract class Module<T> {
  Module(this.quill, this.options);

  final Quill quill;
  final T options;

  /// Called when module is enabled/attached.
  void enable() {}

  /// Called when module is disabled/detached.
  void disable() {}
}