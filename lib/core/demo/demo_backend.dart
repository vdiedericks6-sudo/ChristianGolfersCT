import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/authentication/data/auth_repository.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/community/domain/friend.dart';
import '../../features/community/domain/friend_activity.dart';
import '../../features/community/domain/friend_standing.dart';
import '../../features/courses/data/course_repository.dart';
import '../../features/courses/domain/golf_course.dart';
import '../../features/courses/domain/golf_hole.dart';
import '../../features/courses/domain/tee_set.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/ranges/data/driving_range_repository.dart';
import '../../features/ranges/domain/driving_range.dart';
import '../../features/rounds/data/round_repository.dart';
import '../../features/rounds/domain/golf_round.dart';
import '../../features/rounds/domain/round_player.dart';
import '../../features/scorecard/data/score_repository.dart';
import '../../features/scorecard/domain/hole_score.dart';
import '../auth/christian_golfer_user.dart';
import 'demo_seed.dart';

/// An in-memory stand-in for Supabase.
///
/// Everything lives in this object: no network, no database, no sign-in. It
/// exists so the app can be run and clicked through end to end before the
/// backend is provisioned, and so screens can be built against realistic data.
///
/// Enable with `--dart-define=CHRISTIAN_GOLFERS_DEMO=true`.
class DemoBackend {
  DemoBackend._(this._seed) {
    _profiles = Map.of(_seed.profiles);
    _rounds = Map.of(_seed.rounds);
    _players = {
      for (final entry in _seed.players.entries) entry.key: [...entry.value],
    };
    _scores = {
      for (final entry in _seed.scores.entries) entry.key: [...entry.value],
    };

    _courses = [..._seed.courses];
    _ranges = [..._seed.ranges];
    _teeSets = {
      for (final entry in _seed.teeSets.entries) entry.key: [...entry.value],
    };
    _holes = {
      for (final entry in _seed.holes.entries) entry.key: [...entry.value],
    };

    _friendships = <String, FriendshipState>{
      DemoIds.sipho: FriendshipState.accepted,
      DemoIds.anna: FriendshipState.accepted,
      DemoIds.dave: FriendshipState.incomingRequest,
    };

    _startOpponentTicker();

    // The full South African catalogue lives in the app's assets. Loading it
    // is async, so the demo opens instantly on the built-in course and swaps
    // in all 361 the moment they are parsed - every stream re-emits on _bump.
    unawaited(_loadRealCatalogue());
  }

  factory DemoBackend.seeded() => DemoBackend._(DemoSeed.build());

  final DemoSeed _seed;

  late final Map<String, UserProfile> _profiles;
  late final Map<String, GolfRound> _rounds;
  late final Map<String, List<RoundPlayer>> _players;
  late final Map<String, List<HoleScore>> _scores;
  late final Map<String, FriendshipState> _friendships;

  late List<GolfCourse> _courses;
  late List<DrivingRange> _ranges;
  late Map<String, List<TeeSet>> _teeSets;
  late Map<String, List<GolfHole>> _holes;

  bool catalogueLoaded = false;

  ChristianGolferUser? _currentUser = const ChristianGolferUser(
    id: DemoIds.you,
    email: 'you@christiangolfers.example',
    displayName: 'You',
  );

  final _revision = StreamController<int>.broadcast();
  int _revisionCount = 0;
  Timer? _ticker;
  final _random = Random(20260902);

  void _bump() {
    _revisionCount++;
    if (!_revision.isClosed) _revision.add(_revisionCount);
  }

