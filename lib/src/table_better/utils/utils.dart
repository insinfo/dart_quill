/// Port of quill-table-better `src/utils/index.ts` (v1.2.3).
///
/// Pure helpers are ported fully. Helpers that depend on browser layout
/// (getBoundingClientRect / getComputedStyle) route through
/// [elementRectResolver], which throws [UnimplementedError] until the UI
/// phase installs a real implementation (the platform DOM abstraction in
/// `lib/src/platform/dom.dart` has no layout API yet).
import 'dart:async';

import '../../blots/abstract/blot.dart';
import '../../platform/dom.dart';
import '../../platform/platform.dart';
import '../config/config.dart';
import '../formats/table.dart';

/// Mirrors the TS `CorrectBound` shape ({left, top, right, bottom, width?,
/// height?}); also used as the element-rect type.
class CorrectBound {
  const CorrectBound({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.width = 0,
    this.height = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final double width;
  final double height;
}

/// Resolves an element's bounding rectangle.
typedef ElementRectResolver = CorrectBound Function(DomElement element);

CorrectBound _unimplementedElementRect(DomElement element) {
  // TODO(table-better): lib/src/platform/dom.dart exposes no
  // getBoundingClientRect equivalent yet. The UI phase must install a real
  // resolver here (or tests may install a fake one).
  throw UnimplementedError(
    'table-better: element bounding rects are not available; '
    'assign elementRectResolver before using layout-dependent helpers.',
  );
}

/// Pluggable layout hook (see [_unimplementedElementRect]).
ElementRectResolver elementRectResolver = _unimplementedElementRect;

/// TS `addDimensionsUnit`.
String addDimensionsUnit(String value) {
  if (value.isEmpty) return value;
  final unit = value.replaceFirst(RegExp(r'\d+\.?\d*'), ''); // px / em / %
  if (unit.isEmpty) return '${value}px';
  return value;
}

/// TS `convertUnitToInteger`.
///
/// Deviation: the TS version produces `"NaN"` for unit-less values because of
/// `slice(0, -0)`; here a unit-less number is rounded and returned as-is.
String? convertUnitToInteger(String? withUnit) {
  if (withUnit == null || withUnit.isEmpty || withUnit.endsWith('%')) {
    return withUnit;
  }
  final unit = withUnit.replaceFirst(RegExp(r'\d+\.?\d*'), '');
  final numberPart = unit.isEmpty
      ? withUnit
      : withUnit.substring(0, withUnit.length - unit.length);
  final integerPart = (double.tryParse(numberPart) ?? 0).round();
  return '$integerPart$unit';
}

/// TS `createTooltip`.
DomElement createTooltip(String content) {
  final element = domBindings.adapter.document.createElement('div');
  element.text = content;
  element.classes.add('ql-table-tooltip');
  element.classes.add('ql-hidden');
  element.setAttribute('class', 'ql-table-tooltip ql-hidden');
  return element;
}

/// TS `debounce`. Adapted to a zero-argument callback (Dart has no
/// `arguments` object); wrap captured state in the closure instead.
void Function() debounce(void Function() cb, int delayMs) {
  Timer? timer;
  return () {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: delayMs), cb);
  };
}

/// TS `filterWordStyle` (strips `mso-*` Word artifacts from a style string).
String filterWordStyle(String s) => s.replaceAll(RegExp(r'mso.*?;'), '');

/// TS `getAlign`.
///
/// TODO(table-better): the TS version also inspects `TableList` and
/// `TableHeader` descendants; those blots are not ported yet, so only
/// `TableCellBlock` children are considered.
String getAlign(TableCell cellBlot) {
  const defaultAlign = 'left';
  String? align;

  String getChildAlign(ParentBlot child) {
    for (final name in child.element.classes.values) {
      if (name.startsWith('ql-align-')) {
        return name.split('ql-align-')[1];
      }
    }
    return defaultAlign;
  }

  bool isSameValue(String? prev, String cur) {
    if (prev == null) return true;
    return prev == cur;
  }

  for (final child in cellBlot.descendants<TableCellBlock>()) {
    final childAlign = getChildAlign(child);
    if (isSameValue(align, childAlign)) {
      align = childAlign;
    } else {
      return defaultAlign;
    }
  }
  return align ?? defaultAlign;
}

/// TS `getCellChildBlot`.
///
/// TODO(table-better): should also consider `ListContainer` and `TableHeader`
/// descendants once those blots are ported.
Blot? getCellChildBlot(TableCell cellBlot) {
  for (final child in cellBlot.descendants<TableCellBlock>()) {
    return child;
  }
  return null;
}

