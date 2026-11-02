import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../data/admin_league_dashboard_repository.dart';

class MemberHandicapDialog extends ConsumerStatefulWidget {
  const MemberHandicapDialog({required this.member, super.key});
  final AdminLeagueMember member;

  @override
  ConsumerState<MemberHandicapDialog> createState() => _MemberHandicapDialogState();
}

class _MemberHandicapDialogState extends ConsumerState<MemberHandicapDialog> {
  final _form = GlobalKey<FormState>();
  late final _index = TextEditingController(
    text: widget.member.handicapIndex?.toStringAsFixed(1) ?? '',
  );
  final _source = TextEditingController();
  late bool _visiting = widget.member.visiting;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _index.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(supabaseClientProvider).rpc(
        'admin_update_golfer_handicap',
        params: {
          'p_member_id': widget.member.userId,
          'p_handicap': double.tryParse(_index.text.trim()),
          'p_source': _source.text.trim(),
          'p_is_visiting_golfer': _visiting,
        },
      );
      if (!mounted) return;
      ref.invalidate(adminLeagueDashboardProvider);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error =
        'Could not save. Check your connection and administrator access, then retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text('Handicap: ${widget.member.displayName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _index,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Handicap Index',
                helperText: 'Blank clears the index. Use -2.0 for a plus-2 index.',
                helperMaxLines: 3,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return null;
                final index = double.tryParse(value!.trim());
                return index == null || !index.isFinite || index < -10 || index > 54
                  ? 'Enter a number between -10 and 54.' : null;
              },
            ),
            TextFormField(
              controller: _source,
              enabled: !_saving,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Source of handicap'),
              validator: (value) => _index.text.trim().isNotEmpty &&
                  (value ?? '').trim().isEmpty ? 'Record the source, such as a club record.' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visiting golfer'),
              value: _visiting,
              onChanged: _saving ? null : (value) => setState(() => _visiting = value),
            ),
            const Text('Current league classification follows the configured handicap thresholds. Existing round handicap snapshots are unchanged.'),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
      ],
    ),
  );
}