  /// Emits the current value immediately, then again after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _revision.stream.map((_) => read());
  }

  String? get currentUserId => _currentUser?.id;

  List<UserProfile> get allProfiles => _profiles.values.toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

  double leagueAMaxHandicap = 12.0;
  double leagueBMaxHandicap = 24.0;

  Future<void> updateGolferHandicap({
    required String userId,
    required double? handicapIndex,
    required bool isVisitingGolfer,
    required String? source,
  }) async {
    final existing = _profiles[userId];
    if (existing == null) return;
    _profiles[userId] = existing.copyWith(
      estimatedHandicapIndex: handicapIndex,
      clearHandicap: handicapIndex == null,
      isVisitingGolfer: isVisitingGolfer,
      handicapSource: handicapIndex == null ? null : source,
      clearHandicapSource: handicapIndex == null,
      handicapVerifiedAt: handicapIndex == null ? null : DateTime.now(),
      clearHandicapVerifiedAt: handicapIndex == null,
      updatedAt: DateTime.now(),
    );
    _bump();
  }

  Future<void> updateLeagueThresholds({
    required double leagueAMax,
    required double leagueBMax,
  }) async {
    leagueAMaxHandicap = leagueAMax;
    leagueBMaxHandicap = leagueBMax;
    _bump();
  }

  // ---------------------------------------------------------------------
  // Simulated playing partners
  // ---------------------------------------------------------------------

  /// Every few seconds one of the other golfers posts a score, so the live
  /// leaderboard actually moves while you look at it.
  void _startOpponentTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 6), (_) {
      final round = _rounds[DemoIds.liveRound];
      if (round == null || !round.isActive) return;

      final others = (_players[DemoIds.liveRound] ?? const <RoundPlayer>[])
          .where((player) => player.userId != DemoIds.you)
          .toList();

      if (others.isEmpty) return;

      final player = others[_random.nextInt(others.length)];
      final card = _scores[DemoIds.liveRound] ?? <HoleScore>[];

      final played = card
          .where((score) => score.playerId == player.userId)
          .map((score) => score.holeNumber)
          .toSet();

      final nextHole = List.generate(
        18,
        (index) => index + 1,
      ).firstWhere((hole) => !played.contains(hole), orElse: () => -1);

      if (nextHole == -1) return;

      // Weight towards par so the demo scores look plausible.
      const spread = [-1, 0, 0, 0, 1, 1, 2];
      final overPar = spread[_random.nextInt(spread.length)];

      card.add(
        HoleScore(
          roundId: DemoIds.liveRound,
          playerId: player.userId,
          holeNumber: nextHole,
          strokes: demoPars[nextHole - 1] + overPar,
          putts: overPar >= 1 ? 2 : 1,
          penaltyStrokes: 0,
          confirmed: true,
          updatedAt: DateTime.now(),
        ),
      );

      _scores[DemoIds.liveRound] = card;
      _bump();
    });
  }

  /// Total strokes (including penalties) a golfer took in a round, and how
  /// many holes they entered.
  (int holes, int gross) _cardFor(String roundId, String golferId) {
    final card = (_scores[roundId] ?? const <HoleScore>[]).where(
      (score) => score.playerId == golferId,
    );

    return (
      card.length,
      card.fold<int>(0, (total, score) => total + score.totalStrokes),
    );
  }

  /// Reads the bundled catalogue and replaces the built-in demo data with it.
  ///
  /// Failure is not fatal: if the assets are missing the demo simply keeps its
  /// single hand-built course, which is enough to exercise every screen.
  Future<void> _loadRealCatalogue() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/data/sa_golf_courses.json'),
        rootBundle.loadString('assets/data/sa_course_holes.json'),
        rootBundle.loadString('assets/data/sa_driving_ranges.json'),
      ]);

      final courseRows = (jsonDecode(results[0]) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final holeRows = jsonDecode(results[1]) as Map<String, dynamic>;
      final rangeRows = (jsonDecode(results[2]) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final holes = <String, List<GolfHole>>{};
      for (final entry in holeRows.entries) {
        holes[entry.key] = (entry.value as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(GolfHole.fromJson)
            .toList();
      }

      // The demo course keeps its three hand-built tee sets; every imported
      // course gets one unrated set so a round can actually be started on it.
      final teeSets = <String, List<TeeSet>>{..._seed.teeSets};

      final courses = <GolfCourse>[];
      for (final row in courseRows) {
        final course = GolfCourse.fromJson(row);
        final card = holes[course.id];
        final playable = card != null && card.length >= 18;

        courses.add(
          playable && !course.playable ? _asPlayable(course, card) : course,
        );

        if (playable) {
          teeSets.putIfAbsent(course.id, () => [_defaultTeeSet(course, card)]);
        }
      }

      // Keep only the hand-built demo course - it is the one the live round
      // is played on. The other seeded clubs duplicate real imported entries.
      courses.insertAll(
        0,
        _seed.courses.where((course) => course.id == DemoIds.course),
      );

      _courses = courses;
      _holes = {...holes, ..._seed.holes};
      _ranges = [..._seed.ranges, ...rangeRows.map(DrivingRange.fromJson)];
      _teeSets = teeSets;
      catalogueLoaded = true;
      _bump();
    } catch (error) {
      debugPrint('Demo catalogue not loaded, using built-in data: $error');
    }
  }

  static GolfCourse _asPlayable(GolfCourse course, List<GolfHole> card) {
    return GolfCourse(
      id: course.id,
      name: course.name,
      country: course.country,
      province: course.province,
      city: course.city,
      address: course.address,
      description: course.description,
      website: course.website,
      phone: course.phone,
      imageUrl: course.imageUrl,
      latitude: course.latitude,
      longitude: course.longitude,
      par: course.par ?? card.fold<int>(0, (total, h) => total + h.par),
      holes: course.holes ?? card.length,
      active: course.active,
      playable: true,
      dataStatus: course.dataStatus,
      sourceUrl: course.sourceUrl,
    );
  }

  /// A neutral tee set for imported courses.
  ///
  /// Slope 113 is the definitional standard, at which a course handicap equals
  /// the handicap index, and the rating is taken as par. Both are honest
  /// placeholders rather than invented ratings - the name says so.
  static TeeSet _defaultTeeSet(GolfCourse course, List<GolfHole> card) {
    final par = course.par ?? card.fold<int>(0, (total, h) => total + h.par);

    return TeeSet(
      id: 'default',
      name: 'Club (unrated)',
      colour: 'White',
      courseRating: par.toDouble(),
      slopeRating: 113,
      par: par,
      totalDistance: 0,
      distanceUnit: 'metres',
    );
  }

  void dispose() {
    _ticker?.cancel();
    _revision.close();
  }

  // ---------------------------------------------------------------------
  // Repositories
  // ---------------------------------------------------------------------

  late final AuthRepository auth = _DemoAuthRepository(this);
  late final ProfileRepository profiles = _DemoProfileRepository(this);
  late final CourseRepository courses = _DemoCourseRepository(this);
  late final RoundRepository rounds = _DemoRoundRepository(this);
  late final ScoreRepository scores = _DemoScoreRepository(this);
  late final CommunityRepository community = _DemoCommunityRepository(this);
  late final DrivingRangeRepository ranges = _DemoDrivingRangeRepository(this);
}

