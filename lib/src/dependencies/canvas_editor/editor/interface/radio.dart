import '../dataset/enum/vertical_align.dart';

class IRadio {
	bool? value;
	String? code;
	bool? disabled;

	IRadio({this.value, this.code, this.disabled});
}

class IRadioOption {
	double? width;
	double? height;
	double? gap;
	double? lineWidth;
	String? fillStyle;
	String? strokeStyle;
	VerticalAlign? verticalAlign;

	IRadioOption({
		this.width,
		this.height,
		this.gap,
		this.lineWidth,
		this.fillStyle,
		this.strokeStyle,
		this.verticalAlign,
	});
}