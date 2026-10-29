import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';

class AdminPrivacyRequest {
  const AdminPrivacyRequest({
    required this.id,
    required this.type,
    required this.email,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String email;
  final String message;
  final String status;
  final DateTime? createdAt;

  factory AdminPrivacyRequest.fromJson(Map<String, dynamic> row) =>
      AdminPrivacyRequest(
        id: row['id'] as String? ?? '',
        type: row['request_type'] as String? ?? 'privacy_question',
        email: row['requester_email'] as String? ?? '',
        message: row['message'] as String? ?? '',
        status: row['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      );
}

final adminPrivacyRequestsProvider =
    FutureProvider.autoDispose<List<AdminPrivacyRequest>>((ref) async {
      final client = ref.watch(supabaseClientProvider);
      final result = await client.rpc('admin_privacy_requests');
      if (result is! List) {
        throw const FormatException(
          'The privacy request inbox is unavailable.',
        );
      }
      return result
          .whereType<Map<String, dynamic>>()
          .map(AdminPrivacyRequest.fromJson)
          .toList(growable: false);
    });

Future<void> closeAdminPrivacyRequest(WidgetRef ref, String id) async {
  await ref
      .read(supabaseClientProvider)
      .rpc('admin_close_privacy_request', params: {'p_request_id': id});
}

Future<bool> deleteAdminPrivacyRequestAccount(
  WidgetRef ref,
  String requestId,
) async {
  final response = await ref
      .read(supabaseClientProvider)
      .functions
      .invoke(
        'account-center',
        body: {'action': 'admin-delete-request', 'requestId': requestId},
      );
  if (response.status < 200 || response.status >= 300) {
    throw StateError('The account deletion request could not be processed.');
  }
  return response.data is Map && response.data['accountFound'] == true;
}