// -------------------------------------------------------------------------
// Auth
// -------------------------------------------------------------------------

class _DemoAuthRepository implements AuthRepository {
  _DemoAuthRepository(this._backend);

  final DemoBackend _backend;

  @override
  ChristianGolferUser? get currentUser => _backend._currentUser;

  @override
  String? get currentUserId => _backend._currentUser?.id;

  @override
  Stream<ChristianGolferUser?> authStateChanges() =>
      _backend._watch(() => _backend._currentUser);

  /// No OAuth round trip in demo mode; you are simply signed in.
  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _backend._currentUser = const ChristianGolferUser(
      id: DemoIds.you,
      email: 'you@christiangolfers.example',
      displayName: 'You',
    );
    _backend._bump();
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw StateError('Admin accounts are not available in demo mode.');
  }

  @override
  Future<void> signUpWithPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    throw StateError('Email registration is not available in demo mode.');
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final user = _backend._currentUser;
    if (user == null) return;

    _backend._currentUser = ChristianGolferUser(
      id: user.id,
      email: user.email,
      displayName: trimmed,
      photoUrl: user.photoUrl,
    );
    _backend._bump();
  }

  @override
  Future<void> signOut() async {
    _backend._currentUser = null;
    _backend._bump();
  }
}

// -------------------------------------------------------------------------
// Profiles
// -------------------------------------------------------------------------

class _DemoProfileRepository implements ProfileRepository {
  _DemoProfileRepository(this._backend);

  final DemoBackend _backend;

  @override
  Stream<UserProfile?> watchProfile(String userId) =>
      _backend._watch(() => _backend._profiles[userId]);

  @override
  Future<UserProfile?> getProfile(String userId) async =>
      _backend._profiles[userId];

