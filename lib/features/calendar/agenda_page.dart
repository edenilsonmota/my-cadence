import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/calendar_layout.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_drawer.dart';
import '../tasks/task_providers.dart';
import 'calendar_entries.dart';
import 'calendar_providers.dart';
import 'month_view.dart';
import 'timeline_view.dart';

/// Largura a partir da qual a semana mostra 7 dias (abaixo, 3).
const _wideWeek = 600.0;

/// Aba Agenda: visões Dia, Semana e Mês.
class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(calendarSettingsProvider).value ?? const CalendarSettings();
    final day = ref.watch(calendarDayProvider);
    final mode = settings.mode;
    final wide = MediaQuery.sizeOf(context).width >= _wideWeek;

    final days = switch (mode) {
      CalendarMode.dia => [day],
      CalendarMode.semana when wide => [
        for (var i = 0; i < 7; i++) addDays(weekStart(day), i),
      ],
      _ => [for (var i = 0; i < 3; i++) addDays(day, i)],
    };

    void setMode(CalendarMode m) => ref
        .read(settingsRepositoryProvider)
        .setString(CalendarSettings.modeKey, m.name);

    void openDay(DateTime d) {
      ref.read(calendarDayProvider.notifier).show(d);
      setMode(CalendarMode.dia);
    }

    void step(int direction) {
      final notifier = ref.read(calendarDayProvider.notifier);
      if (mode == CalendarMode.mes) {
        notifier.show(DateTime(day.year, day.month + direction));
      } else {
        notifier.show(addDays(day, direction * days.length));
      }
    }

    // Ano só quando não é o atual (e aí o mês abreviado, para caber).
    final thisYear = ref.watch(todayProvider).year == day.year;
    final title = thisYear
        ? monthNames[day.month - 1]
        : '${monthShort[day.month - 1]} ${day.year}';
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(AppIcons.dropdown),
          label: Text(
            title[0].toUpperCase() + title.substring(1),
            maxLines: 1,
            softWrap: false,
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Ir para a data',
            );
            if (picked != null) {
              ref.read(calendarDayProvider.notifier).show(picked);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            icon: const Icon(AppIcons.search),
            onPressed: () async {
              final found = await showSearch<DateTime?>(
                context: context,
                delegate: _TaskSearch(),
              );
              if (found != null) openDay(found);
            },
          ),
          IconButton(
            tooltip: 'Ir para hoje',
            icon: const Icon(AppIcons.goToday),
            onPressed: () => ref
                .read(calendarDayProvider.notifier)
                .show(ref.read(todayProvider)),
          ),
          PopupMenuButton<String>(
            tooltip: 'Visualização',
            icon: Icon(switch (mode) {
              CalendarMode.dia => AppIcons.viewDay,
              CalendarMode.semana => AppIcons.viewWeek,
              CalendarMode.mes => AppIcons.viewMonth,
            }),
            onSelected: (v) {
              if (v == 'pomodoros') {
                ref
                    .read(settingsRepositoryProvider)
                    .setString(
                      CalendarSettings.pomodorosKey,
                      '${!settings.showPomodoros}',
                    );
              } else {
                setMode(CalendarMode.values.byName(v));
              }
            },
            itemBuilder: (_) => [
              for (final (m, label) in [
                (CalendarMode.dia, 'Dia'),
                (CalendarMode.semana, wide ? 'Semana' : '3 dias'),
                (CalendarMode.mes, 'Mês'),
              ])
                CheckedPopupMenuItem(
                  value: m.name,
                  checked: mode == m,
                  child: Text(label),
                ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'pomodoros',
                checked: settings.showPomodoros,
                child: const Text('Pomodoros realizados'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // abas vivas no IndexedStack; ver CLAUDE.md
        tooltip: 'Nova tarefa',
        onPressed: () => context.push(Routes.newTask(date: day)),
        child: const Icon(AppIcons.add),
      ),
      bottomSheet: mode == CalendarMode.mes ? null : const _NextTaskSheet(),
      body: GestureDetector(
        // Deslizar para os lados troca de período.
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() > 300) step(v < 0 ? 1 : -1);
        },
        child: mode == CalendarMode.mes
            ? MonthView(month: day, onOpenDay: openDay)
            : TimelineView(days: days, onOpenDay: openDay),
      ),
    );
  }
}

/// "Próxima tarefa em X min", sobre a linha do tempo.
class _NextTaskSheet extends ConsumerWidget {
  const _NextTaskSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider.select((t) => t.value?.minute));
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();
    final entries =
        ref
            .watch(
              calendarEntriesProvider((from: today, to: addDays(today, 1))),
            )
            .value ??
        const <CalendarEntry>[];
    final next = nextUpcoming(entries, now);
    if (next == null) return const SizedBox.shrink();

    // Arredonda para cima: faltando 30 s, mostra "1 min".
    final minutes = (next.start.difference(now).inSeconds + 59) ~/ 60;
    final wait = minutes < 60
        ? '$minutes min'
        : '${minutes ~/ 60} h${minutes % 60 == 0 ? '' : ' ${two(minutes % 60)}'}';
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => context.push(Routes.task(next.task.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 88, 10),
          child: Row(
            children: [
              Icon(AppIcons.time, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Próxima tarefa em $wait\n'),
                      TextSpan(
                        text: '${formatTime(next.start)} · ${next.task.title}',
                        style: Theme.of(context).textTheme.bodySmall!
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Busca tarefas com data; escolher uma abre o dia dela na agenda.
class _TaskSearch extends SearchDelegate<DateTime?> {
  _TaskSearch() : super(searchFieldLabel: 'Buscar tarefa');

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Limpar',
        icon: const Icon(AppIcons.close),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Voltar',
    icon: const Icon(AppIcons.back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() => Consumer(
    builder: (context, ref, _) {
      final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
      final now = ref.watch(clockProvider)();
      final q = _fold(query.trim());
      final found =
          [
            for (final t in tasks)
              if ((t.startAt ?? t.dueAt) != null &&
                  (q.isEmpty || _fold(t.title).contains(q)))
                t,
          ]..sort(
            (a, b) => (a.startAt ?? a.dueAt)!.compareTo(b.startAt ?? b.dueAt!),
          );
      if (found.isEmpty) {
        return const Center(child: Text('Nenhuma tarefa com data encontrada.'));
      }
      return ListView(
        children: [
          for (final t in found)
            ListTile(
              title: Text(t.title),
              subtitle: Text(
                formatRelative(t.startAt ?? t.dueAt!, now, withTime: t.hasTime),
              ),
              onTap: () => close(context, t.startAt ?? t.dueAt),
            ),
        ],
      );
    },
  );
}

/// Minúsculas e sem acentos, para buscar "acao" e achar "Ação".
String _fold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}
