/// A conversão documento→PDF tem de rodar EM QUALQUER LUGAR.
///
/// Não é "roda na VM": é independente de plataforma. Nada de `dart:io`
/// (senão não roda no browser), nada de `dart:html`/`package:web`/
/// `dart:js_interop` (senão não roda na VM nem em Flutter nativo). O mesmo
/// contrato que a conversão Delta→PDF já cumpre hoje.
///
/// Este teste percorre o FECHO TRANSITIVO de imports a partir do serviço e
/// falha se qualquer arquivo alcançável trouxer uma dependência de
/// plataforma. É a única forma de a garantia sobreviver: um `import` posto
/// por engano três arquivos abaixo não aparece em nenhum outro teste — o
/// código simplesmente para de compilar no ambiente do cliente, que no caso
/// do SALI é o backend que assina despachos.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// Imports que tornariam a conversão dependente de plataforma.
const _forbidden = {
  'dart:io',
  'dart:html',
  'dart:js',
  'dart:js_interop',
  'dart:js_util',
  'dart:ui',
};

const _forbiddenPackages = {'package:web', 'package:html'};

/// As raízes do caminho de conversão que precisam ser portáveis.
const _entryPoints = [
  'lib/src/document_engine/office/pdf_service.dart',
  'lib/src/document_engine/layout/layout_composer.dart',
  'lib/src/document_engine/layout/pdf_renderer.dart',
  'lib/src/document_engine/office/snapshot.dart',
  'lib/src/document_engine/office/quill_codec.dart',
];

final _importPattern =
    RegExp(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", multiLine: true);

/// Resolve o alvo de um import relativo a [from].
String _resolve(String target, String from) {
  if (target.startsWith('package:dart_quill/')) {
    return 'lib/${target.substring('package:dart_quill/'.length)}';
  }
  if (target.startsWith('dart:') || target.startsWith('package:')) {
    return target;
  }
  final dir = File(from).parent.path.replaceAll(r'\', '/');
  final joined = Uri.parse('$dir/').resolve(target).toString();
  return joined.replaceFirst(RegExp(r'^/'), '');
}

/// Todos os arquivos alcançáveis a partir de [entry], e as dependências
/// externas que eles trazem.
({Set<String> files, Map<String, Set<String>> external}) _closure(
    String entry) {
  final files = <String>{};
  final external = <String, Set<String>>{};
  final pending = <String>[entry];

  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (!files.add(current)) continue;
    final file = File(current);
    if (!file.existsSync()) continue;
    for (final match in _importPattern.allMatches(file.readAsStringSync())) {
      final target = _resolve(match.group(1)!, current);
      if (target.startsWith('dart:') || target.startsWith('package:')) {
        external.putIfAbsent(target, () => {}).add(current);
        continue;
      }
      pending.add(target);
    }
  }
  return (files: files, external: external);
}

void main() {
  group('portabilidade da conversão para PDF', () {
    for (final entry in _entryPoints) {
      test('$entry não alcança dependência de plataforma', () {
        final closure = _closure(entry);
        expect(closure.files.length, greaterThan(1),
            reason: 'o fecho não pode estar vazio — caminho errado?');

        final violations = <String>[];
        closure.external.forEach((dependency, importers) {
          final isForbidden = _forbidden.contains(dependency) ||
              _forbiddenPackages.any(dependency.startsWith);
          if (isForbidden) {
            violations.add('$dependency  <-  ${importers.join(', ')}');
          }
        });

        expect(violations, isEmpty,
            reason: 'a conversão para PDF tem de rodar em qualquer lugar '
                '(backend que assina, browser, Flutter). Encontrado:\n'
                '${violations.join('\n')}');
      });
    }

    test('o serviço usa somente core libraries neutras', () {
      final closure = _closure(_entryPoints.first);
      final dartLibs = closure.external.keys
          .where((dependency) => dependency.startsWith('dart:'))
          .toSet();
      expect(
          dartLibs,
          everyElement(isIn({
            'dart:async',
            'dart:collection',
            'dart:convert',
            'dart:math',
            'dart:typed_data',
          })),
          reason: 'core libraries neutras rodam em VM, browser e Flutter; '
              'qualquer outra amarra o PDF a um ambiente');
    });

    test('nenhum package externo entra no caminho de conversão', () {
      final closure = _closure(_entryPoints.first);
      final packages = closure.external.keys
          .where((dependency) => dependency.startsWith('package:'))
          .where((dependency) => !dependency.startsWith('package:dart_quill/'))
          .toList();
      expect(packages, isEmpty,
          reason: 'converter documento em PDF não pode depender de package '
              'algum — nem os da allowlist, que são de browser/HTML');
    });
  });
}
