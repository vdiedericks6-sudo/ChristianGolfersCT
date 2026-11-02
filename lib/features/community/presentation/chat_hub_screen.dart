import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import 'community_screen.dart';

final chatMessagesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return [];
  return ref.watch(supabaseClientProvider).from('member_messages')
    .select('id,sender_id,body,created_at,profiles(display_name)')
    .order('created_at', ascending: false).limit(100);
});

class ChatHubScreen extends ConsumerStatefulWidget {
  const ChatHubScreen({super.key});
  @override
  ConsumerState<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends ConsumerState<ChatHubScreen> {
  final _message = TextEditingController();
  Timer? _timer;
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        ref.invalidate(chatMessagesProvider);
      }
    });
  }
  @override
  void dispose() { _timer?.cancel(); _message.dispose(); super.dispose(); }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (_sending || body.isEmpty || body.length > 2000) return;
    setState(() => _sending = true);
    try {
      await ref.read(supabaseClientProvider).from('member_messages').insert({'body': body});
      if (!mounted) return;
      _message.clear();
      ref.invalidate(chatMessagesProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not confirmed. Check the feed before retrying.')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete this message?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(supabaseClientProvider).from('member_messages').delete().eq('id', id);
      if (mounted) ref.invalidate(chatMessagesProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the message.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final admin = ref.watch(currentUserIsAdminProvider).valueOrNull ?? false;
    final messages = ref.watch(chatMessagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chat hub'), actions: [
        IconButton(tooltip: 'Refresh messages', onPressed: () => ref.invalidate(chatMessagesProvider), icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Golfing friends', icon: const Icon(Icons.people_outline), onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FellowshipMembersScreen()))),
      ]),
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('Shared with app members · latest 100 messages · refreshes every 10 seconds')),
        Expanded(child: messages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: TextButton(onPressed: () => ref.invalidate(chatMessagesProvider), child: const Text('Could not load messages. Retry'))),
          data: (rows) => rows.isEmpty ? const Center(child: Text('No messages yet.')) : ListView.builder(
            reverse: true, itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final profile = row['profiles'] as Map<String, dynamic>?;
              return ListTile(
                title: Text(profile?['display_name'] as String? ?? 'Member'),
                subtitle: Text(row['body'] as String),
                trailing: row['sender_id'] == me || admin ? IconButton(
                  tooltip: 'Delete message', icon: const Icon(Icons.delete_outline),
                  onPressed: () => _remove(row['id'] as String),
                ) : null,
              );
            },
          ),
        )),
        Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: TextField(controller: _message, enabled: me != null && !_sending,
            minLines: 1, maxLines: 4, maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Message members'))),
          IconButton(tooltip: 'Send message', onPressed: me == null || _sending ? null : _send,
            icon: _sending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()) : const Icon(Icons.send)),
        ])),
      ])),
    );
  }
}
