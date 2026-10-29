import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'community_providers.dart';

/// Bottom sheet for adding a golfer to your crew by email address.
Future<void> showAddFriendSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _AddFriendForm(),
    ),
  );
}

class _AddFriendForm extends ConsumerStatefulWidget {
  const _AddFriendForm();

  @override
  ConsumerState<_AddFriendForm> createState() => _AddFriendFormState();
}

class _AddFriendFormState extends ConsumerState<_AddFriendForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(communityRepositoryProvider)
          .sendFriendRequest(_emailController.text);

      invalidateCommunity(ref);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _readable(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Postgres errors arrive wrapped; show the sentence, not the stack.
  String _readable(Object error) {
    final text = error.toString();
    final match = RegExp(r'([A-Z][^:]*\.)\s*$').firstMatch(text);
    return match?.group(1) ?? text.replaceFirst(RegExp(r'^\w+Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add a golfer',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the email address they signed in to Christian Golfers with. They will '
              'see your request the next time they open the app.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_busy) _send();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}
