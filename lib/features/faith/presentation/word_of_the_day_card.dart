import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'daily_verse_text.dart';

class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DailyReadingBuilder(
      builder: (context, reading) => Container(
        decoration: AppTheme.cardDecoration(
          colour: AppTheme.card,
          border: AppTheme.line,
          radius: AppTheme.radiusCard,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Word of the Day',
                    style: AppTheme.body(
                      11,
                      colour: AppTheme.primaryGreen,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.darkNavy,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reading.reference,
              style: AppTheme.body(
                15,
                weight: FontWeight.w800,
                colour: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“${reading.verse}”',
              style: AppTheme.body(
                13,
                weight: FontWeight.w600,
                colour: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reading.reflection,
              style: AppTheme.body(
                12,
                weight: FontWeight.w500,
                colour: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
