import '../../features/courses/domain/golf_course.dart';
import '../../features/courses/domain/golf_hole.dart';
import '../../features/courses/domain/tee_set.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/ranges/domain/driving_range.dart';
import '../../features/rounds/domain/golf_round.dart';
import '../../features/rounds/domain/round_player.dart';
import '../../features/scorecard/domain/hole_score.dart';

/// Fixed ids so demo data is stable across hot reloads.
class DemoIds {
  const DemoIds._();

  static const you = 'demo-you';
  static const sipho = 'demo-sipho';
  static const anna = 'demo-anna';
  static const dave = 'demo-dave';
  static const socialGolfer = 'demo-social-golfer';
  static const visitingGolfer = 'demo-visiting-golfer';

  static const course = 'christian-golfers-demo-course';

  static const liveRound = 'demo-round-live';
  static const pastRoundOne = 'demo-round-past-1';
  static const pastRoundTwo = 'demo-round-past-2';
  static const pastRoundThree = 'demo-round-past-3';
}

/// The 18 holes of the demo course.
const demoPars = <int>[4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4, 4];
const demoStrokeIndexes = <int>[
  9,
  3,
  17,
  1,
  11,
  5,
  15,
  7,
  13,
  10,
  4,
  18,
  2,
  12,
  6,
  16,
  8,
  14,
];

const demoCoursePar = 72;

class DemoSeed {
  const DemoSeed({
    required this.profiles,
    required this.courses,
    required this.ranges,
    required this.teeSets,
    required this.holes,
    required this.rounds,
    required this.players,
    required this.scores,
  });

  final Map<String, UserProfile> profiles;
  final List<GolfCourse> courses;
  final List<DrivingRange> ranges;
  final Map<String, List<TeeSet>> teeSets;
  final Map<String, List<GolfHole>> holes;
  final Map<String, GolfRound> rounds;
  final Map<String, List<RoundPlayer>> players;
  final Map<String, List<HoleScore>> scores;

