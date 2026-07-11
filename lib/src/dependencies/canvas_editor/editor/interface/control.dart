import '../dataset/enum/common.dart';
import '../dataset/enum/control.dart';
import '../dataset/enum/editor.dart';
import '../dataset/enum/observer.dart';
import '../dataset/enum/row.dart';
import './element.dart';
import './position.dart';
import './range.dart';
import './row.dart';

class IValueSet {
  String value;
  String code;

  IValueSet({required this.value, required this.code});
}

class IControlSelect {
  String? code;
  List<IValueSet> valueSets;
  bool? isMultiSelect;
  String? multiSelectDelimiter;
  Map<String, bool>? selectExclusiveOptions;

  IControlSelect({
    this.code,
    required this.valueSets,
    this.isMultiSelect,
    this.multiSelectDelimiter,
    this.selectExclusiveOptions,
  });
}

class IControlCheckbox {
  String? code;
  int? min;
  int? max;
  FlexDirection flexDirection;
  List<IValueSet> valueSets;

  IControlCheckbox({
    this.code,
    this.min,
    this.max,
    required this.flexDirection,
    required this.valueSets,
  });
}

class IControlRadio {
  String? code;
  FlexDirection flexDirection;
  List<IValueSet> valueSets;

  IControlRadio({
    this.code,
    required this.flexDirection,
    required this.valueSets,
  });
}

class IControlDate {
  String? dateFormat;

  IControlDate({this.dateFormat});
}

class IControlHighlightRule {
  String keyword;
  double? alpha;
  String? backgroundColor;

  IControlHighlightRule({
    required this.keyword,
    this.alpha,
    this.backgroundColor,
  });
}

class IControlHighlight {
  List<IControlHighlightRule> ruleList;
  String? id;
  String? conceptId;

  IControlHighlight({
    required this.ruleList,
    this.id,
    this.conceptId,
  });
}

class IControlRule {
  bool? deletable;
  bool? disabled;
  bool? pasteDisabled;
  bool? hide;

  IControlRule({
    this.deletable,
    this.disabled,
    this.pasteDisabled,
    this.hide,
  });
}

class IControlBasic {
  ControlType type;
  List<IElement>? value;
  String? placeholder;
  String? conceptId;
  String? groupId;
  String? prefix;
  String? postfix;
  double? minWidth;
  bool? underline;
  bool? border;
  dynamic extension;
  ControlIndentation? indentation;
  RowFlex? rowFlex;
  String? preText;
  String? postText;

  IControlBasic({
    required this.type,
    this.value,
    this.placeholder,
    this.conceptId,
    this.groupId,
    this.prefix,
    this.postfix,
    this.minWidth,
    this.underline,
    this.border,
    this.extension,
    this.indentation,
    this.rowFlex,
    this.preText,
    this.postText,
  });
}

class IControlStyle {
  String? font;
  int? size;
  bool? bold;
  String? highlight;
  bool? italic;
  bool? strikeout;

  IControlStyle({
    this.font,
    this.size,
    this.bold,
    this.highlight,
    this.italic,
    this.strikeout,
  });
}

