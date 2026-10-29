import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../authentication/presentation/login_screen.dart';
import '../data/pending_join.dart';
import '../data/round_link.dart';
import 'round_providers.dart';

/// Landing screen for a shared `/join/<code>` link.
///
/// Signed in, it joins straight away. Signed out, it parks the code so the
/// golfer lands in the round after Google sends them back.
class JoinLinkScreen extends ConsumerStatefulWidget {
  const JoinLinkScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<JoinLinkScreen> createState() => _JoinLinkScreenState();
}

class _JoinLinkScreenState extends ConsumerState<JoinLinkScreen> {
  bool _started = false;
  String? _error;

  String get _code => RoundLink.normalise(widget.code);

  Future<void> _join() async {
    try {
      final roundId = await ref
          .read(roundRepositoryProvider)
          .joinRoundByCode(_code);

      await PendingJoin.clear();

      if (mounted) context.go('/rounds/$roundId/lobby');
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!RoundLink.isValid(widget.code)) {
      return _JoinMessage(
        title: 'That link looks wrong',
        message: 'A round code is six characters, like DVT247. Ask whoever '
            'invited you to send the link again.',
        onHome: () => context.go('/home'),
      );
    }

    if (_error != null) {
      return _JoinMessage(
        title: 'Could not join',
        message: _error!,
        onHome: () => context.go('/home'),
      );
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _JoinSpinner(),
      error: (error, stackTrace) => _JoinMessage(
        title: 'Could not join',
        message: '$error',
        onHome: () => context.go('/home'),
      ),
      data: (user) {
        if (user == null) {
          // Park the code, then let them sign in. AuthGate finishes the join.
          PendingJoin.remember(_code);
          return _InviteLogin(code: _code);
        }

        if (!_started) {
          _started = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _join());
        }

        return const _JoinSpinner();
      },
    );
  }
}

class _JoinSpinner extends StatelessWidget {
  const _JoinSpinner();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Joining the round...'),
          ],
        ),
      ),
    );
  }
}

class _JoinMessage extends StatelessWidget {
  const _JoinMessage({
    required this.title,
    required this.message,
    required this.onHome,
  });

  final String title;
  final String message;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onHome, child: const Text('Go to Christian Golfers Cape Town')),
            ],
          ),
        ),
      ),
    );
  }
}

/// The normal login screen with an invitation banner above it, so the golfer
/// knows why they are being asked to sign in.
class _InviteLogin extends StatelessWidget {
  const _InviteLogin({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const LoginScreen(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.golf_course_rounded,
                    color: AppTheme.forestDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You've been invited to round $code. "
                      'Sign in and we\'ll take you straight there.',
                      style: const TextStyle(
                        color: AppTheme.forestDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
