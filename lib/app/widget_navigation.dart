import 'package:go_router/go_router.dart';

import 'nav_tabs.dart';
import 'router.dart';

/// Interpreta URIs vindas dos widgets da tela inicial (`cadence://...`).
///
/// Suporta:
/// - `cadence://today` → abre Hoje (aba ou overlay)
/// - `cadence://task/<id>` → abre o hub da tarefa
/// - `cadence://new-task?dueToday=1` → abre o formulário de nova tarefa
/// - `cadence://agenda?date=YYYY-MM-DD` → seleciona o dia e abre a Agenda
class WidgetNavigator {
  WidgetNavigator(
    this._router, {
    List<NavTab> Function()? readNavTabs,
    this.onSelectAgendaDay,
  }) : _readNavTabs = readNavTabs ?? _defaultTabs;

  final GoRouter _router;
  final List<NavTab> Function() _readNavTabs;
  final void Function(DateTime day)? onSelectAgendaDay;

  static List<NavTab> _defaultTabs() => defaultNavTabs;

  /// Resolve o destino de uma URI de widget; `null` se desconhecida.
  static ({String route, bool replace, DateTime? agendaDay})? resolve(
    String rawUri, {
    List<NavTab> navTabs = defaultNavTabs,
  }) {
    final uri = Uri.tryParse(rawUri);
    if (uri == null || uri.scheme != 'cadence') return null;
    switch (uri.host) {
      case 'today':
        final inBar = navTabs.contains(NavTab.today);
        return (
          route: inBar ? NavTab.today.tabRoute : NavTab.today.overlayRoute,
          replace: inBar,
          agendaDay: null,
        );
      case 'task':
        final id = uri.pathSegments.firstOrNull;
        if (id == null || id.isEmpty) return null;
        return (route: Routes.task(id), replace: false, agendaDay: null);
      case 'new-task':
        final dueToday = uri.queryParameters['dueToday'] == '1';
        final date = DateTime.tryParse(uri.queryParameters['date'] ?? '');
        return (
          route: Routes.newTask(dueToday: dueToday, date: date),
          replace: false,
          agendaDay: null,
        );
      case 'agenda':
        final inBar = navTabs.contains(NavTab.agenda);
        final date = DateTime.tryParse(uri.queryParameters['date'] ?? '');
        return (
          route: inBar ? NavTab.agenda.tabRoute : NavTab.agenda.overlayRoute,
          replace: inBar,
          agendaDay: date,
        );
      default:
        return null;
    }
  }

  void open(String rawUri) {
    void navigate() {
      final target = resolve(rawUri, navTabs: _readNavTabs());
      if (target == null) return;
      if (target.agendaDay case final day?) {
        onSelectAgendaDay?.call(day);
      }
      if (target.replace) {
        _router.go(target.route);
      } else {
        _router.push(target.route);
      }
    }

    final delegate = _router.routerDelegate;
    if (delegate.currentConfiguration.isNotEmpty) {
      navigate();
      return;
    }
    void whenReady() {
      if (delegate.currentConfiguration.isEmpty) return;
      delegate.removeListener(whenReady);
      navigate();
    }

    delegate.addListener(whenReady);
  }
}
