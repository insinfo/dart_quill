import '../dataset/enum/common.dart';
import '../dataset/enum/control.dart';
import '../dataset/enum/element.dart';
import '../dataset/enum/list.dart';
import '../dataset/enum/row.dart';
import '../dataset/enum/table/table.dart';
import '../dataset/enum/title.dart';
import './element.dart';

class IRowElement extends IElement {
  IElementMetrics metrics;
  String style;
  double? left;

  IRowElement({
    required this.metrics,
    required this.style,
    this.left,
    // Properties from IElement
    String? id,
    ElementType? type,
    required String value,
    dynamic extension,
    String? externalId,
    String? font,
    int? size,
    double? width,
    double? height,
    bool? bold,
    String? color,
    String? highlight,
    bool? italic,
    bool? underline,
    bool? strikeout,
    RowFlex? rowFlex,
    double? rowMargin,
    double? letterSpacing,
    ITextDecoration? textDecoration,
    bool? hide,
    List<String>? groupIds,
    List<IColgroup>? colgroup,
    List<ITr>? trList,
    TableBorder? borderType,
    String? borderColor,
    double? borderWidth,
    double? borderExternalWidth,
    double? translateX,
    bool? tableToolDisabled,
    String? tdId,
    String? trId,
    String? tableId,
    String? conceptId,
    String? pagingId,
    int? pagingIndex,
    List<IElement>? valueList,
    String? url,
    String? hyperlinkId,
    int? actualSize,
    List<double>? dashArray,
    IControl? control,
    String? controlId,
    ControlComponent? controlComponent,
    ICheckbox? checkbox,
    IRadio? radio,
    String? laTexSVG,
    String? dateFormat,
    String? dateId,
    ImageDisplay? imgDisplay,
    Map<String, num>? imgFloatPosition,
    IImageCrop? imgCrop,
    IImageCaption? imgCaption,
    bool? imgToolDisabled,
    IBlock? block,
    TitleLevel? level,
    String? titleId,
    ITitle? title,
    ListType? listType,
    ListStyle? listStyle,
    String? listId,
    bool? listWrap,
    String? areaId,
    int? areaIndex,
    IArea? area,
    String? labelId,
    ILabelStyle? label,
  }) : super(
          id: id,
          type: type,
          value: value,
          extension: extension,
          externalId: externalId,
          font: font,
          size: size,
          width: width,
          height: height,
          bold: bold,
          color: color,
          highlight: highlight,
          italic: italic,
          underline: underline,
          strikeout: strikeout,
          rowFlex: rowFlex,
          rowMargin: rowMargin,
          letterSpacing: letterSpacing,
          textDecoration: textDecoration,
          hide: hide,
          groupIds: groupIds,
          colgroup: colgroup,
          trList: trList,
          borderType: borderType,
          borderColor: borderColor,
          borderWidth: borderWidth,
          borderExternalWidth: borderExternalWidth,
          translateX: translateX,
          tableToolDisabled: tableToolDisabled,
          tdId: tdId,
          trId: trId,
          tableId: tableId,
          conceptId: conceptId,
          pagingId: pagingId,
          pagingIndex: pagingIndex,
          valueList: valueList,
          url: url,
          hyperlinkId: hyperlinkId,
          actualSize: actualSize,
          dashArray: dashArray,
          control: control,
          controlId: controlId,
          controlComponent: controlComponent,
          checkbox: checkbox,
          radio: radio,
          laTexSVG: laTexSVG,
          dateFormat: dateFormat,
          dateId: dateId,
          imgDisplay: imgDisplay,
          imgFloatPosition: imgFloatPosition,
          imgCrop: imgCrop,
          imgCaption: imgCaption,
          imgToolDisabled: imgToolDisabled,
          block: block,
          level: level,
          titleId: titleId,
          title: title,
          listType: listType,
          listStyle: listStyle,
          listId: listId,
          listWrap: listWrap,
          areaId: areaId,
          areaIndex: areaIndex,
          area: area,
          labelId: labelId,
          label: label,
        );
}

class IRow {
  double width;
  double height;
  double ascent;
  RowFlex? rowFlex;
  int startIndex;
  bool? isPageBreak;
  bool? isList;
  int? listIndex;
  double? offsetX;
  double? offsetY;
  List<IRowElement> elementList;
  bool? isWidthNotEnough;
  int rowIndex;
  bool? isSurround;

  IRow({
    required this.width,
    required this.height,
    required this.ascent,
    this.rowFlex,
    required this.startIndex,
    this.isPageBreak,
    this.isList,
    this.listIndex,
    this.offsetX,
    this.offsetY,
    required this.elementList,
    this.isWidthNotEnough,
    required this.rowIndex,
    this.isSurround,
  });
}