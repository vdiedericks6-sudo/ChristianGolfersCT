import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/word_of_the_day.dart';

/// Supplies the reading for the local date and refreshes at midnight or when
/// the app resumes after a day change.
class DailyReadingBuilder extends StatefulWidget {
  const DailyReadingBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, WordOfTheDay reading) builder;

  @override
  State<DailyReadingBuilder> createState() => _DailyReadingBuilderState();
}

class _DailyReadingBuilderState extends State<DailyReadingBuilder>
    with WidgetsBindingObserver {
  DateTime _date = DateTime.now();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDate();
  }

  void _refreshDate() {
    final now = DateTime.now();
    if (now.year != _date.year ||
        now.month != _date.month ||
        now.day != _date.day) {
      setState(() => _date = now);
    }
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(tomorrow.difference(now), _refreshDate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reading = WordOfTheDay.forDate(_date);
    return widget.builder(context, reading);
  }
}

/// Daily scripture for the landing screen.
class DailyVerseText extends StatelessWidget {
  const DailyVerseText({
    required this.verseStyle,
    required this.referenceStyle,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final TextStyle verseStyle;
  final TextStyle referenceStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => DailyReadingBuilder(
    builder: (context, reading) => Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text('“${reading.verse}”', textAlign: textAlign, style: verseStyle),
        const SizedBox(height: 5),
        Text(reading.reference, textAlign: textAlign, style: referenceStyle),
      ],
    ),
  );
}
