import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets/cadence_navigation_bar.dart';
import '../../shared/widgets/nav_tab_icon.dart';
import '../../shared/widgets/section_header.dart';

/// Ajustes → Barra de navegação: escolhe quais telas ficam na barra (3 a 6),
/// em qual ordem, com prévia ao vivo e opção de restaurar o padrão.
class NavBarSettingsPage extends ConsumerStatefulWidget {
  const NavBarSettingsPage({super.key});

  @override
  ConsumerState<NavBarSettingsPage> createState() => _NavBarSettingsPageState();
}

class _NavBarSettingsPageState extends ConsumerState<NavBarSettingsPage> {
  List<NavTab>? _pending;
  int _previewIndex = 0;

  Future<void> _save(List<NavTab> next) async {
    setState(() => _pending = next);
    await ref
        .read(settingsRepositoryProvider)
        .setString(navTabsSettingKey, encodeNavTabs(next));
  }

  Future<void> _toggle(List<NavTab> current, NavTab tab) async {
    final next = toggleNavTab(current, tab);
    if (identical(next, current)) return;
    await _save(next);
  }

  Future<void> _reorder(List<NavTab> current, int from, int to) async {
    final next = reorderNavTabs(current, from, to);
    if (identical(next, current)) return;
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final fromDb = ref.watch(navTabsProvider);
    if (_pending != null && encodeNavTabs(_pending!) == encodeNavTabs(fromDb)) {
      _pending = null;
    }
    final tabs = _pending ?? fromDb;
    final extraTabs = drawerNavTabs(tabs);
    final atMin = tabs.length <= minNavTabs;
    final atMax = tabs.length >= maxNavTabs;
    final isDefault = isDefaultNavTabs(tabs);
    final previewSelected = _previewIndex.clamp(0, tabs.length - 1);
    final space = context.space;
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNavBar)),
      body: ListView(
        padding: EdgeInsets.only(bottom: space.xxl),
        children: [
          SectionHeader(
            l10n.navBarPreview,
            detail: l10n.navBarPreviewDetail(tabs.length, maxNavTabs),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.page),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: context.radius.lgAll,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: CadenceNavigationBar(
                tabs: tabs,
                selectedIndex: previewSelected,
                onDestinationSelected: (i) => setState(() => _previewIndex = i),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              space.page,
              space.sm,
              space.page,
              space.xs,
            ),
            child: Text(
              l10n.navBarHelper,
              style: context.text.bodySmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          SectionHeader(l10n.navBarInBar, detail: l10n.navBarDragToOrder),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => _reorder(tabs, from, to),
            children: [
              for (final (index, tab) in tabs.indexed)
                ListTile(
                  key: ValueKey(tab),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: space.sm,
                            horizontal: space.xs,
                          ),
                          child: Icon(
                            AppIcons.dragHandle,
                            color: colors.onSurfaceVariant,
                            semanticLabel: l10n.navBarDragSemantics(
                              tab.labelFor(l10n),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: space.xs),
                      NavTabIcon(tab),
                    ],
                  ),
                  title: Text(tab.labelFor(l10n)),
                  subtitle: _activeSubtitle(
                    l10n: l10n,
                    index: index,
                    atMin: atMin,
                  ),
                  trailing: Switch(
                    value: true,
                    onChanged: atMin ? null : (_) => _toggle(tabs, tab),
                  ),
                ),
            ],
          ),
          SectionHeader(l10n.navBarInDrawer),
          for (final tab in extraTabs)
            ListTile(
              key: ValueKey(tab),
              leading: NavTabIcon(tab),
              title: Text(tab.labelFor(l10n)),
              subtitle: Text(
                atMax ? l10n.navBarMaxLimit(maxNavTabs) : l10n.navBarDrawerHint,
              ),
              trailing: Switch(
                value: false,
                onChanged: atMax ? null : (_) => _toggle(tabs, tab),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(space.page, space.lg, space.page, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isDefault ? null : () => _save(defaultNavTabs),
                icon: const Icon(AppIcons.undo),
                label: Text(l10n.navBarRestoreDefault),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _activeSubtitle({
    required AppLocalizations l10n,
    required int index,
    required bool atMin,
  }) {
    if (index == 0 && atMin) {
      return Text(l10n.navBarInitialTabMin(minNavTabs));
    }
    if (index == 0) return Text(l10n.navBarInitialTab);
    if (atMin) return Text(l10n.navBarMinLimit(minNavTabs));
    return null;
  }
}
