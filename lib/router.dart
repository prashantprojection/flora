import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flora/screens/home_screen.dart';
import 'package:flora/screens/plant_detail_screen.dart';
import 'package:flora/screens/schedule_screen.dart';
import 'package:flora/screens/disease_diagnosis_screen.dart';
import 'package:flora/screens/support_screen.dart';
import 'package:flora/widgets/scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home / Garden
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'plant/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return PlantDetailScreen(plantId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Schedule
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
            ),
          ],
        ),
        // Tab 3: Diagnosis
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/health-check',
              builder: (context, state) => const DiseaseDiagnosisScreen(),
            ),
          ],
        ),
        // Tab 4: Support
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/support',
              builder: (context, state) => const SupportScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
