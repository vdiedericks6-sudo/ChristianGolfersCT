/// Parses short voice commands such as:
///  "Hole seven, six strokes"
///  "Six strokes"
///  "Putjie sewe, ses houe"
///  "Hole 7, 6 strokes"
/// Does not silently alter the score if the speaker states another hole.
class ScoreVoiceParser {
  static const Map<String, int> _numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'een': 1,
    'twee': 2,
    'drie': 3,
    'vier': 4,
    'vyf': 5,
    'ses': 6,
    'sewe': 7,
    'agt': 8,
    'nege': 9,
    'tien': 10,
    'elf': 11,
    'twaalf': 12,
    'dertien': 13,
    'veertien': 14,
    'vyftien': 15,
    'sestien': 16,
    'sewentien': 17,
    'agtien': 18,
  };

  static int? _asNumber(String token) =>
      int.tryParse(token) ?? _numberWords[token];

  /// Returns null when the phrase is not safely understandable for this hole.
  static int? parse(String phrase, {required int currentHole}) {
    final tokens = RegExp(
      r'[a-z0-9]+',
    ).allMatches(phrase.toLowerCase()).map((match) => match.group(0)!).toList();
    if (tokens.isEmpty) return null;

    // Remove an explicit hole reference and check it matches this screen.
    for (var i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == 'hole' || tokens[i] == 'putjie') {
        final hole = _asNumber(tokens[i + 1]);
        if (hole == null || hole != currentHole) return null;
        tokens.removeRange(i, i + 2);
        break;
      }
    }

    // Only accept one remaining numeric value. This prevents accidental
    // matches on ambiguous multi-number speech transcripts.
    final numbers = tokens.map(_asNumber).whereType<int>().toList();
    if (numbers.length != 1) return null;
    final score = numbers.single;
    return (score >= 1 && score <= 25) ? score : null;
  }
}
