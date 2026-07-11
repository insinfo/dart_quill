/// Port of quill-table-better `src/config/index.ts` (v1.2.3).
///
/// Constants and the table/cell property-form descriptor builders used by the
/// properties dialog (the dialog itself belongs to the UI phase).
import '../utils/utils.dart';

/// Mirrors the TS `UseLanguageHandler` (resolves an i18n key to a label).
typedef UseLanguageHandler = String Function(String name);

/// Signature of the `valid` callbacks attached to property descriptors.
typedef PropertyValidator = bool Function(String value);

// TODO(table-better): the TS source imports SVG assets for these icons.
// They are represented as stable identifiers here; the UI phase maps them
// to real icon markup.
const String alignBottomIcon = 'align-bottom';
const String alignCenterIcon = 'align-center';
const String alignLeftIcon = 'align-left';
const String alignMiddleIcon = 'align-middle';
const String alignJustifyIcon = 'align-justify';
const String alignRightIcon = 'align-right';
const String alignTopIcon = 'align-top';

/// TS `CELL_ATTRIBUTE`.
const List<String> cellAttribute = [
  'data-row',
  'width',
  'height',
  'colspan',
  'rowspan',
  'style',
];

/// TS `CELL_DEFAULT_VALUES`.
const Map<String, String> cellDefaultValues = {
  'border-style': 'none',
  'border-color': '',
  'border-width': '',
  'background-color': '',
  'width': '',
  'height': '',
  'padding': '',
  'text-align': 'left',
  'vertical-align': 'middle',
};

/// TS `CELL_DEFAULT_WIDTH`.
const int cellDefaultWidth = 72;

/// TS `CELL_PROPERTIES`.
const List<String> cellProperties = [
  'border-style',
  'border-color',
  'border-width',
  'background-color',
  'width',
  'height',
  'padding',
  'text-align',
  'vertical-align',
];

/// TS `COLORS` (CSS named colors accepted by the color validator).
const List<String> colors = [
  'aliceblue',
  'antiquewhite',
  'aqua',
  'aquamarine',
  'azure',
  'beige',
  'bisque',
  'black',
  'blanchedalmond',
  'blue',
  'blueviolet',
  'brown',
  'burlywood',
  'cadetblue',
  'chartreuse',
  'chocolate',
  'coral',
  'cornflowerblue',
  'cornsilk',
  'crimson',
  'currentcolor',
  'cyan',
  'darkblue',
  'darkcyan',
  'darkgoldenrod',
  'darkgray',
  'darkgreen',
  'darkgrey',
  'darkkhaki',
  'darkmagenta',
  'darkolivegreen',
  'darkorange',
  'darkorchid',
  'darkred',
  'darksalmon',
  'darkseagreen',
  'darkslateblue',
  'darkslategray',
  'darkslategrey',
  'darkturquoise',
  'darkviolet',
  'deeppink',
  'deepskyblue',
  'dimgray',
  'dimgrey',
  'dodgerblue',
  'firebrick',
  'floralwhite',
  'forestgreen',
  'fuchsia',
  'gainsboro',
  'ghostwhite',
  'gold',
  'goldenrod',
  'gray',
  'green',
  'greenyellow',
  'grey',
  'honeydew',
  'hotpink',
  'indianred',
  'indigo',
  'ivory',
  'khaki',
  'lavender',
  'lavenderblush',
  'lawngreen',
  'lemonchiffon',
  'lightblue',
  'lightcoral',
  'lightcyan',
  'lightgoldenrodyellow',
  'lightgray',
  'lightgreen',
  'lightgrey',
  'lightpink',
  'lightsalmon',
  'lightseagreen',
  'lightskyblue',
  'lightslategray',
  'lightslategrey',
  'lightsteelblue',
  'lightyellow',
  'lime',
  'limegreen',
  'linen',
  'magenta',
  'maroon',
  'mediumaquamarine',
  'mediumblue',
  'mediumorchid',
  'mediumpurple',
  'mediumseagreen',
  'mediumslateblue',
  'mediumspringgreen',
  'mediumturquoise',
  'mediumvioletred',
  'midnightblue',
  'mintcream',
  'mistyrose',
  'moccasin',
  'navajowhite',
  'navy',
  'oldlace',
  'olive',
  'olivedrab',
  'orange',
  'orangered',
  'orchid',
  'palegoldenrod',
  'palegreen',
  'paleturquoise',
  'palevioletred',
  'papayawhip',
  'peachpuff',
  'peru',
  'pink',
  'plum',
  'powderblue',
  'purple',
  'rebeccapurple',
  'red',
  'rosybrown',
  'royalblue',
  'saddlebrown',
  'salmon',
  'sandybrown',
  'seagreen',
  'seashell',
  'sienna',
  'silver',
  'skyblue',
  'slateblue',
  'slategray',
  'slategrey',
  'snow',
  'springgreen',
  'steelblue',
  'tan',
  'teal',
  'thistle',
  'tomato',
  'transparent',
  'turquoise',
  'violet',
  'wheat',
  'white',
  'whitesmoke',
  'yellow',
  'yellowgreen',
];

