import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A course scene drawn from the course's own id.
///
/// 361 courses cannot each have a photograph, and a repeated stock image looks
/// worse than none. So each course gets its own scene instead: same visual
/// language, different light, horizon and contours, derived from a hash of the
/// id. It is stable - a course looks the same every time - costs nothing to
/// ship, and stays crisp at any size.
///
/// Drop a real photograph in later and it wins: [CourseArtwork] takes an
/// optional [imageUrl] and only paints when there isn't one.
class CourseArtwork extends StatelessWidget {
  const CourseArtwork({
    required this.seed,
    this.imageUrl,
    this.height,
    this.overlay = true,
    super.key,
  });

  /// Anything stable and unique - a course id works well.
  final String seed;

  /// A real photograph, when the catalogue has one.
  final String? imageUrl;

  final double? height;

  /// Darkens the lower half so text laid over the scene stays readable.
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final scene = imageUrl == null
        ? CustomPaint(painter: _CoursePainter(seed), size: Size.infinite)
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                CustomPaint(painter: _CoursePainter(seed), size: Size.infinite),
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          scene,
          if (overlay)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC0F1F17)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Five light conditions, all sitting inside the brand's dark register so a
/// list of course cards reads as one set rather than a patchwork.
class _Light {
  const _Light(this.skyTop, this.skyBottom, this.ridge, this.turf, this.turfLit);

  final Color skyTop;
  final Color skyBottom;
  final Color ridge;
  final Color turf;
  final Color turfLit;

  static const options = <_Light>[
    // Dusk
    _Light(Color(0xFF16283A), Color(0xFF9A6B3F), Color(0xFF0C1A16),
        Color(0xFF1B3325), Color(0xFF2E5138)),
    // First light
    _Light(Color(0xFF1B2436), Color(0xFFB08050), Color(0xFF0E1A17),
        Color(0xFF1D3527), Color(0xFF33573C)),
    // Overcast highveld
    _Light(Color(0xFF243440), Color(0xFF5E7078), Color(0xFF101E19),
        Color(0xFF1C3324), Color(0xFF2C4E36)),
    // Clear afternoon
    _Light(Color(0xFF1C4257), Color(0xFF6FA0A6), Color(0xFF0D1C17),
        Color(0xFF1F3A29), Color(0xFF37603F)),
    // Late evening
    _Light(Color(0xFF141E2E), Color(0xFF4A3A52), Color(0xFF0B1713),
        Color(0xFF172C1F), Color(0xFF264530)),
  ];
}

class _CoursePainter extends CustomPainter {
  _CoursePainter(this.seed);

  final String seed;

  /// FNV-1a: small, fast, and spreads similar ids (course-1, course-2) apart.
  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(_hash(seed));
    final light = _Light.options[random.nextInt(_Light.options.length)];

    final width = size.width;
    final height = size.height;

    // Horizon sits between a third and a half down.
    final horizon = height * (0.34 + random.nextDouble() * 0.14);

    // --- Sky ---------------------------------------------------------------
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light.skyTop, light.skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, width, horizon)),
    );

    // A low sun, sometimes.
    if (random.nextBool()) {
      final sunX = width * (0.15 + random.nextDouble() * 0.7);
      canvas.drawCircle(
        Offset(sunX, horizon - height * 0.04),
        height * 0.09,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppTheme.goldBright.withValues(alpha: 0.55),
              AppTheme.gold.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(sunX, horizon - height * 0.04),
              radius: height * 0.14,
            ),
          ),
      );
    }

    // --- Tree line ---------------------------------------------------------
    final ridge = Path()..moveTo(0, horizon);
    var x = 0.0;
    while (x < width) {
      final step = width * (0.06 + random.nextDouble() * 0.10);
      final crown = horizon - height * (0.03 + random.nextDouble() * 0.09);
      ridge.quadraticBezierTo(x + step / 2, crown, x + step, horizon);
      x += step;
    }
    ridge
      ..lineTo(width, horizon + 2)
      ..lineTo(0, horizon + 2)
      ..close();
    canvas.drawPath(ridge, Paint()..color = light.ridge);

    // --- Turf --------------------------------------------------------------
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, width, height - horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light.turf, AppTheme.forestDeep],
        ).createShader(Rect.fromLTWH(0, horizon, width, height - horizon)),
    );

    // A fairway sweeping away from the viewer.
    final bend = 0.25 + random.nextDouble() * 0.5;
    final fairway = Path()
      ..moveTo(width * (bend - 0.10), horizon)
      ..quadraticBezierTo(
        width * (bend + 0.28),
        horizon + (height - horizon) * 0.45,
        width * (bend + 0.55),
        height,
      )
      ..lineTo(width * (bend - 0.62), height)
      ..quadraticBezierTo(
        width * (bend - 0.18),
        horizon + (height - horizon) * 0.45,
        width * (bend + 0.05),
        horizon,
      )
      ..close();
    canvas.drawPath(fairway, Paint()..color = light.turfLit);

    // Mown stripes, very faint - they read as maintenance, not decoration.
    canvas.save();
    canvas.clipPath(fairway);
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (var i = 0; i < 8; i++) {
      final top = horizon + (height - horizon) * (i / 8);
      canvas.drawRect(
        Rect.fromLTWH(0, top, width, (height - horizon) / 16),
        stripe,
      );
    }
    canvas.restore();

    // --- Bunkers -----------------------------------------------------------
    final sand = Paint()..color = const Color(0xFFD9CBA8).withValues(alpha: 0.5);
    final bunkers = 1 + random.nextInt(2);
    for (var i = 0; i < bunkers; i++) {
      final centre = Offset(
        width * (0.1 + random.nextDouble() * 0.8),
        horizon + (height - horizon) * (0.25 + random.nextDouble() * 0.45),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centre,
          width: width * (0.10 + random.nextDouble() * 0.10),
          height: height * 0.045,
        ),
        sand,
      );
    }

    // --- Green and flag ----------------------------------------------------
    final greenCentre = Offset(
      width * (bend + 0.02),
      horizon + (height - horizon) * 0.22,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: greenCentre,
        width: width * 0.20,
        height: height * 0.07,
      ),
      Paint()..color = light.turfLit.withValues(alpha: 0.85),
    );

    final pin = Offset(greenCentre.dx, greenCentre.dy - height * 0.015);
    final flagHeight = height * 0.13;
    canvas.drawLine(
      pin,
      Offset(pin.dx, pin.dy - flagHeight),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(pin.dx, pin.dy - flagHeight)
        ..lineTo(pin.dx + width * 0.05, pin.dy - flagHeight + height * 0.025)
        ..lineTo(pin.dx, pin.dy - flagHeight + height * 0.05)
        ..close(),
      Paint()..color = AppTheme.gold,
    );

    // --- Vignette ----------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CoursePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// The Christian Golfers mark: the app icon in a gold-keylined tile.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 78, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppTheme.goldLine, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        'assets/icons/app_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Icon(
          Icons.sports_golf_rounded,
          color: AppTheme.gold,
          size: size * 0.45,
        ),
      ),
    );
  }
}
