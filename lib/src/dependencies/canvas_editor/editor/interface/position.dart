import '../dataset/enum/common.dart';
import '../dataset/enum/editor.dart';
import './element.dart';
import './range.dart';
import './row.dart';
import './table/td.dart';

class ICurrentPosition {
  int index;
  double? x;
  double? y;
  bool? isCheckbox;
  bool? isRadio;
  bool? isControl;
  bool? isImage;
  bool? isLabel;
  bool? isTable;
  bool? isDirectHit;
  int? trIndex;
  int? tdIndex;
  int? tdValueIndex;
  String? tdId;
  String? trId;
  String? tableId;
  EditorZone? zone;
  int? hitLineStartIndex;

  ICurrentPosition({
    required this.index,
    this.x,
    this.y,
    this.isCheckbox,
    this.isRadio,
    this.isControl,
    this.isImage,
    this.isLabel,
    this.isTable,
    this.isDirectHit,
    this.trIndex,
    this.tdIndex,
    this.tdValueIndex,
    this.tdId,
    this.trId,
    this.tableId,
    this.zone,
    this.hitLineStartIndex,
  });
}

class IGetPositionByXYPayload {
  double x;
  double y;
  int? pageNo;
  bool? isTable;
  ITd? td;
  IElementPosition? tablePosition;
  List<IElement>? elementList;
  List<IElementPosition>? positionList;

  IGetPositionByXYPayload({
    required this.x,
    required this.y,
    this.pageNo,
    this.isTable,
    this.td,
    this.tablePosition,
    this.elementList,
    this.positionList,
  });
}

class IGetFloatPositionByXYPayload extends IGetPositionByXYPayload {
  List<ImageDisplay> imgDisplays;

  IGetFloatPositionByXYPayload({
    required this.imgDisplays,
    required double x,
    required double y,
    int? pageNo,
    bool? isTable,
    ITd? td,
    IElementPosition? tablePosition,
    List<IElement>? elementList,
    List<IElementPosition>? positionList,
  }) : super(
          x: x,
          y: y,
          pageNo: pageNo,
          isTable: isTable,
          td: td,
          tablePosition: tablePosition,
          elementList: elementList,
          positionList: positionList,
        );
}

class IPositionContext {
  bool isTable;
  bool? isCheckbox;
  bool? isRadio;
  bool? isControl;
  bool? isImage;
  bool? isLabel;
  bool? isDirectHit;
  int? index;
  int? trIndex;
  int? tdIndex;
  String? tdId;
  String? trId;
  String? tableId;

  IPositionContext({
    required this.isTable,
    this.isCheckbox,
    this.isRadio,
    this.isControl,
    this.isImage,
    this.isLabel,
    this.isDirectHit,
    this.index,
    this.trIndex,
    this.tdIndex,
    this.tdId,
    this.trId,
    this.tableId,
  });
}

class IComputeRowPositionPayload {
  IRow row;
  double innerWidth;

  IComputeRowPositionPayload({
    required this.row,
    required this.innerWidth,
  });
}

class IComputePageRowPositionPayload {
  List<IElementPosition> positionList;
  List<IRow> rowList;
  int pageNo;
  int startRowIndex;
  int startIndex;
  double startX;
  double startY;
  double innerWidth;
  bool? isTable;
  int? index;
  int? tdIndex;
  int? trIndex;
  int? tdValueIndex;
  EditorZone? zone;

  IComputePageRowPositionPayload({
    required this.positionList,
    required this.rowList,
    required this.pageNo,
    required this.startRowIndex,
    required this.startIndex,
    required this.startX,
    required this.startY,
    required this.innerWidth,
    this.isTable,
    this.index,
    this.tdIndex,
    this.trIndex,
    this.tdValueIndex,
    this.zone,
  });
}

class IComputePageRowPositionResult {
  double x;
  double y;
  int index;

  IComputePageRowPositionResult({
    required this.x,
    required this.y,
    required this.index,
  });
}

class IFloatPosition {
  int pageNo;
  IElement element;
  IElementPosition position;
  bool? isTable;
  int? index;
  int? tdIndex;
  int? trIndex;
  int? tdValueIndex;
  EditorZone? zone;

  IFloatPosition({
    required this.pageNo,
    required this.element,
    required this.position,
    this.isTable,
    this.index,
    this.tdIndex,
    this.trIndex,
    this.tdValueIndex,
    this.zone,
  });
}

class ILocationPosition {
  EditorZone zone;
  IRange range;
  IPositionContext positionContext;

  ILocationPosition({
    required this.zone,
    required this.range,
    required this.positionContext,
  });
}

class ISetSurroundPositionPayload {
  IRow row;
  IRowElement rowElement;
  IElementFillRect rowElementRect;
  int pageNo;
  double availableWidth;
  List<IElement> surroundElementList;

  ISetSurroundPositionPayload({
    required this.row,
    required this.rowElement,
    required this.rowElementRect,
    required this.pageNo,
    required this.availableWidth,
    required this.surroundElementList,
  });
}