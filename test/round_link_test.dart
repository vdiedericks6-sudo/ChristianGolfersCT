import 'package:christian_golfers/features/rounds/data/round_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoundLink.normalise', () {
    test('upper-cases a plain code', () {
      expect(RoundLink.normalise('dvt247'), 'DVT247');
    });

    test('trims surrounding whitespace', () {
      expect(RoundLink.normalise('  ABC234  '), 'ABC234');
    });

    test('drops the digits that are not in the alphabet', () {
      // 1 is excluded, so ABC123 is not a code anyone can be issued.
      expect(RoundLink.normalise('ABC123'), 'ABC23');
      expect(RoundLink.isValid('ABC123'), isFalse);
    });

    test('handles a link with a query string', () {
      expect(
        RoundLink.normalise(
          'https://christiangolfers.example/join/DVT247?utm=whatsapp',
        ),
        'DVT247',
      );
    });

    test('pulls the code out of a full invite link', () {
      expect(
        RoundLink.normalise('https://christiangolfers.example/join/DVT247'),
        'DVT247',
      );
    });

    test('pulls the code out of a link with a trailing slash', () {
      expect(
        RoundLink.normalise('https://christiangolfers.example/join/DVT247/'),
        'DVT247',
      );
    });

    test('drops characters the alphabet excludes', () {
      // I, O, 0 and 1 are not in the alphabet: they read ambiguously aloud.
      expect(RoundLink.normalise('AB-CD 23'), 'ABCD23');
    });

    test('rejects a code that is too short', () {
      expect(RoundLink.isValid('ABC'), isFalse);
    });

    test('accepts a well-formed code', () {
      expect(RoundLink.isValid('DVT247'), isTrue);
    });
  });

  group('RoundLink.invitation', () {
    test('names the course when there is one', () {
      final text = RoundLink.invitation(
        joinCode: 'DVT247',
        courseName: 'Royal Cape',
      );

      expect(text, contains('Royal Cape'));
      expect(text, contains('DVT247'));
    });

    test('falls back gracefully with no course name', () {
      final text = RoundLink.invitation(joinCode: 'DVT247', courseName: '  ');

      expect(text, contains('a round'));
      expect(text, contains('DVT247'));
    });
  });
}
