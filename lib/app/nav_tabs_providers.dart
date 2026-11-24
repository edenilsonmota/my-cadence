import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import 'nav_tabs.dart';
import 'theme/app_theme.dart';

/// Abas iniciais carregadas antes da abertura do app (`main.dart` e `pumpApp`),
/// para a primeira aba já abrir sem piscar "Hoje".
final initialNavTabsProvider = Provider<List<NavTab>>((ref) => defaultNavTabs);

final _navTabsStreamProvider = StreamProvider<List<NavTab>>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchString(navTabsSettingKey)
      .map(parseNavTabs),
);

/// Lista atual (sempre válida, de 3 a 6 abas) da barra de navegação.
final navTabsProvider = Provider<List<NavTab>>(
  (ref) =>
      ref.watch(_navTabsStreamProvider).value ??
      ref.watch(initialNavTabsProvider),
);

/// Abre uma tela configurável: vai para a aba se ela estiver na barra, ou
/// empilha por cima do shell se estiver no menu lateral.
void openNavTab(BuildContext context, List<NavTab> barTabs, NavTab tab) {
  if (barTabs.contains(tab)) {
    context.go(tab.tabRoute);
  } else {
    context.push(tab.overlayRoute);
  }
}

/// Ícones de cada tela configurável (padrão e ativo).
extension NavTabIcons on NavTab {
  IconData get icon => switch (this) {
    NavTab.today => AppIcons.today,
    NavTab.tasks => AppIcons.tasks,
    NavTab.agenda => AppIcons.agenda,
    NavTab.review => AppIcons.review,
    NavTab.books => AppIcons.books,
    NavTab.pomodoro => AppIcons.pomodoro,
    NavTab.stats => AppIcons.stats,
  };

  IconData get activeIcon => switch (this) {
    NavTab.today => AppIcons.todayActive,
    NavTab.tasks => AppIcons.tasksActive,
    NavTab.agenda => AppIcons.agendaActive,
    NavTab.review => AppIcons.reviewActive,
    NavTab.books => AppIcons.booksActive,
    NavTab.pomodoro => AppIcons.pomodoroActive,
    NavTab.stats => AppIcons.statsActive,
  };
}
