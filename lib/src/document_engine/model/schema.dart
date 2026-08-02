import 'node.dart';
import 'fragment.dart';
import 'mark.dart';
import 'content.dart';

class Attribute {
  final bool hasDefault;
  final dynamic defaultValue;
  final void Function(dynamic value)? validate;

  Attribute(String typeName, String attrName, AttributeSpec options)
      : hasDefault = options.defaultValue != null || options.hasDefault,
        defaultValue = options.defaultValue,
        validate = options.validate != null
            ? (options.validate is String
                ? _validateType(typeName, attrName, options.validate as String)
                : options.validate as void Function(dynamic))
            : null;

  bool get isRequired => !hasDefault;
}

void Function(dynamic) _validateType(
    String typeName, String attrName, String type) {
  return (dynamic value) {
    // Simplified runtime type checking (in Dart we might use 'int', 'String', 'bool', etc.)
    // Simplified runtime type checking (in Dart we might use 'int', 'String', 'bool', etc.)
    // Note: This needs robust Dart-specific type matching for production.
  };
}

class NodeType {
  final String name;
  final Schema schema;
  final NodeSpec spec;
  final List<String> groups;
  final Map<String, Attribute> attrs;
  final Map<String, dynamic> defaultAttrs;

  late ContentMatch contentMatch;
  late bool inlineContent;
  late bool isBlock;
  late bool isText;

  List<MarkType>? markSet;

  NodeType(this.name, this.schema, this.spec)
      : groups = spec.group?.split(" ") ?? [],
        attrs = _initAttrs(name, spec.attrs),
        defaultAttrs = _defaultAttrs(_initAttrs(name, spec.attrs)) ?? {} {
    isBlock = !(spec.inline == true || name == "text");
    isText = name == "text";
  }

  bool get isInline => !isBlock;
  bool get isTextblock => isBlock && inlineContent;
  bool get isLeaf => contentMatch == ContentMatch.empty;
  bool get isAtom => isLeaf || (spec.atom == true);

  bool isInGroup(String group) => groups.contains(group);

  String get whitespace =>
      spec.whitespace ?? (spec.code == true ? "pre" : "normal");

  bool hasRequiredAttrs() {
    for (var attr in attrs.values) {
      if (attr.isRequired) return true;
    }
    return false;
  }

  bool compatibleContent(NodeType other) {
    return this == other || contentMatch.compatible(other.contentMatch);
  }

  Map<String, dynamic> computeAttrs(Map<String, dynamic>? attrsArgs) {
    if (attrsArgs == null && defaultAttrs.isNotEmpty) return defaultAttrs;
    return _computeAttrs(attrs, attrsArgs);
  }

  PMNode create(
      [Map<String, dynamic>? attrsArgs, dynamic content, List<Mark>? marks]) {
    if (isText) throw StateError("NodeType.create can't construct text nodes");
    return PMNode(this, computeAttrs(attrsArgs), Fragment.from(content),
        Mark.setFrom(marks));
  }

  PMNode createChecked(
      [Map<String, dynamic>? attrsArgs, dynamic content, List<Mark>? marks]) {
    Fragment frag = Fragment.from(content);
    checkContent(frag);
    return PMNode(this, computeAttrs(attrsArgs), frag, Mark.setFrom(marks));
  }

  PMNode? createAndFill(
      [Map<String, dynamic>? attrsArgs, dynamic content, List<Mark>? marks]) {
    Map<String, dynamic> computedAttrs = computeAttrs(attrsArgs);
    Fragment frag = Fragment.from(content);
    if (frag.size > 0) {
      Fragment? before = contentMatch.fillBefore(frag);
      if (before == null) return null;
      frag = before.append(frag);
    }
    ContentMatch? matched = contentMatch.matchFragment(frag);
    Fragment? after = matched?.fillBefore(Fragment.empty, true);
    if (after == null) return null;
    return PMNode(this, computedAttrs, frag.append(after), Mark.setFrom(marks));
  }

  bool validContent(Fragment content) {
    ContentMatch? result = contentMatch.matchFragment(content);
    if (result == null || !result.validEnd) return false;
    for (int i = 0; i < content.childCount; i++) {
      if (!allowsMarks(content.child(i).marks)) return false;
    }
    return true;
  }

  void checkContent(Fragment content) {
    if (!validContent(content)) {
      throw RangeError("Invalid content for node $name");
    }
  }

  void checkAttrs(Map<String, dynamic> attrsArgs) {
    _checkAttrs(attrs, attrsArgs, "node", name);
  }

  bool allowsMarkType(MarkType markType) {
    return markSet == null || markSet!.contains(markType);
  }

  bool allowsMarks(List<Mark> marks) {
    if (markSet == null) return true;
    for (int i = 0; i < marks.length; i++) {
      if (!allowsMarkType(marks[i].type)) return false;
    }
    return true;
  }

  List<Mark> allowedMarks(List<Mark> marks) {
    if (markSet == null) return marks;
    List<Mark>? copy;
    for (int i = 0; i < marks.length; i++) {
      if (!allowsMarkType(marks[i].type)) {
        copy ??= marks.sublist(0, i);
      } else if (copy != null) {
        copy.add(marks[i]);
      }
    }
    return copy == null ? marks : (copy.isEmpty ? Mark.none : copy);
  }

