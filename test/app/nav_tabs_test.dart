import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/nav_tabs.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';

void main() {
  test('padrão tem 5 abas válidas e o ajuste é local do aparelho', () {
    expect(defaultNavTabs, [
      NavTab.today,
      NavTab.tasks,
      NavTab.agenda,
      NavTab.review,
      NavTab.books,
    ]);
    expect(isValidNavTabs(defaultNavTabs), isTrue);
    expect(isDefaultNavTabs(defaultNavTabs), isTrue);
    expect(isLocalSetting(navTabsSettingKey), isTrue);
  });

  test('isValidNavTabs valida mínimo, máximo e duplicadas', () {
    expect(isValidNavTabs([NavTab.today, NavTab.tasks]), isFalse);
    expect(isValidNavTabs([NavTab.today, NavTab.tasks, NavTab.agenda]), isTrue);
    expect(
      isValidNavTabs([
        NavTab.today,
        NavTab.tasks,
        NavTab.agenda,
        NavTab.review,
        NavTab.books,
        NavTab.pomodoro,
      ]),
      isFalse,
    );
    expect(isValidNavTabs([NavTab.today, NavTab.today, NavTab.tasks]), isFalse);
  });

  test(
    'normalizeNavTabs ignora desconhecidas, remove duplicadas e aplica limites',
    () {
      expect(parseNavTabs(null), defaultNavTabs);
      expect(parseNavTabs(''), defaultNavTabs);
      expect(parseNavTabs('   '), defaultNavTabs);

      expect(parseNavTabs('pomodoro, invalida, stats, today'), [
        NavTab.pomodoro,
        NavTab.stats,
        NavTab.today,
      ]);

      expect(parseNavTabs('books,today,books,pomodoro,today'), [
        NavTab.books,
        NavTab.today,
        NavTab.pomodoro,
      ]);

      // Menos que o mínimo volta ao padrão.
      expect(parseNavTabs('today,tasks'), defaultNavTabs);
      expect(parseNavTabs('foo,bar,baz'), defaultNavTabs);
      expect(parseNavTabs('today,today,today'), defaultNavTabs);

      // Mais que o máximo limita às 5 primeiras válidas.
      expect(parseNavTabs('stats,pomodoro,books,review,agenda,tasks,today'), [
        NavTab.stats,
        NavTab.pomodoro,
        NavTab.books,
        NavTab.review,
        NavTab.agenda,
      ]);
    },
  );

  test('encodeNavTabs e parseNavTabs fazem ida e volta sem perda', () {
    const custom = [NavTab.pomodoro, NavTab.today, NavTab.stats, NavTab.review];
    final encoded = encodeNavTabs(custom);
    expect(encoded, 'pomodoro,today,stats,review');
    expect(parseNavTabs(encoded), custom);
  });

  test('drawerNavTabs devolve as telas fora da barra na ordem canônica', () {
    expect(drawerNavTabs(defaultNavTabs), [NavTab.pomodoro, NavTab.stats]);
    expect(drawerNavTabs([NavTab.pomodoro, NavTab.stats, NavTab.review]), [
      NavTab.today,
      NavTab.tasks,
      NavTab.agenda,
      NavTab.books,
    ]);
    expect(
      drawerNavTabs([
        NavTab.stats,
        NavTab.pomodoro,
        NavTab.today,
        NavTab.tasks,
        NavTab.agenda,
      ]),
      [NavTab.review, NavTab.books],
    );
  });

  test('canToggleNavTab e toggleNavTab respeitam mínimo 3 e máximo 5', () {
    // No máximo (5): pode desligar, não pode ligar mais uma.
    expect(canToggleNavTab(defaultNavTabs, NavTab.pomodoro), isFalse);
    expect(toggleNavTab(defaultNavTabs, NavTab.pomodoro), defaultNavTabs);
    expect(canToggleNavTab(defaultNavTabs, NavTab.books), isTrue);

    final four = toggleNavTab(defaultNavTabs, NavTab.books);
    expect(four, [NavTab.today, NavTab.tasks, NavTab.agenda, NavTab.review]);
    expect(canToggleNavTab(four, NavTab.pomodoro), isTrue);
    expect(canToggleNavTab(four, NavTab.agenda), isTrue);

    final three = toggleNavTab(four, NavTab.agenda);
    expect(three, [NavTab.today, NavTab.tasks, NavTab.review]);
    // No mínimo (3): não pode desligar, pode ligar.
    expect(canToggleNavTab(three, NavTab.today), isFalse);
    expect(toggleNavTab(three, NavTab.today), three);
    expect(canToggleNavTab(three, NavTab.stats), isTrue);

    final withStats = toggleNavTab(three, NavTab.stats);
    expect(withStats, [
      NavTab.today,
      NavTab.tasks,
      NavTab.review,
      NavTab.stats,
    ]);
  });

  test('reorderNavTabs move itens mantendo os demais na ordem', () {
    const start = [NavTab.today, NavTab.tasks, NavTab.agenda, NavTab.review];
    expect(reorderNavTabs(start, 2, 0), [
      NavTab.agenda,
      NavTab.today,
      NavTab.tasks,
      NavTab.review,
    ]);
    expect(reorderNavTabs(start, 0, 3), [
      NavTab.tasks,
      NavTab.agenda,
      NavTab.review,
      NavTab.today,
    ]);
    expect(reorderNavTabs(start, 1, 1), start);
    expect(reorderNavTabs(start, -1, 2), start);
    expect(reorderNavTabs(start, 0, 9), start);
    expect(isDefaultNavTabs(reorderNavTabs(defaultNavTabs, 0, 1)), isFalse);
  });
}
