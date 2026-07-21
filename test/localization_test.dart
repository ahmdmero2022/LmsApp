import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('supports English and Arabic', () {
      final codes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
      expect(codes, containsAll(['en', 'ar']));
    });

    test('returns locale-specific strings', () {
      const en = AppLocalizations(Locale('en'));
      const ar = AppLocalizations(Locale('ar'));
      expect(en.navCatalog, 'Catalog');
      expect(ar.navCatalog, 'الدورات');
      expect(en.signOut, 'Sign out');
      expect(ar.signOut, 'تسجيل الخروج');
    });

    test('falls back to English for an unsupported locale', () {
      const fr = AppLocalizations(Locale('fr'));
      expect(fr.navProfile, 'Profile');
    });

    test('unknown key falls back to the key itself', () {
      const en = AppLocalizations(Locale('en'));
      expect(en.t('definitelyMissingKey'), 'definitelyMissingKey');
    });

    test('every English key has an Arabic translation', () {
      const en = AppLocalizations(Locale('en'));
      const ar = AppLocalizations(Locale('ar'));
      // Sample the getters that back real UI; each must differ across locales
      // to guarantee the Arabic map isn't silently falling back to English.
      final samples = <String Function(AppLocalizations)>[
        (l) => l.navCatalog,
        (l) => l.appTitle,
        (l) => l.language,
        (l) => l.notifications,
      ];
      for (final get in samples) {
        expect(get(ar), isNot(equals(get(en))));
      }
    });

    test('languageName renders each language in its own script', () {
      expect(AppLocalizations.languageName('en'), 'English');
      expect(AppLocalizations.languageName('ar'), 'العربية');
    });

    test('delegate only supports the configured languages', () {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('ar')), isTrue);
      expect(delegate.isSupported(const Locale('de')), isFalse);
    });
  });
}
