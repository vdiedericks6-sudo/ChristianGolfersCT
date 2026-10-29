import 'package:flutter/material.dart';

/// The official logo cropped from the supplied Christian Golfers mockup.
class ChristianGolfersMark extends StatelessWidget {
  const ChristianGolfersMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.asset('assets/images/christian_golfers_logo.png', fit: BoxFit.contain),
  );
}
