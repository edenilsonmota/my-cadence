import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
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
import '../tasks/alarm_diagnostics.dart';
import '../tasks/alarms.dart';
import '../tasks/daily_reminders.dart';
import '../tasks/daily_reminders_providers.dart';
import '../update/update_widgets.dart';

final _allDayHourProvider = StreamProvider.autoDispose<String?>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).watchString(allDayReminderHourKey),
);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLocale current,
  ) async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<AppLocale>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                ctx.space.page,
                0,
                ctx.space.page,
                ctx.space.sm,
              ),
              child: Text(l10n.settingsLanguage, style: ctx.text.titleMedium),
            ),
            for (final option in AppLocale.values)
              ListTile(
                title: Text(option.labelFor(l10n)),
                trailing: option == current
                    ? Icon(AppIcons.check, color: ctx.colors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(option),
              ),
            SizedBox(height: ctx.space.sm),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await ref
        .read(settingsRepositoryProvider)
        .setString(appLocaleSettingKey, picked.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s =
        ref.watch(pomodoroSettingsProvider).value ?? const PomodoroSettings();
    final cards = ref.watch(cardSettingsProvider).value ?? const CardSettings();
    final navTabs = ref.watch(navTabsProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final locale = ref.watch(appLocaleProvider);
    final allDayHour = parseAllDayHour(ref.watch(_allDayHourProvider).value);
    final daily =
        ref.watch(dailyReminderSettingsProvider).value ??
        const DailyReminderSettings();
    final diagnostics =
        ref.watch(alarmDiagnosticsProvider).value ?? AlarmDiagnostics.allGood;
    final repo = ref.read(settingsRepositoryProvider);
    void setInt(String key, int v) => repo.setString(key, '$v');
    void setBool(String key, bool v) => repo.setString(key, '$v');
    Future<void> setDailyToggle(String key, bool v) async {
      await repo.setString(key, '$v');
      if (v) await ref.read(alarmSchedulerProvider).requestPermission();
    }

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
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Header(l10n.settingsAppearance),
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
                Text(l10n.settingsTheme, style: context.text.bodyLarge),
                SizedBox(height: context.space.sm),
                SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    for (final mode in AppThemeMode.values)
                      ButtonSegment(
                        value: mode,
                        label: Text(mode.labelFor(l10n)),
                      ),
                  ],
                  selected: {themeSettings.mode},
                  onSelectionChanged: (s) =>
                      repo.setString(themeModeSettingKey, s.single.name),
                ),
                SizedBox(height: context.space.lg),
                Text(l10n.settingsColor, style: context.text.bodyLarge),
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
            title: Text(l10n.settingsLightsOut),
            subtitle: Text(
              themeSettings.mode == AppThemeMode.light
                  ? l10n.settingsLightsOutHintLight
                  : l10n.settingsLightsOutHintDark,
            ),
            value: themeSettings.lightsOut,
            onChanged: (v) => setBool(lightsOutSettingKey, v),
          ),
          ListTile(
            leading: const Icon(AppIcons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(locale.labelFor(l10n)),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => _pickLanguage(context, ref, locale),
          ),
          ListTile(
            leading: const Icon(AppIcons.navBar),
            title: Text(l10n.settingsNavBar),
            subtitle: Text(navTabs.map((t) => t.labelFor(l10n)).join(' · ')),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => context.push(Routes.navBarSettings),
          ),
          _Header(l10n.settingsFlashcards),
          ListTile(
            title: Text(l10n.settingsNewCardsPerDay),
            trailing: NumberStepper(
              value: cards.newPerDay,
              min: 0,
              max: 500,
              semanticLabel: l10n.settingsNewCardsPerDay,
              onChanged: (v) => setInt(CardSettings.keyNewPerDay, v),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDesiredRetention),
            subtitle: Text(
              l10n.settingsDesiredRetentionHint(cards.retentionPercent),
            ),
            trailing: NumberStepper(
              value: cards.retentionPercent,
              min: 70,
              max: 99,
              semanticLabel: l10n.settingsDesiredRetentionSemantics,
              onChanged: (v) => setInt(CardSettings.keyRetention, v),
            ),
          ),
          _Header(l10n.settingsPomodoro),
          minutes(
            l10n.settingsFocusMinutes,
            PomodoroSettings.keyFocus,
            s.focusMinutes,
          ),
          minutes(
            l10n.settingsShortBreakMinutes,
            PomodoroSettings.keyShortBreak,
            s.shortBreakMinutes,
          ),
          minutes(
            l10n.settingsLongBreakMinutes,
            PomodoroSettings.keyLongBreak,
            s.longBreakMinutes,
          ),
          ListTile(
            title: Text(l10n.settingsLongBreakEvery),
            subtitle: Text(l10n.settingsLongBreakEveryDetail(s.longBreakEvery)),
            trailing: NumberStepper(
              value: s.longBreakEvery,
              min: 1,
              max: 12,
              semanticLabel: l10n.settingsLongBreakEverySemantics,
              onChanged: (v) => setInt(PomodoroSettings.keyLongEvery, v),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsAutoStartBreaks),
            subtitle: Text(l10n.settingsAutoStartBreaksHint),
            value: s.autoStartBreaks,
            onChanged: (v) => setBool(PomodoroSettings.keyAutoBreaks, v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsSoundOnEnd),
            value: s.sound,
            onChanged: (v) => setBool(PomodoroSettings.keySound, v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsVibrateOnEnd),
            value: s.vibrate,
            onChanged: (v) => setBool(PomodoroSettings.keyVibrate, v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsKeepScreenOn),
            subtitle: Text(l10n.settingsKeepScreenOnHint),
            value: s.keepScreenOn,
            onChanged: (v) => setBool(PomodoroSettings.keyScreenOn, v),
          ),
          _Header(l10n.settingsTasks),
          ListTile(
            title: Text(l10n.settingsAllDayReminder),
            subtitle: Text(l10n.settingsAllDayReminderHint(allDayHour)),
            trailing: NumberStepper(
              value: allDayHour,
              min: 0,
              max: 23,
              semanticLabel: l10n.settingsAllDayReminderSemantics,
              onChanged: (v) => setInt(allDayReminderHourKey, v),
            ),
          ),
          ListTile(
            leading: Icon(
              AppIcons.diagnostics,
              color: diagnostics.hasAnyIssue
                  ? context.palette.warning.strong
                  : null,
            ),
            title: Text(l10n.settingsAlarmDiagnostics),
            subtitle: Text(
              diagnostics.hasAnyIssue
                  ? l10n.settingsAlarmDiagnosticsIssues(diagnostics.issueCount)
                  : l10n.settingsAlarmDiagnosticsOk,
            ),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => context.push(Routes.alarmDiagnostics),
          ),
          _Header(l10n.settingsDailyReminders),
          SwitchListTile(
            title: Text(l10n.settingsDailySummary),
            subtitle: Text(
              daily.summaryEnabled
                  ? l10n.settingsDailySummaryHint(daily.summaryHour)
                  : l10n.settingsDailySummaryOffHint,
            ),
            value: daily.summaryEnabled,
            onChanged: (v) =>
                setDailyToggle(DailyReminderSettings.keySummaryEnabled, v),
          ),
          if (daily.summaryEnabled)
            ListTile(
              title: Text(l10n.settingsHourLabel),
              trailing: NumberStepper(
                value: daily.summaryHour,
                min: 0,
                max: 23,
                semanticLabel: l10n.settingsDailySummaryHourSemantics,
                onChanged: (v) =>
                    setInt(DailyReminderSettings.keySummaryHour, v),
              ),
            ),
          SwitchListTile(
            title: Text(l10n.settingsDailyReview),
            subtitle: Text(
              daily.reviewEnabled
                  ? l10n.settingsDailyReviewHint(daily.reviewHour)
                  : l10n.settingsDailyReviewOffHint,
            ),
            value: daily.reviewEnabled,
            onChanged: (v) =>
                setDailyToggle(DailyReminderSettings.keyReviewEnabled, v),
          ),
          if (daily.reviewEnabled)
            ListTile(
              title: Text(l10n.settingsHourLabel),
              trailing: NumberStepper(
                value: daily.reviewHour,
                min: 0,
                max: 23,
                semanticLabel: l10n.settingsDailyReviewHourSemantics,
                onChanged: (v) =>
                    setInt(DailyReminderSettings.keyReviewHour, v),
              ),
            ),
          _Header(l10n.settingsBackup),
          ListTile(
            leading: const Icon(AppIcons.export),
            title: Text(l10n.settingsExportJson),
            subtitle: Text(l10n.settingsExportJsonHint),
            onTap: () => exportJsonFlow(context, ref),
          ),
          ListTile(
            leading: const Icon(AppIcons.import),
            title: Text(l10n.settingsImportJson),
            subtitle: Text(l10n.settingsImportJsonHint),
            onTap: () => importJsonFlow(context, ref),
          ),
          _Header(l10n.settingsUpdates),
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
    final label = accent.labelFor(context.l10n);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
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
