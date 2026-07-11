import 'dart:io';
import 'dart:convert';

void main() async {
 

  // Defaults
  String inputDir = r'C:\MyDartProjects\dart_quill\lib\src\dependencies';
  String outputFile = r'C:\MyDartProjects\dart_quill\merged_quilldart_src.dart.txt';

  

  final input = Directory(inputDir);
  if (!await input.exists()) {
    stderr.writeln('Input directory does not exist: $inputDir');
    exit(2);
  }

  final buffer = StringBuffer();
  buffer.writeln('// Merged TypeScript files from: $inputDir');
  buffer.writeln();

  final excludedDirs = <String>{
   // 'test', 'tests', '__helpers__', '__dev_server__', 'fuzz', 'unit', 'e2e'
  };

  final tsFiles = <File>[];

  await for (final entity in input.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final path = entity.path;
      if (path.endsWith('.dart') ) {
        // skip files inside excluded directories
        final parts = path.split(Platform.pathSeparator).map((s) => s.toLowerCase()).toList();
        if (parts.any((p) => excludedDirs.contains(p))) continue;
        tsFiles.add(entity);
      }
    }
  }

  // Sort by path for determinism
 // tsFiles.sort((a, b) => a.path.compareTo(b.path));

  for (final file in tsFiles) {
    final relPath = file.uri.toFilePath();
    buffer.writeln('// ---- Start: $relPath ----');
    try {
      final contents = await file.readAsString(encoding: utf8);
      buffer.writeln(contents);
    } catch (e) {
      stderr.writeln('Failed to read ${file.path}: $e');
    }
    buffer.writeln('// ---- End: $relPath ----');
    buffer.writeln();
  }

  final out = File(outputFile);
  await out.writeAsString(buffer.toString(), encoding: utf8);
  print('Wrote ${tsFiles.length} files into: $outputFile');
}
