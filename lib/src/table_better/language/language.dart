/// Port of quill-table-better `src/language/index.ts` (v1.2.3).
///
/// The TS source registers 16 locales; only `en_US` and `pt_BR` are bundled
/// with this port. Additional locales can be added at runtime through
/// [Language.registry] (mirroring the TS API).
import 'en_us.dart';
import 'pt_br.dart';

/// Mirrors the TS `LanguageConfig` interface (`{ name, content }`).
class LanguageConfig {
  const LanguageConfig({required this.name, required this.content});

  final String name;
  final Map<String, String> content;
}

/// Mirrors the TS `Language` class: a registry of locale maps with a
/// currently selected locale name.
class Language {
  /// [language] may be a locale name ([String]), a [LanguageConfig] to
  /// register-and-select in one step, or null (defaults to `en_US`).
  Language([dynamic language]) {
    config = <String, Map<String, String>>{
      'en_US': enUS,
      'pt_BR': ptBR,
    };
    init(language);
  }

  late Map<String, Map<String, String>> config;
  late String name;

  void changeLanguage(String name) {
    this.name = name;
  }

  void init(dynamic language) {
    if (language == null || language is String) {
      changeLanguage((language as String?) ?? 'en_US');
    } else if (language is LanguageConfig) {
      if (language.content.isNotEmpty) {
        registry(language.name, language.content);
      }
      if (language.name.isNotEmpty) {
        changeLanguage(language.name);
      }
    } else {
      changeLanguage('en_US');
    }
  }

  void registry(String name, Map<String, String> content) {
    config = <String, Map<String, String>>{
      ...config,
      name: content,
    };
  }

  String useLanguage(String name) => config[this.name]?[name] ?? '';
}
