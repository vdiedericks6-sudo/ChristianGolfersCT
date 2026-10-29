/// The signed-in golfer, independent of who is providing authentication.
///
/// Keeping Supabase's `User` out of the app means the demo backend can supply
/// a golfer without a network call, and swapping auth providers later touches
/// one file instead of every screen.
class ChristianGolferUser {
  const ChristianGolferUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Best available name, falling back to the email local part.
  String get bestName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final address = email;
    if (address != null && address.contains('@')) {
      return address.split('@').first;
    }

    return 'Christian Golfer';
  }

  @override
  bool operator ==(Object other) => other is ChristianGolferUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
