import 'dart:math' as math;

import '../../formats/abstract/attributor.dart';
import '../../platform/dom.dart';

typedef BlotPredicate = bool Function(Blot blot);

class RegistryEntry {
  RegistryEntry({
    required this.blotName,
    required this.scope,
    required this.create,
    this.tagNames = const <String>[],
    this.classNames = const <String>[],
  });

  final String blotName;
  final int scope;
  final Blot Function([dynamic value]) create;
  final List<String> tagNames;
  final List<String> classNames;
}

class Registry {
  final Map<String, RegistryEntry> _entries = {};
  // Attributors are looked up both by attrName (format name) and keyName
  // (DOM attribute/class/style key), mirroring parchment's Registry.
  final Map<String, Attributor> _attributors = {};

  void register(RegistryEntry entry) {
    _entries[entry.blotName] = entry;
  }

  void registerAttributor(Attributor attributor) {
    _attributors[attributor.attrName] = attributor;
    _attributors[attributor.keyName] = attributor;
  }

  Iterable<RegistryEntry> get entries => _entries.values;

  Iterable<Attributor> get attributors => _attributors.values.toSet();

  /// Finds an attributor registered under [name] (attrName or keyName) whose
  /// scope matches [scope].
  Attributor? queryAttributor(String name, [int scope = Scope.ANY]) {
    final attributor = _attributors[name];
    if (attributor == null) return null;
    if (scope == Scope.ANY || Scope.matches(attributor.scope, scope)) {
      return attributor;
    }
    return null;
  }

  bool contains(String name) => _entries.containsKey(name);

  RegistryEntry? query(String name, int scope) {
    final entry = _entries[name];
    if (entry == null) return null;
    if (Scope.matches(entry.scope, scope)) {
      return entry;
    }
    return null;
  }

  RegistryEntry? queryByTagName(String tagName, {int scope = Scope.ANY}) {
    final upper = tagName.toUpperCase();
    for (final entry in _entries.values) {
      if (!Scope.matches(entry.scope, scope)) {
        continue;
      }
      for (final tag in entry.tagNames) {
        if (tag.toUpperCase() == upper) {
          return entry;
        }
      }
    }
    return null;
  }

  RegistryEntry? queryByClassName(String className, {int scope = Scope.ANY}) {
    if (className.isEmpty) return null;
    final tokens = className
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    for (final entry in _entries.values) {
      if (!Scope.matches(entry.scope, scope)) {
        continue;
      }
      for (final token in tokens) {
        if (entry.classNames.contains(token)) {
          return entry;
        }
      }
    }
    return null;
  }

  Blot create(String name, [dynamic value]) {
    final entry = _entries[name];
    if (entry == null) {
      throw ArgumentError('Unknown blot "$name"');
    }
    return entry.create(value);
  }
}

class Scope {
  Scope._();

  static const int BLOT = 0x0001;
  static const int INLINE = 0x0002;
  static const int BLOCK = 0x0004;
  static const int EMBED = 0x0008;
  static const int ATTRIBUTE = 0x0100;

  static const int INLINE_BLOT = INLINE | BLOT;
  static const int BLOCK_BLOT = BLOCK | BLOT;
  static const int INLINE_ATTRIBUTE = INLINE | ATTRIBUTE;
  static const int BLOCK_ATTRIBUTE = BLOCK | ATTRIBUTE;
  static const int ANY = 0xffff;

  static bool matches(int entryScope, int queryScope) {
    if (queryScope == ANY) {
      return true;
    }
    return (entryScope & queryScope) == queryScope;
  }
}

abstract class Blot {
  Blot(this.domNode);

  ParentBlot? parent;
  Blot? prev;
  Blot? next;
  final DomNode domNode;

  String get blotName;
  int get scope;

  ScrollBlot get scroll {
    Blot? current = this;
    while (current != null) {
      if (current is ScrollBlot) {
        return current;
      }
      current = current.parent;
    }
    throw StateError('Blot is not attached to a scroll');
  }

  bool get isAttached => parent != null;

  Blot clone();

  int length();

  dynamic value();

  Map<String, dynamic> formats() => const {};

  void format(String name, dynamic value) {}

  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) return;
    format(name, value);
  }

  void insertAt(int index, String value, [dynamic def]);

  void deleteAt(int index, int length);

  Blot? split(int index, {bool force = false});

  void remove() {
    parent?.removeChild(this);
  }

  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    // Default implementation does nothing
    // Subclasses can override to implement specific optimization logic
  }

  List<MapEntry<Blot, int>> path(int index, {bool inclusive = false}) {
    return [MapEntry(this, index)];
  }

  int offset(Blot target) {
    if (target == this) return 0;
    throw ArgumentError('Cannot compute offset for unrelated blot');
  }

  MapEntry<Blot?, int> find(dynamic query, {bool bubble = false}) {
    if (query is DomNode && domNode == query) {
      return MapEntry(this, 0);
    }
    if (bubble && parent != null) {
      return parent!.find(query, bubble: true);
    }
    return const MapEntry(null, -1);
  }
}

