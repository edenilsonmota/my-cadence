import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/nav_tabs.dart';
import 'package:my_cadence/app/router.dart';
import 'package:my_cadence/app/widget_navigation.dart';

void main() {
  group('WidgetNavigator.resolve', () {
    test('resolve today respeitando se Hoje está na barra ou no menu', () {
      final inBar = WidgetNavigator.resolve(
        'cadence://today',
        navTabs: const [NavTab.today, NavTab.tasks, NavTab.agenda],
      )!;
      expect(inBar.route, NavTab.today.tabRoute);
      expect(inBar.replace, isTrue);

      final inDrawer = WidgetNavigator.resolve(
        'cadence://today',
        navTabs: const [NavTab.tasks, NavTab.agenda, NavTab.books],
      )!;
      expect(inDrawer.route, NavTab.today.overlayRoute);
      expect(inDrawer.replace, isFalse);
    });

    test('complete conclui e abre Hoje', () {
      final r = WidgetNavigator.resolve('cadence://complete/abc')!;
      expect(r.completeTaskId, 'abc');
      expect(r.route, NavTab.today.tabRoute);
      expect(WidgetNavigator.resolve('cadence://complete/'), isNull);
    });

    test('resolve task e new-task corretamente', () {
      final task = WidgetNavigator.resolve('cadence://task/abc-123')!;
      expect(task.route, Routes.task('abc-123'));
      expect(task.replace, isFalse);

      final newTask = WidgetNavigator.resolve('cadence://new-task?dueToday=1')!;
      expect(newTask.route, Routes.newTask(dueToday: true));
      expect(newTask.replace, isFalse);
    });

    test('resolve agenda com data selecionada', () {
      final target = WidgetNavigator.resolve(
        'cadence://agenda?date=2026-11-28',
        navTabs: const [NavTab.today, NavTab.tasks, NavTab.agenda],
      )!;
      expect(target.route, NavTab.agenda.tabRoute);
      expect(target.replace, isTrue);
      expect(target.agendaDay, DateTime(2026, 11, 28));
    });

    test('ignora URIs desconhecidas ou inválidas', () {
      expect(WidgetNavigator.resolve('https://example.com'), isNull);
      expect(WidgetNavigator.resolve('cadence://task/'), isNull);
      expect(WidgetNavigator.resolve('cadence://desconhecido'), isNull);
    });
  });
}
