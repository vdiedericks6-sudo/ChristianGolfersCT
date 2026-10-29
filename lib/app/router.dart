import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

import '../features/authentication/presentation/auth_gate.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/courses/presentation/course_detail_screen.dart';
import '../features/courses/presentation/course_list_screen.dart';
import '../features/courses/presentation/course_seed_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leagues/presentation/leagues_screen.dart';
import '../features/admin/presentation/admin_portal_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/leaderboard/presentation/round_leaderboard_screen.dart';
import '../features/play/presentation/play_screen.dart';
import '../features/profile/domain/user_profile.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/rounds/presentation/join_link_screen.dart';
import '../features/rounds/presentation/join_round_screen.dart';
import '../features/rounds/presentation/round_lobby_screen.dart';
import '../features/scorecard/presentation/live_round_screen.dart';
import '../features/scorecard/presentation/scorecard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final profile = state.extra;

        if (profile is! UserProfile) {
          return const Scaffold(
            body: Center(child: Text('Profile data is unavailable.')),
          );
        }

        return EditProfileScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/courses/:courseId',
      builder: (context, state) =>
          CourseDetailScreen(courseId: state.pathParameters['courseId']!),
    ),
    GoRoute(
      path: '/course-seed',
      builder: (context, state) => const CourseSeedScreen(),
    ),
    GoRoute(
      path: '/join-round',
      builder: (context, state) => const JoinRoundScreen(),
    ),
    GoRoute(
      path: '/join/:code',
      builder: (context, state) =>
          JoinLinkScreen(code: state.pathParameters['code'] ?? ''),
    ),
    GoRoute(
      path: '/rounds/:roundId/lobby',
      builder: (context, state) =>
          RoundLobbyScreen(roundId: state.pathParameters['roundId']!),
    ),
    GoRoute(
      path: '/rounds/:roundId/live',
      builder: (context, state) =>
          LiveRoundScreen(roundId: state.pathParameters['roundId']!),
    ),
    GoRoute(
      path: '/rounds/:roundId/scorecard',
      builder: (context, state) =>
          ScorecardScreen(roundId: state.pathParameters['roundId']!),
    ),
    GoRoute(
      path: '/rounds/:roundId/leaderboard',
      builder: (context, state) =>
          RoundLeaderboardScreen(roundId: state.pathParameters['roundId']!),
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminPortalScreen()),
    GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
    GoRoute(path: '/play', builder: (context, state) => const PlayScreen()),
    GoRoute(
      path: '/leaderboards',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/courses',
              builder: (context, state) => const CourseListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/leagues',
              builder: (context, state) => const LeaguesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.outlined_flag),
              selectedIcon: Icon(Icons.flag_rounded),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Leagues',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Fellowship',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
