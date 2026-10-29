import 'package:christian_golfers/features/faith/domain/word_of_the_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scripture changes on the next local calendar day', () {
    final today = WordOfTheDay.forDate(DateTime(2026, 10, 29));
    final tomorrow = WordOfTheDay.forDate(DateTime(2026, 10, 30));

    expect(today.reference, isNot(tomorrow.reference));
    expect(today.verse, isNot(tomorrow.verse));
  });

  test('scripture stays stable throughout the same date', () {
    final morning = WordOfTheDay.forDate(DateTime(2026, 10, 29, 8));
    final evening = WordOfTheDay.forDate(DateTime(2026, 10, 29, 20));

    expect(morning.reference, evening.reference);
    expect(morning.verse, evening.verse);
  });
}