/// TS `getCellFormats` — returns `(formats, cellId)`.
(Map<String, String>, String) getCellFormats(TableCell cellBlot) {
  final formats = TableCell.formatsFromNode(cellBlot.element);
  final childBlot = getCellChildBlot(cellBlot);
  if (childBlot == null) {
    final parts = (formats['data-row'] ?? '').split('-');
    final row = parts.length > 1 ? parts[1] : '';
    return (formats, 'cell-$row');
  }
  final childFormats = childBlot.formats()[childBlot.blotName];
  return (formats, getCellId(childFormats) ?? '');
}

/// TS `getCellId` (formats may be the id string itself or a props map).
String? getCellId(dynamic formats) {
  if (formats is Map) return formats['cellId'] as String?;
  return formats as String?;
}

/// TS `getClosestElement` (`element.closest(selector)`).
///
/// The platform DOM abstraction has no `closest`; this walks up the tree with
/// a minimal selector matcher supporting `tag`, `.class` and `tag.class`.
DomElement? getClosestElement(DomElement element, String selector) {
  final dotIndex = selector.indexOf('.');
  final tag = dotIndex == 0
      ? null
      : (dotIndex == -1 ? selector : selector.substring(0, dotIndex))
          .trim()
          .toUpperCase();
  final className =
      dotIndex == -1 ? null : selector.substring(dotIndex + 1).trim();

  bool matches(DomElement el) {
    if (tag != null && tag.isNotEmpty && el.tagName.toUpperCase() != tag) {
      return false;
    }
    if (className != null && className.isNotEmpty) {
      return el.classes.contains(className);
    }
    return true;
  }

  DomNode? current = element;
  while (current != null) {
    if (current is DomElement && matches(current)) return current;
    current = current.parentNode;
  }
  return null;
}

/// TS `getComputeBounds`.
CorrectBound getComputeBounds(
  CorrectBound startCorrectBounds,
  CorrectBound endCorrectBounds,
) {
  final left = startCorrectBounds.left < endCorrectBounds.left
      ? startCorrectBounds.left
      : endCorrectBounds.left;
  final right = startCorrectBounds.right > endCorrectBounds.right
      ? startCorrectBounds.right
      : endCorrectBounds.right;
  final top = startCorrectBounds.top < endCorrectBounds.top
      ? startCorrectBounds.top
      : endCorrectBounds.top;
  final bottom = startCorrectBounds.bottom > endCorrectBounds.bottom
      ? startCorrectBounds.bottom
      : endCorrectBounds.bottom;
  return CorrectBound(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    width: right - left,
    height: bottom - top,
  );
}

/// TS `getComputeSelectedCols`.
///
/// Adapted: takes the [TableContainer] blot directly instead of resolving it
/// with `Quill.find`. Layout-dependent (see [elementRectResolver]).
List<DomElement> getComputeSelectedCols(
  CorrectBound computeBounds,
  TableContainer table,
  DomElement container,
) {
  final selectedCols = <DomElement>[];
  var correctLeft = 0.0;
  for (final col in table.descendants<TableCol>()) {
    final bounds = getCorrectBounds(col.element, container);
    correctLeft = correctLeft != 0 ? correctLeft : bounds.left;
    if (correctLeft + deviation >= computeBounds.left &&
        correctLeft - deviation + bounds.width <= computeBounds.right) {
      selectedCols.add(col.element);
    }
    correctLeft += bounds.width;
  }
  return selectedCols;
}

/// TS `getComputeSelectedTds`.
///
/// Adapted: takes the [TableContainer] blot directly instead of resolving it
/// with `Quill.find`. Layout-dependent (see [elementRectResolver]).
List<DomElement> getComputeSelectedTds(
  CorrectBound computeBounds,
  TableContainer table,
  DomElement container, [
  String? type,
]) {
  final selectedTds = <DomElement>[];
  for (final tableCell in table.descendants<TableCell>()) {
    final bounds = getCorrectBounds(tableCell.element, container);
    final left = bounds.left;
    final top = bounds.top;
    final width = bounds.width;
    final height = bounds.height;
    switch (type) {
      case 'column':
        if (left + deviation >= computeBounds.left &&
            left - deviation + width <= computeBounds.right) {
          selectedTds.add(tableCell.element);
        } else if (left + deviation < computeBounds.right &&
            computeBounds.right < left - deviation + width) {
          selectedTds.add(tableCell.element);
        } else if (computeBounds.left > left + deviation &&
            computeBounds.left < left - deviation + width) {
          selectedTds.add(tableCell.element);
        }
        break;
      case 'row':
        break;
      default:
        if (left + deviation >= computeBounds.left &&
            left - deviation + width <= computeBounds.right &&
            top + deviation >= computeBounds.top &&
            top - deviation + height <= computeBounds.bottom) {
          selectedTds.add(tableCell.element);
        }
        break;
    }
  }
  return selectedTds;
}

