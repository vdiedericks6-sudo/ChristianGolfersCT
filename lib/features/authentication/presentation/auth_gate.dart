import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/christian_golfer_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../rounds/data/pending_join.dart';
import '../../rounds/presentation/round_providers.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _handledUserId;

  void _openAuthenticatedApp(ChristianGolferUser user) {
    if (_handledUserId == user.id) {
      return;
    }

    _handledUserId = user.id;
    unawaited(_bootstrap(user));
  }

  /// Make sure the profile row exists, then honour any invite link the golfer
  /// followed before signing in.
  Future<void> _bootstrap(ChristianGolferUser user) async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .ensureProfileExists(user)
          .timeout(const Duration(seconds: 8));
    } catch (error) {
      // The auth trigger normally creates it; never block startup on this.
      debugPrint('Unable to ensure profile exists: $error');
    }

    var destination = '/home';

    try {
      final pendingCode = await PendingJoin.take();

      if (pendingCode != null) {
        final roundId = await ref
            .read(roundRepositoryProvider)
            .joinRoundByCode(pendingCode);
        destination = '/rounds/$roundId/lobby';
      }
    } catch (error) {
      debugPrint('Could not complete the invited join: $error');
    }

    if (mounted) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          _handledUserId = null;
          return const LoginScreen();
        }

        _openAuthenticatedApp(user);

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to check your login status.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
