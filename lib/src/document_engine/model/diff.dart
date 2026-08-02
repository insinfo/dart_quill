import 'fragment.dart';
import 'node.dart';

class Diff {
  static int? findDiffStart(Fragment a, Fragment b, int pos) {
    for (int i = 0;; i++) {
      if (i == a.childCount || i == b.childCount) {
        return a.childCount == b.childCount ? null : pos;
      }

      PMNode childA = a.child(i);
      PMNode childB = b.child(i);

      if (identical(childA, childB)) {
        pos += childA.nodeSize;
        continue;
      }

      if (!childA.sameMarkup(childB)) return pos;

      if (childA.isText && childA.text != childB.text) {
        String tA = childA.text!;
        String tB = childB.text!;
        int j = 0;
        for (; j < tA.length && j < tB.length && tA[j] == tB[j]; j++) {
          pos++;
        }
        if (j > 0 &&
            j < tA.length &&
            j < tB.length &&
            _surrogateHigh(tA.codeUnitAt(j - 1)) &&
            _surrogateLow(tA.codeUnitAt(j))) {
          pos--;
        }
        return pos;
      }

      if (childA.content.size > 0 || childB.content.size > 0) {
        int? inner = findDiffStart(childA.content, childB.content, pos + 1);
        if (inner != null) return inner;
      }
      pos += childA.nodeSize;
    }
  }

  static DiffEndResult? findDiffEnd(
      Fragment a, Fragment b, int posA, int posB) {
    for (int iA = a.childCount, iB = b.childCount;;) {
      if (iA == 0 || iB == 0) {
        return iA == iB ? null : DiffEndResult(posA, posB);
      }

      PMNode childA = a.child(--iA);
      PMNode childB = b.child(--iB);
      int size = childA.nodeSize;

      if (identical(childA, childB)) {
        posA -= size;
        posB -= size;
        continue;
      }

      if (!childA.sameMarkup(childB)) return DiffEndResult(posA, posB);

      if (childA.isText && childA.text != childB.text) {
        String tA = childA.text!;
        String tB = childB.text!;
        int iA_str = tA.length;
        int iB_str = tB.length;
        while (iA_str > 0 &&
            iB_str > 0 &&
            tA[iA_str - 1] == tB[iB_str - 1]) {
          iA_str--;
          iB_str--;
          posA--;
          posB--;
        }
        if (iA_str > 0 &&
            iB_str > 0 &&
            iA_str < tA.length &&
            _surrogateHigh(tA.codeUnitAt(iA_str - 1)) &&
            _surrogateLow(tA.codeUnitAt(iA_str))) {
          posA++;
          posB++;
        }
        return DiffEndResult(posA, posB);
      }

      if (childA.content.size > 0 || childB.content.size > 0) {
        DiffEndResult? inner =
            findDiffEnd(childA.content, childB.content, posA - 1, posB - 1);
        if (inner != null) return inner;
      }
      posA -= size;
      posB -= size;
    }
  }
}

class DiffEndResult {
  final int a;
  final int b;
  DiffEndResult(this.a, this.b);
}

bool _surrogateLow(int ch) => ch >= 0xDC00 && ch < 0xE000;
bool _surrogateHigh(int ch) => ch >= 0xD800 && ch < 0xDC00;