  static Map<String, NodeType> compile(
      Map<String, NodeSpec> nodes, Schema schema) {
    Map<String, NodeType> result = {};
    nodes.forEach((name, spec) => result[name] = NodeType(name, schema, spec));
    String topType = schema.spec.topNode ?? "doc";
    if (!result.containsKey(topType)) {
      throw RangeError("Schema is missing its top node type ('$topType')");
    }
    if (!result.containsKey("text")) {
      throw RangeError("Every schema needs a 'text' type");
    }
    if (result["text"]!.attrs.isNotEmpty) {
      throw RangeError("The text node type should not have attributes");
    }
    return result;
  }
}

class MarkType {
  final String name;
  final int rank;
  final Schema schema;
  final MarkSpec spec;
  final Map<String, Attribute> attrs;
  late List<MarkType> excluded;
  Mark? instance;

  MarkType(this.name, this.rank, this.schema, this.spec)
      : attrs = _initAttrs(name, spec.attrs) {
    Map<String, dynamic>? defaults = _defaultAttrs(attrs);
    instance = defaults != null ? Mark(this, defaults) : null;
  }

  Mark create([Map<String, dynamic>? attrsArgs]) {
    if (attrsArgs == null && instance != null) return instance!;
    return Mark(this, _computeAttrs(attrs, attrsArgs));
  }

  static Map<String, MarkType> compile(
      Map<String, MarkSpec> marks, Schema schema) {
    Map<String, MarkType> result = {};
    int rank = 0;
    marks.forEach(
        (name, spec) => result[name] = MarkType(name, rank++, schema, spec));
    return result;
  }

  List<Mark> removeFromSet(List<Mark> set) {
    for (int i = 0; i < set.length; i++) {
      if (set[i].type == this) {
        return [...set.sublist(0, i), ...set.sublist(i + 1)];
      }
    }
    return set;
  }

  Mark? isInSet(List<Mark> set) {
    for (int i = 0; i < set.length; i++) {
      if (set[i].type == this) return set[i];
    }
    return null;
  }

  void checkAttrs(Map<String, dynamic> attrsArgs) {
    _checkAttrs(attrs, attrsArgs, "mark", name);
  }

  bool excludes(MarkType other) {
    return excluded.contains(other);
  }
}

class Schema {
  final SchemaSpec spec;
  late final Map<String, NodeType> nodes;
  late final Map<String, MarkType> marks;
  NodeType? linebreakReplacement;
  late final NodeType topNodeType;
  final Map<String, dynamic> cached = {};

  Schema(this.spec) {
    nodes = NodeType.compile(spec.nodes, this);
    marks = MarkType.compile(spec.marks ?? {}, this);

    Map<String, ContentMatch> contentExprCache = {};
    for (String prop in nodes.keys) {
      if (marks.containsKey(prop)) {
        throw RangeError("$prop can not be both a node and a mark");
      }
      NodeType type = nodes[prop]!;
      String contentExpr = type.spec.content ?? "";
      String? markExpr = type.spec.marks;
      type.contentMatch = contentExprCache[contentExpr] ??=
          ContentMatch.parse(contentExpr, nodes);
      type.inlineContent = type.contentMatch.inlineContent;

      if (type.spec.linebreakReplacement == true) {
        if (linebreakReplacement != null)
          throw RangeError("Multiple linebreak nodes defined");
        if (!type.isInline || !type.isLeaf)
          throw RangeError(
              "Linebreak replacement nodes must be inline leaf nodes");
        linebreakReplacement = type;
      }

      type.markSet = markExpr == "_"
          ? null
          : (markExpr != null
              ? (markExpr == "" ? [] : _gatherMarks(this, markExpr.split(" ")))
              : (!type.inlineContent ? [] : null));
    }

    for (String prop in marks.keys) {
      MarkType type = marks[prop]!;
      String? excl = type.spec.excludes;
      type.excluded = excl == null
          ? [type]
          : (excl == "" ? [] : _gatherMarks(this, excl.split(" ")));
    }

    topNodeType = nodes[spec.topNode ?? "doc"]!;
  }

  PMNode node(dynamic type,
      [Map<String, dynamic>? attrs, dynamic content, List<Mark>? marksList]) {
    NodeType t;
    if (type is String) {
      t = nodeType(type);
    } else if (type is NodeType) {
      t = type;
      if (t.schema != this)
        throw RangeError("Node type from different schema used (${t.name})");
    } else {
      throw RangeError("Invalid node type: $type");
    }
    return t.createChecked(attrs, content, marksList);
  }

  PMNode text(String text, [List<Mark>? marksList]) {
    NodeType type = nodes["text"]!;
    return TextNode(type, type.defaultAttrs, text, Mark.setFrom(marksList));
  }

  Mark mark(dynamic type, [Map<String, dynamic>? attrs]) {
    MarkType t;
    if (type is String) {
      t = marks[type]!;
    } else {
      t = type as MarkType;
    }
    return t.create(attrs);
  }

