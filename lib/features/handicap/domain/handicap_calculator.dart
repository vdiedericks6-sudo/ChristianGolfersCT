class HandicapCalculator {
  const HandicapCalculator._();

  static int courseHandicap({
    required double handicapIndex,
    required int slopeRating,
    required double courseRating,
    required int par,
  }) {
    final value = handicapIndex * (slopeRating / 113.0) + (courseRating - par);
    return value.round();
  }

  static int playingHandicap({
    required int courseHandicap,
    double allowance = 1.0,
  }) {
    return (courseHandicap * allowance).round();
  }

  static int strokesReceivedOnHole({
    required int playingHandicap,
    required int strokeIndex,
  }) {
    if (playingHandicap == 0) {
      return 0;
    }

    if (playingHandicap > 0) {
      final base = playingHandicap ~/ 18;
      final remainder = playingHandicap % 18;
      return base + (strokeIndex <= remainder ? 1 : 0);
    }

    final absolute = playingHandicap.abs();
    final base = absolute ~/ 18;
    final remainder = absolute % 18;

    var strokes = -base;

    if (remainder > 0 && strokeIndex > 18 - remainder) {
      strokes -= 1;
    }

    return strokes;
  }

  static int netHoleScore({
    required int grossScore,
    required int strokesReceived,
  }) {
    return grossScore - strokesReceived;
  }

  static double scoreDifferential({
    required double adjustedGrossScore,
    required double courseRating,
    required int slopeRating,
    double playingConditionsAdjustment = 0,
  }) {
    return (113.0 / slopeRating) *
        (adjustedGrossScore - courseRating - playingConditionsAdjustment);
  }

  static double? estimatedHandicapIndex(List<double> differentials) {
    if (differentials.length < 3) {
      return null;
    }

    final recent = differentials.length <= 20
        ? List<double>.from(differentials)
        : differentials.sublist(differentials.length - 20);

    final sorted = List<double>.from(recent)..sort();

    double result;

    switch (sorted.length) {
      case 3:
        result = sorted.first - 2.0;
      case 4:
        result = sorted.first - 1.0;
      case 5:
        result = sorted.first;
      case 6:
        result = _average(sorted.take(2)) - 1.0;
      case 7:
      case 8:
        result = _average(sorted.take(2));
      case 9:
      case 10:
      case 11:
        result = _average(sorted.take(3));
      case 12:
      case 13:
      case 14:
        result = _average(sorted.take(4));
      case 15:
      case 16:
        result = _average(sorted.take(5));
      case 17:
      case 18:
        result = _average(sorted.take(6));
      case 19:
        result = _average(sorted.take(7));
      default:
        result = _average(sorted.take(8));
    }

    return (result * 10).round() / 10.0;
  }

  static double _average(Iterable<double> values) {
    final items = values.toList();
    return items.reduce((a, b) => a + b) / items.length;
  }
}