/// TS `getCopyTd` (strips selection/table classes and data attributes from a
/// copied `<td>` fragment).
String getCopyTd(String html) {
  return html
      .replaceAll(RegExp(r'data-(?!list)[a-z]+="[^"]*"'), '')
      .replaceAllMapped(RegExp(r'class="[^"]*"'), (match) {
        return match
            .group(0)!
            .replaceAll(RegExp(r'ql-cell-[^"]*'), '')
            .replaceFirst(RegExp(r'ql-table-[^"]*'), '')
            .replaceAll(RegExp(r'table-list(?:[^"]*)?'), '');
      })
      .replaceAll(RegExp(r'class="\s*"'), '');
}

/// TS `getCorrectBounds`. Layout-dependent (see [elementRectResolver]).
CorrectBound getCorrectBounds(DomElement target, [DomElement? container]) {
  container ??= target;
  final targetBounds = elementRectResolver(target);
  final containerBounds = elementRectResolver(container);
  final left = targetBounds.left - containerBounds.left - container.scrollLeft;
  final top = targetBounds.top - containerBounds.top - container.scrollTop;
  final width = targetBounds.width;
  final height = targetBounds.height;
  return CorrectBound(
    left: left,
    top: top,
    width: width,
    height: height,
    right: left + width,
    bottom: top + height,
  );
}

/// TS `getCorrectCellBlot` (walks up to the nearest `table-cell`/`table-th`).
TableCell? getCorrectCellBlot(Blot? blot) {
  while (blot != null) {
    if (blot.blotName == TableCell.kBlotName ||
        blot.blotName == TableTh.kBlotName) {
      return blot as TableCell;
    }
    blot = blot.parent;
  }
  return null;
}

/// TS `getCorrectContainerWidth`.
///
/// TODO(table-better): the TS version subtracts the editor's computed
/// horizontal padding; computed styles are unavailable through the platform
/// abstraction, so this falls back to the raw `clientWidth`.
double getCorrectContainerWidth() {
  final container = domBindings.adapter.document.querySelector('.ql-editor');
  if (container == null) {
    throw StateError('table-better: no .ql-editor container found');
  }
  return container.clientWidth.toDouble();
}

/// TS `getCorrectWidth`.
String getCorrectWidth(double width, bool isPercent) {
  if (!isPercent) return '${formatNum(width)}px';
  final w = getCorrectContainerWidth();
  return '${((width / w) * 100).toStringAsFixed(2)}%';
}

/// TS `getElementStyle`.
///
/// TODO(table-better): computed styles are unavailable through the platform
/// abstraction; only inline styles (the `style` attribute) are read.
Map<String, String> getElementStyle(DomElement node, List<String> rules) {
  final inline = parseInlineStyle(node);
  return {
    for (final rule in rules) rule: rgbToHex(inline[rule] ?? ''),
  };
}

/// TS `isDimensions`.
bool isDimensions(String key) {
  if (key.endsWith('width') || key.endsWith('height')) return true;
  return false;
}

bool _isSimpleColor(String color) => colors.contains(color);

/// TS `isValidColor`.
bool isValidColor(String color) {
  if (color.isEmpty) return true;
  final hexRegex = RegExp(r'^#([A-Fa-f0-9]{3,6})$');
  final rgbRegex = RegExp(r'^rgb\((\d{1,3}), (\d{1,3}), (\d{1,3})\)$');
  if (hexRegex.hasMatch(color)) return true;
  if (rgbRegex.hasMatch(color)) return true;
  return _isSimpleColor(color);
}

/// TS `isValidDimensions`.
bool isValidDimensions(String value) {
  if (value.isEmpty) return true;
  final unit = value.replaceFirst(RegExp(r'\d+\.?\d*'), '');
  if (unit.isEmpty) return true;
  if (unit != 'px' && unit != 'em' && unit != '%') {
    return !RegExp(r'[a-z]').hasMatch(unit) && double.tryParse(unit) != null;
  }
  return true;
}

/// Parses the inline `style` attribute into a declaration map.
///
/// Adaptation detail: the TS code manipulates `CSSStyleDeclaration`; the
/// platform abstraction has no typed style object, so table-better reads and
/// writes the `style` attribute directly.
Map<String, String> parseInlineStyle(DomElement node) {
  final styles = <String, String>{};
  final raw = node.getAttribute('style');
  if (raw == null || raw.trim().isEmpty) return styles;
  for (final declaration in raw.split(';')) {
    final index = declaration.indexOf(':');
    if (index <= 0) continue;
    final key = declaration.substring(0, index).trim();
    final value = declaration.substring(index + 1).trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      styles[key] = value;
    }
  }
  return styles;
}

/// Returns one inline style declaration value, or null.
String? getInlineStyleValue(DomElement node, String property) =>
    parseInlineStyle(node)[property];

