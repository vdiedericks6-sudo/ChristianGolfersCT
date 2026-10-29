import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Credit line for the course and driving-range catalogue.
///
/// The data comes from OpenStreetMap under the Open Database Licence, which
/// permits commercial use on condition that the source is credited wherever
/// the data is shown. This is not decoration - it is the licence term.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({this.dense = false, super.key});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 10),
      child: Text(
        'Course and range data © OpenStreetMap contributors',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          color: AppTheme.muted,
        ),
      ),
    );
  }
}
