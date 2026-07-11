enum TextDecorationStyle {
	solid('solid'),
	double_('double'),
	dashed('dashed'),
	dotted('dotted'),
	wavy('wavy');

	final String value;

	const TextDecorationStyle(this.value);
}

enum DashType {
	solid('solid'),
	dashed('dashed'),
	dotted('dotted');

	final String value;

	const DashType(this.value);
}