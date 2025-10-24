/// Temporary shim that forwards to the production clipboard module.
///
/// Historically this file contained a placeholder while the main clipboard
/// implementation was being ported.  The real implementation now lives in
/// `clipboard.dart`, so we simply re-export it for backwards compatibility.
export 'clipboard.dart';