  @override
  Future<void> ensureProfileExists(ChristianGolferUser user) async {
    _backend._profiles.putIfAbsent(
      user.id,
      () => UserProfile(
        id: user.id,
        displayName: user.bestName,
        email: user.email ?? '',
        photoUrl: user.photoUrl,
        preferredDistanceUnit: 'metres',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    _backend._bump();
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String displayName,
    required String preferredDistanceUnit,
  }) async {
    final existing = _backend._profiles[userId];
    if (existing == null) return;

    _backend._profiles[userId] = existing.copyWith(
      displayName: displayName.trim(),
      preferredDistanceUnit: preferredDistanceUnit,
      updatedAt: DateTime.now(),
    );
    _backend._bump();
  }
}

// -------------------------------------------------------------------------
// Courses
// -------------------------------------------------------------------------

class _DemoCourseRepository implements CourseRepository {
  _DemoCourseRepository(this._backend);

  final DemoBackend _backend;

  @override
  Stream<List<GolfCourse>> watchActiveCourses() => _backend._watch(() {
    final list = _backend._courses.where((course) => course.active).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  });

  @override
  Stream<GolfCourse?> watchCourse(String courseId) => _backend._watch(() {
    for (final course in _backend._courses) {
      if (course.id == courseId) return course;
    }
    return null;
  });

  @override
  Stream<List<TeeSet>> watchTeeSets(String courseId) =>
      _backend._watch(() => _backend._teeSets[courseId] ?? const <TeeSet>[]);

  @override
  Stream<List<GolfHole>> watchHoles(String courseId) =>
      _backend._watch(() => _backend._holes[courseId] ?? const <GolfHole>[]);

  @override
  Future<List<GolfCourse>> coursesByIds(Iterable<String> courseIds) async {
    final wanted = courseIds.toSet();
    return _backend._courses
        .where((course) => wanted.contains(course.id))
        .toList(growable: false);
  }

  @override
  Future<Map<String, List<GolfHole>>> holesForCourses(
    Iterable<String> courseIds,
  ) async {
    final wanted = courseIds.toSet();
    return {
      for (final entry in _backend._holes.entries)
        if (wanted.contains(entry.key)) entry.key: entry.value,
    };
  }

  @override
  Future<bool> isCurrentUserAdmin(String userId) async =>
      _backend._profiles[userId]?.isAdmin ?? false;

  @override
  Future<int> seedSouthAfricanCourseCatalog() async => _backend._courses.length;

  @override
  Future<int> seedCourseHoles() async {
    // Written out rather than an `async =>` one-liner: in an expression body
    // the context type is FutureOr<int>, which fold infers as its accumulator
    // type, and FutureOr has no '+'.
    var total = 0;
    for (final holes in _backend._holes.values) {
      total += holes.length;
    }
    return total;
  }

  @override
  Future<void> seedDevelopmentCourse() async {}
}

// -------------------------------------------------------------------------
// Rounds
// -------------------------------------------------------------------------

class _DemoRoundRepository implements RoundRepository {
  _DemoRoundRepository(this._backend);

  final DemoBackend _backend;

  String get _me {
    final id = _backend.currentUserId;
    if (id == null) throw StateError('You must be signed in.');
    return id;
  }

  @override
  Future<String> createRound({
    required GolfCourse course,
    required TeeSet teeSet,
  }) async {
    final me = _me;
    final id = 'demo-round-${DateTime.now().millisecondsSinceEpoch}';

    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(
      6,
      (_) => alphabet[_backend._random.nextInt(alphabet.length)],
    ).join();

    _backend._rounds[id] = GolfRound(
      id: id,
      hostUserId: me,
      courseId: course.id,
      courseName: course.name,
      teeSetId: teeSet.id,
      teeSetName: teeSet.name,
      joinCode: code,
      format: 'strokePlay',
      status: 'waiting',
      currentHole: 1,
      createdAt: DateTime.now(),
    );

    final profile = _backend._profiles[me];

    _backend._players[id] = [
      RoundPlayer(
        userId: me,
        displayName: profile?.displayName ?? 'You',
        role: 'host',
        active: true,
        handicapIndex: profile?.estimatedHandicapIndex,
        joinedAt: DateTime.now(),
      ),
    ];
    _backend._scores[id] = <HoleScore>[];

    _backend._bump();
    return id;
  }

