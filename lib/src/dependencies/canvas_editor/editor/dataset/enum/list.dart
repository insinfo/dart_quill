enum ListType {
	unordered('ul'),
	ordered('ol');

	final String value;

	const ListType(this.value);
}

enum UlStyle {
	disc('disc'),
	circle('circle'),
	square('square'),
	checkbox('checkbox');

	final String value;

	const UlStyle(this.value);
}

enum OlStyle {
	decimal('decimal');

	final String value;

	const OlStyle(this.value);
}

enum ListStyle {
	disc('disc'),
	circle('circle'),
	square('square'),
	decimal('decimal'),
	checkbox('checkbox');

	final String value;

	const ListStyle(this.value);
}