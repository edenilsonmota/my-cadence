import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

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
        _ => Routes.settings,
      }),
      selectedIndex: null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'My Cadence',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.timer_outlined),
          label: Text('Pomodoro'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.insights_outlined),
          label: Text('Métricas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Ajustes'),
        ),
      ],
    );
  }
}