abstract class ParentBlot extends Blot {
  ParentBlot(DomElement domNode) : super(domNode);

  final List<Blot> children = [];

  /// Optional UI node (e.g. `.ql-ui` marker element prepended by list blots).
  DomElement? uiNode;

  DomElement get element => domNode as DomElement;

  Blot? get firstChild => children.isNotEmpty ? children.first : null;
  Blot? get lastChild => children.isNotEmpty ? children.last : null;

  @override
  int length() =>
      children.fold<int>(0, (length, child) => length + child.length());

  @override
  dynamic value() => children.map((child) => child.value()).toList();

  int childOffset(Blot child) {
    var offset = 0;
    for (final current in children) {
      if (current == child) {
        return offset;
      }
      offset += current.length();
    }
    return -1;
  }

  void appendChild(Blot blot) => insertBefore(blot, null);

  Blot? createDefaultChild([dynamic value]) => null;

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    final snapshot = List<Blot>.from(children);
    for (final child in snapshot) {
      child.optimize(mutations, context);
    }

    for (final child in List<Blot>.from(children)) {
      _ensureChildDomParent(child, mutations, context);
    }
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (children.isEmpty) {
      final child = createDefaultChild(value);
      if (child == null) {
        throw UnsupportedError('Cannot insert into empty ${runtimeType}');
      }
      appendChild(child);
      child.insertAt(index, value, def);
      return;
    }

