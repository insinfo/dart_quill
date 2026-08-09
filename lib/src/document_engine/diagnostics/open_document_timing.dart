/// Lightweight phase attribution for the synchronous part of DOCX opening.
///
/// The Zone value exists only around the File-tab import path. Ordinary
/// editor construction, transactions and public APIs pay no stopwatch cost.
library;

import 'dart:async';

final Object _openDocumentTimingsZoneKey = Object();

void runWithOpenDocumentTimings(
  Map<String, int> timings,
  void Function() operation,
) {
  runZoned<void>(
    operation,
    zoneValues: <Object, Object>{_openDocumentTimingsZoneKey: timings},
  );
}

T measureOpenDocumentPhase<T>(String name, T Function() operation) {
  final timings =
      Zone.current[_openDocumentTimingsZoneKey] as Map<String, int>?;
  if (timings == null) return operation();

  final watch = Stopwatch()..start();
  try {
    return operation();
  } finally {
    watch.stop();
    timings[name] = (timings[name] ?? 0) + watch.elapsedMicroseconds;
  }
}
