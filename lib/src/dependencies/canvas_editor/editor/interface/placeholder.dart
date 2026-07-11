class IPlaceholder {
	String data;
	String? color;
	double? opacity;
	double? size;
	String? font;

	IPlaceholder({
		required this.data,
		this.color,
		this.opacity,
		this.size,
		this.font,
	});
}