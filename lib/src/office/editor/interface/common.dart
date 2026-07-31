typedef Primitive = Object?;

/// Builtin values tracked by the original TypeScript implementation. The
/// alias is kept for parity and backwards compatibility with the ported API.
typedef Builtin = Object?;

/// Mirrors the TypeScript utility type. In Dart we rely on runtime maps to
/// represent nested optional structures (e.g. localized strings), so the alias
/// resolves to a JSON-like map.
typedef DeepPartial<T> = Map<String, dynamic>;

/// The majority of the Dart port works with already-required objects, so this
/// alias remains an identity helper while preserving intent in the function
/// signatures.
typedef DeepRequired<T> = T;

class IPadding {
  IPadding({
    required num top,
    required num right,
    required num bottom,
    required num left,
  })  : top = top.toDouble(),
        right = right.toDouble(),
        bottom = bottom.toDouble(),
        left = left.toDouble();

  /// Convenience constructor mirroring tuple-style instantiation in the
  /// original codebase.
  IPadding.fromList(List<num> values)
      : assert(values.length == 4, 'IPadding requires exactly four entries.'),
        top = values[0].toDouble(),
        right = values[1].toDouble(),
        bottom = values[2].toDouble(),
        left = values[3].toDouble();

  final double top;
  final double right;
  final double bottom;
  final double left;

  List<double> toList() => <double>[top, right, bottom, left];

  IPadding copyWith({
    num? top,
    num? right,
    num? bottom,
    num? left,
  }) {
    return IPadding(
      top: top?.toDouble() ?? this.top,
      right: right?.toDouble() ?? this.right,
      bottom: bottom?.toDouble() ?? this.bottom,
      left: left?.toDouble() ?? this.left,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is IPadding &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() =>
      'IPadding(top: $top, right: $right, bottom: $bottom, left: $left)';
}
