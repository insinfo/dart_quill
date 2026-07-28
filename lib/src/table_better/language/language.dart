/// Port of quill-table-better `src/language/index.ts` (v1.2.3).
///
/// All 16 locales from the TS source are bundled with this port. Additional
/// locales can be added at runtime through [Language.registry] (mirroring the
/// TS API).
import 'cs_cz.dart';
import 'da_dk.dart';
import 'de_de.dart';
import 'en_us.dart';
import 'fr_fr.dart';
import 'it_it.dart';
import 'ja_jp.dart';
import 'nb_no.dart';
import 'pl_pl.dart';
import 'pt_br.dart';
import 'pt_pt.dart';
import 'ru_ru.dart';
import 'sv_se.dart';
import 'tr_tr.dart';
import 'zh_cn.dart';
import 'zh_tw.dart';

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
      'zh_CN': zhCN,
      'fr_FR': frFR,
      'pl_PL': plPL,
      'de_DE': deDE,
      'ru_RU': ruRU,
      'tr_TR': trTR,
      'pt_PT': ptPT,
      'ja_JP': jaJP,
      'pt_BR': ptBR,
      'cs_CZ': csCZ,
      'da_DK': daDK,
      'nb_NO': nbNO,
      'it_IT': itIT,
      'sv_SE': svSE,
      'zh_TW': zhTW,
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
