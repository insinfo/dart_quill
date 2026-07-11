import '../dataset/enum/common.dart';
import '../dataset/enum/control.dart';
import '../dataset/enum/element.dart';
import '../dataset/enum/list.dart';
import '../dataset/enum/row.dart';
import '../dataset/enum/title.dart';
import '../dataset/enum/table/table.dart';
import './area.dart';
import './block.dart';
import './checkbox.dart';
import './control.dart';
import './label.dart';
import './radio.dart';
import './text.dart';
import './title.dart';
import './table/colgroup.dart';
import './table/tr.dart';

export './area.dart';
export './block.dart';
export './checkbox.dart';
export './common.dart';
export './control.dart';
export './label.dart';
export './radio.dart';
export './text.dart';
export './title.dart';
export './table/colgroup.dart';
export './table/tr.dart';

class IElementBasic {
  String? id;
  ElementType? type;
  String value;
  dynamic extension;
  String? externalId;

  IElementBasic({
    this.id,
    this.type,
    required this.value,
    this.extension,
    this.externalId,
  });
}

class IElementStyle {
  String? font;
  int? size;
  double? width;
  double? height;
  bool? bold;
  String? color;
  String? highlight;
  bool? italic;
  bool? underline;
  bool? strikeout;
  RowFlex? rowFlex;
  double? rowMargin;
  double? letterSpacing;
  ITextDecoration? textDecoration;

  IElementStyle({
    this.font,
    this.size,
    this.width,
    this.height,
    this.bold,
    this.color,
    this.highlight,
    this.italic,
    this.underline,
    this.strikeout,
    this.rowFlex,
    this.rowMargin,
    this.letterSpacing,
    this.textDecoration,
  });
}

class IElementRule {
  bool? hide;

  IElementRule({
    this.hide,
  });
}

class IElementGroup {
  List<String>? groupIds;

  IElementGroup({
    this.groupIds,
  });
}

class ITitleElement {
  List<IElement>? valueList;
  TitleLevel? level;
  String? titleId;
  ITitle? title;

  ITitleElement({
    this.valueList,
    this.level,
    this.titleId,
    this.title,
  });
}

class IListElement {
  List<IElement>? valueList;
  ListType? listType;
  ListStyle? listStyle;
  String? listId;
  bool? listWrap;

  IListElement({
    this.valueList,
    this.listType,
    this.listStyle,
    this.listId,
    this.listWrap,
  });
}

class ITableAttr {
  List<IColgroup>? colgroup;
  List<ITr>? trList;
  TableBorder? borderType;
  String? borderColor;
  double? borderWidth;
  double? borderExternalWidth;
  double? translateX;

  ITableAttr({
    this.colgroup,
    this.trList,
    this.borderType,
    this.borderColor,
    this.borderWidth,
    this.borderExternalWidth,
    this.translateX,
  });
}

class ITableRule {
  bool? tableToolDisabled;

  ITableRule({
    this.tableToolDisabled,
  });
}

class ITableElement {
  String? tdId;
  String? trId;
  String? tableId;
  String? conceptId;
  String? pagingId;
  int? pagingIndex;

  ITableElement({
    this.tdId,
    this.trId,
    this.tableId,
    this.conceptId,
    this.pagingId,
    this.pagingIndex,
  });
}

class ITable implements ITableAttr, ITableRule, ITableElement {
  // ITableAttr
  @override
  List<IColgroup>? colgroup;
  @override
  List<ITr>? trList;
  @override
  TableBorder? borderType;
  @override
  String? borderColor;
  @override
  double? borderWidth;
  @override
  double? borderExternalWidth;
  @override
  double? translateX;

  // ITableRule
  @override
  bool? tableToolDisabled;

  // ITableElement
  @override
  String? tdId;
  @override
  String? trId;
  @override
  String? tableId;
  @override
  String? conceptId;
  @override
  String? pagingId;
  @override
  int? pagingIndex;

  ITable({
    this.colgroup,
    this.trList,
    this.borderType,
    this.borderColor,
    this.borderWidth,
    this.borderExternalWidth,
    this.translateX,
    this.tableToolDisabled,
    this.tdId,
    this.trId,
    this.tableId,
    this.conceptId,
    this.pagingId,
    this.pagingIndex,
  });
}

class IHyperlinkElement {
  List<IElement>? valueList;
  String? url;
  String? hyperlinkId;

  IHyperlinkElement({
    this.valueList,
    this.url,
    this.hyperlinkId,
  });
}

