import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/seed.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.16),
              scheme.tertiary.withValues(alpha: 0.10),
              scheme.surface,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.primary, scheme.tertiary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LMS Learning Platform',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Courses, progress tracking and notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  const _LoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  bool _registerMode = false;
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.student;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _busy = false;
    });
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    setState(() {
      _error = null;
      _busy = true;
    });
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty) {
      _fail('Enter an email.');
      return;
    }
    if (password.isEmpty) {
      _fail('Enter a password.');
      return;
    }
    if (_registerMode) {
      if (_nameCtrl.text.trim().isEmpty) {
        _fail('Enter your name.');
        return;
      }
      if (password.length < 6) {
        _fail('Password must be at least 6 characters.');
        return;
      }
      if (_confirmCtrl.text != password) {
        _fail('Passwords do not match.');
        return;
      }
      final user = await state.register(
        name: _nameCtrl.text,
        email: email,
        password: password,
        role: _role,
      );
      if (user == null && mounted) {
        _fail('An account with that email already exists.');
      }
    } else {
      final ok = await state.login(email, password);
      if (!ok && mounted) {
        _fail('Incorrect email or password.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Sign in')),
                ButtonSegment(value: true, label: Text('Sign up')),
              ],
              selected: {_registerMode},
              onSelectionChanged: (s) =>
                  setState(() => _registerMode = s.first),
            ),
            const SizedBox(height: 16),
            if (_registerMode) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_registerMode) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.student,
                    label: Text('Student'),
                    icon: Icon(Icons.menu_book),
                  ),
                  ButtonSegment(
                    value: UserRole.instructor,
                    label: Text('Instructor'),
                    icon: Icon(Icons.co_present),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_registerMode ? 'Create account' : 'Sign in'),
            ),
            if (!_registerMode) ...[
              const Divider(height: 32),
              Text(
                'Demo accounts',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'One-tap sign in, or use password "$kDemoPassword".',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ...state.allUsers.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Material(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        child: Text(u.initials),
                      ),
                      title: Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${u.email} · ${u.role.label}'),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: () => state.loginAs(u),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
