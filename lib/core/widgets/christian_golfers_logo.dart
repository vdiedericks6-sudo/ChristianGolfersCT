import 'package:flutter/material.dart';

/// Displays the official CGCT wordmark without its black source background.
///
/// The logo is an opaque monochrome JPEG. Its luminance is used as alpha, then
/// the visible pixels are tinted with the selected brand color, preserving the
/// original lettering and silhouette exactly.
class ChristianGolfersLogo extends StatelessWidget {
  const ChristianGolfersLogo({
    required this.width,
    required this.height,
    this.color = Colors.white,
    super.key,
  });

  final double width;
  final double height;
  final Color color;

  List<double> _colorMatrix(Color tint) => <double>[
    0, 0, 0, 0, tint.red.toDouble(),
    0, 0, 0, 0, tint.green.toDouble(),
    0, 0, 0, 0, tint.blue.toDouble(),
    0.2126, 0.7152, 0.0722, 0, 0,
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Christian Golfers Cape Town logo',
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.square(
              dimension: width,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_colorMatrix(color)),
                child: Image.asset(
                  'assets/images/cgct_official_logo.jpeg',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