class ISuperscriptSubscript {
  int? actualSize;

  ISuperscriptSubscript({
    this.actualSize,
  });
}

class ISeparator {
  List<double>? dashArray;

  ISeparator({
    this.dashArray,
  });
}

class IControlElement {
  IControl? control;
  String? controlId;
  ControlComponent? controlComponent;

  IControlElement({
    this.control,
    this.controlId,
    this.controlComponent,
  });
}

class ICheckboxElement {
  ICheckbox? checkbox;

  ICheckboxElement({
    this.checkbox,
  });
}

class IRadioElement {
  IRadio? radio;

  IRadioElement({
    this.radio,
  });
}

class ILaTexElement {
  String? laTexSVG;

  ILaTexElement({
    this.laTexSVG,
  });
}

class IDateElement {
  String? dateFormat;
  String? dateId;

  IDateElement({
    this.dateFormat,
    this.dateId,
  });
}

class IImageCrop {
  num x;
  num y;
  num width;
  num height;

  IImageCrop({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class IImageCaption {
  String value;
  String? color;
  String? font;
  num? size;
  num? top;

  IImageCaption({
    required this.value,
    this.color,
    this.font,
    this.size,
    this.top,
  });
}

class IImgCaptionOption {
  final String? color;
  final String? font;
  final num? size;
  final num? top;

  const IImgCaptionOption({
    this.color,
    this.font,
    this.size,
    this.top,
  });
}

class IImageRule {
  bool? imgToolDisabled;

  IImageRule({
    this.imgToolDisabled,
  });
}

class IImageBasic {
  ImageDisplay? imgDisplay;
  Map<String, num>? imgFloatPosition;
  IImageCrop? imgCrop;
  IImageCaption? imgCaption;

  IImageBasic({
    this.imgDisplay,
    this.imgFloatPosition,
    this.imgCrop,
    this.imgCaption,
  });
}

class IImageElement implements IImageBasic, IImageRule {
  // IImageBasic
  @override
  ImageDisplay? imgDisplay;
  @override
  Map<String, num>? imgFloatPosition;
  @override
  IImageCrop? imgCrop;
  @override
  IImageCaption? imgCaption;

  // IImageRule
  @override
  bool? imgToolDisabled;

  IImageElement({
    this.imgDisplay,
    this.imgFloatPosition,
    this.imgCrop,
    this.imgCaption,
    this.imgToolDisabled,
  });
}

class IBlockElement {
  IBlock? block;

  IBlockElement({
    this.block,
  });
}

class IAreaElement {
  List<IElement>? valueList;
  String? areaId;
  int? areaIndex;
  IArea? area;

  IAreaElement({
    this.valueList,
    this.areaId,
    this.areaIndex,
    this.area,
  });
}

class ILabelElement {
  String? labelId;
  ILabelStyle? label;

  ILabelElement({
    this.labelId,
    this.label,
  });
}

class IElement
    implements
        IElementBasic,
        IElementStyle,
        IElementRule,
        IElementGroup,
        ITable,
        IHyperlinkElement,
        ISuperscriptSubscript,
        ISeparator,
        IControlElement,
        ICheckboxElement,
        IRadioElement,
        ILaTexElement,
        IDateElement,
        IImageElement,
        IBlockElement,
        ITitleElement,
        IListElement,
        IAreaElement,
        ILabelElement {
  // IElementBasic
  @override
  String? id;
  @override
  ElementType? type;
  @override
  String value;
  @override
  dynamic extension;
  @override
  String? externalId;

  // IElementStyle
  @override
  String? font;
  @override
  int? size;
  @override
  double? width;
  @override
  double? height;
  @override
  bool? bold;
  @override
  String? color;
  @override
  String? highlight;
  @override
  bool? italic;
  @override
  bool? underline;
  @override
  bool? strikeout;
  @override
  RowFlex? rowFlex;
  @override
  double? rowMargin;
  @override
  double? letterSpacing;
  @override
  ITextDecoration? textDecoration;

  // Espaçamento Word-fiel (roteiro F4.3, doc/plano_otimizacao_performance):
  // `w:spacing` do pPr efetivo do DOCX. Quando lineSpacingRule != null o
  // layout calcula a altura da linha pelas métricas da FONTE (como o Word)
  // em vez do padding fixo do editor (defaultBasicRowMarginHeight).
  /// 'auto' (value = múltiplo de single), 'atLeast' ou 'exact' (value = px).
  String? lineSpacingRule;
  double? lineSpacingValue;
  /// `w:before`/`w:after` do parágrafo em px (aplicados no offsetY da
  /// primeira linha do parágrafo/do seguinte).
  double? paraSpacingBefore;
  double? paraSpacingAfter;

  /// `w:ind` do parágrafo em px (F4.2): recuo à esquerda de todas as linhas
  /// e delta da primeira linha (firstLine positivo, hanging negativo).
  double? paraIndentLeft;
  double? paraIndentFirstLine;

  // IElementRule
  @override
  bool? hide;

  // IElementGroup
  @override
  List<String>? groupIds;

  // ITable
  @override
  List<IColgroup>? colgroup;
  @override
  List<ITr>? trList;

  /// Estado transitório do table paging (F4.5/F5): quando uma parte de tabela
  /// dividida foi particionada no render [tablePartRenderId], o layout emite
  /// direto a geometria [tablePartHeight] sem re-executar o setup O(linhas)
  /// da tabela — evita o custo O(partes×linhas) numa tabela de milhares de
  /// linhas. Não serializado.
  int? tablePartRenderId;
  double? tablePartHeight;

  /// Cache de posições de célula (perf de digitação): `tablePreY`/`pageNo` da
  /// última vez que as posições das células desta parte de tabela foram
  /// calculadas. Se a tabela não se moveu (mesmo tablePreY e pageNo), as
  /// posições absolutas das células são idênticas — `computePositionList` pula
  /// o recálculo. Sem isso, cada tecla recomputava TODAS as células da tabela
  /// gigante do TR (94% do conteúdo), custando ~250-450 ms/tecla. Não serializado.
  double? lastPositionedTablePreY;
  int? lastPositionedPageNo;
  @override
  TableBorder? borderType;
  @override
  String? borderColor;
  @override
  double? borderWidth;
  @override
  double? borderExternalWidth;
  @override
  double? translateX;
  @override
  bool? tableToolDisabled;
  @override
  String? tdId;
  @override
  String? trId;
  @override
  String? tableId;
  @override
  String? conceptId;
  @override
  String? pagingId;
  @override
  int? pagingIndex;

  // IHyperlinkElement
  @override
  List<IElement>? valueList;
  @override
  String? url;
  @override
  String? hyperlinkId;

  // ISuperscriptSubscript
  @override
  int? actualSize;

  // ISeparator
  @override
  List<double>? dashArray;

  // IControlElement
  @override
  IControl? control;
  @override
  String? controlId;
  @override
  ControlComponent? controlComponent;

  // ICheckboxElement
  @override
  ICheckbox? checkbox;

  // IRadioElement
  @override
  IRadio? radio;

  // ILaTexElement
  @override
  String? laTexSVG;

  // IDateElement
  @override
  String? dateFormat;
  @override
  String? dateId;

  // IImageElement
  @override
  ImageDisplay? imgDisplay;
  @override
  Map<String, num>? imgFloatPosition;
  @override
  IImageCrop? imgCrop;
  @override
  IImageCaption? imgCaption;
  @override
  bool? imgToolDisabled;

  // IBlockElement
  @override
  IBlock? block;

  // ITitleElement
  @override
  TitleLevel? level;
  @override
  String? titleId;
  @override
  ITitle? title;

  // IListElement
  @override
  ListType? listType;
  @override
  ListStyle? listStyle;
  @override
  String? listId;
  @override
  bool? listWrap;

  // IAreaElement
  @override
  String? areaId;
  @override
  int? areaIndex;
  @override
  IArea? area;

  // ILabelElement
  @override
  String? labelId;
  @override
  ILabelStyle? label;

  IElement({
    // IElementBasic
    this.id,
    this.type,
    required this.value,
    this.extension,
    this.externalId,
    // IElementStyle
    this.font,
    this.size,
    this.width,
    this.height,
    this.bold,
    this.color,
    this.highlight,
    this.italic,
    this.underline,
    this.strikeout,
    this.rowFlex,
    this.rowMargin,
    this.letterSpacing,
    this.textDecoration,
    this.lineSpacingRule,
    this.lineSpacingValue,
    this.paraSpacingBefore,
    this.paraSpacingAfter,
    this.paraIndentLeft,
    this.paraIndentFirstLine,
    // IElementRule
    this.hide,
    // IElementGroup
    this.groupIds,
    // ITable
    this.colgroup,
    this.trList,
    this.borderType,
    this.borderColor,
    this.borderWidth,
    this.borderExternalWidth,
    this.translateX,
    this.tableToolDisabled,
    this.tdId,
    this.trId,
    this.tableId,
    this.conceptId,
    this.pagingId,
    this.pagingIndex,
    // IHyperlinkElement
    this.valueList,
    this.url,
    this.hyperlinkId,
    // ISuperscriptSubscript
    this.actualSize,
    // ISeparator
    this.dashArray,
    // IControlElement
    this.control,
    this.controlId,
    this.controlComponent,
    // ICheckboxElement
    this.checkbox,
    // IRadioElement
    this.radio,
    // ILaTexElement
    this.laTexSVG,
    // IDateElement
    this.dateFormat,
    this.dateId,
    // IImageElement
    this.imgDisplay,
    this.imgFloatPosition,
    this.imgCrop,
    this.imgCaption,
    this.imgToolDisabled,
    // IBlockElement
    this.block,
    // ITitleElement
    this.level,
    this.titleId,
    this.title,
    // IListElement
    this.listType,
    this.listStyle,
    this.listId,
    this.listWrap,
    // IAreaElement
    this.areaId,
    this.areaIndex,
    this.area,
    // ILabelElement
    this.labelId,
    this.label,
  });
}

class IElementMetrics {
  double width;
  double height;
  double boundingBoxAscent;
  double boundingBoxDescent;

  IElementMetrics({
    required this.width,
    required this.height,
    required this.boundingBoxAscent,
    required this.boundingBoxDescent,
  });
}

class IElementPosition {
  int pageNo;
  int index;
  String value;
  int rowIndex;
  int rowNo;
  double ascent;
  double lineHeight;
  double left;
  IElementMetrics metrics;
  bool isFirstLetter;
  bool isLastLetter;

  /// Canto superior esquerdo do elemento. Os quatro cantos do [coordinate]
  /// são deriváveis de (coordX, coordY, metrics.width, lineHeight); guardar
  /// só os dois doubles evita 5 alocações (1 Map + 4 List) por elemento por
  /// render (plano de otimização A4).
  double coordX;
  double coordY;
  Map<String, List<double>>? _coordinate;

  IElementPosition({
    required this.pageNo,
    required this.index,
    required this.value,
    required this.rowIndex,
    required this.rowNo,
    required this.ascent,
    required this.lineHeight,
    required this.left,
    required this.metrics,
    required this.isFirstLetter,
    required this.isLastLetter,
    this.coordX = 0,
    this.coordY = 0,
    Map<String, List<double>>? coordinate,
  }) : _coordinate = coordinate;

  /// Materializado sob demanda (lazy) e cacheado; a maioria das posições
  /// nunca tem as coordenadas lidas entre um render e o seguinte.
  Map<String, List<double>> get coordinate {
    return _coordinate ??= <String, List<double>>{
      'leftTop': <double>[coordX, coordY],
      'leftBottom': <double>[coordX, coordY + lineHeight],
      'rightTop': <double>[coordX + metrics.width, coordY],
      'rightBottom': <double>[coordX + metrics.width, coordY + lineHeight],
    };
  }

  set coordinate(Map<String, List<double>> value) {
    _coordinate = value;
  }
}

class IElementFillRect {
  double x;
  double y;
  double width;
  double height;

  IElementFillRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class IUpdateElementByIdOption {
  String? id;
  String? conceptId;
  IElement properties;

  IUpdateElementByIdOption({
    this.id,
    this.conceptId,
    required this.properties,
  });
}

class IDeleteElementByIdOption {
  String? id;
  String? conceptId;

  IDeleteElementByIdOption({
    this.id,
    this.conceptId,
  });
}

class IGetElementByIdOption {
  String? id;
  String? conceptId;

  IGetElementByIdOption({
    this.id,
    this.conceptId,
  });
}

class IInsertElementListOption {
  bool? isReplace;
  bool? isSubmitHistory;
  bool? isSubmitHistoryDeferred;
  bool? isFastLayout;
  bool? isDeltaHistory;

  IInsertElementListOption({
    this.isReplace,
    this.isSubmitHistory,
    this.isSubmitHistoryDeferred,
    this.isFastLayout,
    this.isDeltaHistory,
  });
}

class ISpliceElementListOption {
  bool? isIgnoreDeletedRule;

  ISpliceElementListOption({
    this.isIgnoreDeletedRule,
  });
}