void _writeInlineStyle(DomElement node, Map<String, String> styles) {
  if (styles.isEmpty) {
    node.removeAttribute('style');
    return;
  }
  final serialized =
      styles.entries.map((e) => '${e.key}: ${e.value};').join(' ');
  node.setAttribute('style', serialized);
}

/// TS `removeElementProperty`.
void removeElementProperty(DomElement node, List<String> properties) {
  final styles = parseInlineStyle(node);
  for (final property in properties) {
    styles.remove(property);
  }
  _writeInlineStyle(node, styles);
}

/// TS `rgbToHex`.
String rgbToHex(String value) {
  if (value.startsWith('rgba(')) return rgbaToHex(value);
  if (!value.startsWith('rgb(')) return value;
  final inner = value
      .replaceFirst(RegExp(r'^[^\d]+'), '')
      .replaceFirst(RegExp(r'[^\d]+$'), '');
  final hex = inner
      .split(',')
      .map((component) =>
          (int.tryParse(component.trim()) ?? 0).toRadixString(16).padLeft(2, '0'))
      .join();
  return '#$hex';
}

/// TS `rgbaToHex`.
///
/// Deviation: the TS version indexes characters of the stripped string
/// (`value[0]` is the first character, not the first component) which is a
/// latent bug; this port splits the components as clearly intended.
String rgbaToHex(String value) {
  final inner = value
      .replaceFirst(RegExp(r'^[^\d]+'), '')
      .replaceFirst(RegExp(r'[^\d]+$'), '');
  final parts = inner.split(',').map((p) => p.trim()).toList();
  if (parts.length < 4) return value;
  final r = (double.tryParse(parts[0]) ?? 0).round();
  final g = (double.tryParse(parts[1]) ?? 0).round();
  final b = (double.tryParse(parts[2]) ?? 0).round();
  final a = ((double.tryParse(parts[3]) ?? 0) * 255)
      .round()
      .toRadixString(16)
      .toUpperCase()
      .padLeft(2, '0');
  final rgb =
      ((1 << 24) + (r << 16) + (g << 8) + b).toRadixString(16).substring(1);
  return '#$rgb$a';
}

/// TS `setElementAttribute`.
void setElementAttribute(DomElement node, Map<String, String> attributes) {
  for (final entry in attributes.entries) {
    node.setAttribute(entry.key, entry.value);
  }
}

/// TS `setElementProperty` (merges declarations into the inline style).
void setElementProperty(DomElement node, Map<String, String> properties) {
  final styles = parseInlineStyle(node);
  styles.addAll(properties);
  _writeInlineStyle(node, styles);
}

/// TS `throttle`. Adapted to a zero-argument callback.
void Function() throttle(void Function() cb, int delayMs) {
  var last = 0;
  return () {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last >= delayMs) {
      last = now;
      cb();
    }
  };
}

/// TS `throttleStrong`. Adapted to a zero-argument callback.
void Function() throttleStrong(void Function() cb, int delayMs) {
  var last = 0;
  Timer? timer;
  return () {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < delayMs) {
      timer?.cancel();
      timer = Timer(Duration(milliseconds: delayMs), () {
        last = now;
        cb();
      });
    } else {
      last = now;
      cb();
    }
  };
}

/// Formats a number the way JS string interpolation would (no trailing `.0`).
String formatNum(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}

/// TS `updateTableWidth`.
///
/// Adapted: takes the [TableContainer] blot directly instead of resolving the
/// table element with `Quill.find`. The non-colgroup / percent paths are
/// layout-dependent (see [getCorrectWidth]).
void updateTableWidth(
  TableContainer tableBlot,
  CorrectBound tableBounds,
  double change,
) {
  final isPercent = tableBlot.isPercent();
  if (isPercent && change == 0) return;
  final colgroup = tableBlot.colgroup();
  final temporary = tableBlot.temporary();
  if (temporary == null) return;
  if (colgroup != null) {
    if (isPercent) {
      var width = 0.0;
      for (final col in colgroup.element.querySelectorAll('col')) {
        final raw = getInlineStyleValue(col, 'width');
        if (raw != null && raw.isNotEmpty) {
          width += double.tryParse(raw.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0;
        }
      }
      setElementProperty(temporary.element, {'width': '${formatNum(width)}%'});
    } else {
      var width = 0;
      for (final col in colgroup.element.querySelectorAll('col')) {
        width += int.tryParse(col.getAttribute('width') ?? '') ?? 0;
      }
      setElementProperty(temporary.element, {
        'width': getCorrectWidth(width.toDouble(), isPercent),
      });
    }
  } else {
    setElementProperty(temporary.element, {
      'width': getCorrectWidth(tableBounds.width + change, isPercent),
    });
  }
}
