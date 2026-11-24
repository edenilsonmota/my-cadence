import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cards/cards_providers.dart';
import '../features/pomodoro/pomodoro_mini_player.dart';
import 'theme/app_theme.dart';

/// Shell com a barra de navegação das 5 abas. Cada aba mantém a própria pilha.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PomodoroMiniPlayer(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            // Tocar de novo na aba ativa volta para a raiz dela.
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(AppIcons.today),
                selectedIcon: Icon(AppIcons.todayActive),
                label: 'Hoje',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.tasks),
                selectedIcon: Icon(AppIcons.tasksActive),
                label: 'Tarefas',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.agenda),
                selectedIcon: Icon(AppIcons.agendaActive),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: _ReviewIcon(AppIcons.review),
                selectedIcon: _ReviewIcon(AppIcons.reviewActive),
                label: 'Revisar',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.books),
                selectedIcon: Icon(AppIcons.booksActive),
                label: 'Books',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ícone da aba Revisar com o número de cards para revisar agora.
class _ReviewIcon extends ConsumerWidget {
  const _ReviewIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueCountProvider);
    return Badge(
      isLabelVisible: due > 0,
      label: Text(due > 99 ? '99+' : '$due'),
      child: Icon(icon),
    );
  }
}
