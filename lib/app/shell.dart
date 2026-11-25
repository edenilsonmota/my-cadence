import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/pomodoro/pomodoro_mini_player.dart';
import '../features/update/update_widgets.dart';
import '../shared/widgets/cadence_navigation_bar.dart';
import '../shared/widgets/glass_surface.dart';
import 'nav_tabs.dart';
import 'nav_tabs_providers.dart';
import 'theme/app_theme.dart';

/// Escopo que informa às telas descendentes que elas estão rodando como aba
/// dentro do shell (e qual aba está ativa no momento).
class _ShellScope extends InheritedWidget {
  const _ShellScope({
    required this.activeTab,
    required this.barInset,
    required super.child,
  });

  final NavTab activeTab;

  /// Quanto a barra flutuante cobre do conteúdo, além da área do sistema.
  final double barInset;

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      activeTab != oldWidget.activeTab || barInset != oldWidget.barInset;
}

/// Shell com a barra de navegação configurável (3 a 6 abas). Cada tela mantém
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

  /// Altura da barra flutuante sobre o conteúdo (0 fora do shell). Para
  /// subir botões flutuantes acima dela.
  static double barInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellScope>()?.barInset ?? 0;

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

    final space = context.space;
    return Scaffold(
      // O conteúdo passa por baixo da barra flutuante (vidro).
      extendBody: true,
      body: Builder(
        builder: (context) {
          final inset =
              MediaQuery.paddingOf(context).bottom -
              MediaQuery.viewPaddingOf(context).bottom;
          return _ShellScope(
            activeTab: activeTab,
            barInset: inset > 0 ? inset : 0,
            child: UpdateWatcher(child: widget.navigationShell),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(space.md, 0, space.md, space.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activeTab != NavTab.pomodoro)
              const PomodoroMiniPlayer(floating: true),
            GlassSurface(
              borderRadius: context.radius.pillAll,
              child: CadenceNavigationBar(
                floating: true,
                tabs: tabs,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
