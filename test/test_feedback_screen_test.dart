import 'package:christian_golfers/features/feedback/presentation/test_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short feedback is rejected before sending', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TestFeedbackScreen())));
    await tester.enterText(find.byType(TextFormField), 'short');
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Please add at least 10 characters.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