  /// In demo mode any six-character code joins the live demo round, so the
  /// join flow can be exercised without a second device.
  @override
  Future<String> joinRoundByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    if (code.length != 6) {
      throw StateError('Enter the six-character round code.');
    }

    final match = _backend._rounds.values.where(
      (round) => round.joinCode == code,
    );

    final round = match.isNotEmpty
        ? match.first
        : _backend._rounds[DemoIds.liveRound];

    if (round == null) {
      throw StateError('No round was found for that code.');
    }

    final seats = _backend._players[round.id] ?? <RoundPlayer>[];

    if (!seats.any((player) => player.userId == _me)) {
      if (seats.length >= 4) {
        throw StateError('This 4-ball already has four players.');
      }

      final profile = _backend._profiles[_me];
      seats.add(
        RoundPlayer(
          userId: _me,
          displayName: profile?.displayName ?? 'You',
          role: 'player',
          active: true,
          handicapIndex: profile?.estimatedHandicapIndex,
          joinedAt: DateTime.now(),
        ),
      );
      _backend._players[round.id] = seats;
      _backend._bump();
    }

    return round.id;
  }

  @override
  Stream<GolfRound?> watchRound(String roundId) =>
      _backend._watch(() => _backend._rounds[roundId]);

  @override
  Stream<List<RoundPlayer>> watchPlayers(String roundId) => _backend._watch(() {
    final seats = [...?_backend._players[roundId]];
    seats.sort((a, b) {
      if (a.isHost && !b.isHost) return -1;
      if (!a.isHost && b.isHost) return 1;
      return a.displayName.compareTo(b.displayName);
    });
    return seats;
  });

  @override
  Future<List<GolfRound>> myRounds({int limit = 50}) async {
    final mine = _backend._rounds.values.where((round) {
      final seats = _backend._players[round.id] ?? const <RoundPlayer>[];
      return seats.any((player) => player.userId == _me);
    }).toList();

    mine.sort((a, b) {
      final left = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });

    return mine.take(limit).toList(growable: false);
  }

  GolfRound _require(String roundId) {
    final round = _backend._rounds[roundId];
    if (round == null) throw StateError('Round not found.');
    return round;
  }

  GolfRound _copy(
    GolfRound round, {
    String? status,
    int? currentHole,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return GolfRound(
      id: round.id,
      hostUserId: round.hostUserId,
      courseId: round.courseId,
      courseName: round.courseName,
      teeSetId: round.teeSetId,
      teeSetName: round.teeSetName,
      joinCode: round.joinCode,
      format: round.format,
      status: status ?? round.status,
      currentHole: currentHole ?? round.currentHole,
      createdAt: round.createdAt,
      startedAt: startedAt ?? round.startedAt,
      completedAt: completedAt ?? round.completedAt,
    );
  }

  @override
  Future<void> startRound(String roundId) async {
    final round = _require(roundId);

    if (round.hostUserId != _me) {
      throw StateError('Only the host can start the round.');
    }
    if (!round.isWaiting) {
      throw StateError('The round is no longer waiting to start.');
    }

    _backend._rounds[roundId] = _copy(
      round,
      status: 'active',
      currentHole: 1,
      startedAt: DateTime.now(),
    );
    _backend._bump();
  }

  @override
  Future<void> setCurrentHole({
    required String roundId,
    required int holeNumber,
  }) async {
    if (holeNumber < 1 || holeNumber > 18) {
      throw ArgumentError('Hole number must be between 1 and 18.');
    }

    final round = _require(roundId);

    if (round.hostUserId != _me) {
      throw StateError('Only the host can move the shared round hole.');
    }
    if (!round.isActive) {
      throw StateError('The round is not active.');
    }

    _backend._rounds[roundId] = _copy(round, currentHole: holeNumber);
    _backend._bump();
  }

  @override
  Future<void> completeRound(String roundId) async {
    final round = _require(roundId);

    if (round.hostUserId != _me) {
      throw StateError('Only the host can complete the round.');
    }

    _backend._rounds[roundId] = _copy(
      round,
      status: 'completed',
      completedAt: DateTime.now(),
    );
    _backend._bump();
  }
}

// -------------------------------------------------------------------------
// Scores
// -------------------------------------------------------------------------

class _DemoScoreRepository implements ScoreRepository {
  _DemoScoreRepository(this._backend);