  factory DemoSeed.build() {
    final now = DateTime.now();

    UserProfile profile(
      String id,
      String name,
      String email,
      double? handicap, {
      bool admin = false,
      bool visiting = false,
    }) {
      return UserProfile(
        id: id,
        displayName: name,
        email: email,
        preferredDistanceUnit: 'metres',
        estimatedHandicapIndex: handicap,
        isAdmin: admin,
        isVisitingGolfer: visiting,
        createdAt: now.subtract(const Duration(days: 240)),
        updatedAt: now,
      );
    }

    final profiles = <String, UserProfile>{
      DemoIds.you: profile(
        DemoIds.you,
        'You',
        'you@christiangolfers.example',
        14.2,
        admin: true,
      ),
      DemoIds.sipho: profile(
        DemoIds.sipho,
        'Sipho Ndlovu',
        'sipho@christiangolfers.example',
        8.1,
      ),
      DemoIds.anna: profile(
        DemoIds.anna,
        'Anna Botha',
        'anna@christiangolfers.example',
        21.5,
      ),
      DemoIds.dave: profile(
        DemoIds.dave,
        'Dave Mercer',
        'dave@christiangolfers.example',
        11.0,
      ),
      DemoIds.socialGolfer: profile(
        DemoIds.socialGolfer,
        'Jordan Social',
        'jordan@christiangolfers.example',
        null,
      ),
      DemoIds.visitingGolfer: profile(
        DemoIds.visitingGolfer,
        'Casey Visitor',
        'casey@christiangolfers.example',
        16.4,
        visiting: true,
      ),
    };

    GolfCourse course(
      String id,
      String name,
      String province,
      String city, {
      bool playable = false,
      int? par,
      int? holes,
    }) {
      return GolfCourse(
        id: id,
        name: name,
        country: 'South Africa',
        province: province,
        city: city,
        active: true,
        playable: playable,
        par: par,
        holes: holes,
        dataStatus: playable ? 'demo' : 'catalog',
        description: playable
            ? 'Full demo data: 18 holes, three tee sets, live scoring.'
            : 'Catalogue entry. Hole data has not been captured yet.',
      );
    }

    final courses = <GolfCourse>[
      course(
        DemoIds.course,
        'Christian Golfers Demo Course',
        'Western Cape',
        'Cape Town',
        playable: true,
        par: demoCoursePar,
        holes: 18,
      ),
      course(
        'demo-royal-cape',
        'Royal Cape Golf Club',
        'Western Cape',
        'Cape Town',
      ),
      course('demo-fancourt', 'Fancourt Links', 'Western Cape', 'George'),
      course(
        'demo-leopard-creek',
        'Leopard Creek Country Club',
        'Mpumalanga',
        'Malelane',
      ),
      course(
        'demo-durban-cc',
        'Durban Country Club',
        'KwaZulu-Natal',
        'Durban',
      ),
      course(
        'demo-glendower',
        'Glendower Golf Club',
        'Gauteng',
        'Johannesburg',
      ),
    ];

    const ranges = <DrivingRange>[
      DrivingRange(
        id: 'demo-christian-golfers-range',
        courseId: DemoIds.course,
        name: 'Christian Golfers Demo Course driving range',
        country: 'South Africa',
        province: 'Western Cape',
        city: 'Cape Town',
        active: true,
        latitude: -33.9231,
        longitude: 18.4262,
        bays: 24,
        floodlit: true,
        covered: true,
        ballTracking: BallTracking.toptracer,
        dataStatus: 'demo',
      ),
      DrivingRange(
        id: 'demo-observatory-range',
        name: 'Observatory Driving Range',
        country: 'South Africa',
        province: 'Gauteng',
        city: 'Johannesburg',
        active: true,
        latitude: -26.1795,
        longitude: 28.0742,
        bays: 30,
        floodlit: true,
        covered: false,
        dataStatus: 'demo',
      ),
      DrivingRange(
        id: 'demo-milnerton-range',
        name: 'Milnerton Golf Club driving range',
        country: 'South Africa',
        province: 'Western Cape',
        city: 'Cape Town',
        active: true,
        latitude: -33.8749,
        longitude: 18.5045,
        bays: 16,
        floodlit: false,
        covered: true,
        dataStatus: 'demo',
      ),
      DrivingRange(
        id: 'demo-golden-horse-range',
        name: 'Golden Horse Driving Range',
        country: 'South Africa',
        province: 'KwaZulu-Natal',
        city: 'Pietermaritzburg',
        active: true,
        latitude: -29.6215,
        longitude: 30.3898,
        bays: 20,
        floodlit: true,
        dataStatus: 'demo',
      ),
      DrivingRange(
        id: 'demo-tin-cup-range',
        name: 'Tin Cup Driving Range',
        country: 'South Africa',
        province: 'Gauteng',
        city: 'Pretoria',
        active: true,
        latitude: -25.7801,
        longitude: 28.2364,
        bays: 40,
        floodlit: true,
        covered: true,
        ballTracking: BallTracking.trackman,
        dataStatus: 'demo',
      ),
    ];

    Map<int, int> demoDistances({
      required int par3,
      required int par4,
      required int par5,
    }) => {
      for (var index = 0; index < demoPars.length; index++)
        index + 1: switch (demoPars[index]) {
          3 => par3,
          5 => par5,
          _ => par4,
        },
    };

    final teeSets = <String, List<TeeSet>>{
      DemoIds.course: [
        TeeSet(
          id: 'red',
          name: 'Red tees',
          colour: 'Red',
          courseRating: 70.1,
          slopeRating: 118,
          par: demoCoursePar,
          totalDistance: 5310,
          distanceUnit: 'metres',
          holeDistancesMeters: demoDistances(par3: 130, par4: 305, par5: 435),
        ),
        TeeSet(
          id: 'yellow',
          name: 'Yellow tees',
          colour: 'Yellow',
          courseRating: 71.5,
          slopeRating: 122,
          par: demoCoursePar,
          totalDistance: 5740,
          distanceUnit: 'metres',
          holeDistancesMeters: demoDistances(par3: 145, par4: 330, par5: 465),
        ),
        TeeSet(
          id: 'blue',
          name: 'Blue tees',
          colour: 'Blue',
          courseRating: 73.5,
          slopeRating: 134,
          par: demoCoursePar,
          totalDistance: 6120,
          distanceUnit: 'metres',
          holeDistancesMeters: demoDistances(par3: 160, par4: 350, par5: 495),
        ),
        TeeSet(
          id: 'club',
          name: 'White tees',
          colour: 'White',
          courseRating: 72.4,
          slopeRating: 126,
          par: demoCoursePar,
          totalDistance: 6350,
          distanceUnit: 'metres',
          holeDistancesMeters: demoDistances(par3: 165, par4: 365, par5: 510),
        ),
      ],
    };

    final holes = <String, List<GolfHole>>{
      DemoIds.course: [
        for (var index = 0; index < 18; index++)
          GolfHole(
            number: index + 1,
            par: demoPars[index],
            strokeIndex: demoStrokeIndexes[index],
            teeLatitude: -33.9249 + (index * 0.00035),
            teeLongitude: 18.4241 + (index * 0.00028),
            greenFrontLatitude: -33.9249 + (index * 0.00035) + 0.0018,
            greenFrontLongitude: 18.4241 + (index * 0.00028) + 0.0015,
            greenCentreLatitude: -33.9249 + (index * 0.00035) + 0.0019,
            greenCentreLongitude: 18.4241 + (index * 0.00028) + 0.0016,
            greenBackLatitude: -33.9249 + (index * 0.00035) + 0.0020,
            greenBackLongitude: 18.4241 + (index * 0.00028) + 0.0017,
          ),
      ],
    };

    GolfRound round(
      String id,
      String joinCode,
      String status,
      int currentHole,
      DateTime created, {
      DateTime? completed,
    }) {
      return GolfRound(
        id: id,
        hostUserId: DemoIds.you,
        courseId: DemoIds.course,
        courseName: 'Christian Golfers Demo Course',
        teeSetId: 'club',
        teeSetName: 'Club',
        joinCode: joinCode,
        format: 'strokePlay',
        status: status,
        currentHole: currentHole,
        createdAt: created,
        startedAt: created.add(const Duration(minutes: 4)),
        completedAt: completed,
      );
    }

    final rounds = <String, GolfRound>{
      DemoIds.liveRound: round(
        DemoIds.liveRound,
        'DVT247',
        'active',
        7,
        now.subtract(const Duration(hours: 2)),
      ),
      DemoIds.pastRoundOne: round(
        DemoIds.pastRoundOne,
        'PAST24',
        'completed',
        18,
        now.subtract(const Duration(days: 6)),
        completed: now.subtract(const Duration(days: 6, hours: -4)),
      ),
      DemoIds.pastRoundTwo: round(
        DemoIds.pastRoundTwo,
        'PAST25',
        'completed',
        18,
        now.subtract(const Duration(days: 20)),
        completed: now.subtract(const Duration(days: 20, hours: -4)),
      ),
      DemoIds.pastRoundThree: round(
        DemoIds.pastRoundThree,
        'PAST26',
        'completed',
        18,
        now.subtract(const Duration(days: 41)),
        completed: now.subtract(const Duration(days: 41, hours: -4)),
      ),
    };

    RoundPlayer player(String userId, String role, DateTime joined) {
      final source = profiles[userId]!;
      return RoundPlayer(
        userId: userId,
        displayName: source.displayName,
        role: role,
        active: true,
        handicapIndex: source.estimatedHandicapIndex,
        courseHandicap: source.estimatedHandicapIndex == null
            ? null
            : (source.estimatedHandicapIndex! * 126 / 113).round(),
        playingHandicap: null,
        joinedAt: joined,
      );
    }

    List<RoundPlayer> squad(DateTime joined, {bool full = true}) {
      return [
        player(DemoIds.you, 'host', joined),
        player(DemoIds.sipho, 'player', joined),
        if (full) player(DemoIds.anna, 'player', joined),
        if (full) player(DemoIds.dave, 'player', joined),
      ];
    }

    final players = <String, List<RoundPlayer>>{
      DemoIds.liveRound: squad(now.subtract(const Duration(hours: 2))),
      DemoIds.pastRoundOne: squad(now.subtract(const Duration(days: 6))),
      DemoIds.pastRoundTwo: squad(
        now.subtract(const Duration(days: 20)),
        full: false,
      ),
      DemoIds.pastRoundThree: squad(now.subtract(const Duration(days: 41))),
    };

    // Deterministic pseudo-random scoring so the demo looks the same each run.
    HoleScore scoreFor(
      String roundId,
      String playerId,
      int hole,
      int overPar,
      int putts,
      DateTime at,
    ) {
      return HoleScore(
        roundId: roundId,
        playerId: playerId,
        holeNumber: hole,
        strokes: demoPars[hole - 1] + overPar,
        putts: putts,
        penaltyStrokes: 0,
        confirmed: true,
        updatedAt: at,
      );
    }

    List<HoleScore> card(
      String roundId,
      String playerId,
      List<int> overPar,
      DateTime at,
    ) {
      return [
        for (var index = 0; index < overPar.length; index++)
          scoreFor(
            roundId,
            playerId,
            index + 1,
            overPar[index],
            overPar[index] >= 1 ? 2 : (index.isEven ? 2 : 1),
            at.add(Duration(minutes: index * 11)),
          ),
      ];
    }

    // Six holes played in the live round; the ticker fills in the rest.
    final liveAt = now.subtract(const Duration(hours: 2));
    final scores = <String, List<HoleScore>>{
      DemoIds.liveRound: [
        ...card(DemoIds.liveRound, DemoIds.you, [0, 1, 0, 1, 0, 2], liveAt),
        ...card(DemoIds.liveRound, DemoIds.sipho, [0, 0, 1, 0, -1, 1], liveAt),
        ...card(DemoIds.liveRound, DemoIds.anna, [2, 1, 1, 2, 1, 1], liveAt),
        ...card(DemoIds.liveRound, DemoIds.dave, [1, 0, 0, 1, 1, 0], liveAt),
      ],
      DemoIds.pastRoundOne: [
        ...card(DemoIds.pastRoundOne, DemoIds.you, [
          0,
          1,
          0,
          1,
          0,
          1,
          1,
          0,
          1,
          0,
          1,
          0,
          2,
          1,
          0,
          1,
          1,
          0,
        ], now.subtract(const Duration(days: 6))),
        ...card(DemoIds.pastRoundOne, DemoIds.sipho, [
          0,
          0,
          1,
          0,
          -1,
          0,
          1,
          0,
          0,
          1,
          0,
          0,
          1,
          0,
          1,
          0,
          0,
          1,
        ], now.subtract(const Duration(days: 6))),
        ...card(DemoIds.pastRoundOne, DemoIds.anna, [
          1,
          2,
          1,
          2,
          1,
          1,
          2,
          1,
          1,
          2,
          1,
          1,
          2,
          1,
          1,
          2,
          1,
          1,
        ], now.subtract(const Duration(days: 6))),
        ...card(DemoIds.pastRoundOne, DemoIds.dave, [
          1,
          0,
          1,
          1,
          0,
          1,
          0,
          1,
          1,
          0,
          1,
          1,
          0,
          1,
          0,
          1,
          1,
          0,
        ], now.subtract(const Duration(days: 6))),
      ],
      DemoIds.pastRoundTwo: [
        ...card(DemoIds.pastRoundTwo, DemoIds.you, [
          1,
          1,
          0,
          2,
          1,
          1,
          0,
          1,
          1,
          1,
          2,
          0,
          1,
          1,
          1,
          0,
          2,
          1,
        ], now.subtract(const Duration(days: 20))),
        ...card(
          DemoIds.pastRoundTwo,
          DemoIds.sipho,
          [0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0],
          now.subtract(const Duration(days: 20)),
        ),
      ],
      DemoIds.pastRoundThree: [
        ...card(
          DemoIds.pastRoundThree,
          DemoIds.you,
          [1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1],
          now.subtract(const Duration(days: 41)),
        ),
        ...card(
          DemoIds.pastRoundThree,
          DemoIds.sipho,
          [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1],
          now.subtract(const Duration(days: 41)),
        ),
        ...card(
          DemoIds.pastRoundThree,
          DemoIds.anna,
          [2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 1, 2],
          now.subtract(const Duration(days: 41)),
        ),
        ...card(
          DemoIds.pastRoundThree,
          DemoIds.dave,
          [0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1],
          now.subtract(const Duration(days: 41)),
        ),
      ],
    };

    return DemoSeed(
      profiles: profiles,
      courses: courses,
      ranges: ranges,
      teeSets: teeSets,
      holes: holes,
      rounds: rounds,
      players: players,
      scores: scores,
    );
  }
}
