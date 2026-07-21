import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

/// Central place for app-wide preferences: appearance (theme) and language.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l10n.appearance),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: state.themeMode,
              onChanged: (m) {
                if (m != null) state.setThemeMode(m);
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: const Icon(Icons.brightness_auto),
                    title: Text(l10n.themeSystem),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: const Icon(Icons.light_mode),
                    title: Text(l10n.themeLight),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: const Icon(Icons.dark_mode),
                    title: Text(l10n.themeDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.language),
          Card(
            child: RadioGroup<String?>(
              groupValue: state.locale?.languageCode,
              onChanged: (code) => state.setLocale(
                code == null ? null : Locale(code),
              ),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    secondary: const Icon(Icons.translate),
                    title: Text(l10n.systemDefault),
                  ),
                  for (final locale in AppLocalizations.supportedLocales)
                    RadioListTile<String?>(
                      value: locale.languageCode,
                      secondary: const Icon(Icons.language),
                      title: Text(
                        AppLocalizations.languageName(locale.languageCode),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
