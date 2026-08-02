import 'comparedeep.dart';
import 'schema.dart';

/// A mark is a piece of information that can be attached to a node,
/// such as it being emphasized, in code font, or a link. It has a
/// type and optionally a set of attributes that provide further
/// information (such as the target of the link). Marks are created
/// through a `Schema`, which controls which types exist and which
/// attributes they have.
class Mark {
  /// The type of this mark.
  final MarkType type;

  /// The attributes associated with this mark.
  final Map<String, dynamic> attrs;

  /// @internal
  const Mark(this.type, this.attrs);

  /// Given a set of marks, create a new set which contains this one as
  /// well, in the right position. If this mark is already in the set,
  /// the set itself is returned. If any marks that are set to be
  /// [exclusive](#model.MarkSpec.excludes) with this mark are present,
  /// those are replaced by this one.
  List<Mark> addToSet(List<Mark> set) {
    List<Mark>? copy;
    bool placed = false;
    for (int i = 0; i < set.length; i++) {
      Mark other = set[i];
      if (eq(other)) return set;
      if (type.excludes(other.type)) {
        copy ??= set.sublist(0, i);
      } else if (other.type.excludes(type)) {
        return set;
      } else {
        if (!placed && other.type.rank > type.rank) {
          copy ??= set.sublist(0, i);
          copy.add(this);
          placed = true;
        }
        if (copy != null) copy.add(other);
      }
    }
    copy ??= List.of(set);
    if (!placed) copy.add(this);
    return copy;
  }

  /// Remove this mark from the given set, returning a new set. If this
  /// mark is not in the set, the set itself is returned.
  List<Mark> removeFromSet(List<Mark> set) {
    for (int i = 0; i < set.length; i++) {
      if (eq(set[i])) {
        return [...set.sublist(0, i), ...set.sublist(i + 1)];
      }
    }
    return set;
  }

  /// Test whether this mark is in the given set of marks.
  bool isInSet(List<Mark> set) {
    for (int i = 0; i < set.length; i++) {
      if (eq(set[i])) return true;
    }
    return false;
  }

  /// Test whether this mark has the same type and attributes as
  /// another mark.
  bool eq(Mark other) {
    return identical(this, other) ||
        (type == other.type && compareDeep(attrs, other.attrs));
  }

  /// Convert this mark to a JSON-serializeable representation.
  dynamic toJSON() {
    Map<String, dynamic> obj = {'type': type.name};
    if (attrs.isNotEmpty) {
      obj['attrs'] = attrs;
    }
    return obj;
  }

  /// Deserialize a mark from JSON.
  static Mark fromJSON(Schema schema, dynamic json) {
    if (json == null) throw RangeError("Invalid input for Mark.fromJSON");
    MarkType? type = schema.marks[json['type']];
    if (type == null) {
      throw RangeError("There is no mark type ${json['type']} in this schema");
    }
    Mark mark = type.create(json['attrs']);
    type.checkAttrs(mark.attrs);
    return mark;
  }

  /// Test whether two sets of marks are identical.
  static bool sameSet(List<Mark> a, List<Mark> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!a[i].eq(b[i])) return false;
    }
    return true;
  }

  /// Create a properly sorted mark set from null, a single mark, or an
  /// unsorted array of marks.
  static List<Mark> setFrom([dynamic marks]) {
    if (marks == null || (marks is List && marks.isEmpty)) return none;
    if (marks is Mark) return [marks];
    if (marks is List<Mark>) {
      List<Mark> copy = List.of(marks);
      copy.sort((a, b) => a.type.rank.compareTo(b.type.rank));
      return copy;
    }
    throw ArgumentError("Invalid marks input for Mark.setFrom");
  }

  /// The empty set of marks.
  static const List<Mark> none = [];
}
