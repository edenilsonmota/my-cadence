import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/dates.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../../data/providers.dart';
import '../reschedule.dart';
import '../task_providers.dart';

/// Leva [task] para outro dia (hoje, amanhã, daqui a uma semana ou uma data
/// escolhida), mantendo a hora. Tarefa pausada volta para "a fazer".
Future<void> showRescheduleSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final l10n = context.l10n;
  final lang = context.lang;
  final today = ref.read(todayProvider);
  final repo = ref.read(tasksRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  final day = await showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheet) {
      Widget option(String label, DateTime value) => ListTile(
        leading: const Icon(AppIcons.date),
        title: Text(label),
        trailing: Text(formatDate(value, today, lang: lang)),
        onTap: () => Navigator.of(sheet).pop(value),
      );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sheet.space.page),
              child: Text(l10n.rescheduleAction, style: sheet.text.titleMedium),
            ),
            if (task.status == TaskStatus.pausada)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sheet.space.page,
                  sheet.space.xs,
                  sheet.space.page,
                  0,
                ),
                child: Text(
                  l10n.rescheduleResumesHint,
                  style: sheet.text.bodySmall!.copyWith(
                    color: sheet.colors.onSurfaceVariant,
                  ),
                ),
              ),
            option(l10n.quickDateToday, today),
            option(l10n.quickDateTomorrow, addDays(today, 1)),
            option(l10n.quickDateNextWeek, addDays(today, 7)),
            ListTile(
              leading: const Icon(AppIcons.edit),
              title: Text(l10n.rescheduleChoose),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheet,
                  initialDate: task.dueAt ?? today,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && sheet.mounted) {
                  Navigator.of(sheet).pop(picked);
                }
              },
            ),
          ],
        ),
      );
    },
  );
  if (day == null) return;
  final dates = rescheduleToDay(task, day);
  await repo.rescheduleTask(
    task.id,
    startAt: dates.startAt,
    dueAt: dates.dueAt,
    hasTime: dates.hasTime,
    status: task.status == TaskStatus.pausada ? TaskStatus.aFazer : null,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          l10n.rescheduledTo(formatRelative(day, today, lang: lang)),
        ),
      ),
    );
}
