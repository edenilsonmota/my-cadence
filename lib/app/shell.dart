import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/pomodoro/pomodoro_mini_player.dart';
import '../features/update/update_widgets.dart';
import '../shared/widgets/nav_tab_icon.dart';
import 'nav_tabs.dart';
import 'nav_tabs_providers.dart';

/// Escopo que informa às telas descendentes que elas estão rodando como aba
/// dentro do shell (e qual aba está ativa no momento).
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.activeTab, required super.child});

  final NavTab activeTab;

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      activeTab != oldWidget.activeTab;
}

/// Shell com a barra de navegação configurável (3 a 5 abas). Cada tela mantém
/// a própria pilha enquanto está na barra.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// `true` se o widget está dentro de uma aba do shell (e não empilhado por
  /// cima dele).
  static bool isTab(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellScope>() != null;

  /// Aba atualmente visível no shell, ou `null` fora do shell.
  static NavTab? activeTabOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellScope>()?.activeTab;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  void _ensureActiveTabInBar(List<NavTab> tabs) {
    final activeTab = NavTab.values[widget.navigationShell.currentIndex];
    if (!tabs.contains(activeTab)) {
      widget.navigationShell.goBranch(tabs.first.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<NavTab>>(navTabsProvider, (_, next) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _ensureActiveTabInBar(next);
      }
    });

    final tabs = ref.watch(navTabsProvider);
    final activeTab = NavTab.values[widget.navigationShell.currentIndex];
    final selectedIndex = tabs.indexOf(activeTab);
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent && selectedIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          _ensureActiveTabInBar(ref.read(navTabsProvider));
        }
      });
    }

    return Scaffold(
      body: _ShellScope(
        activeTab: activeTab,
        child: UpdateWatcher(child: widget.navigationShell),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeTab != NavTab.pomodoro) const PomodoroMiniPlayer(),
          NavigationBar(
            selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
            // Tocar de novo na aba ativa volta para a raiz dela.
            onDestinationSelected: (barIndex) {
              final tab = tabs[barIndex];
              widget.navigationShell.goBranch(
                tab.index,
                initialLocation:
                    tab.index == widget.navigationShell.currentIndex,
              );
            },
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: NavTabIcon(tab),
                  selectedIcon: NavTabIcon(tab, active: true),
                  label: tab.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