/// TS `DEVIATION` (pixel tolerance for boundary matching).
const int deviation = 2;

/// TS `TABLE_PROPERTIES`.
const List<String> tableProperties = [
  'border-style',
  'border-color',
  'border-width',
  'background-color',
  'width',
  'height',
  'align',
];

/// Mirrors the TS `Options` interface passed to `getProperties`.
class PropertiesOptions {
  const PropertiesOptions({required this.type, required this.attribute});

  final String type;
  final Map<String, String> attribute;
}

/// A single entry of a `menus` category descriptor.
class PropertyMenu {
  const PropertyMenu({
    required this.icon,
    required this.describe,
    required this.align,
  });

  final String icon;
  final String describe;
  final String align;
}

/// One control of the properties form ("dropdown", "color", "input", "menus").
class PropertyDescriptor {
  const PropertyDescriptor({
    required this.category,
    required this.propertyName,
    this.value,
    this.options,
    this.attribute,
    this.valid,
    this.message,
    this.menus,
  });

  final String category;
  final String propertyName;
  final String? value;
  final List<String>? options;
  final Map<String, String>? attribute;
  final PropertyValidator? valid;
  final String? message;
  final List<PropertyMenu>? menus;
}

/// A titled group of controls (TS `properties[i]`).
class PropertyGroup {
  const PropertyGroup({required this.content, required this.children});

  final String content;
  final List<PropertyDescriptor> children;
}

/// The full form description (TS return value of `get*Properties`).
class PropertiesForm {
  const PropertiesForm({required this.title, required this.properties});

  final String title;
  final List<PropertyGroup> properties;
}

const List<String> _borderStyleOptions = [
  'dashed',
  'dotted',
  'double',
  'groove',
  'inset',
  'none',
  'outset',
  'ridge',
  'solid',
];

