import 'state.dart';
import 'transaction.dart';
// Note: EditorView will be imported from prosemirror-view later
// import '../view/index.dart';

typedef PluginViewUpdate = void Function(dynamic view, EditorState prevState);
typedef PluginViewDestroy = void Function();

class PluginView {
  final PluginViewUpdate? update;
  final PluginViewDestroy? destroy;

  PluginView({this.update, this.destroy});
}

class StateField<T> {
  final dynamic init;
  final dynamic apply;
  final dynamic Function(dynamic value)? toJSON;
  final dynamic Function(EditorStateConfig config, dynamic value, EditorState state)? fromJSON;

  StateField({
    required this.init,
    required this.apply,
    this.toJSON,
    this.fromJSON,
  });
}

class PluginSpec<T> {
  final Map<String, dynamic>? props;
  final StateField<T>? state;
  final PluginKey? key;
  final PluginView Function(dynamic view)? view; // view is EditorView
  final bool Function(Transaction tr, EditorState state)? filterTransaction;
  final Transaction? Function(List<Transaction> transactions, EditorState oldState, EditorState newState)? appendTransaction;
  final Map<String, dynamic> extraProps;

  PluginSpec({
    this.props,
    this.state,
    this.key,
    this.view,
    this.filterTransaction,
    this.appendTransaction,
    this.extraProps = const {},
  });
}

Map<String, int> _pluginKeys = {};

String _createKey(String name) {
  if (_pluginKeys.containsKey(name)) {
    _pluginKeys[name] = _pluginKeys[name]! + 1;
    return '$name\$${_pluginKeys[name]}';
  }
  _pluginKeys[name] = 0;
  return '$name\$';
}

class PluginKey<T> {
  late final String key;

  PluginKey([String name = "key"]) {
    key = _createKey(name);
  }

  Plugin<T>? get(EditorState state) {
    return state.config.pluginsByKey[key] as Plugin<T>?;
  }

  T? getState(EditorState state) {
    return state.pluginState[key] as T?;
  }
}

class Plugin<T> {
  final PluginSpec<T> spec;
  late final String key;
  final Map<String, dynamic> props = {};

  Plugin(this.spec) {
    if (spec.props != null) {
      props.addAll(spec.props!);
    }
    key = spec.key?.key ?? _createKey("plugin");
  }

  T? getState(EditorState state) {
    return state.pluginState[key] as T?;
  }
}
