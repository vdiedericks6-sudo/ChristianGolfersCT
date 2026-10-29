import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/christian_golfers_logo.dart';
import '../../faith/presentation/daily_verse_text.dart';
import 'auth_error_message.dart';
import 'auth_providers.dart';

/// Sign in screen matching Screen 1 & 8 in the Christian Golfers Cape Town branding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted && !kIsWeb) setState(() => _busy = false);
    }
  }

  Future<void> _chooseSignInMethod() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.85,
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: _EmailAccessSheet(
            onGoogle: () {
              Navigator.pop(sheetContext);
              _signInWithGoogle();
            },
            onEmailComplete: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Use the supplied Table Mountain photo as a full-screen landing image.
          Image.asset(
            'assets/images/golf_landing_table_mountain.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stack) =>
                const CourseArtwork(seed: 'login-bg', overlay: false),
          ),

          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x9920292D),
                  Color(0xCC20292D),
                  Color(0xFA20292D),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // Circular Logo Icon
                  const ChristianGolfersLogo(
                    width: 260,
                    height: 140,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'FAITH • GOLF • FELLOWSHIP',
                    textAlign: TextAlign.center,
                    style: AppTheme.label(
                      10,
                      colour: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  const Spacer(),

                  // Verse / Quote
                  DailyVerseText(
                    textAlign: TextAlign.center,
                    verseStyle: AppTheme.body(
                      13.5,
                      colour: Colors.white.withValues(alpha: 0.95),
                    ),
                    referenceStyle: AppTheme.body(
                      12,
                      colour: AppTheme.primaryGreenLight,
                      weight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Get Started / Sign In Button
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _chooseSignInMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: const Color(0xFF19201D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: AppTheme.body(
                              15,
                              weight: FontWeight.w700,
                              colour: const Color(0xFF19201D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: const Color(0xFF19201D),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cursive Tagline
                  Text(
                    'Play with Purpose',
                    style: AppTheme.scriptAccent(
                      32,
                      colour: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailAccessSheet extends ConsumerStatefulWidget {
  const _EmailAccessSheet({
    required this.onGoogle,
    required this.onEmailComplete,
  });
  final VoidCallback onGoogle;
  final VoidCallback onEmailComplete;

  @override
  ConsumerState<_EmailAccessSheet> createState() => _EmailAccessSheetState();
}

class _EmailAccessSheetState extends ConsumerState<_EmailAccessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_register) {
        await auth.signUpWithPassword(
          displayName: _name.text,
          email: _email.text,
          password: _password.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to confirm, then sign in.',
              ),
            ),
          );
          widget.onEmailComplete();
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text,
          password: _password.text,
        );
        if (mounted) widget.onEmailComplete();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _register ? 'Create your account' : 'Welcome back',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : widget.onGoogle,
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continue with Google'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(),
        ),
        if (_register)
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
          ),
        if (_register) const SizedBox(height: 10),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email address'),
          validator: (v) => (v?.contains('@') ?? false)
              ? null
              : 'Enter a valid email address',
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _password,
          obscureText: true,
          autofillHints: _register
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (v) =>
              (v?.length ?? 0) >= 8 ? null : 'Use at least 8 characters',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(
            _busy
                ? 'Please wait…'
                : _register
                ? 'Create account'
                : 'Sign in with email',
          ),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() => _register = !_register),
          child: Text(
            _register
                ? 'Already registered? Sign in'
                : 'New here? Create an account',
          ),
        ),
      ],
    ),
  );
}