    var offset = 0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childLength = child.length();
      final end = offset + childLength;
      final isLast = i == children.length - 1;
      if (index < end || isLast) {
        child.insertAt(index - offset, value, def);
        return;
      }
      offset = end;
    }
  }

  @override
  void deleteAt(int index, int length) {
    if (length <= 0) return;

    var offset = 0;
    for (final child in List<Blot>.from(children)) {
      final childLength = child.length();
      final end = offset + childLength;
      if (index < end) {
        final localIndex = index - offset;
        final removable = math.min(length, childLength - localIndex).toInt();
        child.deleteAt(localIndex, removable);
        if (child.length() == 0 ||
            (child is LeafBlot &&
                localIndex == 0 &&
                removable == childLength)) {
          removeChild(child);
        }
        final remaining = length - removable;
        if (remaining > 0) {
          deleteAt(index, remaining);
        }
        return;
      }
      offset = end;
    }
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) return;

    var offset = 0;
    var remaining = length;
    for (final child in children) {
      final childLength = child.length();
      final end = offset + childLength;
      if (index < end) {
        final localIndex = index - offset;
        final localLength =
            math.min(remaining, childLength - localIndex).toInt();
        child.formatAt(localIndex, localLength, name, value);
        remaining -= localLength;
        index = end;
        if (remaining <= 0) {
          break;
        }
      }
      offset = end;
    }
  }

  void insertBefore(Blot blot, Blot? ref) {
    if (blot == ref) return;
    if (ref != null && ref.parent != this) {
      throw ArgumentError('Reference blot is not a child of this parent');
    }

    final targetIndex = ref != null ? children.indexOf(ref) : children.length;
    if (targetIndex == -1) {
      throw ArgumentError('Reference blot is not managed by this parent');
    }

    blot.parent?.removeChild(blot);

    final previous = targetIndex > 0 ? children[targetIndex - 1] : null;
    final next =
        ref ?? (targetIndex < children.length ? children[targetIndex] : null);

    blot.parent = this;
    blot.prev = previous;
    blot.next = next;
    previous?.next = blot;
    next?.prev = blot;

    if (ref != null) {
      element.insertBefore(blot.domNode, ref.domNode);
    } else {
      element.append(blot.domNode);
    }

    children.insert(targetIndex, blot);
  }

  void removeChild(Blot child) {
    final index = children.indexOf(child);
    if (index == -1) return;

    final previous = child.prev;
    final next = child.next;
    previous?.next = next;
    next?.prev = previous;

    children.removeAt(index);

    child.parent = null;
    child.prev = null;
    child.next = null;
    child.domNode.remove();
  }

  void moveChildren(ParentBlot target, Blot? ref) {
    final toMove = List<Blot>.from(children);
    for (final child in toMove) {
      target.insertBefore(child, ref);
    }
  }

  void _ensureChildDomParent(
    Blot child,
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ) {
    if (child.parent != this) {
      return;
    }
    final domParent = child.domNode.parentNode;
    if (domParent == element) {
      return;
    }

    if (domParent == null) {
      element.append(child.domNode);
      return;
    }

    if (domParent is! DomElement) {
      element.append(child.domNode);
      return;
    }

    ParentBlot? wrapperBlot;
    for (final candidate in children) {
      if (candidate is ParentBlot && identical(candidate.domNode, domParent)) {
        wrapperBlot = candidate;
        break;
      }
    }

    if (wrapperBlot == null) {
      final scrollBlot = scroll;
      final registry = scrollBlot.registry;
      var entry = registry.queryByTagName(domParent.tagName, scope: Scope.ANY);
      entry ??= registry.queryByClassName(domParent.className ?? '',
          scope: Scope.ANY);

      if (entry == null) {
        element.insertBefore(child.domNode, domParent);
        domParent.remove();
        return;
      }

      final created = scrollBlot.create(entry.blotName, domParent);
      if (created is! ParentBlot) {
        element.insertBefore(child.domNode, domParent);
        domParent.remove();
        return;
      }

      wrapperBlot = created;
      insertBefore(wrapperBlot, child);
    }

    removeChild(child);
    wrapperBlot.insertBefore(child, null);
    wrapperBlot.optimize(mutations, context);
  }

  Iterable<T> descendants<T extends Blot>(
      {bool Function(T blot)? predicate}) sync* {
    for (final child in children) {
      if (child is T && (predicate == null || predicate(child))) {
        yield child;
      }
      if (child is ParentBlot) {
        yield* child.descendants<T>(predicate: predicate);
      }
    }
  }

  /// Descendants of type [T] intersecting the range [index, index+length),
  /// mirroring parchment's `ParentBlot.descendants(criteria, index, length)`.
  List<T> descendantsAt<T extends Blot>(int index, int length,
      {bool Function(T blot)? predicate}) {
    final result = <T>[];
    var lengthLeft = length;
    var offset = 0;
    for (final child in children) {
      final childLength = child.length();
      final end = offset + childLength;
      if (end > index && offset < index + length) {
        final childIndex = math.max(0, index - offset);
        final visited =
            math.min(end, index + length) - math.max(offset, index);
        if (child is T && (predicate == null || predicate(child))) {
          result.add(child);
        }
        if (child is ParentBlot) {
          result.addAll(child.descendantsAt<T>(childIndex, lengthLeft,
              predicate: predicate));
        }
        lengthLeft -= math.max(0, visited).toInt();
      }
      offset = end;
      if (offset >= index + length) {
        break;
      }
    }
    return result;
  }

  MapEntry<Blot?, int> descendant(dynamic query, int index) {
    if (index < 0) {
      return const MapEntry(null, -1);
    }

    var offset = 0;
    for (final child in children) {
      final childLength = child.length();
      final end = offset + childLength;

      final isLastChild =
          identical(child, children.isNotEmpty ? children.last : null);
      final containsIndex = index < end || (index == end && isLastChild);

      if (containsIndex) {
        if (_matches(child, query)) {
          return MapEntry(child, index - offset);
        }
        if (child is ParentBlot) {
          return child.descendant(query, index - offset);
        }
        break;
      }

      offset = end;
    }
    return const MapEntry(null, -1);
  }

  bool _matches(Blot blot, dynamic query) {
    if (query is BlotPredicate) {
      return query(blot);
    }
    if (query is Type) {
      return blot.runtimeType == query;
    }
    if (query is String) {
      return blot.blotName == query;
    }
    return false;
  }

  @override
  List<MapEntry<Blot, int>> path(int index, {bool inclusive = false}) {
    if (index < 0) {
      throw RangeError.index(index, this, 'index');
    }

    var offset = 0;
    final result = <MapEntry<Blot, int>>[MapEntry(this, index)];
    for (final child in children) {
      final childLength = child.length();
      final end = offset + childLength;
      // Inclusive boundary matching mirrors parchment's LinkedList.find:
      // prefer the earlier child unless the next sibling is zero-length.
      final isTarget = index < end ||
          (inclusive &&
              index == end &&
              (child.next == null || child.next!.length() != 0));
      if (isTarget) {
        final childOffset = index - offset;
        result.add(MapEntry(child, childOffset));
        if (child is ParentBlot) {
          result.addAll(child.path(childOffset, inclusive: inclusive).skip(1));
        }
        break;
      }
      offset = end;
    }
    return result;
  }

  @override
  Blot? split(int index, {bool force = false}) {
    final totalLength = length();
    if (!force) {
      if (index <= 0) return this;
      if (index >= totalLength) return next;
    }

    var offset = 0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childLength = child.length();
      final end = offset + childLength;

      if (index < end) {
        final remainder = child.split(index - offset, force: force);
        if (!force) {
          return remainder ?? child.next?.parent ?? child.parent;
        }

        final splitParent = clone() as ParentBlot;
        parent?.insertBefore(splitParent, next);

        Blot? move = remainder ?? child.next;
        while (move != null) {
          final nextMove = move.next;
          splitParent.insertBefore(move, null);
          move = nextMove;
        }
        return splitParent;
      }

      if (index == end) {
        final splitParent = clone() as ParentBlot;
        parent?.insertBefore(splitParent, next);
        final tail = List<Blot>.from(children.skip(i + 1));
        for (final tailChild in tail) {
          splitParent.appendChild(tailChild);
        }
        return splitParent;
      }
      offset = end;
    }

    if (force) {
      final splitParent = clone() as ParentBlot;
      parent?.insertBefore(splitParent, next);
      return splitParent;
    }

    return next;
  }

  @override
  MapEntry<Blot?, int> find(dynamic query, {bool bubble = false}) {
    if (query is DomNode) {
      if (domNode == query) {
        return MapEntry(this, 0);
      }
      for (final child in children) {
        final result = child.find(query, bubble: false);
        if (result.key != null) {
          return result;
        }
      }
    } else if (query is BlotPredicate || query is Type || query is String) {
      for (final child in children) {
        if (_matches(child, query)) {
          return MapEntry(child, childOffset(child));
        }
        if (child is ParentBlot) {
          final result = child.find(query, bubble: false);
          if (result.key != null) {
            return result;
          }
        }
      }
    }

    return bubble && parent != null
        ? parent!.find(query, bubble: true)
        : const MapEntry(null, -1);
  }

  bool contains(Blot blot) {
    Blot? current = blot;
    while (current != null) {
      if (current == this) return true;
      current = current.parent;
    }
    return false;
  }

  @override
  int offset(Blot target) {
    if (!contains(target)) {
      return -1;
    }
    var offset = 0;
    Blot? current = target;
    while (current != null && current != this) {
      final parent = current.parent;
      if (parent == null) {
        break;
      }
      offset += parent.childOffset(current);
      current = parent;
    }
    return offset;
  }
}

