import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flora/screens/home_screen.dart';
import 'package:flora/screens/plant_detail_screen.dart';
import 'package:flora/screens/schedule_screen.dart';
import 'package:flora/screens/health_check_screen.dart';
import 'package:flora/screens/support_screen.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/plant/:id',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id']!;
        return PlantDetailScreen(plantId: id);
      },
    ),
    GoRoute(
      path: '/schedule',
      builder: (BuildContext context, GoRouterState state) {
        return const ScheduleScreen();
      },
    ),
    GoRoute(
      path: '/health-check',
      builder: (BuildContext context, GoRouterState state) {
        return const HealthCheckScreen();
      },
    ),
    GoRoute(
      path: '/support',
      builder: (BuildContext context, GoRouterState state) {
        return const SupportScreen();
      },
    ),
  ],
);
