import 'package:flutter/material.dart';

import '../../features/courses/domain/golf_hole.dart';
import 'course_artwork.dart';

class HoleArtwork extends StatelessWidget {
  const HoleArtwork({
    required this.hole,
    required this.seed,
    this.height = 170,
    super.key,
  });

  final GolfHole hole;
  final String seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = hole.imageUrl;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl == null || imageUrl.isEmpty
            ? CourseArtwork(
                seed: '$seed-${hole.number}',
                fallbackLabel: 'Hole ${hole.number} photo unavailable',
                overlay: false,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => CourseArtwork(
                  seed: '$seed-${hole.number}',
                  fallbackLabel: 'Hole ${hole.number} photo unavailable',
                  overlay: false,
                ),
              ),
      ),
    );
  }
}
