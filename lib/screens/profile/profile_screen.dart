import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../achievements/achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final enrolledCount = state.myEnrollments.length;
    final teachingCount = state.myCourses.length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(user.email),
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(
                    user.role == UserRole.instructor
                        ? Icons.co_present
                        : Icons.menu_book,
                    size: 18,
                  ),
                  label: Text(user.role.label),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                if (user.role == UserRole.instructor)
                  ListTile(
                    leading: const Icon(Icons.library_books),
                    title: Text(l10n.coursesTaught),
                    trailing: Text('$teachingCount'),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(l10n.coursesEnrolled),
                    trailing: Text('$enrolledCount'),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(l10n.unreadNotifications),
                  trailing: Text('${state.unreadCount}'),
                ),
              ],
            ),
          ),
          if (user.role == UserRole.student) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final game = state.myGameStats();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(l10n.achievements),
                    subtitle: Text(
                      '${game.points} pts · ${game.badges.length} badges · '
                      '${game.streak}-day streak',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AchievementsScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.language),
              subtitle: Text(
                state.locale == null
                    ? l10n.systemDefault
                    : AppLocalizations.languageName(state.locale!.languageCode),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSheet(context, state),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: state.logout,
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, AppState state) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        Widget option(String title, Locale? locale, bool selected) => ListTile(
              title: Text(title),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () {
                state.setLocale(locale);
                Navigator.of(sheetContext).pop();
              },
            );
        final current = state.locale?.languageCode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              option(l10n.systemDefault, null, state.locale == null),
              for (final locale in AppLocalizations.supportedLocales)
                option(
                  AppLocalizations.languageName(locale.languageCode),
                  locale,
                  current == locale.languageCode,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final hasPassword = state.currentUser?.hasPassword ?? false;
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (hasPassword && current.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await state.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    switch (result) {
      case ChangePasswordResult.success:
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated.')),
        );
      case ChangePasswordResult.wrongCurrentPassword:
        setState(() {
          _busy = false;
          _error = 'Current password is incorrect.';
        });
      case ChangePasswordResult.notSignedIn:
        setState(() {
          _busy = false;
          _error = 'You are not signed in.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = context.read<AppState>().currentUser?.hasPassword ?? false;
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPassword) ...[
            TextField(
              controller: _currentCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _newCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
