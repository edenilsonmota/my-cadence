import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/dates.dart';
import '../features/books/book_page.dart';
import '../features/books/books_page.dart';
import '../features/books/page_editor_page.dart';
import '../features/calendar/agenda_page.dart';
import '../features/cards/cards_list_page.dart';
import '../features/cards/review_page.dart';
import '../features/cards/review_session_page.dart';
import '../features/dev/components_page.dart';
import '../features/pomodoro/pomodoro_page.dart';
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

  /// Catálogo de componentes (só em debug).
  static const devComponents = '/dev/componentes';

  /// Hub da tarefa (também alvo dos deep links das notificações).
  static String task(String id) => '/tarefa/$id';
  static String editTask(String id) => '/tarefa/$id/editar';

  /// Telas provisórias até as etapas de revisão, pomodoro e books.
  static String reviewTask(String taskId) => reviewSession(taskId: taskId);
  static String reviewSession({String? deckId, String? taskId}) => Uri(
    path: '/revisao',
    queryParameters: {'deck': ?deckId, 'tarefa': ?taskId},
  ).toString();

  /// Lista de cards (todos, ou de um deck).
  static String cards({String? deckId}) =>
      Uri(path: '/cards', queryParameters: {'deck': ?deckId}).toString();
  static String pomodoro({String? taskId}) =>
      Uri(path: '/pomodoro', queryParameters: {'tarefa': ?taskId}).toString();
  static String page(String id, {bool edit = false}) =>
      edit ? '/pagina/$id?editar=1' : '/pagina/$id';
  static String book(String id) => '/book/$id';

  /// Formulário de nova tarefa, opcionalmente como subtarefa, com prazo hoje,
  /// com prazo num dia ([date], dia inteiro) ou começando num horário ([at]).
  static String newTask({
    String? parentId,
    bool dueToday = false,
    DateTime? date,
    DateTime? at,
  }) => Uri(
    path: '/tarefa/nova',
    queryParameters: {
      'pai': ?parentId,
      if (dueToday) 'prazo': 'hoje',
      if (date != null) 'data': _isoDate(date),
      if (at != null) 'inicio': '${_isoDate(at)}T${formatTime(at)}',
    },
  ).toString();

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
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
      if (kDebugMode)
        GoRoute(
          path: Routes.devComponents,
          parentNavigatorKey: rootKey,
          builder: (_, _) => const ComponentsPage(),
        ),
      GoRoute(
        path: '/revisao',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ReviewSessionPage(
          deckId: state.uri.queryParameters['deck'],
          taskId: state.uri.queryParameters['tarefa'],
        ),
      ),
      GoRoute(
        path: '/cards',
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            CardsListPage(deckId: state.uri.queryParameters['deck']),
      ),
      GoRoute(
        path: '/pomodoro',
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            PomodoroPage(taskId: state.uri.queryParameters['tarefa']),
      ),
      GoRoute(
        path: '/pagina/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) => PageEditorPage(
          pageId: state.pathParameters['id']!,
          startEditing: state.uri.queryParameters['editar'] == '1',
        ),
      ),
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            BookPage(notebookId: state.pathParameters['id']!),
      ),
      // Tarefas abrem em tela cheia, por cima das abas. `nova` vem antes de
      // `:id` para não ser lida como id.
      GoRoute(
        path: '/tarefa/nova',
        parentNavigatorKey: rootKey,
        builder: (_, state) => TaskFormPage(
          parentId: state.uri.queryParameters['pai'],
          dueToday: state.uri.queryParameters['prazo'] == 'hoje',
          date: DateTime.tryParse(state.uri.queryParameters['data'] ?? ''),
          startAt: DateTime.tryParse(state.uri.queryParameters['inicio'] ?? ''),
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
