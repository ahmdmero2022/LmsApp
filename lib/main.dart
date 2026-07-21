import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/root_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  runApp(const LmsApp());
}

class LmsApp extends StatelessWidget {
  const LmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'LMS',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return state.isLoggedIn ? const RootShell() : const LoginScreen();
  }
}
