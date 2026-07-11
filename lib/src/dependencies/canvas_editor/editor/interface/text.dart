import '../dataset/enum/text.dart';

class ITextMetrics {
	double width;
	double actualBoundingBoxAscent;
	double actualBoundingBoxDescent;
	double actualBoundingBoxLeft;
	double actualBoundingBoxRight;
	double fontBoundingBoxAscent;
	double fontBoundingBoxDescent;

	ITextMetrics({
		required this.width,
		required this.actualBoundingBoxAscent,
		required this.actualBoundingBoxDescent,
		required this.actualBoundingBoxLeft,
		required this.actualBoundingBoxRight,
		required this.fontBoundingBoxAscent,
		required this.fontBoundingBoxDescent,
	});
}

class ITextDecoration {
	TextDecorationStyle? style;

	ITextDecoration({this.style});
}