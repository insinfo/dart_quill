import '../dataset/enum/block.dart';

class IIFrameBlock {
	String? src;
	String? srcdoc;

	IIFrameBlock({this.src, this.srcdoc});
}

class IVideoBlock {
	String src;

	IVideoBlock({required this.src});
}

class IBlock {
	BlockType type;
	IIFrameBlock? iframeBlock;
	IVideoBlock? videoBlock;

	IBlock({
		required this.type,
		this.iframeBlock,
		this.videoBlock,
	});
}