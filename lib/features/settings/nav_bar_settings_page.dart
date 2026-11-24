import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Barra de navegação')),
      body: ListView(
        padding: EdgeInsets.only(bottom: space.xxl),
        children: [
          SectionHeader('Prévia', detail: '${tabs.length} de $maxNavTabs abas'),
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
              'A primeira aba abre com o app. As telas fora da barra '
              'continuam no menu lateral.',
              style: context.text.bodySmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SectionHeader('Na barra', detail: 'Arraste para ordenar'),
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
                            semanticLabel: 'Arrastar ${tab.label}',
                          ),
                        ),
                      ),
                      SizedBox(width: space.xs),
                      NavTabIcon(tab),
                    ],
                  ),
                  title: Text(tab.label),
                  subtitle: _activeSubtitle(index: index, atMin: atMin),
                  trailing: Switch(
                    value: true,
                    onChanged: atMin ? null : (_) => _toggle(tabs, tab),
                  ),
                ),
            ],
          ),
          const SectionHeader('No menu lateral'),
          for (final tab in extraTabs)
            ListTile(
              key: ValueKey(tab),
              leading: NavTabIcon(tab),
              title: Text(tab.label),
              subtitle: Text(
                atMax
                    ? 'Máximo de $maxNavTabs abas atingido'
                    : 'Acessível pelo menu lateral',
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
                label: const Text('Restaurar padrão'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _activeSubtitle({required int index, required bool atMin}) {
    if (index == 0 && atMin) {
      return const Text('Aba inicial · mínimo de $minNavTabs abas');
    }
    if (index == 0) return const Text('Aba inicial');
    if (atMin) return const Text('Mínimo de $minNavTabs abas na barra');
    return null;
  }
}
