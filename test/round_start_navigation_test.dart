import 'package:christian_golfers/app/app.dart';
import 'package:christian_golfers/app/router.dart';
import 'package:christian_golfers/core/demo/demo_backend.dart';
import 'package:christian_golfers/core/demo/demo_providers.dart';
import 'package:christian_golfers/core/demo/demo_seed.dart';
import 'package:christian_golfers/features/authentication/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'starting a fourball opens the live round without duplicate page keys',
    (tester) async {
      final demo = DemoBackend.seeded();
      appRouter.go('/home');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoBackendProvider.overrideWith((ref) => demo),
            currentUserIdProvider.overrideWithValue(DemoIds.you),
          ],
          child: const ChristianGolfersApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Play Golf'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Play Golf'));
      await tester.pumpAndSettle();
      expect(find.text('New Round'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('New Round'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('New Round'));
      await tester.pumpAndSettle();
      expect(find.text('Christian Golfers Demo Course'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'The Play Golf → New Round route must not reserve duplicate page keys.',
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Christian Golfers Demo Course'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Christian Golfers Demo Course').first);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Create round'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create round'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Start the round'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Start the round'),
        findsOneWidget,
        reason:
            'route=${appRouter.routeInformationProvider.value.uri}; '
            'visibleText=${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList()}; '
            'exception=${tester.takeException()}',
      );

      await tester.tap(find.text('Start the round'));
      await tester.pumpAndSettle();
      expect(find.text('Live round'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byTooltip('Scorecard'));
        await tester.pumpAndSettle();
        expect(find.text('SCORECARD'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Live round'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      demo.dispose();
    },
  );
}
