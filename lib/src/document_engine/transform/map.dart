import 'dart:math';

abstract class Mappable {
  int map(int pos, [int assoc = 1]);
  MapResult mapResult(int pos, [int assoc = 1]);
}

const int _lower16 = 0xffff;
final double _factor16 = pow(2, 16).toDouble();

int _makeRecover(int index, int offset) {
  return index + (offset * _factor16).toInt();
}

int _recoverIndex(int value) {
  return value & _lower16;
}

int _recoverOffset(int value) {
  return ((value - (value & _lower16)) / _factor16).toInt();
}

const int DEL_BEFORE = 1;
const int DEL_AFTER = 2;
const int DEL_ACROSS = 4;
const int DEL_SIDE = 8;

class MapResult {
  final int pos;
  final int delInfo;
  final int? recover;

  MapResult(this.pos, this.delInfo, this.recover);

  bool get deleted => (delInfo & DEL_SIDE) > 0;
  bool get deletedBefore => (delInfo & (DEL_BEFORE | DEL_ACROSS)) > 0;
  bool get deletedAfter => (delInfo & (DEL_AFTER | DEL_ACROSS)) > 0;
  bool get deletedAcross => (delInfo & DEL_ACROSS) > 0;
}

class StepMap implements Mappable {
  final List<int> ranges;
  final bool inverted;

  StepMap(this.ranges, [this.inverted = false]);

  int recover(int value) {
    int diff = 0, index = _recoverIndex(value);
    if (!inverted) {
      for (int i = 0; i < index; i++) {
        diff += ranges[i * 3 + 2] - ranges[i * 3 + 1];
      }
    }
    return ranges[index * 3] + diff + _recoverOffset(value);
  }

  @override
  MapResult mapResult(int pos, [int assoc = 1]) {
    return _map(pos, assoc, false) as MapResult;
  }

  @override
  int map(int pos, [int assoc = 1]) {
    return _map(pos, assoc, true) as int;
  }

  dynamic _map(int pos, int assoc, bool simple) {
    int diff = 0;
    int oldIndex = inverted ? 2 : 1;
    int newIndex = inverted ? 1 : 2;

    for (int i = 0; i < ranges.length; i += 3) {
      int start = ranges[i] - (inverted ? diff : 0);
      if (start > pos) break;
      int oldSize = ranges[i + oldIndex];
      int newSize = ranges[i + newIndex];
      int end = start + oldSize;
      
      if (pos <= end) {
        int side = oldSize == 0 ? assoc : (pos == start ? -1 : (pos == end ? 1 : assoc));
        int result = start + diff + (side < 0 ? 0 : newSize);
        if (simple) return result;
        
        int? recover = pos == (assoc < 0 ? start : end) ? null : _makeRecover(i ~/ 3, pos - start);
        int del = pos == start ? DEL_AFTER : (pos == end ? DEL_BEFORE : DEL_ACROSS);
        if (assoc < 0 ? pos != start : pos != end) del |= DEL_SIDE;
        
        return MapResult(result, del, recover);
      }
      diff += newSize - oldSize;
    }
    return simple ? pos + diff : MapResult(pos + diff, 0, null);
  }

  bool touches(int pos, int recover) {
    int diff = 0, index = _recoverIndex(recover);
    int oldIndex = inverted ? 2 : 1, newIndex = inverted ? 1 : 2;
    for (int i = 0; i < ranges.length; i += 3) {
      int start = ranges[i] - (inverted ? diff : 0);
      if (start > pos) break;
      int oldSize = ranges[i + oldIndex];
      int end = start + oldSize;
      if (pos <= end && i == index * 3) return true;
      diff += ranges[i + newIndex] - oldSize;
    }
    return false;
  }

