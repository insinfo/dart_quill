import '../dataset/enum/editor.dart';
import './element.dart';

class IRange {
	int startIndex;
	int endIndex;
	bool? isCrossRowCol;
	String? tableId;
	int? startTdIndex;
	int? endTdIndex;
	int? startTrIndex;
	int? endTrIndex;
	EditorZone? zone;

	IRange({
		required this.startIndex,
		required this.endIndex,
		this.isCrossRowCol,
		this.tableId,
		this.startTdIndex,
		this.endTdIndex,
		this.startTrIndex,
		this.endTrIndex,
		this.zone,
	});
}

typedef RangeRowArray = Map<int, List<int>>;

typedef RangeRowMap = Map<int, Set<int>>;

typedef RangeRect = IElementFillRect;

class RangeContext {
	bool isCollapsed;
	IElement startElement;
	IElement endElement;
	int startPageNo;
	int endPageNo;
	int startRowNo;
	int endRowNo;
	int startColNo;
	int endColNo;
	List<RangeRect> rangeRects;
	EditorZone zone;
	bool isTable;
	int? trIndex;
	int? tdIndex;
	IElement? tableElement;
	String? selectionText;
	List<IElement> selectionElementList;
	String? titleId;
	int? titleStartPageNo;

	RangeContext({
		required this.isCollapsed,
		required this.startElement,
		required this.endElement,
		required this.startPageNo,
		required this.endPageNo,
		required this.startRowNo,
		required this.endRowNo,
		required this.startColNo,
		required this.endColNo,
		required this.rangeRects,
		required this.zone,
		required this.isTable,
		this.trIndex,
		this.tdIndex,
		this.tableElement,
		this.selectionText,
		required this.selectionElementList,
		this.titleId,
		this.titleStartPageNo,
	});
}

class IRangeParagraphInfo {
	List<IElement> elementList;
	int startIndex;

	IRangeParagraphInfo({
		required this.elementList,
		required this.startIndex,
	});
}

class IRangeElementStyle {
	bool? bold;
	String? color;
	String? highlight;
	String? font;
	int? size;
	bool? italic;
	bool? underline;
	bool? strikeout;

	IRangeElementStyle({
		this.bold,
		this.color,
		this.highlight,
		this.font,
		this.size,
		this.italic,
		this.underline,
		this.strikeout,
	});
}