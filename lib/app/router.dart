import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/books/books_page.dart';
import '../features/calendar/agenda_page.dart';
import '../features/cards/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/stats/stats_page.dart';
import '../features/tasks/tasks_page.dart';
import '../features/tasks/today_page.dart';
import 'shell.dart';

/// Caminhos das rotas, para não espalhar strings pelo app.
abstract final class Routes {
  static const today = '/hoje';
  static const tasks = '/tarefas';
  static const agenda = '/agenda';
  static const review = '/revisar';
  static const books = '/books';
  static const stats = '/metricas';
  static const settings = '/ajustes';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildRouter({String initialLocation = Routes.today}) {
  final rootKey = GlobalKey<NavigatorState>();

  StatefulShellBranch branch(String path, Widget page) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => page)],
  );

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          branch(Routes.today, const TodayPage()),
          branch(Routes.tasks, const TasksPage()),
          branch(Routes.agenda, const AgendaPage()),
          branch(Routes.review, const ReviewPage()),
          branch(Routes.books, const BooksPage()),
        ],
      ),
      // Métricas e ajustes abrem por cima do shell, a partir do menu lateral.
      GoRoute(
        path: Routes.stats,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const StatsPage(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
  );
}
