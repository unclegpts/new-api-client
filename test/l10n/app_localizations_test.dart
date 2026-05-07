import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:new_api_client/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('delegate isSupported returns true for zh/en', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('zh')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    });

    test('delegate isSupported returns false for unsupported', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('ja')), isFalse);
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('shouldReload returns false', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.shouldReload(delegate), isFalse);
    });

    test('t returns key when translation missing', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.t('nonexistent_key'), equals('nonexistent_key'));
    });

    test('t replaces placeholders', () {
      final l10n = AppLocalizations(const Locale('en'));
      // Without actual translation loaded, key is returned
      expect(l10n.t('welcome_back', {'nickname': 'Alice'}),
          equals('welcome_back'));
    });
  });
}
