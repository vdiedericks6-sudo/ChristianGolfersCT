import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/config/app_config.dart';

/// Builds and parses the `/join/<code>` links golfers send each other.
class RoundLink {
  const RoundLink._();

  static const codeLength = 6;
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Where the app is served from, without a trailing slash.
  static String get origin {
    if (AppConfig.publicBaseUrl.isNotEmpty) {
      return _trimSlash(AppConfig.publicBaseUrl);
    }

    if (kIsWeb) {
      return _trimSlash(Uri.base.origin);
    }

    // Mobile builds have no origin of their own; point at the web app.
    return 'https://christiangolfers.example';
  }

  static String _trimSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  static String forCode(String joinCode) =>
      '$origin/join/${normalise(joinCode)}';

  /// Turns anything a golfer might paste into a bare code: a whole invite
  /// link, a link with a query string, or a code typed with a stray space.
  ///
  /// Note the alphabet has no I, O, 0 or 1 - they are too easily confused when
  /// a code is read out on the first tee - so those are stripped, not mapped.
  static String normalise(String raw) {
    var text = raw.trim();

    // Drop any query string or fragment first: /join/ABC123?utm=whatsapp
    text = text.split('?').first.split('#').first;

    // If it looks like a URL or path, keep only the last real segment.
    if (text.contains('/')) {
      final segments = text
          .split('/')
          .where((segment) => segment.trim().isNotEmpty)
          .toList();

      if (segments.isNotEmpty) text = segments.last;
    }

    final buffer = StringBuffer();

    for (final rune in text.toUpperCase().runes) {
      final character = String.fromCharCode(rune);
      if (_alphabet.contains(character)) buffer.write(character);
    }

    final cleaned = buffer.toString();
    return cleaned.length > codeLength
        ? cleaned.substring(cleaned.length - codeLength)
        : cleaned;
  }

  static bool isValid(String raw) => normalise(raw).length == codeLength;

  /// Human-friendly invite text for WhatsApp and the like.
  static String invitation({
    required String joinCode,
    required String courseName,
  }) {
    final where = courseName.trim().isEmpty ? 'a round' : courseName.trim();
    return 'Join my round at $where on Christian Golfers Cape Town.\n\n'
        '${forCode(joinCode)}\n\n'
        'Or open Christian Golfers Cape Town and enter code ${normalise(joinCode)}.';
  }
}
