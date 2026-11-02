import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';

class TestFeedbackScreen extends ConsumerStatefulWidget {
  const TestFeedbackScreen({super.key});
  @override
  ConsumerState<TestFeedbackScreen> createState() => _TestFeedbackScreenState();
}

class _TestFeedbackScreenState extends ConsumerState<TestFeedbackScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _category = 'scoring';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      await ref.read(supabaseClientProvider).from('member_test_feedback').insert({
        'category': _category,
        'description': _description.text.trim(),
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Feedback sent. Thank you.')));
    } catch (_) {
      if (mounted) setState(() => _error = 'Feedback was not sent. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Testing feedback')),
      body: SafeArea(child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Tell the league administrators what happened. Include the course and hole if relevant.'),
        const SizedBox(height: 10),
        const Text('Your account is attached so the team can follow up. Do not include passwords or sensitive information.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Area'),
          items: const [
            DropdownMenuItem(value:'scoring',child:Text('Scoring and rounds')),
            DropdownMenuItem(value:'course',child:Text('Course information')),
            DropdownMenuItem(value:'gps',child:Text('GPS and maps')),
            DropdownMenuItem(value:'sign-in',child:Text('Sign-in')),
            DropdownMenuItem(value:'performance',child:Text('Speed and battery')),
            DropdownMenuItem(value:'other',child:Text('Other')),
          ], onChanged: _sending ? null : (value) => setState(() => _category = value!)),
        const SizedBox(height: 16),
        TextFormField(controller: _description, enabled: !_sending, maxLength: 2000, minLines: 4, maxLines: 8,
          decoration: const InputDecoration(labelText:'What happened?',hintText:'What did you expect, and what happened instead?'),
          validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Please add at least 10 characters.' : null),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _sending ? null : _submit, child: Text(_sending ? 'Sending…' : 'Send feedback')),
      ]))),
    ),
  );
}
