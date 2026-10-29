import 'package:christian_golfers/features/handicap/domain/handicap_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HandicapCalculator', () {
    test('calculates course handicap', () {
      final result = HandicapCalculator.courseHandicap(
        handicapIndex: 18.0,
        slopeRating: 126,
        courseRating: 72.4,
        par: 72,
      );

      expect(result, 20);
    });

    test('allocates one stroke to hardest holes', () {
      expect(
        HandicapCalculator.strokesReceivedOnHole(
          playingHandicap: 10,
          strokeIndex: 1,
        ),
        1,
      );

      expect(
        HandicapCalculator.strokesReceivedOnHole(
          playingHandicap: 10,
          strokeIndex: 11,
        ),
        0,
      );
    });

    test('allocates two strokes when handicap is above 18', () {
      expect(
        HandicapCalculator.strokesReceivedOnHole(
          playingHandicap: 22,
          strokeIndex: 4,
        ),
        2,
      );

      expect(
        HandicapCalculator.strokesReceivedOnHole(
          playingHandicap: 22,
          strokeIndex: 5,
        ),
        1,
      );
    });

    test('calculates net hole score', () {
      expect(
        HandicapCalculator.netHoleScore(grossScore: 6, strokesReceived: 1),
        5,
      );
    });

    test('calculates score differential', () {
      final differential = HandicapCalculator.scoreDifferential(
        adjustedGrossScore: 90,
        courseRating: 72,
        slopeRating: 113,
      );

      expect(differential, 18);
    });

    test('requires at least three differentials for estimate', () {
      expect(HandicapCalculator.estimatedHandicapIndex([15.0, 16.0]), isNull);
    });

    test('uses eight best from twenty', () {
      final differentials = List<double>.generate(20, (index) => 10.0 + index);

      final result = HandicapCalculator.estimatedHandicapIndex(differentials);

      expect(result, 13.5);
    });
  });
}
