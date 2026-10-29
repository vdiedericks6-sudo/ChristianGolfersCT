import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_back_button.dart';

import '../data/round_link.dart';
import 'round_providers.dart';

class JoinRoundScreen extends ConsumerStatefulWidget {
  const JoinRoundScreen({super.key});

  @override
  ConsumerState<JoinRoundScreen> createState() => _JoinRoundScreenState();
}

class _JoinRoundScreenState extends ConsumerState<JoinRoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final roundId = await ref
          .read(roundRepositoryProvider)
          .joinRoundByCode(RoundLink.normalise(_codeController.text));

      if (mounted) {
        context.go('/rounds/$roundId/lobby');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Join a round'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.group_add_rounded,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enter the round code',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask the host for their six-character Christian Golfers Cape Town code.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      // No maxLength: a pasted invite link must fit, and
                      // RoundLink.normalise pulls the code back out of it.
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Round code or invite link',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (value) {
                        // Accepts a pasted invite link as well as a bare code.
                        if (!RoundLink.isValid(value ?? '')) {
                          return 'Enter all six characters.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_busy) _join();
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _join,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Join round'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
