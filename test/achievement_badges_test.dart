import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:christian_golfers/features/profile/presentation/achievement_badges.dart';

void main() {
  testWidgets('shows earned and in-progress badges', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [achievementBadgesProvider.overrideWith((ref) async => [
        {'id':'first_round','title':'First Round','description':'Complete a round','earned':true,'progress':1,'target':1},
        {'id':'five_rounds','title':'Five Rounds','description':'Complete five rounds','earned':false,'progress':2,'target':5},
      ])],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AchievementBadges()))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First Round'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });
}
