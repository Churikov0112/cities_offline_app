import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_game/presentation/ai_game_screen.dart';
import '../../features/ai_game/presentation/ai_rules_screen.dart';
import '../../features/ai_game/presentation/ai_sessions_screen.dart';
import '../../features/home/presentation/home_screen/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/mediator/presentation/mediator_rules_screen.dart';
import '../../features/mediator/presentation/mediator_screen/mediator_screen.dart';
import '../../features/mediator/presentation/mediator_sessions_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

enum RoutePaths {
  home(path: '/'),
  mediator(path: '/mediator'),
  mediatorGame(path: 'game/:sessionId'),
  mediatorRules(path: 'rules'),
  mediatorRulesForSession(path: 'rules/:sessionId'),
  ai(path: '/ai'),
  aiGame(path: 'game/:sessionId'),
  aiRules(path: 'rules'),
  aiRulesForSession(path: 'rules/:sessionId'),
  map(path: '/map'),
  settings(path: '/settings');

  const RoutePaths({required this.path});
  final String path;
}

class AppRouter {
  late GoRouter router;

  static final AppRouter _inst = AppRouter._internal();

  factory AppRouter() {
    _inst.router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.home.path,
      routes: [
        GoRoute(
          path: RoutePaths.home.path,
          name: RoutePaths.home.name,
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: RoutePaths.mediator.path,
              name: RoutePaths.mediator.name,
              builder: (context, state) => const MediatorSessionsScreen(),
              routes: [
                GoRoute(
                  path: RoutePaths.mediatorGame.path,
                  name: RoutePaths.mediatorGame.name,
                  builder: (context, state) => MediatorScreen(
                    sessionId: state.pathParameters['sessionId']!,
                  ),
                ),
                GoRoute(
                  path: RoutePaths.mediatorRules.path,
                  name: RoutePaths.mediatorRules.name,
                  builder: (context, state) => const MediatorRulesScreen(),
                ),
                GoRoute(
                  path: RoutePaths.mediatorRulesForSession.path,
                  name: RoutePaths.mediatorRulesForSession.name,
                  builder: (context, state) => MediatorRulesScreen(
                    sessionId: state.pathParameters['sessionId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.ai.path,
          name: RoutePaths.ai.name,
          builder: (context, state) => const AiSessionsScreen(),
          routes: [
            GoRoute(
              path: RoutePaths.aiGame.path,
              name: RoutePaths.aiGame.name,
              builder: (context, state) => AiGameScreen(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
            GoRoute(
              path: RoutePaths.aiRules.path,
              name: RoutePaths.aiRules.name,
              builder: (context, state) => const AiRulesScreen(),
            ),
            GoRoute(
              path: RoutePaths.aiRulesForSession.path,
              name: RoutePaths.aiRulesForSession.name,
              builder: (context, state) => AiRulesScreen(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.map.path,
          name: RoutePaths.map.name,
          builder: (context, state) => MapScreen(
            lat: double.parse(state.uri.queryParameters['lat']!),
            lon: double.parse(state.uri.queryParameters['lon']!),
            cityName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
        GoRoute(
          path: RoutePaths.settings.path,
          name: RoutePaths.settings.name,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    return _inst;
  }

  AppRouter._internal();
}
