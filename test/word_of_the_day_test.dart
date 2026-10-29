import 'package:flutter_test/flutter_test.dart';
import 'package:christian_golfers/features/faith/domain/word_of_the_day.dart';

void main() {
  group('WordOfTheDay', () {
    test('returns a populated reading for a date', () {
      final reading = WordOfTheDay.forDate(DateTime(2026, 10, 28));

      expect(reading.reference, isNotEmpty);
      expect(reading.verse, isNotEmpty);
      expect(reading.reflection, isNotEmpty);
    });

    test('returns the same reading throughout the same calendar day', () {
      final morning = WordOfTheDay.forDate(DateTime(2026, 10, 28, 7));
      final evening = WordOfTheDay.forDate(DateTime(2026, 10, 28, 19));

      expect(evening.reference, morning.reference);
      expect(evening.verse, morning.verse);
    });
  });
}
