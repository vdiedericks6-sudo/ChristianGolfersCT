import 'package:flutter_test/flutter_test.dart';
import 'package:christian_golfers/features/scorecard/domain/score_voice_parser.dart';

void main() {
  group('voice gross score', () {
    test('accepts English and Afrikaans for the selected hole', () {
      expect(
        ScoreVoiceParser.parse('Hole seven, six strokes', currentHole: 7),
        6,
      );
      expect(
        ScoreVoiceParser.parse('Putjie sewe, ses houe', currentHole: 7),
        6,
      );
      expect(ScoreVoiceParser.parse('five strokes', currentHole: 7), 5);
    });
    test('rejects a different hole, multiple numbers and invalid scores', () {
      expect(
        ScoreVoiceParser.parse('Hole eight, six strokes', currentHole: 7),
        isNull,
      );
      expect(
        ScoreVoiceParser.parse('six or seven strokes', currentHole: 7),
        isNull,
      );
      expect(ScoreVoiceParser.parse('zero strokes', currentHole: 7), isNull);
      expect(ScoreVoiceParser.parse('thirty strokes', currentHole: 7), isNull);
    });
  });
}