  final DemoBackend _backend;

  String get _me {
    final id = _backend.currentUserId;
    if (id == null) throw StateError('You must be signed in.');
    return id;
  }

  List<HoleScore> _sorted(String roundId) {
    final card = [...?_backend._scores[roundId]];
    card.sort((a, b) {
      final byPlayer = a.playerId.compareTo(b.playerId);
      if (byPlayer != 0) return byPlayer;
      return a.holeNumber.compareTo(b.holeNumber);
    });
    return card;
  }

  @override
  Stream<List<HoleScore>> watchScores(String roundId) =>
      _backend._watch(() => _sorted(roundId));

  @override
  Stream<List<HoleScore>> watchMyScores(String roundId) => _backend._watch(() {
    final mine = _sorted(
      roundId,
    ).where((score) => score.playerId == _me).toList();
    mine.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
    return mine;
  });

  @override
  Future<List<HoleScore>> myScoresForRounds(Iterable<String> roundIds) async {
    final wanted = roundIds.toSet();
    return [
      for (final entry in _backend._scores.entries)
        if (wanted.contains(entry.key))
          ...entry.value.where((score) => score.playerId == _me),
    ];
  }

  @override
  Future<void> saveMyScore({
    required String roundId,
    required int holeNumber,
    required int strokes,
    required int putts,
    required int penaltyStrokes,
    int sandShots = 0,
    String? fairway,
    bool? greenInRegulation,
    bool confirmed = true,
  }) async {
    if (holeNumber < 1 || holeNumber > 18) {
      throw ArgumentError('Hole number must be between 1 and 18.');
    }
    if (strokes < 1 || strokes > 20) {
      throw ArgumentError('Strokes must be between 1 and 20.');
    }
    if (putts < 0 || putts > 10) {
      throw ArgumentError('Putts must be between 0 and 10.');
    }
    if (penaltyStrokes < 0 || penaltyStrokes > 10) {
      throw ArgumentError('Penalty strokes must be between 0 and 10.');
    }

    final card = _backend._scores[roundId] ?? <HoleScore>[];
    card.removeWhere(
      (score) => score.playerId == _me && score.holeNumber == holeNumber,
    );
    card.add(
      HoleScore(
        roundId: roundId,
        playerId: _me,
        holeNumber: holeNumber,
        strokes: strokes,
        putts: putts,
        penaltyStrokes: penaltyStrokes,
        sandShots: sandShots,
        fairway: fairway,
        greenInRegulation: greenInRegulation,
        confirmed: confirmed,
        updatedAt: DateTime.now(),
      ),
    );

    _backend._scores[roundId] = card;
    _backend._bump();
  }
}

// -------------------------------------------------------------------------
// Community
// -------------------------------------------------------------------------

class _DemoCommunityRepository implements CommunityRepository {
  _DemoCommunityRepository(this._backend);

  final DemoBackend _backend;

  String get _me {
    final id = _backend.currentUserId;
    if (id == null) throw StateError('You must be signed in.');
    return id;
  }

