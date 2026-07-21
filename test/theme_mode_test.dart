import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/data/repositories.dart';
import 'package:lms_app/state/app_state.dart';

/// An in-memory [SettingsRepository] stand-in backed by a plain map so the
/// AppState theme/locale persistence can be tested without a real database.
class _FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> _store = {};

  @override
  Future<String?> getString(String field) async => _store[field];

  @override
  Future<void> setString(String field, String? value) async {
    if (value == null) {
      _store.remove(field);
    } else {
      _store[field] = value;
    }
  }
}

void main() {
  group('AppState theme mode', () {
    test('defaults to system', () {
      final state = AppState(settings: _FakeSettingsRepository());
      expect(state.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates and persists the choice', () async {
      final settings = _FakeSettingsRepository();
      final state = AppState(settings: settings);

      await state.setThemeMode(ThemeMode.dark);

      expect(state.themeMode, ThemeMode.dark);
      expect(await settings.getString('themeMode'), 'dark');
    });

    test('setLocale persists the language code and null clears it', () async {
      final settings = _FakeSettingsRepository();
      final state = AppState(settings: settings);

      await state.setLocale(const Locale('ar'));
      expect(state.locale?.languageCode, 'ar');
      expect(await settings.getString('localeCode'), 'ar');

      await state.setLocale(null);
      expect(state.locale, isNull);
      expect(await settings.getString('localeCode'), isNull);
    });
  });
}
