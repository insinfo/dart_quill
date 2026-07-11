import '../dataset/enum/vertical_align.dart';

class ICheckbox {
	bool? value;
	String? code;
	bool? disabled;

	ICheckbox({this.value, this.code, this.disabled});
}

class ICheckboxOption {
	double? width;
	double? height;
	double? gap;
	double? lineWidth;
	String? fillStyle;
	String? strokeStyle;
	VerticalAlign? verticalAlign;

	ICheckboxOption({
		this.width,
		this.height,
		this.gap,
		this.lineWidth,
		this.fillStyle,
		this.strokeStyle,
		this.verticalAlign,
	});
}