class IControl
    implements
        IControlBasic,
        IControlRule,
        IControlStyle,
        IControlSelect,
        IControlCheckbox,
        IControlRadio,
        IControlDate {
  // IControlBasic
  @override
  ControlType type;
  @override
  List<IElement>? value;
  @override
  String? placeholder;
  @override
  String? conceptId;
  @override
  String? groupId;
  @override
  String? prefix;
  @override
  String? postfix;
  @override
  double? minWidth;
  @override
  bool? underline;
  @override
  bool? border;
  @override
  dynamic extension;
  @override
  ControlIndentation? indentation;
  @override
  RowFlex? rowFlex;
  @override
  String? preText;
  @override
  String? postText;

  // IControlRule
  @override
  bool? deletable;
  @override
  bool? disabled;
  @override
  bool? pasteDisabled;
  @override
  bool? hide;

  // IControlStyle
  @override
  String? font;
  @override
  int? size;
  @override
  bool? bold;
  @override
  String? highlight;
  @override
  bool? italic;
  @override
  bool? strikeout;

  // IControlSelect
  @override
  String? code;
  @override
  List<IValueSet> valueSets;
  @override
  bool? isMultiSelect;
  @override
  String? multiSelectDelimiter;
  @override
  Map<String, bool>? selectExclusiveOptions;

  // IControlCheckbox
  @override
  int? min;
  @override
  int? max;
  @override
  FlexDirection flexDirection;

  // IControlRadio

  // IControlDate
  @override
  String? dateFormat;

  IControl({
    required this.type,
    this.value,
    this.placeholder,
    this.conceptId,
    this.groupId,
    this.prefix,
    this.postfix,
    this.minWidth,
    this.underline,
    this.border,
    this.extension,
    this.indentation,
    this.rowFlex,
    this.preText,
    this.postText,
    this.deletable,
    this.disabled,
    this.pasteDisabled,
    this.hide,
    this.font,
    this.size,
    this.bold,
    this.highlight,
    this.italic,
    this.strikeout,
    this.code,
    required this.valueSets,
    this.isMultiSelect,
    this.multiSelectDelimiter,
    this.selectExclusiveOptions,
    this.min,
    this.max,
    required this.flexDirection,
    this.dateFormat,
  });
}

class IControlOption {
  String? placeholderColor;
  String? bracketColor;
  String? prefix;
  String? postfix;
  double? borderWidth;
  String? borderColor;
  String? activeBackgroundColor;
  String? disabledBackgroundColor;
  String? existValueBackgroundColor;
  String? noValueBackgroundColor;

  IControlOption({
    this.placeholderColor,
    this.bracketColor,
    this.prefix,
    this.postfix,
    this.borderWidth,
    this.borderColor,
    this.activeBackgroundColor,
    this.disabledBackgroundColor,
    this.existValueBackgroundColor,
    this.noValueBackgroundColor,
  });
}

class IControlInitOption {
  int index;
  bool? isTable;
  int? trIndex;
  int? tdIndex;
  int? tdValueIndex;

  IControlInitOption({
    required this.index,
    this.isTable,
    this.trIndex,
    this.tdIndex,
    this.tdValueIndex,
  });
}

class IControlInitResult {
  int newIndex;

  IControlInitResult({required this.newIndex});
}

class IMoveCursorResult {
  int newIndex;
  IElement newElement;

  IMoveCursorResult({required this.newIndex, required this.newElement});
}

abstract class IControlInstance {
  void setElement(IElement element);
  IElement getElement();
  List<IElement> getValue({IControlContext? context});
  int setValue(List<IElement> data, {IControlContext? context, IControlRuleOption? options});
  int? keydown(dynamic evt);
  int cut();
}

class IControlContext {
  IRange? range;
  List<IElement>? elementList;

  IControlContext({this.range, this.elementList});
}

class IControlRuleOption {
  bool? isIgnoreDisabledRule;
  bool? isIgnoreDeletedRule;
  bool? isAddPlaceholder;

  IControlRuleOption({
    this.isIgnoreDisabledRule,
    this.isIgnoreDeletedRule,
    this.isAddPlaceholder,
  });
}

class IGetControlValueOption {
  String? id;
  String? groupId;
  String? conceptId;
  String? areaId;

  IGetControlValueOption({this.id, this.groupId, this.conceptId, this.areaId});
}

class IGetControlValueResult {
  // Properties from Omit<IControl, 'value'>
  ControlType type;
  String? placeholder;
  String? conceptId;
  String? groupId;
  String? prefix;
  String? postfix;
  double? minWidth;
  bool? underline;
  bool? border;
  dynamic extension;
  ControlIndentation? indentation;
  RowFlex? rowFlex;
  String? preText;
  String? postText;
  bool? deletable;
  bool? disabled;
  bool? pasteDisabled;
  bool? hide;
  String? font;
  int? size;
  bool? bold;
  String? highlight;
  bool? italic;
  bool? strikeout;
  String? code;
  List<IValueSet> valueSets;
  bool? isMultiSelect;
  String? multiSelectDelimiter;
  Map<String, bool>? selectExclusiveOptions;
  int? min;
  int? max;
  FlexDirection flexDirection;
  String? dateFormat;

