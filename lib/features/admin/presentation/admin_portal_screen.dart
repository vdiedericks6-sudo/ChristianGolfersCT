import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import 'admin_dashboard_screen.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../profile/presentation/profile_providers.dart';

class AdminPortalScreen extends ConsumerWidget {
  const AdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(currentUserIsAdminProvider);
    return adminState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not verify owner/captain access.\n$error'),
          ),
        ),
      ),
      data: (authorized) => authorized
          ? const AdminDashboardScreen()
          : Scaffold(
              backgroundColor: AppTheme.pageBg,
              appBar: AppBar(
                backgroundColor: AppTheme.darkNavy,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => context.pop(),
                ),
                title: const Text('Owner / captain sign-in'),
                centerTitle: true,
              ),
              body: const _AdminSignIn(),
            ),
    );
  }
}

class _AdminSignIn extends ConsumerStatefulWidget {
  const _AdminSignIn();

  @override
  ConsumerState<_AdminSignIn> createState() => _AdminSignInState();
}

class _AdminSignInState extends ConsumerState<_AdminSignIn> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: _username.text, password: _password.text);
      final authorized = await ref.refresh(currentUserIsAdminProvider.future);
      if (!authorized) {
        await ref.read(authRepositoryProvider).signOut();
        setState(
          () => _error = 'This account is not on the administrator allowlist.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Sign-in failed. Check the account details and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ChristianGolfersCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 42,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Administrator sign-in',
                textAlign: TextAlign.center,
                style: AppTheme.display(22),
              ),
              const SizedBox(height: 8),
              Text(
                'Use a provisioned admin account. Access is checked against the secure server allowlist.',
                textAlign: TextAlign.center,
                style: AppTheme.body(12, colour: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _username,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Username (email address)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (_) => _signIn(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppTheme.body(12, colour: AppTheme.danger),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _signIn,
                child: Text(_busy ? 'Checking access…' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
