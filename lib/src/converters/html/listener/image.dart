// --- image.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Convert Image attributes into image element.
class Image extends InlineListener {
  String wrapper =
      '<img src="{src}" {width} {height} alt="" class="img-responsive img-fluid" />';

  @override
  void process(Line line) {
    final embedUrl = line.insertJsonKey('image');
    if (embedUrl != null) {
      String widthStr = '';
      final width = line.getAttribute('width');
      if (width != null) {
        widthStr = 'width="${line.getLexer().escape(width.toString())}"';
      }

      String heightStr = '';
      final height = line.getAttribute('height');
      if (height != null) {
        heightStr = 'height="${line.getLexer().escape(height.toString())}"';
      }

      String output = wrapper
          .replaceAll('{src}', line.getLexer().escape(embedUrl.toString()))
          .replaceAll('{width}', widthStr)
          .replaceAll('{height}', heightStr);

      output = output.replaceAll(RegExp(r'\s+'), ' ');

      updateInput(line, output);
    }
  }
}
