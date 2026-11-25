/// Snapshot puro dos widgets de calendário da tela inicial (Hoje, Semanal,
/// Mensal). Puro, sem Flutter.
library;

import 'dart:convert';

import '../../app/theme/theme_settings.dart';
import '../../app/theme/widget_palette.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../calendar/calendar_entries.dart';
import '../tasks/task_appearance.dart';
import '../tasks/task_lists.dart';

/// Máximo de tarefas enviadas para a lista rolável do widget "Hoje".
const maxTodayWidgetItems = 30;

/// Item de tarefa exibido nos widgets da tela inicial.
class WidgetTaskItem {
  const WidgetTaskItem({
    required this.id,
    required this.title,
    required this.colorArgb,
    required this.overdue,
    required this.done,
    this.timeLabel,
  });

  final String id;
  final String title;
  final String? timeLabel;
  final int colorArgb;
  final bool overdue;
  final bool done;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    if (timeLabel != null) 'timeLabel': timeLabel,
    'colorArgb': colorArgb,
    'overdue': overdue,
    'done': done,
  };
}

/// Snapshot serializável entregue aos widgets nativos da tela inicial.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.dateIso,
    required this.lang,
    required this.themeMode,
    required this.lightsOut,
    required this.accentArgb,
    required this.todayTitle,
    required this.todayDateLabel,
    required this.emptyTodayLabel,
    required this.overdueLabel,
    required this.overdueCount,
    required this.todayCount,
    required this.todayItems,
  });

  final String dateIso;
  final String lang;
  final String themeMode;
  final bool lightsOut;
  final int accentArgb;
  final String todayTitle;
  final String todayDateLabel;
  final String emptyTodayLabel;
  final String overdueLabel;
  final int overdueCount;
  final int todayCount;
  final List<WidgetTaskItem> todayItems;

  Map<String, Object?> toJson() => {
    'version': 1,
    'dateIso': dateIso,
    'lang': lang,
    'themeMode': themeMode,
    'lightsOut': lightsOut,
    'accentArgb': accentArgb,
    'todayTitle': todayTitle,
    'todayDateLabel': todayDateLabel,
    'emptyTodayLabel': emptyTodayLabel,
    'overdueLabel': overdueLabel,
    'overdueCount': overdueCount,
    'todayCount': todayCount,
    'todayItems': [for (final item in todayItems) item.toJson()],
  };

  String encode() => jsonEncode(toJson());
}

/// Monta o snapshot dos widgets para o dia [today] a partir das tarefas vivas,
/// aparência e preferências de tema/idioma.
HomeWidgetSnapshot buildHomeWidgetSnapshot({
  required List<Task> tasks,
  required List<Tag> tags,
  required Map<String, Set<String>> tagIdsByTask,
  required DateTime today,
  required ThemeSettings theme,
  String lang = 'pt',
}) {
  final dayStart = startOfDay(today);
  final dayEnd = addDays(dayStart, 1);
  // Mesma herança de cor da UI: 1ª tag em ordem alfabética.
  final sortedTags = [...tags]..sort((a, b) => a.name.compareTo(b.name));
  final resolver = AppearanceResolver(
    tasks: tasks,
    firstTagColor: {
      for (final MapEntry(key: taskId, value: ids) in tagIdsByTask.entries)
        if (sortedTags.where((t) => ids.contains(t.id)).firstOrNull
            case final tag?)
          taskId: tag.colorKey,
    },
    validColors: widgetPaletteArgb.keys.toSet(),
    validIcons: const {},
  );

  // Atrasadas (abertas com prazo antes de hoje) + tarefas de hoje.
  final overdue = <Task>[];
  final dueToday = <Task>[];
  final seenIds = <String>{};

  for (final task in tasks) {
    if (task.deletedAt != null || task.status == TaskStatus.feita) continue;
    final due = task.dueAt;
    if (due == null) continue;
    if (due.isBefore(dayStart)) {
      overdue.add(task);
      seenIds.add(task.id);
    } else if (due.isBefore(dayEnd)) {
      dueToday.add(task);
      seenIds.add(task.id);
    }
  }

  // Ocorrências virtuais de rotinas que caem hoje (se a rotina ainda não entrou).
  final virtualEntries = expandOccurrences(tasks, dayStart, dayEnd);
  for (final entry in virtualEntries) {
    if (entry.done || seenIds.contains(entry.task.id)) continue;
    dueToday.add(entry.task);
    seenIds.add(entry.task.id);
  }

  overdue.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  final sortedToday = sortToday(dueToday);

  String? labelFor(Task task, {required bool isOverdue}) {
    final due = task.dueAt;
    if (due == null) return null;
    if (isOverdue) {
      return formatRelative(due, dayStart, withTime: task.hasTime, lang: lang);
    }
    if (task.hasTime) return formatTime(due);
    return null;
  }

  final items = <WidgetTaskItem>[
    for (final task in overdue)
      WidgetTaskItem(
        id: task.id,
        title: task.title,
        timeLabel: labelFor(task, isOverdue: true),
        colorArgb: argbForWidgetColorKey(resolver.colorKeyOf(task)),
        overdue: true,
        done: false,
      ),
    for (final task in sortedToday)
      WidgetTaskItem(
        id: task.id,
        title: task.title,
        timeLabel: labelFor(task, isOverdue: false),
        colorArgb: argbForWidgetColorKey(resolver.colorKeyOf(task)),
        overdue: false,
        done: task.status == TaskStatus.feita,
      ),
  ];

  final rawDate = formatDate(dayStart, dayStart, lang: lang);
  final dateLabel = rawDate.isEmpty
      ? rawDate
      : rawDate[0].toUpperCase() + rawDate.substring(1);

  return HomeWidgetSnapshot(
    dateIso:
        '${dayStart.year.toString().padLeft(4, '0')}-'
        '${two(dayStart.month)}-${two(dayStart.day)}',
    lang: lang,
    themeMode: theme.mode.name,
    lightsOut: theme.lightsOut,
    accentArgb: theme.accent.argb,
    todayTitle: switch (lang) {
      'en' => 'Today',
      'es' => 'Hoy',
      _ => 'Hoje',
    },
    todayDateLabel: dateLabel,
    emptyTodayLabel: switch (lang) {
      'en' => 'Nothing for today yet.',
      'es' => 'Nada para hoy todavía.',
      _ => 'Nada para hoje ainda.',
    },
    overdueLabel: switch (lang) {
      'en' => 'Overdue',
      'es' => 'Atrasadas',
      _ => 'Atrasadas',
    },
    overdueCount: overdue.length,
    todayCount: sortedToday.length,
    todayItems: items.take(maxTodayWidgetItems).toList(growable: false),
  );
}
