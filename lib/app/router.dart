import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/books/books_page.dart';
import '../features/calendar/agenda_page.dart';
import '../features/cards/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/stats/stats_page.dart';
import '../features/tasks/task_form_page.dart';
import '../features/tasks/task_page.dart';
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

  /// Hub da tarefa (também alvo dos deep links das notificações).
  static String task(String id) => '/tarefa/$id';
  static String editTask(String id) => '/tarefa/$id/editar';

  /// Formulário de nova tarefa, opcionalmente como subtarefa ou com prazo hoje.
  static String newTask({String? parentId, bool dueToday = false}) => Uri(
    path: '/tarefa/nova',
    queryParameters: {'pai': ?parentId, if (dueToday) 'prazo': 'hoje'},
  ).toString();
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
      // Tarefas abrem em tela cheia, por cima das abas. `nova` vem antes de
      // `:id` para não ser lida como id.
      GoRoute(
        path: '/tarefa/nova',
        parentNavigatorKey: rootKey,
        builder: (_, state) => TaskFormPage(
          parentId: state.uri.queryParameters['pai'],
          dueToday: state.uri.queryParameters['prazo'] == 'hoje',
        ),
      ),
      GoRoute(
        path: '/tarefa/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) => TaskPage(taskId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'editar',
            parentNavigatorKey: rootKey,
            builder: (_, state) =>
                TaskFormPage(taskId: state.pathParameters['id']),
          ),
        ],
      ),
    ],
  );
}
