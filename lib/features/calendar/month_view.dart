import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../core/calendar_layout.dart';
import '../../core/dates.dart';
import '../tasks/task_appearance.dart';
import '../tasks/task_providers.dart';
import 'calendar_entries.dart';
import 'calendar_providers.dart';
import 'timeline_view.dart';

/// Grade 7×N do mês de [month], com até 3 itens por dia e "+N".
class MonthView extends ConsumerWidget {
  const MonthView({required this.month, required this.onOpenDay, super.key});

  final DateTime month;
  final ValueChanged<DateTime> onOpenDay;

  static const maxChips = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = monthGridDays(month);
    final range = (from: days.first, to: addDays(days.last, 1));
    final entries =
        ref.watch(calendarEntriesProvider(range)).value ??
        const <CalendarEntry>[];
    final resolver = ref.watch(appearanceResolverProvider);
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final weekdays = weekdaysShortFor(context.lang);
    return Column(
      children: [
        Row(
          children: [
            for (final name in weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
        for (var w = 0; w < days.length; w += 7)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in days.sublist(w, w + 7))
                  Expanded(
                    child: _DayCell(
                      day: day,
                      inMonth: day.month == month.month,
                      isToday: isSameDay(day, today),
                      entries: [
                        for (final e in entries)
                          if (e.occursOn(day)) e,
                      ],
                      resolver: resolver,
                      onTap: () => onOpenDay(day),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.entries,
    required this.resolver,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<CalendarEntry> entries;
  final AppearanceResolver resolver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Dia inteiro primeiro, depois por horário.
    final sorted = [
      ...entries.where((e) => e.allDay),
      ...entries.where((e) => !e.allDay),
    ];

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: scheme.outlineVariant, width: 0.5),
            bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: LayoutBuilder(
          builder: (context, box) {
            // Quantos itens cabem: se não couberem todos, um lugar vira "+N".
            const header = 25.0, more = 14.0, chip = EntryChip.denseHeight;
            final room = box.maxHeight - header;
            final fitAll = (room / chip).floor();
            final shown =
                sorted.length <= MonthView.maxChips && sorted.length <= fitAll
                ? sorted.length
                : ((room - more) / chip).floor().clamp(0, MonthView.maxChips);
            final extra = sorted.length - shown;
            return Opacity(
              opacity: inMonth ? 1 : 0.45,
              // Sem rolagem: só evita o aviso de estouro com fonte grande.
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 21,
                        height: 21,
                        alignment: Alignment.center,
                        decoration: isToday
                            ? BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          '${day.day}',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: isToday
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    for (final e in sorted.take(shown))
                      EntryChip(
                        entry: e,
                        tones: entryTones(context, e.task, resolver),
                        dense: true,
                      ),
                    if (extra > 0)
                      SizedBox(
                        height: more,
                        child: Text(
                          '+$extra',
                          textAlign: TextAlign.center,
                          style: context.type.micro,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
