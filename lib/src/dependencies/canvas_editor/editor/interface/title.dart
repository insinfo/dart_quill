import '../dataset/enum/editor.dart';

class ITitleOption {
	double? defaultFirstSize;
	double? defaultSecondSize;
	double? defaultThirdSize;
	double? defaultFourthSize;
	double? defaultFifthSize;
	double? defaultSixthSize;

	ITitleOption({
		this.defaultFirstSize,
		this.defaultSecondSize,
		this.defaultThirdSize,
		this.defaultFourthSize,
		this.defaultFifthSize,
		this.defaultSixthSize,
	});
}

class ITitle {
	bool? deletable;
	bool? disabled;
	String? conceptId;

	ITitle({this.deletable, this.disabled, this.conceptId});
}

class IGetTitleValueOption {
	String conceptId;

	IGetTitleValueOption({required this.conceptId});
}

class ITitleValueItem<TElement> extends ITitle {
	String? value;
	List<TElement> elementList;
	EditorZone zone;

	ITitleValueItem({
		bool? deletable,
		bool? disabled,
		String? conceptId,
		this.value,
		required this.elementList,
		required this.zone,
	}) : super(
					deletable: deletable,
					disabled: disabled,
					conceptId: conceptId,
				);
}