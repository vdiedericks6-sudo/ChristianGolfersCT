import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../authentication/presentation/auth_providers.dart';

const _privacyUrl =
    'https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=privacy';
const _deleteUrl =
    'https://cegmyadsnrvzlgpwoezu.supabase.co/functions/v1/account-center?view=delete';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _deleting = false;

  Future<void> _open(String value) async {
    final uri = Uri.parse(value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the page. Please try again.'),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account, profile, friendships, scores, and results. Rounds you hosted and every player’s records from those rounds will also be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final response = await ref
          .read(supabaseClientProvider)
          .functions
          .invoke('account-center', body: {'action': 'delete-account'});
      if (response.status < 200 || response.status >= 300) {
        throw StateError('The account could not be deleted.');
      }
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deletion failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.pageBg,
    appBar: AppBar(
      backgroundColor: AppTheme.darkNavy,
      leading: const AppBackButton(),
      title: const Text('Privacy & account'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your data and choices', style: AppTheme.display(24)),
        const SizedBox(height: 8),
        Text(
          'Christian Golfers Cape Town stores account and profile details, handicap information, round participants, hole scores and league results. Round members and allowlisted league administrators can view relevant scores and standings.',
          style: AppTheme.body(14, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 14),
        Text(
          'Deleting your account removes your account and linked golf records. Hosted rounds and the associated player records are removed too. Read the full policy before continuing.',
          style: AppTheme.body(14, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => _open(_privacyUrl),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Read privacy policy'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _open(_deleteUrl),
          icon: const Icon(Icons.language_rounded),
          label: const Text('Request deletion without the app'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _deleting ? null : _deleteAccount,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(_deleting ? 'Deleting account…' : 'Delete my account'),
        ),
      ],
    ),
  );
}