abstract class BlockBlot extends ParentBlot {
  BlockBlot(DomElement domNode) : super(domNode);
}

abstract class ContainerBlot extends ParentBlot {
  ContainerBlot(DomElement domNode) : super(domNode);
}

abstract class LeafBlot extends Blot {
  LeafBlot(DomNode domNode) : super(domNode);

  @override
  int length() => 1;

  @override
  void insertAt(int index, String value, [dynamic def]) {
    throw UnsupportedError('Cannot insert into ${runtimeType}');
  }

  @override
  void deleteAt(int index, int length) {
    // LeafBlots are atomic (except TextBlot which overrides this).
    // The parent handles removal if the deletion covers the entire blot.
  }

  @override
  Blot? split(int index, {bool force = false}) {
    if (!force) {
      if (index <= 0) return this;
      if (index >= length()) return next;
    }
    final clone = this.clone();
    parent?.insertBefore(clone, next);
    return clone;
  }

  @override
  List<MapEntry<Blot, int>> path(int index, {bool inclusive = false}) {
    return [MapEntry(this, index)];
  }

  /// Maps an offset within this leaf to a native (DOM node, offset) pair,
  /// mirroring parchment's `LeafBlot.position`. Non-text leaves resolve to
  /// their parent element with a child offset, which is how carets are
  /// placed next to embeds and line breaks.
  MapEntry<DomNode, int> position(int index, [bool inclusive = false]) {
    final parentBlot = parent;
    if (parentBlot == null) {
      return MapEntry(domNode, 0);
    }
    final childNodes = parentBlot.element.childNodes;
    var offset = childNodes.indexOf(domNode);
    if (offset < 0) {
      offset = 0;
    }
    if (index > 0) {
      offset += 1;
    }
    return MapEntry(parentBlot.domNode, offset);
  }
}

abstract class EmbedBlot extends LeafBlot {
  EmbedBlot(DomElement domNode) : super(domNode);

  DomElement get element => domNode as DomElement;
}

abstract class ScrollBlot extends ParentBlot {
  ScrollBlot(this.registry, DomElement domNode) : super(domNode);

  final Registry registry;
  DomMutationObserver? observer;

  RegistryEntry? query(String name, int scope) => registry.query(name, scope);

  Attributor? queryAttributor(String name, [int scope = Scope.ANY]) =>
      registry.queryAttributor(name, scope);

  Blot create(String name, [dynamic value]) => registry.create(name, value);

  void update([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]);

  Map<String, dynamic> getFormat(int index, [int length = 0]);
}
