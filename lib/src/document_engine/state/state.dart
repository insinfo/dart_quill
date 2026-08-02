import '../model/index.dart';
import 'selection.dart';
import 'transaction.dart';
import 'plugin.dart';

class FieldDesc {
  final String name;
  final dynamic init;
  final dynamic apply;

  FieldDesc(this.name, this.init, this.apply);
}

final List<FieldDesc> _baseFields = [
  FieldDesc("doc",
      (EditorStateConfig config, EditorState instance) => config.doc ?? config.schema!.topNodeType.createAndFill()!,
      (Transaction tr, PMNode value, EditorState oldState, EditorState newState) => tr.doc),
  FieldDesc("selection",
      (EditorStateConfig config, EditorState instance) => config.selection ?? Selection.atStart(instance.doc),
      (Transaction tr, Selection value, EditorState oldState, EditorState newState) => tr.selection),
  FieldDesc("storedMarks",
      (EditorStateConfig config, EditorState instance) => config.storedMarks,
      (Transaction tr, List<Mark>? marks, EditorState oldState, EditorState newState) => (newState.selection is TextSelection && (newState.selection as TextSelection).empty) ? tr.storedMarks : null),
  FieldDesc("scrollToSelection",
      (EditorStateConfig config, EditorState instance) => 0,
      (Transaction tr, int prev, EditorState oldState, EditorState newState) => tr.scrolledIntoView ? prev + 1 : prev),
];

class Configuration {
  final Schema schema;
  final List<FieldDesc> fields;
  final List<Plugin> plugins;
  final Map<String, Plugin> pluginsByKey;

  Configuration._(this.schema, this.fields, this.plugins, this.pluginsByKey);

  factory Configuration(Schema schema, [List<Plugin>? plugins]) {
    List<FieldDesc> fields = List.from(_baseFields);
    List<Plugin> currentPlugins = [];
    Map<String, Plugin> pluginsByKey = {};

    if (plugins != null) {
      for (Plugin plugin in plugins) {
        if (pluginsByKey.containsKey(plugin.key)) {
          throw RangeError("Adding different instances of a keyed plugin (${plugin.key})");
        }
        currentPlugins.add(plugin);
        pluginsByKey[plugin.key] = plugin;
        if (plugin.spec.state != null) {
          fields.add(FieldDesc(
            plugin.key,
            (EditorStateConfig config, EditorState instance) => plugin.spec.state!.init(config, instance),
            (Transaction tr, dynamic value, EditorState oldState, EditorState newState) => plugin.spec.state!.apply(tr, value, oldState, newState),
          ));
        }
      }
    }
    return Configuration._(schema, fields, currentPlugins, pluginsByKey);
  }
}

class EditorStateConfig {
  final Schema? schema;
  final PMNode? doc;
  final Selection? selection;
  final List<Mark>? storedMarks;
  final List<Plugin>? plugins;

  EditorStateConfig({
    this.schema,
    this.doc,
    this.selection,
    this.storedMarks,
    this.plugins,
  });
}

class EditorState {
  final Configuration config;

  PMNode get doc => _doc;
  late PMNode _doc;

  Selection get selection => _selection;
  late Selection _selection;

  List<Mark>? get storedMarks => _storedMarks;
  List<Mark>? _storedMarks;

  final Map<String, dynamic> pluginState = {};

  EditorState._(this.config);

  Schema get schema => config.schema;
  List<Plugin> get plugins => config.plugins;

  EditorState apply(Transaction tr) {
    return applyTransaction(tr).state;
  }

  bool filterTransaction(Transaction tr, [int ignore = -1]) {
    for (int i = 0; i < config.plugins.length; i++) {
      if (i != ignore) {
        Plugin plugin = config.plugins[i];
        if (plugin.spec.filterTransaction != null && !plugin.spec.filterTransaction!(tr, this)) {
          return false;
        }
      }
    }
    return true;
  }

  _TransactionResult applyTransaction(Transaction rootTr) {
    if (!filterTransaction(rootTr)) return _TransactionResult(this, []);

    List<Transaction> trs = [rootTr];
    EditorState newState = applyInner(rootTr);
    List<_SeenPlugin>? seen;

    while (true) {
      bool haveNew = false;
      for (int i = 0; i < config.plugins.length; i++) {
        Plugin plugin = config.plugins[i];
        if (plugin.spec.appendTransaction != null) {
          int n = seen != null ? seen[i].n : 0;
          EditorState oldState = seen != null ? seen[i].state : this;
          Transaction? tr = n < trs.length ? plugin.spec.appendTransaction!(n > 0 ? trs.sublist(n) : trs, oldState, newState) : null;
          if (tr != null && newState.filterTransaction(tr, i)) {
            tr.setMeta("appendedTransaction", rootTr);
            if (seen == null) {
              seen = [];
              for (int j = 0; j < config.plugins.length; j++) {
                seen.add(j < i ? _SeenPlugin(newState, trs.length) : _SeenPlugin(this, 0));
              }
            }
            trs.add(tr);
            newState = newState.applyInner(tr);
            haveNew = true;
          }
          if (seen != null) seen[i] = _SeenPlugin(newState, trs.length);
        }
      }
      if (!haveNew) return _TransactionResult(newState, trs);
    }
  }

