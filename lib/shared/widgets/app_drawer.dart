import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import 'nav_tab_icon.dart';

/// Menu lateral com as telas que ficaram fora da barra de navegação, além de
/// Ajustes (e o catálogo de componentes em debug).
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final extraTabs = drawerNavTabs(ref.watch(navTabsProvider));
    final routes = <String>[
      for (final tab in extraTabs) tab.overlayRoute,
      Routes.weekReview,
      Routes.tags,
      Routes.trash,
      Routes.settings,
      if (kDebugMode) Routes.devComponents,
    ];

    void open(int index) {
      Navigator.of(context).pop();
      context.push(routes[index]);
    }

    return NavigationDrawer(
      onDestinationSelected: open,
      selectedIndex: null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: context.radius.smAll,
                child: Image.asset(
                  'assets/branding/logo.png',
                  width: 32,
                  height: 32,
                  excludeFromSemantics: true,
                ),
              ),
              SizedBox(width: context.space.md),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        for (final tab in extraTabs)
          NavigationDrawerDestination(
            icon: NavTabIcon(tab),
            label: Text(tab.labelFor(l10n)),
          ),
        if (extraTabs.isNotEmpty) const Divider(indent: 28, endIndent: 28),
        NavigationDrawerDestination(
          icon: const Icon(AppIcons.weekReview),
          label: Text(l10n.weekReviewShort),
        ),
        NavigationDrawerDestination(
          icon: const Icon(AppIcons.tag),
          label: Text(l10n.navTags),
        ),
        NavigationDrawerDestination(
          icon: const Icon(AppIcons.delete),
          label: Text(l10n.navTrash),
        ),
        NavigationDrawerDestination(
          icon: const Icon(AppIcons.settings),
          label: Text(l10n.navSettings),
        ),
        if (kDebugMode)
          NavigationDrawerDestination(
            icon: const Icon(AppIcons.color),
            label: Text(l10n.navComponents),
          ),
      ],
    );
  }
}
