/// Imported starting League A standings transcribed from the supplied CGGT
/// "A Division Standings — Top 7 Scores" screenshot.
///
/// These are historical aggregate totals only. No round-by-round score/points
/// records were supplied, so they must not be used to reconstruct round awards.
class LeagueAStandingSnapshotEntry {
  const LeagueAStandingSnapshotEntry({
    required this.position,
    required this.firstName,
    required this.initials,
    required this.surname,
    required this.totalPoints,
  });

  final int position;
  final String firstName;
  final String initials;
  final String surname;
  final int totalPoints;

  String get fullName => '$firstName $surname';
}

const leagueAStartingStandings = <LeagueAStandingSnapshotEntry>[
  LeagueAStandingSnapshotEntry(position: 1, firstName: 'Ross', initials: 'L.', surname: 'Meiring', totalPoints: 259),
  LeagueAStandingSnapshotEntry(position: 2, firstName: 'Jehiel', initials: 'L.', surname: 'Blignaut', totalPoints: 249),
  LeagueAStandingSnapshotEntry(position: 3, firstName: 'Jerome', initials: 'L.', surname: 'Meiring', totalPoints: 244),
  LeagueAStandingSnapshotEntry(position: 4, firstName: 'Joe', initials: 'L.', surname: 'Naidoo', totalPoints: 244),
  LeagueAStandingSnapshotEntry(position: 5, firstName: 'Raymond', initials: 'L.', surname: 'Karelse', totalPoints: 241),
  LeagueAStandingSnapshotEntry(position: 6, firstName: 'Vernon', initials: 'L.', surname: 'Arendse', totalPoints: 240),
  LeagueAStandingSnapshotEntry(position: 7, firstName: 'Donovan', initials: 'L.', surname: 'Pedro', totalPoints: 231),
  LeagueAStandingSnapshotEntry(position: 8, firstName: 'Wynne', initials: 'L.', surname: 'Jordan', totalPoints: 229),
  LeagueAStandingSnapshotEntry(position: 9, firstName: 'Jaco', initials: 'L.', surname: 'Oosthuizen', totalPoints: 228),
  LeagueAStandingSnapshotEntry(position: 10, firstName: 'Wesley', initials: 'L.', surname: 'Smith', totalPoints: 227),
  LeagueAStandingSnapshotEntry(position: 11, firstName: 'Jerome', initials: 'L.', surname: 'Gabriels', totalPoints: 225),
  LeagueAStandingSnapshotEntry(position: 12, firstName: 'Peter', initials: 'L.', surname: 'Abrahams', totalPoints: 214),
  LeagueAStandingSnapshotEntry(position: 13, firstName: 'Dean', initials: 'L.', surname: 'Carelse', totalPoints: 212),
  LeagueAStandingSnapshotEntry(position: 14, firstName: 'Hennie', initials: 'L.', surname: 'Pretorius', totalPoints: 212),
  LeagueAStandingSnapshotEntry(position: 15, firstName: 'Gilmore', initials: 'L.', surname: 'Doolings', totalPoints: 137),
  LeagueAStandingSnapshotEntry(position: 16, firstName: 'Brandon', initials: 'L.', surname: 'Swanepoel', totalPoints: 130),
  LeagueAStandingSnapshotEntry(position: 17, firstName: 'Volant', initials: 'L.', surname: 'Willis', totalPoints: 130),
  LeagueAStandingSnapshotEntry(position: 18, firstName: 'Fanie', initials: 'L.', surname: 'Van der Merwe', totalPoints: 129),
  LeagueAStandingSnapshotEntry(position: 19, firstName: 'Anand', initials: 'L.', surname: 'Wait', totalPoints: 77),
  LeagueAStandingSnapshotEntry(position: 20, firstName: 'Shaun', initials: 'L.', surname: 'Pereth', totalPoints: 53),
  LeagueAStandingSnapshotEntry(position: 21, firstName: 'Grant', initials: 'L.', surname: 'Pereth', totalPoints: 50),
];

const leagueBStartingStandings = <LeagueAStandingSnapshotEntry>[
  LeagueAStandingSnapshotEntry(position: 1, firstName: 'Jurgen', initials: 'L.', surname: 'Beck', totalPoints: 371),
  LeagueAStandingSnapshotEntry(position: 2, firstName: 'Julian', initials: 'L.', surname: 'Voigt', totalPoints: 359),
  LeagueAStandingSnapshotEntry(position: 3, firstName: 'Adrian', initials: 'L.', surname: 'Dobbin (C)', totalPoints: 328),
  LeagueAStandingSnapshotEntry(position: 4, firstName: 'Neil', initials: 'L.', surname: 'Booysen', totalPoints: 313),
  LeagueAStandingSnapshotEntry(position: 5, firstName: 'Heinrich', initials: 'L.', surname: 'Behr', totalPoints: 307),
  LeagueAStandingSnapshotEntry(position: 6, firstName: 'Jacques', initials: 'L.', surname: 'Snyders', totalPoints: 272),
  LeagueAStandingSnapshotEntry(position: 7, firstName: 'Jonothan', initials: 'L.', surname: 'Martheze', totalPoints: 207),
  LeagueAStandingSnapshotEntry(position: 8, firstName: 'Riaan', initials: 'L.', surname: 'Dippenaar', totalPoints: 196),
  LeagueAStandingSnapshotEntry(position: 9, firstName: 'Vincent', initials: 'L.', surname: 'September', totalPoints: 188),
  LeagueAStandingSnapshotEntry(position: 10, firstName: 'Martin', initials: 'L.', surname: 'Eygenberg', totalPoints: 186),
  LeagueAStandingSnapshotEntry(position: 11, firstName: 'Sam', initials: 'L.', surname: 'Oyugi', totalPoints: 154),
  LeagueAStandingSnapshotEntry(position: 12, firstName: 'Clifton', initials: 'L.', surname: 'Carolus', totalPoints: 93),
  LeagueAStandingSnapshotEntry(position: 13, firstName: 'Edeon', initials: 'L.', surname: 'Wyngaard', totalPoints: 47),
];