/// TS `getCellProperties`.
PropertiesForm getCellProperties(
  Map<String, String> attribute,
  UseLanguageHandler useLanguage,
) {
  return PropertiesForm(
    title: useLanguage('cellProps'),
    properties: [
      PropertyGroup(
        content: useLanguage('border'),
        children: [
          PropertyDescriptor(
            category: 'dropdown',
            propertyName: 'border-style',
            value: attribute['border-style'],
            options: _borderStyleOptions,
          ),
          PropertyDescriptor(
            category: 'color',
            propertyName: 'border-color',
            value: attribute['border-color'],
            attribute: {'type': 'text', 'placeholder': useLanguage('color')},
            valid: isValidColor,
            message: useLanguage('colorMsg'),
          ),
          PropertyDescriptor(
            category: 'input',
            propertyName: 'border-width',
            value: convertUnitToInteger(attribute['border-width']),
            attribute: {'type': 'text', 'placeholder': useLanguage('width')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
        ],
      ),
      PropertyGroup(
        content: useLanguage('background'),
        children: [
          PropertyDescriptor(
            category: 'color',
            propertyName: 'background-color',
            value: attribute['background-color'],
            attribute: {'type': 'text', 'placeholder': useLanguage('color')},
            valid: isValidColor,
            message: useLanguage('colorMsg'),
          ),
        ],
      ),
      PropertyGroup(
        content: useLanguage('dims'),
        children: [
          PropertyDescriptor(
            category: 'input',
            propertyName: 'width',
            value: convertUnitToInteger(attribute['width']),
            attribute: {'type': 'text', 'placeholder': useLanguage('width')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
          PropertyDescriptor(
            category: 'input',
            propertyName: 'height',
            value: convertUnitToInteger(attribute['height']),
            attribute: {'type': 'text', 'placeholder': useLanguage('height')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
          PropertyDescriptor(
            category: 'input',
            propertyName: 'padding',
            value: convertUnitToInteger(attribute['padding']),
            attribute: {'type': 'text', 'placeholder': useLanguage('padding')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
        ],
      ),
      PropertyGroup(
        content: useLanguage('tblCellTxtAlm'),
        children: [
          PropertyDescriptor(
            category: 'menus',
            propertyName: 'text-align',
            value: attribute['text-align'],
            menus: [
              PropertyMenu(
                  icon: alignLeftIcon,
                  describe: useLanguage('alCellTxtL'),
                  align: 'left'),
              PropertyMenu(
                  icon: alignCenterIcon,
                  describe: useLanguage('alCellTxtC'),
                  align: 'center'),
              PropertyMenu(
                  icon: alignRightIcon,
                  describe: useLanguage('alCellTxtR'),
                  align: 'right'),
              PropertyMenu(
                  icon: alignJustifyIcon,
                  describe: useLanguage('jusfCellTxt'),
                  align: 'justify'),
            ],
          ),
          PropertyDescriptor(
            category: 'menus',
            propertyName: 'vertical-align',
            value: attribute['vertical-align'],
            menus: [
              PropertyMenu(
                  icon: alignTopIcon,
                  describe: useLanguage('alCellTxtT'),
                  align: 'top'),
              PropertyMenu(
                  icon: alignMiddleIcon,
                  describe: useLanguage('alCellTxtM'),
                  align: 'middle'),
              PropertyMenu(
                  icon: alignBottomIcon,
                  describe: useLanguage('alCellTxtB'),
                  align: 'bottom'),
            ],
          ),
        ],
      ),
    ],
  );
}

/// TS `getTableProperties`.
PropertiesForm getTableProperties(
  Map<String, String> attribute,
  UseLanguageHandler useLanguage,
) {
  return PropertiesForm(
    title: useLanguage('tblProps'),
    properties: [
      PropertyGroup(
        content: useLanguage('border'),
        children: [
          PropertyDescriptor(
            category: 'dropdown',
            propertyName: 'border-style',
            value: attribute['border-style'],
            options: _borderStyleOptions,
          ),
          PropertyDescriptor(
            category: 'color',
            propertyName: 'border-color',
            value: attribute['border-color'],
            attribute: {'type': 'text', 'placeholder': useLanguage('color')},
            valid: isValidColor,
            message: useLanguage('colorMsg'),
          ),
          PropertyDescriptor(
            category: 'input',
            propertyName: 'border-width',
            value: convertUnitToInteger(attribute['border-width']),
            attribute: {'type': 'text', 'placeholder': useLanguage('width')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
        ],
      ),
      PropertyGroup(
        content: useLanguage('background'),
        children: [
          PropertyDescriptor(
            category: 'color',
            propertyName: 'background-color',
            value: attribute['background-color'],
            attribute: {'type': 'text', 'placeholder': useLanguage('color')},
            valid: isValidColor,
            message: useLanguage('colorMsg'),
          ),
        ],
      ),
      PropertyGroup(
        content: useLanguage('dimsAlm'),
        children: [
          PropertyDescriptor(
            category: 'input',
            propertyName: 'width',
            value: convertUnitToInteger(attribute['width']),
            attribute: {'type': 'text', 'placeholder': useLanguage('width')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
          PropertyDescriptor(
            category: 'input',
            propertyName: 'height',
            value: convertUnitToInteger(attribute['height']),
            attribute: {'type': 'text', 'placeholder': useLanguage('height')},
            valid: isValidDimensions,
            message: useLanguage('dimsMsg'),
          ),
          PropertyDescriptor(
            category: 'menus',
            propertyName: 'align',
            value: attribute['align'],
            menus: [
              PropertyMenu(
                  icon: alignLeftIcon,
                  describe: useLanguage('alTblL'),
                  align: 'left'),
              PropertyMenu(
                  icon: alignCenterIcon,
                  describe: useLanguage('tblC'),
                  align: 'center'),
              PropertyMenu(
                  icon: alignRightIcon,
                  describe: useLanguage('alTblR'),
                  align: 'right'),
            ],
          ),
        ],
      ),
    ],
  );
}

/// TS `getProperties`.
PropertiesForm getProperties(
  PropertiesOptions options,
  UseLanguageHandler useLanguage,
) {
  if (options.type == 'table') {
    return getTableProperties(options.attribute, useLanguage);
  }
  return getCellProperties(options.attribute, useLanguage);
}
