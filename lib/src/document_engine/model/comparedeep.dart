bool compareDeep(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  
  if (a == null || b == null) return false;

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!compareDeep(a[i], b[i])) return false;
    }
    return true;
  }

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key) || !compareDeep(a[key], b[key])) return false;
    }
    return true;
  }

  return a == b;
}