  // Added properties
  String? value;
  String? innerText;
  EditorZone zone;
  List<IElement>? elementList;

  IGetControlValueResult({
    required this.type,
    this.placeholder,
    this.conceptId,
    this.groupId,
    this.prefix,
    this.postfix,
    this.minWidth,
    this.underline,
    this.border,
    this.extension,
    this.indentation,
    this.rowFlex,
    this.preText,
    this.postText,
    this.deletable,
    this.disabled,
    this.pasteDisabled,
    this.hide,
    this.font,
    this.size,
    this.bold,
    this.highlight,
    this.italic,
    this.strikeout,
    this.code,
    required this.valueSets,
    this.isMultiSelect,
    this.multiSelectDelimiter,
    this.selectExclusiveOptions,
    this.min,
    this.max,
    required this.flexDirection,
    this.dateFormat,
    this.value,
    this.innerText,
    required this.zone,
    this.elementList,
  });
}

class ISetControlValueOption {
  String? id;
  String? groupId;
  String? conceptId;
  String? areaId;
  dynamic value; // string | IElement[] | null
  bool? isSubmitHistory;

  ISetControlValueOption({
    this.id,
    this.groupId,
    this.conceptId,
    this.areaId,
    this.value,
    this.isSubmitHistory,
  });
}

class ISetControlExtensionOption {
  String? id;
  String? groupId;
  String? conceptId;
  String? areaId;
  dynamic extension;

  ISetControlExtensionOption({
    this.id,
    this.groupId,
    this.conceptId,
    this.areaId,
    required this.extension,
  });
}

typedef ISetControlHighlightOption = List<IControlHighlight>;

class ISetControlProperties {
  String? id;
  String? groupId;
  String? conceptId;
  String? areaId;
  IControl properties; // Partial<Omit<IControl, 'value'>>
  bool? isSubmitHistory;

  ISetControlProperties({
    this.id,
    this.groupId,
    this.conceptId,
    this.areaId,
    required this.properties,
    this.isSubmitHistory,
  });
}

class IRepaintControlOption {
  int? curIndex;
  bool? isCompute;
  bool? isSubmitHistory;
  bool? isSetCursor;

  IRepaintControlOption({
    this.curIndex,
    this.isCompute,
    this.isSubmitHistory,
    this.isSetCursor,
  });
}

class IControlChangeOption {
  IControlContext? context;
  IElement? controlElement;
  List<IElement>? controlValue;

  IControlChangeOption({
    this.context,
    this.controlElement,
    this.controlValue,
  });
}

class INextControlContext {
  IPositionContext positionContext;
  int nextIndex;

  INextControlContext({required this.positionContext, required this.nextIndex});
}

class IInitNextControlOption {
  MoveDirection? direction;

  IInitNextControlOption({this.direction});
}

class ILocationControlOption {
  LocationPosition position;

  ILocationControlOption({required this.position});
}

class ISetControlRowFlexOption {
  IRow row;
  IRowElement rowElement;
  double availableWidth;
  double controlRealWidth;

  ISetControlRowFlexOption({
    required this.row,
    required this.rowElement,
    required this.availableWidth,
    required this.controlRealWidth,
  });
}

class IControlChangeResult {
  ControlState state;
  IControl control;
  String controlId;

  IControlChangeResult({
    required this.state,
    required this.control,
    required this.controlId,
  });
}

class IControlContentChangeResult {
  IControl control;
  String controlId;

  IControlContentChangeResult({required this.control, required this.controlId});
}

class IDestroyControlOption {
  bool? isEmitEvent;

  IDestroyControlOption({this.isEmitEvent});
}

class IRemoveControlOption {
  String? id;
  String? conceptId;

  IRemoveControlOption({this.id, this.conceptId});
}