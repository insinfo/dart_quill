import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import 'abstract/attributor.dart';

/// Whitelist de famílias aceitas pelos attributors de fonte.
///
/// O upstream nasce com `['serif', 'monospace']`, o que é suficiente para a
/// demo do Quill e insuficiente para um editor de documentos: um DOCX traz
/// `Arial`, `Calibri`, `Times New Roman`, e sem estarem aqui o formato é
/// descartado em silêncio ao abrir o arquivo. Use [setFontWhitelist] para
/// declarar as famílias da aplicação.
final Map<String, dynamic> fontConfig = {
  'scope': Scope.INLINE,
  'whitelist': ['serif', 'monospace']
};

/// Declara as famílias de fonte aceitas.
///
/// `null` aceita qualquer valor — o que faz sentido ao abrir documentos de
/// terceiros, em que a família vem do arquivo e não de uma lista fechada.
/// A whitelist é consultada a cada aplicação de formato, então isto vale
/// também para editores já criados.
void setFontWhitelist(List<String>? families) {
  if (families == null) {
    fontConfig.remove('whitelist');
  } else {
    fontConfig['whitelist'] = List<String>.of(families);
  }
}

class FontClass extends ClassAttributor {
  static final FontClass instance = FontClass._();

  FontClass._() : super('font', 'ql-font', fontConfig);
}

class FontStyleAttributor extends StyleAttributor {
  static final FontStyleAttributor instance = FontStyleAttributor._();

  FontStyleAttributor._() : super('font', 'font-family', fontConfig);

  @override
  String? value(DomElement node) {
    final raw = super.value(node) as String?;
    if (raw == null) return null;
    return raw.replaceAll('"', '').replaceAll("'", '');
  }
}
