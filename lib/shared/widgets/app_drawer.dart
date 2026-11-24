import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';

/// Menu lateral com o que não cabe nas abas: pomodoro, métricas e ajustes.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      Navigator.of(context).pop();
      context.push(route);
    }

    return NavigationDrawer(
      onDestinationSelected: (index) => open(switch (index) {
        0 => Routes.pomodoro(),
        1 => Routes.stats,
        2 => Routes.settings,
        _ => Routes.devComponents,
      }),
      selectedIndex: null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/branding/logo.png',
                  width: 32,
                  height: 32,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'My Cadence',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(AppIcons.pomodoro),
          label: Text('Pomodoro'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(AppIcons.stats),
          label: Text('Métricas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(AppIcons.settings),
          label: Text('Ajustes'),
        ),
        if (kDebugMode)
          const NavigationDrawerDestination(
            icon: Icon(AppIcons.color),
            label: Text('Componentes'),
          ),
      ],
    );
  }
}
