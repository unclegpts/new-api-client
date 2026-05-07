import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

/// 轻量级多语言系统 — 从 JSON 加载翻译
class AppLocalizations {
  final Locale locale;
  Map<String, String> _strings = {};

  AppLocalizations(this.locale);

  /// 获取翻译文本，支持 {placeholder} 替换
  String t(String key, [Map<String, String>? args]) {
    var text = _strings[key] ?? key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  /// 加载翻译文件
  Future<void> load() async {
    final lang = locale.languageCode;
    // 尝试加载具体语言，fallback 到中文
    final candidates = ['$lang.json', 'zh.json'];
    for (final file in candidates) {
      try {
        final jsonStr = await rootBundle.loadString('lib/l10n/$file');
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _strings = map.map((k, v) => MapEntry(k, v.toString()));
        return;
      } catch (_) {}
    }
  }

  // ── Static helpers ──
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l10n = AppLocalizations(locale);
    await l10n.load();
    return l10n;
  }

  @override
  bool shouldReload(covariant _AppLocalizationsDelegate old) => false;
}

/// 快捷访问扩展
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