  EditorState applyInner(Transaction tr) {
    if (!tr.before.eq(doc)) throw RangeError("Applying a mismatched transaction");
    EditorState newInstance = EditorState._(config);
    for (int i = 0; i < config.fields.length; i++) {
      FieldDesc field = config.fields[i];
      dynamic oldValue;
      if (field.name == 'doc') oldValue = _doc;
      else if (field.name == 'selection') oldValue = _selection;
      else if (field.name == 'storedMarks') oldValue = _storedMarks;
      else oldValue = pluginState[field.name];

      dynamic newValue = field.apply(tr, oldValue, this, newInstance);

      if (field.name == 'doc') newInstance._doc = newValue;
      else if (field.name == 'selection') newInstance._selection = newValue;
      else if (field.name == 'storedMarks') newInstance._storedMarks = newValue;
      else newInstance.pluginState[field.name] = newValue;
    }
    return newInstance;
  }

  Transaction get tr => Transaction(this);

  static EditorState create(EditorStateConfig config) {
    Configuration configObj = Configuration(config.doc != null ? config.doc!.type.schema : config.schema!, config.plugins);
    EditorState instance = EditorState._(configObj);
    for (int i = 0; i < configObj.fields.length; i++) {
      FieldDesc field = configObj.fields[i];
      dynamic value = field.init(config, instance);
      if (field.name == 'doc') instance._doc = value;
      else if (field.name == 'selection') instance._selection = value;
      else if (field.name == 'storedMarks') instance._storedMarks = value;
      else instance.pluginState[field.name] = value;
    }
    return instance;
  }

  EditorState reconfigure({List<Plugin>? plugins}) {
    Configuration configObj = Configuration(schema, plugins);
    List<FieldDesc> fields = configObj.fields;
    EditorState instance = EditorState._(configObj);
    for (int i = 0; i < fields.length; i++) {
      String name = fields[i].name;
      dynamic value;
      if (name == 'doc') value = _doc;
      else if (name == 'selection') value = _selection;
      else if (name == 'storedMarks') value = _storedMarks;
      else if (pluginState.containsKey(name)) value = pluginState[name];
      else {
        // init new field
        value = fields[i].init(EditorStateConfig(plugins: plugins), instance);
      }
      
      if (name == 'doc') instance._doc = value;
      else if (name == 'selection') instance._selection = value;
      else if (name == 'storedMarks') instance._storedMarks = value;
      else instance.pluginState[name] = value;
    }
    return instance;
  }

  Map<String, dynamic> toJSON([Map<String, Plugin>? pluginFields]) {
    Map<String, dynamic> result = {
      "doc": doc.toJSON(),
      "selection": selection.toJSON(),
    };
    if (storedMarks != null) {
      result["storedMarks"] = storedMarks!.map((m) => m.toJSON()).toList();
    }
    if (pluginFields != null) {
      for (String prop in pluginFields.keys) {
        if (prop == "doc" || prop == "selection") {
          throw RangeError("The JSON fields `doc` and `selection` are reserved");
        }
        Plugin plugin = pluginFields[prop]!;
        StateField<dynamic>? state = plugin.spec.state;
        if (state != null && state.toJSON != null) {
          result[prop] = state.toJSON!(pluginState[plugin.key]);
        }
      }
    }
    return result;
  }

  static EditorState fromJSON(EditorStateConfig config, dynamic json, [Map<String, Plugin>? pluginFields]) {
    if (json == null) throw RangeError("Invalid input for EditorState.fromJSON");
    if (config.schema == null) throw RangeError("Required config field 'schema' missing");
    Configuration configObj = Configuration(config.schema!, config.plugins);
    EditorState instance = EditorState._(configObj);

    for (var field in configObj.fields) {
      if (field.name == "doc") {
        instance._doc = PMNode.fromJSON(config.schema!, json['doc']);
      } else if (field.name == "selection") {
        instance._selection = Selection.fromJSON(instance._doc, json['selection']);
      } else if (field.name == "storedMarks") {
        if (json['storedMarks'] != null) {
          instance._storedMarks = (json['storedMarks'] as List).map((m) => config.schema!.markFromJSON(m)).toList();
        }
      } else {
        bool handled = false;
        if (pluginFields != null) {
          for (String prop in pluginFields.keys) {
            Plugin plugin = pluginFields[prop]!;
            StateField<dynamic>? state = plugin.spec.state;
            if (plugin.key == field.name && state != null && state.fromJSON != null && json.containsKey(prop)) {
              instance.pluginState[field.name] = state.fromJSON!(config, json[prop], instance);
              handled = true;
              break;
            }
          }
        }
        if (!handled) {
          instance.pluginState[field.name] = field.init(config, instance);
        }
      }
    }
    return instance;
  }
}

class _TransactionResult {
  final EditorState state;
  final List<Transaction> transactions;

  _TransactionResult(this.state, this.transactions);
}

class _SeenPlugin {
  final EditorState state;
  final int n;

  _SeenPlugin(this.state, this.n);
}
