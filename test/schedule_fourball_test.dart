import 'package:christian_golfers/core/demo/demo_backend.dart';
import 'package:christian_golfers/core/demo/demo_providers.dart';
import 'package:christian_golfers/features/admin/presentation/schedule_fourball_screen.dart';
import 'package:christian_golfers/features/admin/data/admin_league_dashboard_repository.dart';
import 'package:christian_golfers/features/rounds/domain/golf_round.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard retains scheduled dates', () {
    final dashboard = AdminLeagueDashboard.fromJson({
      'rounds': [
        {'scheduled_at': '2026-11-01T06:00:00Z'},
      ],
    });
    expect(dashboard.rounds.single.scheduledAt!.toUtc(), DateTime.utc(2026, 11, 1, 6));
  });
  testWidgets('fourball selection cannot seat a fifth member', (tester) async {
    final demo = DemoBackend.seeded();
    final dashboard = AdminLeagueDashboard.fromJson({
      'members': List.generate(
        5,
        (i) => {
          'user_id': '$i',
          'display_name': 'Member $i',
          'email': 'member$i@example.test',
        },
      ),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoBackendProvider.overrideWith((ref) => demo),
          adminLeagueDashboardProvider.overrideWith(
            (ref, filter) async => dashboard,
          ),
        ],
        child: const MaterialApp(home: ScheduleFourballScreen()),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.text('Member $i'));
      await tester.tap(find.text('Member $i'));
      await tester.pumpAndSettle();
    }
    final fifth = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Member 4'),
    );
    expect(fifth.onChanged, isNull);
    expect(fifth.value, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    demo.dispose();
  });
  test(
    'scheduled dates preserve the instant and old rounds remain readable',
    () {
      expect(GolfRound.fromJson({}).scheduledAt, isNull);
      final round = GolfRound.fromJson({
        'scheduled_at': '2026-11-01T08:00:00+02:00',
      });
      expect(round.scheduledAt!.toUtc(), DateTime.utc(2026, 11, 1, 6));
    },
  );
  testWidgets(
    'schedule form blocks incomplete allocations without sending a request',
    (tester) async {
      final demo = DemoBackend.seeded();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [demoBackendProvider.overrideWith((ref) => demo)],
          child: const MaterialApp(home: ScheduleFourballScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule fourball'));
      await tester.pumpAndSettle();
      expect(
        find.text('Choose a course, tee, future time and one to four members.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      demo.dispose();
    },
  );
}
