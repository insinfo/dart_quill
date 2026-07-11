import '../dataset/enum/area.dart';
import '../dataset/enum/common.dart';
import './placeholder.dart';

class IArea {
	dynamic extension;
	IPlaceholder? placeholder;
	double? top;
	String? borderColor;
	String? backgroundColor;
	AreaMode? mode;
	bool? hide;
	bool? deletable;

	IArea({
		this.extension,
		this.placeholder,
		this.top,
		this.borderColor,
		this.backgroundColor,
		this.mode,
		this.hide,
		this.deletable,
	});
}

class IAreaRange {
	int startIndex;
	int endIndex;

	IAreaRange({required this.startIndex, required this.endIndex});
}

class IInsertAreaOption<TElement> {
	String? id;
	IArea area;
	List<TElement> value;
	LocationPosition? position;
	IAreaRange? range;

	IInsertAreaOption({
		this.id,
		required this.area,
		required this.value,
		this.position,
		this.range,
	});
}

class ISetAreaValueOption<TElement> {
	String? id;
	List<TElement> value;

	ISetAreaValueOption({this.id, required this.value});
}

class ISetAreaPropertiesOption {
	String? id;
	IArea properties;

	ISetAreaPropertiesOption({this.id, required this.properties});
}

class IGetAreaValueOption {
	String? id;

	IGetAreaValueOption({this.id});
}

class IGetAreaValueResult<TElement> {
	String? id;
	IArea area;
	int startPageNo;
	int endPageNo;
	List<TElement> value;

	IGetAreaValueResult({
		this.id,
		required this.area,
		required this.startPageNo,
		required this.endPageNo,
		required this.value,
	});
}

class IAreaInfo<TElement, TPosition> {
	String id;
	IArea area;
	List<TElement> elementList;
	List<TPosition> positionList;

	IAreaInfo({
		required this.id,
		required this.area,
		required this.elementList,
		required this.positionList,
	});
}

class ILocationAreaOption {
	LocationPosition position;
	bool? isAppendLastLineBreak;

	ILocationAreaOption({
		required this.position,
		this.isAppendLastLineBreak,
	});
}

class IDeleteAreaOption {
	String? id;

	IDeleteAreaOption({this.id});
}