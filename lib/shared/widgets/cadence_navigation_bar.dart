import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/theme/app_theme.dart';
import 'nav_tab_icon.dart';

/// Barra de navegação inferior compartilhada entre o shell e a prévia nos
/// ajustes. Com 6 abas, reduz levemente o ícone e o rótulo para caber bem em
/// telas estreitas (360 dp).
class CadenceNavigationBar extends StatelessWidget {
  const CadenceNavigationBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.floating = false,
    super.key,
  });

  /// Dentro da pílula de vidro do shell: sem fundo próprio e mais baixa.
  final bool floating;

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = tabs.length > 5;
    final bar = NavigationBar(
      height: floating ? 64 : null,
      backgroundColor: floating
          ? context.colors.surface.withValues(alpha: 0)
          : null,
      elevation: floating ? 0 : null,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final tab in tabs)
          NavigationDestination(
            icon: NavTabIcon(tab),
            selectedIcon: NavTabIcon(tab, active: true),
            label: tab.labelFor(l10n),
          ),
      ],
    );
    if (!compact) return bar;

    final base = Theme.of(context).navigationBarTheme;
    final c = context.colors;
    final micro = context.type.micro;
    return NavigationBarTheme(
      data: base.copyWith(
        labelPadding: EdgeInsets.zero,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIconSize.standard,
            color: states.contains(WidgetState.selected)
                ? c.onSecondaryContainer
                : c.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => micro.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
          ),
        ),
      ),
      child: bar,
    );
  }
}
