import 'dart:typed_data';

import '../../ce_opc.dart';
import '../../ce_xml.dart';

/// Validador estrutural de DOCX (roteiro_editor_profissional, F3.4c).
///
/// Não substitui o Word: verifica as invariantes que causam o diálogo de
/// repair — XML well-formed, rels consistentes, content types completos e
/// referências de estilo/numeração existentes.
class DocxValidator {
  DocxValidator._();

  /// Valida os bytes de um .docx. Retorna a lista de problemas (vazia = ok).
  static List<String> validate(Uint8List bytes) {
    final problems = <String>[];
    final OpcPackage package;
    try {
      package = OpcPackage.decode(bytes);
    } catch (error) {
      return ['pacote OPC inválido: $error'];
    }

    // 1. Todas as partes XML são well-formed.
    for (final name in package.partNames) {
      if (!name.endsWith('.xml') && !name.endsWith('.rels')) continue;
      try {
        XmlDocument.parse(package.partString(name)!);
      } catch (error) {
        problems.add('parte XML malformada: $name ($error)');
      }
    }

    // 2. Content types cobrem todas as partes.
    for (final name in package.partNames) {
      if (name == '[Content_Types].xml') continue;
      if (package.contentTypeOf(name) == null) {
        problems.add('parte sem content type: $name');
      }
    }

    // 3. Targets internos de todos os .rels existem.
    for (final relsPart
        in package.partNames.where((n) => n.endsWith('.rels'))) {
      final owner = relsPart == '_rels/.rels'
          ? null
          : relsPart
              .replaceFirst('_rels/', '')
              .replaceFirst(RegExp(r'\.rels$'), '');
      for (final rel in package.relationshipsFor(owner).items) {
        if (rel.isExternal) continue;
        final target = package.resolveTarget(owner, rel.target);
        if (!package.hasPart(target)) {
          problems.add('rel ${rel.id} de $relsPart aponta para parte '
              'inexistente: $target');
        }
      }
    }

    // 4. Parte principal presente e referências de estilo/numeração válidas.
    try {
      final mainPart = package.mainDocumentPartName;
      final documentXml = package.partString(mainPart);
      if (documentXml == null) {
        problems.add('parte principal ausente: $mainPart');
        return problems;
      }
      final root = XmlDocument.parse(documentXml).rootElement;

      final styleIds = <String>{};
      final stylesXml = package.partString('word/styles.xml');
      if (stylesXml != null) {
        for (final style
            in XmlDocument.parse(stylesXml).rootElement.childElements) {
          final id = style.getAttribute('w:styleId');
          if (id != null) styleIds.add(id);
        }
      }
      final numIds = <String>{'0'};
      final numberingXml = package.partString('word/numbering.xml');
      if (numberingXml != null) {
        for (final num in XmlDocument.parse(numberingXml)
            .rootElement
            .childrenNamed('w:num')) {
          final id = num.getAttribute('w:numId');
          if (id != null) numIds.add(id);
        }
      }

      for (final qname in ['w:pStyle', 'w:rStyle', 'w:tblStyle']) {
        for (final el in root.descendantsNamed(qname)) {
          final id = el.getAttribute('w:val');
          if (id != null && !styleIds.contains(id)) {
            problems.add('$qname referencia estilo inexistente: $id');
          }
        }
      }
      for (final el in root.descendantsNamed('w:numId')) {
        final id = el.getAttribute('w:val');
        if (id != null && !numIds.contains(id)) {
          problems.add('numPr referencia numId inexistente: $id');
        }
      }

      // 5. r:id usados no document.xml existem nos rels da parte.
      final rels = package.relationshipsFor(mainPart);
      for (final el in root.descendants) {
        final relId = el.getAttribute('r:id') ?? el.getAttribute('r:embed');
        if (relId != null && rels.byId(relId) == null) {
          problems.add('${el.qname} referencia rel inexistente: $relId');
        }
      }
    } catch (error) {
      problems.add('falha ao validar document.xml: $error');
    }

    return problems;
  }
}
