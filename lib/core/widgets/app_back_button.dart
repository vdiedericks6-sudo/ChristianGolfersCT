import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Consistent in-app back navigation, including routes entered with `go()`
/// where there is no previous page to pop.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        final path = GoRouterState.of(context).uri.path;
        final fallback = switch (path) {
          '/courses' || '/courses/' => '/home',
          '/leagues' || '/leagues/' => '/home',
          '/community' || '/community/' => '/home',
          '/profile' || '/profile/' => '/home',
          '/play' || '/play/' => '/home',
          '/more' ||
          '/more/' ||
          '/admin' ||
          '/course-seed' ||
          '/join-round' => '/home',
          _ when path.endsWith('/scorecard') => path.replaceFirst(
            '/scorecard',
            '/live',
          ),
          _ when path.endsWith('/leaderboard') => path.replaceFirst(
            '/leaderboard',
            '/live',
          ),
          _ when path.endsWith('/live') => path.replaceFirst('/live', '/lobby'),
          _ when path.startsWith('/courses/') => '/courses',
          _ when path.startsWith('/join/') => '/home',
          _ => '/home',
        };
        context.go(fallback);
      }
    },
  );
}