  void forEach(void Function(int oldStart, int oldEnd, int newStart, int newEnd) f) {
    int oldIndex = inverted ? 2 : 1, newIndex = inverted ? 1 : 2;
    for (int i = 0, diff = 0; i < ranges.length; i += 3) {
      int start = ranges[i];
      int oldStart = start - (inverted ? diff : 0);
      int newStart = start + (inverted ? 0 : diff);
      int oldSize = ranges[i + oldIndex];
      int newSize = ranges[i + newIndex];
      f(oldStart, oldStart + oldSize, newStart, newStart + newSize);
      diff += newSize - oldSize;
    }
  }

  StepMap invert() {
    return StepMap(ranges, !inverted);
  }

  @override
  String toString() {
    return (inverted ? "-" : "") + ranges.toString();
  }

  static StepMap offset(int n) {
    return n == 0 ? StepMap.empty : StepMap(n < 0 ? [0, -n, 0] : [0, 0, n]);
  }

  static final StepMap empty = StepMap([]);
}

class Mapping implements Mappable {
  List<StepMap> _maps = [];
  List<int>? mirror;
  int from;
  int to;
  bool _ownData;

  Mapping([List<StepMap>? maps, this.mirror, this.from = 0, int? to])
      : to = to ?? (maps?.length ?? 0),
        _ownData = !(maps != null || mirror != null) {
    if (maps != null) _maps = maps;
  }

  List<StepMap> get maps => _maps;

  Mapping slice([int from = 0, int? to]) {
    return Mapping(_maps, mirror, from, to ?? _maps.length);
  }

  void appendMap(StepMap map, [int? mirrors]) {
    if (!_ownData) {
      _maps = List.from(_maps);
      if (mirror != null) mirror = List.from(mirror!);
      _ownData = true;
    }
    _maps.add(map);
    to = _maps.length;
    if (mirrors != null) setMirror(_maps.length - 1, mirrors);
  }

  void appendMapping(Mapping mapping) {
    int startSize = _maps.length;
    for (int i = 0; i < mapping._maps.length; i++) {
      int? mirr = mapping.getMirror(i);
      appendMap(mapping._maps[i], (mirr != null && mirr < i) ? startSize + mirr : null);
    }
  }

  int? getMirror(int n) {
    if (mirror != null) {
      for (int i = 0; i < mirror!.length; i++) {
        if (mirror![i] == n) return mirror![i + (i % 2 != 0 ? -1 : 1)];
      }
    }
    return null;
  }

  void setMirror(int n, int m) {
    mirror ??= [];
    mirror!.add(n);
    mirror!.add(m);
  }

  void appendMappingInverted(Mapping mapping) {
    int totalSize = _maps.length + mapping._maps.length;
    for (int i = mapping.maps.length - 1; i >= 0; i--) {
      int? mirr = mapping.getMirror(i);
      appendMap(mapping._maps[i].invert(), (mirr != null && mirr > i) ? totalSize - mirr - 1 : null);
    }
  }

  Mapping invert() {
    Mapping inverse = Mapping();
    inverse.appendMappingInverted(this);
    return inverse;
  }

  @override
  int map(int pos, [int assoc = 1]) {
    if (mirror != null) return _map(pos, assoc, true) as int;
    for (int i = from; i < to; i++) {
      pos = _maps[i].map(pos, assoc);
    }
    return pos;
  }

  @override
  MapResult mapResult(int pos, [int assoc = 1]) {
    return _map(pos, assoc, false) as MapResult;
  }

  dynamic _map(int pos, int assoc, bool simple) {
    int delInfo = 0;

    for (int i = from; i < to; i++) {
      StepMap map = _maps[i];
      MapResult result = map.mapResult(pos, assoc);
      if (result.recover != null) {
        int? corr = getMirror(i);
        if (corr != null && corr > i && corr < to) {
          i = corr;
          pos = _maps[corr].recover(result.recover!);
          continue;
        }
      }

      delInfo |= result.delInfo;
      pos = result.pos;
    }

    return simple ? pos : MapResult(pos, delInfo, null);
  }
}