  PMNode nodeFromJSON(dynamic json) => PMNode.fromJSON(this, json);
  Mark markFromJSON(dynamic json) => Mark.fromJSON(this, json);

  NodeType nodeType(String name) {
    NodeType? found = nodes[name];
    if (found == null) throw RangeError("Unknown node type: $name");
    return found;
  }
}

class SchemaSpec {
  final Map<String, NodeSpec> nodes;
  final Map<String, MarkSpec>? marks;
  final String? topNode;

  SchemaSpec({required this.nodes, this.marks, this.topNode});
}

class NodeSpec {
  final String? content;
  final String? marks;
  final String? group;
  final bool? inline;
  final bool? atom;
  final Map<String, AttributeSpec>? attrs;
  final bool? selectable;
  final bool? draggable;
  final bool? code;
  final String? whitespace;
  final bool? definingAsContext;
  final bool? definingForContent;
  final bool? defining;
  final bool? isolating;
  final bool? linebreakReplacement;
  final List<dynamic>? parseDOM;
  final dynamic Function(PMNode)? toDOM;
  final dynamic disableDropCursor;

  /// Experimental prosemirror-view kludge: when true, the view re-parses the
  /// node from the DOM instead of relying on its view desc (TS accesses this
  /// through NodeSpec's index signature).
  final bool? reparseInView;

  final String? Function(PMNode)? leafText;
  final String? Function(PMNode)? toDebugString;

  NodeSpec({
    this.content,
    this.marks,
    this.group,
    this.inline,
    this.atom,
    this.attrs,
    this.selectable,
    this.draggable,
    this.code,
    this.whitespace,
    this.definingAsContext,
    this.definingForContent,
    this.defining,
    this.isolating,
    this.linebreakReplacement,
    this.parseDOM,
    this.toDOM,
    this.disableDropCursor,
    this.reparseInView,
    this.leafText,
    this.toDebugString,
  });
}

class MarkSpec {
  final Map<String, AttributeSpec>? attrs;
  final bool? inclusive;
  final String? excludes;
  final String? group;
  final bool? spanning;
  final bool? code;
  final List<dynamic>? parseDOM;
  final dynamic Function(Mark, bool)? toDOM;

  /// Experimental prosemirror-view kludge: when true, the view re-parses the
  /// mark from the DOM instead of relying on its view desc (TS accesses this
  /// through MarkSpec's index signature).
  final bool? reparseInView;

  MarkSpec({
    this.attrs,
    this.inclusive,
    this.excludes,
    this.group,
    this.spanning,
    this.code,
    this.parseDOM,
    this.toDOM,
    this.reparseInView,
  });
}

class AttributeSpec {
  final dynamic defaultValue;
  final bool hasDefault;
  final dynamic validate; // String or Function

  AttributeSpec({this.defaultValue, this.hasDefault = false, this.validate});
}

Map<String, dynamic>? _defaultAttrs(Map<String, Attribute> attrs) {
  Map<String, dynamic> defaults = {};
  for (String attrName in attrs.keys) {
    Attribute attr = attrs[attrName]!;
    if (!attr.hasDefault) return null;
    defaults[attrName] = attr.defaultValue;
  }
  return defaults;
}

Map<String, dynamic> _computeAttrs(
    Map<String, Attribute> attrs, Map<String, dynamic>? value) {
  Map<String, dynamic> built = {};
  for (String name in attrs.keys) {
    dynamic given = value?[name];
    if (given == null) {
      Attribute attr = attrs[name]!;
      if (attr.hasDefault) {
        given = attr.defaultValue;
      } else {
        throw RangeError("No value supplied for attribute $name");
      }
    }
    built[name] = given;
  }
  return built;
}

void _checkAttrs(Map<String, Attribute> attrs, Map<String, dynamic> values,
    String type, String name) {
  for (String attr in values.keys) {
    if (!attrs.containsKey(attr))
      throw RangeError("Unsupported attribute $attr for $type of type $name");
  }
  for (String attr in attrs.keys) {
    if (attrs[attr]!.validate != null) {
      attrs[attr]!.validate!(values[attr]);
    }
  }
}

Map<String, Attribute> _initAttrs(
    String typeName, Map<String, AttributeSpec>? attrs) {
  Map<String, Attribute> result = {};
  if (attrs != null) {
    for (String name in attrs.keys) {
      result[name] = Attribute(typeName, name, attrs[name]!);
    }
  }
  return result;
}

List<MarkType> _gatherMarks(Schema schema, List<String> marks) {
  List<MarkType> found = [];
  for (int i = 0; i < marks.length; i++) {
    String name = marks[i];
    MarkType? mark = schema.marks[name];
    MarkType? ok = mark;
    if (mark != null) {
      found.add(mark);
    } else {
      for (String prop in schema.marks.keys) {
        MarkType m = schema.marks[prop]!;
        if (name == "_" ||
            (m.spec.group != null && m.spec.group!.split(" ").contains(name))) {
          found.add(ok = m);
        }
      }
    }
    if (ok == null) throw FormatException("Unknown mark type: '${marks[i]}'");
  }
  return found;
}
