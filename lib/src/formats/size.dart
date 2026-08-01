import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

/// Whitelist do attributor de tamanho por CLASSE (`ql-size-small` etc.).
final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
  'whitelist': ['small', 'large', 'huge'],
};

/// Whitelist do attributor de tamanho por ESTILO (`font-size`).
///
/// O upstream nasce com três tamanhos em px, o que descarta qualquer tamanho
/// vindo de um documento real: o Word usa pontos (10pt, 11pt, 12pt…) e o
/// importador de DOCX os converte para px. Use [setSizeStyleWhitelist] para
/// declarar os tamanhos da aplicação — ou `null` para aceitar qualquer um.
final Map<String, dynamic> sizeStyleConfig = {
  'scope': Scope.INLINE,
  'whitelist': ['10px', '18px', '32px'],
};

/// Declara os tamanhos aceitos pelo attributor de tamanho por classe.
void setSizeWhitelist(List<String>? sizes) {
  if (sizes == null) {
    config.remove('whitelist');
  } else {
    config['whitelist'] = List<String>.of(sizes);
  }
}

/// Declara os tamanhos aceitos pelo attributor de tamanho por estilo
/// (`font-size`). `null` aceita qualquer valor, que é o caso de quem abre
/// documentos de terceiros: o tamanho vem do arquivo, não de uma lista.
void setSizeStyleWhitelist(List<String>? sizes) {
  if (sizes == null) {
    sizeStyleConfig.remove('whitelist');
  } else {
    sizeStyleConfig['whitelist'] = List<String>.of(sizes);
  }
}

class SizeClass extends ClassAttributor {
  static final SizeClass instance = SizeClass._();

  SizeClass._() : super('size', 'ql-size', config);
}

class SizeStyle extends StyleAttributor {
  static final SizeStyle instance = SizeStyle._();

  SizeStyle._() : super('size', 'font-size', sizeStyleConfig);
}
