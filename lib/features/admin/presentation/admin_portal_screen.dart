import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../profile/presentation/profile_providers.dart';

class AdminPortalScreen extends ConsumerWidget {
  const AdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentProfileProvider);
    final adminState = ref.watch(currentUserIsAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.shield_outlined, size: 20),
            SizedBox(width: 8),
            Text('Admin Portal'),
          ],
        ),
        centerTitle: true,
      ),
      body: adminState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not verify admin access: $error')),
        data: (authorized) {
          if (!authorized) {
            return const _AdminSignIn();
          }
          return profileState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Could not load profile: $error')),
            data: (_) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  children: [
                    _AdminTileScreen7(
                      icon: Icons.people_outline_rounded,
                      title: 'Manage Members',
                      subtitle: 'View and update member profiles',
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _AdminTileScreen7(
                      icon: Icons.shield_outlined,
                      title: 'League Configuration',
                      subtitle: 'Set thresholds and rules',
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _AdminTileScreen7(
                      icon: Icons.location_on_rounded,
                      title: 'Handicap Management',
                      subtitle: 'Record existing handicaps',
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _AdminTileScreen7(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Member Data Import',
                      subtitle: 'Bulk upload player and member data',
                      badge: 'Coming Soon',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),

                    // Upload Box Card matching Screen 7
                    ChristianGolfersCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.upload_outlined,
                              color: AppTheme.primaryGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload member register',
                            style: AppTheme.body(14, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CSV or Excel import will be supported when this feature is implemented.',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                              11.5,
                              colour: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
      if (mounted)
        setState(
          () => _error =
              'Sign-in failed. Check the account details and try again.',
        );
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

class _AdminTileScreen7 extends StatelessWidget {
  const _AdminTileScreen7({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(14, weight: FontWeight.w700),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge!,
                          style: AppTheme.body(
                            9.5,
                            colour: AppTheme.primaryGreen,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
