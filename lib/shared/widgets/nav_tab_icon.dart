import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../features/cards/cards_providers.dart';

/// Ícone de uma tela da navegação; na tela Revisar, inclui o selo de cards
/// vencidos, tanto na barra inferior quanto no menu lateral.
class NavTabIcon extends ConsumerWidget {
  const NavTabIcon(this.tab, {this.active = false, super.key});

  final NavTab tab;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconData = active ? tab.activeIcon : tab.icon;
    if (tab != NavTab.review) return Icon(iconData);
    final due = ref.watch(dueCountProvider);
    return Badge(
      isLabelVisible: due > 0,
      label: Text(due > 99 ? '99+' : '$due'),
      child: Icon(iconData),
    );
  }
}
