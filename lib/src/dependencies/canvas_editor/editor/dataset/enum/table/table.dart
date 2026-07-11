enum TableBorder {
	all('all'),
	empty('empty'),
	external('external'),
	internal('internal'),
	dash('dash');

	final String value;

	const TableBorder(this.value);
}

enum TdBorder {
	top('top'),
	right('right'),
	bottom('bottom'),
	left('left');

	final String value;

	const TdBorder(this.value);
}

enum TdSlash {
	forward('forward'),
	back('back');

	final String value;

	const TdSlash(this.value);
}