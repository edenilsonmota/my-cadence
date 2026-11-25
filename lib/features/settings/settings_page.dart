import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/nav_tabs_providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_providers.dart';
import '../../data/providers.dart';
import '../../shared/widgets/number_stepper.dart';
import '../../shared/widgets/section_header.dart';
import '../cards/cards_providers.dart';
import '../cards/review_queue.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../pomodoro/pomodoro_logic.dart';
import '../sync/presentation/backup_actions.dart';
import '../tasks/alarms.dart';
import '../update/update_widgets.dart';

final _allDayHourProvider = StreamProvider.autoDispose<String?>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).watchString(allDayReminderHourKey),
);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s =
        ref.watch(pomodoroSettingsProvider).value ?? const PomodoroSettings();
    final cards = ref.watch(cardSettingsProvider).value ?? const CardSettings();
    final navTabs = ref.watch(navTabsProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final allDayHour = parseAllDayHour(ref.watch(_allDayHourProvider).value);
    final repo = ref.read(settingsRepositoryProvider);
    void setInt(String key, int v) => repo.setString(key, '$v');
    void setBool(String key, bool v) => repo.setString(key, '$v');

    Widget minutes(String label, String key, int value) => ListTile(
      title: Text(label),
      trailing: NumberStepper(
        value: value,
        min: 1,
        max: 180,
        semanticLabel: label,
        onChanged: (v) => setInt(key, v),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Header('Aparência'),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.space.page,
              context.space.xs,
              context.space.page,
              context.space.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tema', style: context.text.bodyLarge),
                SizedBox(height: context.space.sm),
                SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    for (final mode in AppThemeMode.values)
                      ButtonSegment(value: mode, label: Text(mode.label)),
                  ],
                  selected: {themeSettings.mode},
                  onSelectionChanged: (s) =>
                      repo.setString(themeModeSettingKey, s.single.name),
                ),
                SizedBox(height: context.space.lg),
                Text('Cor', style: context.text.bodyLarge),
                SizedBox(height: context.space.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final accent in AppAccentColor.values)
                      _AccentDot(
                        accent: accent,
                        selected: accent == themeSettings.accent,
                        onTap: () =>
                            repo.setString(accentColorSettingKey, accent.name),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Lights out (alto contraste)'),
            subtitle: Text(
              themeSettings.mode == AppThemeMode.light
                  ? 'Usado no modo escuro ou automático (preto puro e alto contraste)'
                  : 'Preto puro (OLED) e texto em alto contraste no modo escuro',
            ),
            value: themeSettings.lightsOut,
            onChanged: (v) => setBool(lightsOutSettingKey, v),
          ),
          ListTile(
            leading: const Icon(AppIcons.navBar),
            title: const Text('Barra de navegação'),
            subtitle: Text(navTabs.map((t) => t.label).join(' · ')),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => context.push(Routes.navBarSettings),
          ),
          const _Header('Flashcards'),
          ListTile(
            title: const Text('Cards novos por dia'),
            trailing: NumberStepper(
              value: cards.newPerDay,
              min: 0,
              max: 500,
              semanticLabel: 'Cards novos por dia',
              onChanged: (v) => setInt(CardSettings.keyNewPerDay, v),
            ),
          ),
          ListTile(
            title: const Text('Retenção desejada'),
            subtitle: Text(
              '${cards.retentionPercent}%: mais alta = revisões mais frequentes',
            ),
            trailing: NumberStepper(
              value: cards.retentionPercent,
              min: 70,
              max: 99,
              semanticLabel: 'Retenção desejada em porcentagem',
              onChanged: (v) => setInt(CardSettings.keyRetention, v),
            ),
          ),
          const _Header('Pomodoro'),
          minutes('Foco (min)', PomodoroSettings.keyFocus, s.focusMinutes),
          minutes(
            'Pausa curta (min)',
            PomodoroSettings.keyShortBreak,
            s.shortBreakMinutes,
          ),
          minutes(
            'Pausa longa (min)',
            PomodoroSettings.keyLongBreak,
            s.longBreakMinutes,
          ),
          ListTile(
            title: const Text('Pausa longa a cada'),
            subtitle: Text('${s.longBreakEvery} focos'),
            trailing: NumberStepper(
              value: s.longBreakEvery,
              min: 1,
              max: 12,
              semanticLabel: 'Focos até a pausa longa',
              onChanged: (v) => setInt(PomodoroSettings.keyLongEvery, v),
            ),
          ),
          SwitchListTile(
            title: const Text('Iniciar pausas sozinho'),
            subtitle: const Text(
              'Ao fim do foco, a pausa começa automaticamente',
            ),
            value: s.autoStartBreaks,
            onChanged: (v) => setBool(PomodoroSettings.keyAutoBreaks, v),
          ),
          SwitchListTile(
            title: const Text('Som ao terminar'),
            value: s.sound,
            onChanged: (v) => setBool(PomodoroSettings.keySound, v),
          ),
          SwitchListTile(
            title: const Text('Vibrar ao terminar'),
            value: s.vibrate,
            onChanged: (v) => setBool(PomodoroSettings.keyVibrate, v),
          ),
          SwitchListTile(
            title: const Text('Manter a tela ligada'),
            subtitle: const Text('Enquanto a tela do pomodoro estiver aberta'),
            value: s.keepScreenOn,
            onChanged: (v) => setBool(PomodoroSettings.keyScreenOn, v),
          ),
          const _Header('Tarefas'),
          ListTile(
            title: const Text('Lembrete de dia inteiro'),
            subtitle: Text(
              'Tarefas sem hora lembram às ${allDayHour}h '
              '(menos a antecedência escolhida)',
            ),
            trailing: NumberStepper(
              value: allDayHour,
              min: 0,
              max: 23,
              semanticLabel: 'Hora do lembrete de dia inteiro',
              onChanged: (v) => setInt(allDayReminderHourKey, v),
            ),
          ),
          const _Header('Backup'),
          ListTile(
            leading: const Icon(AppIcons.export),
            title: const Text('Exportar JSON'),
            subtitle: const Text('Todos os dados num arquivo'),
            onTap: () => exportJsonFlow(context, ref),
          ),
          ListTile(
            leading: const Icon(AppIcons.import),
            title: const Text('Importar JSON'),
            subtitle: const Text(
              'Mesclar ou substituir pelos dados de um backup',
            ),
            onTap: () => importJsonFlow(context, ref),
          ),
          const _Header('Atualizações'),
          const UpdateTiles(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(text);
  }
}

/// Bolinha selecionável da cor de destaque em Ajustes → Aparência.
class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccentColor accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: accent.label,
      child: Tooltip(
        message: accent.label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.swatch,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: context.colors.onSurface, width: 2)
                  : null,
            ),
            child: selected
                ? Icon(
                    AppIcons.check,
                    color: accent.onSwatch,
                    size: AppIconSize.standard,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
