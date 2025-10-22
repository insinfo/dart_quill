import '../core/quill.dart';

/// Base class for all Quill modules.
abstract class Module {
  Module(this.quill, this.options);

  final Quill quill;
  final Map<String, dynamic> options;

  /// Called when module is enabled/attached.
  void enable() {}

  /// Called when module is disabled/detached.
  void disable() {}
}