class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    required this.holesCompleted,
    required this.grossTotal,
    required this.netTotal,
    required this.grossToPar,
    required this.netToPar,
    required this.position,
    required this.isCurrentUser,
  });

  final String playerId;
  final String displayName;
  final int holesCompleted;
  final int grossTotal;
  final int netTotal;
  final int grossToPar;
  final int netToPar;
  final int position;
  final bool isCurrentUser;

  LeaderboardEntry copyWith({int? position}) {
    return LeaderboardEntry(
      playerId: playerId,
      displayName: displayName,
      holesCompleted: holesCompleted,
      grossTotal: grossTotal,
      netTotal: netTotal,
      grossToPar: grossToPar,
      netToPar: netToPar,
      position: position ?? this.position,
      isCurrentUser: isCurrentUser,
    );
  }
}
