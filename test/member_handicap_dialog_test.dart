import 'package:christian_golfers/features/admin/data/admin_league_dashboard_repository.dart';
import 'package:christian_golfers/features/admin/presentation/member_handicap_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invalid handicap and missing provenance cannot be submitted', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(
      body: MemberHandicapDialog(member: AdminLeagueMember(
        userId: 'member', displayName: 'Test golfer', email: 'test@example.org',
        handicapIndex: 12, visiting: false, createdAt: null,
      )),
    ))));
    await tester.enterText(find.byType(TextFormField).first, '55');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number between -10 and 54.'), findsOneWidget);
    expect(find.text('Record the source, such as a club record.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'NaN');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number between -10 and 54.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
