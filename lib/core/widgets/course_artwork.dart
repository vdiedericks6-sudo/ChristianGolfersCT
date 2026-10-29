import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Displays a course-specific photograph when the course catalog supplies one.
/// Missing photos are called out explicitly instead of being replaced with a
/// made-up course illustration.
class CourseArtwork extends StatelessWidget {
  const CourseArtwork({
    required this.seed,
    this.imageUrl,
    this.height,
    this.overlay = true,
    this.fallbackLabel = 'Course photo unavailable',
    super.key,
  });

  /// A stable id retained for call-site compatibility and semantics.
  final String seed;

  /// Licensed/club-provided photograph URL, when available.
  final String? imageUrl;
  final double? height;
  final bool overlay;
  final String fallbackLabel;

  Widget _placeholder() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 90 || constraints.maxWidth < 90;
      return Container(
        color: AppTheme.darkNavyLight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        child: compact
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18,
                    color: AppTheme.primaryGreenLight,
                  ),
                  SizedBox(height: 3),
                  Text(
                    'No photo',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 27,
                    color: AppTheme.primaryGreenLight,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fallbackLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      10,
                      colour: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final scene = url == null || url.isEmpty
        ? _placeholder()
        : Image.network(
            url,
            fit: BoxFit.cover,
            semanticLabel: 'Course photograph',
            errorBuilder: (context, error, stack) => _placeholder(),
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: url == null || url.isEmpty
                ? fallbackLabel
                : 'Course photograph',
            child: KeyedSubtree(key: ValueKey(seed), child: scene),
          ),
          if (overlay && url != null && url.isNotEmpty)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB30F172A)],
                  stops: [0.4, 1],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Christian Golfers mark shown when an asset cannot be loaded.
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
        border: Border.all(color: AppTheme.primaryGreen, width: 1.4),
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
          color: AppTheme.primaryGreen,
          size: size * 0.45,
        ),
      ),
    );
  }
}
