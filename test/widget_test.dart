import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter test environment works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Christian Golfers'))),
    );

    expect(find.text('Christian Golfers'), findsOneWidget);
  });
}