  @override
  Future<List<Friend>> friendships() async {
    final list = <Friend>[
      for (final entry in _backend._friendships.entries)
        if (_backend._profiles[entry.key] != null)
          Friend(
            id: entry.key,
            displayName: _backend._profiles[entry.key]!.displayName,
            email: _backend._profiles[entry.key]!.email,
            photoUrl: _backend._profiles[entry.key]!.photoUrl,
            handicapIndex:
                _backend._profiles[entry.key]!.estimatedHandicapIndex,
            state: entry.value,
            since: DateTime.now().subtract(const Duration(days: 30)),
          ),
    ];

    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  @override
  Future<void> sendFriendRequest(String email) async {
    final wanted = email.trim().toLowerCase();

    if (wanted.isEmpty) {
      throw StateError('Enter an email address.');
    }

    final match = _backend._profiles.values.where(
      (profile) => profile.email.toLowerCase() == wanted,
    );

    if (match.isEmpty) {
      throw StateError(
        'No Christian Golfers member is using that email address yet.',
      );
    }

    final target = match.first;

    if (target.id == _me) {
      throw StateError('That is your own account.');
    }

    // Mirrors the RPC: an existing incoming request becomes a friendship.
    _backend._friendships[target.id] =
        _backend._friendships[target.id] == FriendshipState.incomingRequest
        ? FriendshipState.accepted
        : FriendshipState.outgoingRequest;

    _backend._bump();
  }

  @override
  Future<void> respondToRequest({
    required String requesterId,
    required bool accept,
  }) async {
    if (_backend._friendships[requesterId] != FriendshipState.incomingRequest) {
      throw StateError('That friend request is no longer open.');
    }

    if (accept) {
      _backend._friendships[requesterId] = FriendshipState.accepted;
    } else {
      _backend._friendships.remove(requesterId);
    }

    _backend._bump();
  }

  @override
  Future<void> removeFriend(String golferId) async {
    _backend._friendships.remove(golferId);
    _backend._bump();
  }

  Set<String> get _acceptedFriends => {
    for (final entry in _backend._friendships.entries)
      if (entry.value == FriendshipState.accepted) entry.key,
  };

  @override
  Future<List<FriendActivity>> activity({int limit = 25}) async {
    final friends = _acceptedFriends;
    final feed = <FriendActivity>[];

    for (final round in _backend._rounds.values) {
      if (!round.isCompleted) continue;

      for (final player
          in _backend._players[round.id] ?? const <RoundPlayer>[]) {
        if (player.userId == _me) continue;
        if (!friends.contains(player.userId)) continue;

        final (holes, gross) = _backend._cardFor(round.id, player.userId);
        if (holes == 0) continue;

        feed.add(
          FriendActivity(
            roundId: round.id,
            golferId: player.userId,
            displayName: player.displayName,
            courseName: round.courseName,
            playedAt: round.completedAt ?? round.createdAt ?? DateTime.now(),
            holes: holes,
            gross: gross,
          ),
        );
      }
    }

    feed.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return feed.take(limit).toList(growable: false);
  }

  @override
  Future<List<FriendStanding>> standings({DateTime? since}) async {
    final crew = {..._acceptedFriends, _me};
    final cutoff = since ?? DateTime.now().subtract(const Duration(days: 365));

    final grossByGolfer = <String, List<int>>{};

    for (final round in _backend._rounds.values) {
      if (!round.isCompleted) continue;

      final playedAt = round.completedAt ?? round.createdAt;
      if (playedAt != null && playedAt.isBefore(cutoff)) continue;

      for (final player
          in _backend._players[round.id] ?? const <RoundPlayer>[]) {
        if (!crew.contains(player.userId)) continue;

        final (holes, gross) = _backend._cardFor(round.id, player.userId);
        if (holes < 18) continue;

        (grossByGolfer[player.userId] ??= <int>[]).add(gross);
      }
    }

    final standings = <FriendStanding>[
      for (final entry in grossByGolfer.entries)
        if (_backend._profiles[entry.key] != null)
          FriendStanding(
            golferId: entry.key,
            displayName: _backend._profiles[entry.key]!.displayName,
            photoUrl: _backend._profiles[entry.key]!.photoUrl,
            roundsPlayed: entry.value.length,
            bestGross: entry.value.reduce((a, b) => a < b ? a : b),
            averageGross:
                entry.value.reduce((a, b) => a + b) / entry.value.length,
          ),
    ];

    standings.sort((a, b) {
      final byAverage = a.averageGross.compareTo(b.averageGross);
      if (byAverage != 0) return byAverage;
      return b.roundsPlayed.compareTo(a.roundsPlayed);
    });

    return standings;
  }
}

// -------------------------------------------------------------------------
// Driving ranges
// -------------------------------------------------------------------------

class _DemoDrivingRangeRepository implements DrivingRangeRepository {
  _DemoDrivingRangeRepository(this._backend);

  final DemoBackend _backend;

  @override
  Stream<List<DrivingRange>> watchActiveRanges() => _backend._watch(() {
    final list = _backend._ranges.where((range) => range.active).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  });

  @override
  Future<List<DrivingRange>> rangesForCourse(String courseId) async {
    return _backend._ranges
        .where((range) => range.courseId == courseId)
        .toList(growable: false);
  }

  @override
  Future<int> seedDrivingRanges() async => _backend._ranges.length;
}
