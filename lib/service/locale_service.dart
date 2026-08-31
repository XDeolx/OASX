import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Keeps local test-version labels from being replaced by an older OAS server.
@visibleForTesting
Map<String, Map<String, String>> protectBundledChessTestTranslations(
  Map<String, Map<String, String>> remoteTranslations,
) {
  final merged = <String, Map<String, String>>{
    for (final entry in remoteTranslations.entries)
      entry.key: Map<String, String>.from(entry.value),
  };
  final bundledTranslations = Messages().keys;
  for (final locale in const ['zh_CN', 'en_US']) {
    final bundledLocale = bundledTranslations[locale];
    if (bundledLocale == null) {
      continue;
    }
    final targetLocale =
        merged.putIfAbsent(locale, () => <String, String>{});
    for (final key in ['Chess', I18n.chessTestNotice]) {
      final value = bundledLocale[key];
      if (value != null && value.isNotEmpty) {
        targetLocale[key] = value;
      }
    }
  }
  return merged;
}

class LocaleService extends GetxService {
  final _storage = GetStorage();
  final language = 'zh-CN'.obs;

  final fallbackLocale = const Locale('zh', 'CN');

  Locale get currentLocale => _loadLocaleFromStorage();

  @override
  void onInit() {
    language.value = _storage.read(StorageKey.language.name) ?? 'zh-CN';
    _updateLocale(language.value);
    super.onInit();
  }

  void switchLanguage(String lang) {
    language.value = lang;
    _storage.write(StorageKey.language.name, lang);
    _updateLocale(lang);
  }

  void _updateLocale(String lang) {
    final locale = switch (lang) {
      'zh-CN' => const Locale('zh', 'CN'),
      'en-US' => const Locale('en', 'US'),
      _ => fallbackLocale,
    };
    Get.updateLocale(locale);
  }

  Locale _loadLocaleFromStorage() {
    final code = _storage.read(StorageKey.language.name);
    if (code == null) return fallbackLocale;
    return Locale(code);
  }

  Future<void> refreshTransFromRemote() async {
    final additionalTrans = protectBundledChessTestTranslations(
      await ApiClient().getAdditionalTranslate(),
    );
    Get.appendTranslations(additionalTrans);
    _updateLocale(language.value);
  }
}
