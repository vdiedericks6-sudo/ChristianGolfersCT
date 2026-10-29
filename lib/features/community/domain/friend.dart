import '../../../core/data/json_parsing.dart';

/// Where a friendship stands from the signed-in golfer's point of view.
enum FriendshipState {
  /// They asked; you have not answered.
  incomingRequest,

  /// You asked; they have not answered.
  outgoingRequest,

  /// Both sides agreed.
  accepted,
}

class Friend {
  const Friend({
    required this.id,
    required this.displayName,
    required this.state,
    this.email,
    this.photoUrl,
    this.handicapIndex,
    this.since,
  });

  final String id;
  final String displayName;
  final FriendshipState state;
  final String? email;
  final String? photoUrl;
  final double? handicapIndex;
  final DateTime? since;

  bool get isAccepted => state == FriendshipState.accepted;
  bool get needsMyAnswer => state == FriendshipState.incomingRequest;
  bool get isWaitingOnThem => state == FriendshipState.outgoingRequest;

  factory Friend.fromJson(Json data) {
    final status = asString(data['status'], 'pending');
    final direction = asString(data['direction'], 'outgoing');

    return Friend(
      id: asString(data['golfer_id']),
      displayName: asString(data['display_name'], 'Christian Golfer'),
      email: asStringOrNull(data['email']),
      photoUrl: asStringOrNull(data['photo_url']),
      handicapIndex: asDoubleOrNull(data['handicap_index']),
      since: asDateOrNull(data['created_at']),
      state: status == 'accepted'
          ? FriendshipState.accepted
          : direction == 'incoming'
              ? FriendshipState.incomingRequest
              : FriendshipState.outgoingRequest,
    );
  }
}
