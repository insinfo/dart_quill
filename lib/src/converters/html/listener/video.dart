// --- video.dart ---
import 'dart:core';
import '../block_listener.dart';
import '../line.dart';

/// Convert Video attributes into tags.
class Video extends BlockListener {
  List<String> allow = [
    'accelerometer',
    'autoplay',
    'encrypted-media',
    'gyroscope',
    'picture-in-picture'
  ];
  String wrapper =
      '<div class="embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="{url}" frameborder="0" allow="{allow}" allowfullscreen></iframe></div>\n';

  @override
  void process(Line line) {
    final embedUrl = line.insertJsonKey('video');
    if (embedUrl != null) {
      line.output = wrapper
          .replaceAll('{url}', line.getLexer().escape(embedUrl.toString()))
          .replaceAll('{allow}', allow.join("; "));
      line.setDone();
    }
  }
}
