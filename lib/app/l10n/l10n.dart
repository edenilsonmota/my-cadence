import 'package:flutter/widgets.dart';

import '../../data/db/enums.dart';
import '../../features/cards/fsrs_bridge.dart';
import '../../features/tasks/task_lists.dart';
import '../../l10n/generated/app_localizations.dart';
import '../nav_tabs.dart';
import '../theme/theme_settings.dart';
import 'locale_settings.dart';

export '../../l10n/generated/app_localizations.dart';
export 'locale_providers.dart';
export 'locale_settings.dart';

/// Atalhos para textos localizados e código do idioma ativo (`pt`, `en`, `es`).
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Código de idioma ativo (`'pt'`, `'en'`, `'es'`) para formatadores puros.
  String get lang => Localizations.localeOf(this).languageCode;
}

extension AppLocaleL10n on AppLocale {
  String labelFor(AppLocalizations l10n) =>
      this == AppLocale.system ? l10n.languageAutomatic : nativeLabel;
}

extension NavTabL10n on NavTab {
  String labelFor(AppLocalizations l10n) => switch (this) {
    NavTab.today => l10n.navToday,
    NavTab.tasks => l10n.navTasks,
    NavTab.agenda => l10n.navAgenda,
    NavTab.review => l10n.navReview,
    NavTab.books => l10n.navBooks,
    NavTab.pomodoro => l10n.navPomodoro,
    NavTab.stats => l10n.navStats,
  };
}

extension AppThemeModeL10n on AppThemeMode {
  String labelFor(AppLocalizations l10n) => switch (this) {
    AppThemeMode.system => l10n.themeAutomatic,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
  };
}

extension AppAccentColorL10n on AppAccentColor {
  String labelFor(AppLocalizations l10n) => switch (this) {
    AppAccentColor.azul => l10n.accentBlue,
    AppAccentColor.amarelo => l10n.accentYellow,
    AppAccentColor.rosa => l10n.accentPink,
    AppAccentColor.violeta => l10n.accentViolet,
    AppAccentColor.laranja => l10n.accentOrange,
    AppAccentColor.verde => l10n.accentGreen,
  };
}

extension TaskKindL10n on TaskKind {
  String labelFor(AppLocalizations l10n) => switch (this) {
    TaskKind.simples => l10n.taskKindSimple,
    TaskKind.estudo => l10n.taskKindStudy,
    TaskKind.rotina => l10n.taskKindRoutine,
    TaskKind.evento => l10n.taskKindEvent,
  };
}

extension TaskStatusL10n on TaskStatus {
  String labelFor(AppLocalizations l10n) => switch (this) {
    TaskStatus.aFazer => l10n.taskStatusTodo,
    TaskStatus.fazendo => l10n.taskStatusDoing,
    TaskStatus.feita => l10n.taskStatusDone,
  };
}

extension ReminderModeL10n on ReminderMode {
  String labelFor(AppLocalizations l10n) => switch (this) {
    ReminderMode.notificacao => l10n.reminderModeNotification,
    ReminderMode.alarme => l10n.reminderModeAlarm,
  };
}

extension PomodoroKindL10n on PomodoroKind {
  String labelFor(AppLocalizations l10n) => switch (this) {
    PomodoroKind.foco => l10n.pomodoroFocus,
    PomodoroKind.pausaCurta => l10n.pomodoroShortBreak,
    PomodoroKind.pausaLonga => l10n.pomodoroLongBreak,
  };
}

extension TaskSortL10n on TaskSort {
  String labelFor(AppLocalizations l10n) => switch (this) {
    TaskSort.manual => l10n.tasksSortManual,
    TaskSort.prazo => l10n.tasksSortDue,
    TaskSort.prioridade => l10n.tasksSortPriority,
    TaskSort.criacao => l10n.tasksSortNewest,
    TaskSort.titulo => l10n.tasksSortTitle,
  };
}

extension GradeL10n on Grade {
  String labelFor(AppLocalizations l10n) => switch (this) {
    Grade.errei => l10n.reviewGradeAgain,
    Grade.dificil => l10n.reviewGradeHard,
    Grade.bom => l10n.reviewGradeGood,
    Grade.facil => l10n.reviewGradeEasy,
  };
}

String priorityLabel(int priority, AppLocalizations l10n) => switch (priority) {
  1 => l10n.priorityLow,
  2 => l10n.priorityMedium,
  3 => l10n.priorityHigh,
  _ => l10n.priorityNone,
};

/// Rótulo de uma antecedência de lembrete. Em tarefa de dia inteiro, "na
/// hora" vira "No dia, às 9h" (a hora do ajuste).
String reminderOffsetLabel(
  int minutes,
  AppLocalizations l10n, {
  bool allDay = false,
  int allDayHour = 9,
}) {
  if (minutes == 0) {
    return allDay ? l10n.reminderOnTheDay(allDayHour) : l10n.reminderAtTime;
  }
  const day = 1440, week = 7 * day;
  if (minutes % week == 0) return l10n.reminderWeeksBefore(minutes ~/ week);
  if (minutes % day == 0) return l10n.reminderDaysBefore(minutes ~/ day);
  return switch (minutes) {
    60 => l10n.reminder1Hour,
    _ => l10n.reminderMinutesBefore(minutes),
  };
}

String reminderOptionLabel(int? minutes, AppLocalizations l10n) =>
    switch (minutes) {
      null => l10n.reminderNone,
      0 => l10n.reminderAtTime,
      5 => l10n.reminder5Min,
      10 => l10n.reminder10Min,
      15 => l10n.reminder15Min,
      30 => l10n.reminder30Min,
      60 => l10n.reminder1Hour,
      1440 => l10n.reminder1Day,
      _ => '$minutes min',
    };
