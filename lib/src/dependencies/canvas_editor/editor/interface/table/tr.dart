import './td.dart';

class ITr {
	String? id;
	dynamic extension;
	String? externalId;
	double height;
	List<ITd> tdList;
	double? minHeight;
	bool? pagingRepeat;

	ITr({
		this.id,
		this.extension,
		this.externalId,
		required this.height,
		required this.tdList,
		this.minHeight,
		this.pagingRepeat,
	});
}