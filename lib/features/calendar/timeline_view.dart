import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/router.dart';
import '../../core/calendar_layout.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../tasks/task_providers.dart';
import 'calendar_entries.dart';
import 'calendar_providers.dart';

const _gutter = 48.0; // coluna das horas
const _minHourHeight = 24.0;
const _maxHourHeight = 160.0;
const _resizeZone = 16.0; // faixa no pé do bloco que redimensiona
const _pomodoroLane = 7.0; // faixa da camada de pomodoros

/// Altura de uma hora na linha do tempo (zoom), compartilhada por Dia e
/// Semana enquanto o app estiver aberto.
final hourHeightProvider = NotifierProvider<HourHeightNotifier, double>(
  HourHeightNotifier.new,
);

class HourHeightNotifier extends Notifier<double> {
  @override
  double build() => 56;

  void set(double v) => state = v.clamp(_minHourHeight, _maxHourHeight);
}

/// Visões Dia e Semana: cabeçalho dos dias, faixa de dia inteiro e a linha
/// do tempo com os blocos.
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({required this.days, this.onOpenDay, super.key});

  /// Dias consecutivos mostrados (1, 3 ou 7).
  final List<DateTime> days;

  /// Toque no cabeçalho de um dia (abre a visão Dia).
  final ValueChanged<DateTime>? onOpenDay;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

enum _DragMode { move, resize }

class _Drag {
  _Drag(this.entry, this.mode);

  final CalendarEntry entry;
  final _DragMode mode;
  Offset offset = Offset.zero;
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late final ScrollController _scroll;
  bool _allDayExpanded = false;
  _Drag? _drag;

  // Pinça: ponteiros na tela e o estado no início do gesto.
  final _pointers = <int, Offset>{};
  double? _pinchStartDistance;
  double _pinchStartHeight = 0;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final hour = ref.read(hourHeightProvider);
    // Começa perto de agora, com uma hora de folga acima.
    _scroll = ScrollController(
      initialScrollOffset: math.max(0, now.hour - 1) * hour,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  DateRange get _range =>
      (from: widget.days.first, to: addDays(widget.days.last, 1));

  // ─── Pinça ────────────────────────────────────────────────────────────────

  void _pointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _pinchStartDistance = _distance();
      _pinchStartHeight = ref.read(hourHeightProvider);
      setState(() {}); // trava a rolagem durante a pinça
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStartDistance;
    if (start == null || _pointers.length != 2 || start == 0) return;
    final old = ref.read(hourHeightProvider);
    ref
        .read(hourHeightProvider.notifier)
        .set(_pinchStartHeight * _distance() / start);
    final now = ref.read(hourHeightProvider);
    if (_scroll.hasClients && now != old) {
      // Mantém o mesmo horário no topo da tela.
      _scroll.jumpTo(
        (_scroll.offset * now / old).clamp(0, double.infinity).toDouble(),
      );
    }
  }

  void _pointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _pinchStartDistance != null) {
      setState(() => _pinchStartDistance = null);
    }
  }

  double _distance() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }

  // ─── Arrastar ─────────────────────────────────────────────────────────────

  void _startDrag(CalendarEntry entry, _DragMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _drag = _Drag(entry, mode));
  }

  void _updateDrag(Offset offset) => setState(() => _drag?.offset = offset);

  /// Onde o bloco arrastado vai parar (minutos em passos de 15).
  ({DateTime start, DateTime end}) _dropTarget(
    _Drag drag,
    double hourHeight,
    double dayWidth,
  ) {
    final minutes = roundToStep(drag.offset.dy / hourHeight * 60);
    final entry = drag.entry;
    if (drag.mode == _DragMode.resize) {
      var end = entry.end.add(Duration(minutes: minutes));
      final min = entry.start.add(minBlockDuration);
      if (end.isBefore(min)) end = min;
      return (start: entry.start, end: end);
    }
    final dayShift = widget.days.length == 1
        ? 0
        : (drag.offset.dx / dayWidth).round();
    final start = addDays(
      entry.start,
      dayShift,
    ).add(Duration(minutes: minutes));
    return (start: start, end: start.add(entry.end.difference(entry.start)));
  }

  Future<void> _endDrag(double hourHeight, double dayWidth) async {
    final drag = _drag;
    if (drag == null) return;
    final target = _dropTarget(drag, hourHeight, dayWidth);
    setState(() => _drag = null);
    final entry = drag.entry;
    if (target.start == entry.start && target.end == entry.end) return;
    final times = drag.mode == _DragMode.move
        ? moveEntry(entry, target.start)
        : resizeEntry(entry, target.end);
    await ref
        .read(tasksRepositoryProvider)
        .rescheduleTask(
          entry.task.id,
          startAt: times.startAt,
          dueAt: times.dueAt,
        );
    if (!mounted || !entry.isRoutine) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Rotina reagendada (todas as ocorrências).'),
        ),
      );
  }

  // ─── Construção ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(calendarEntriesProvider(_range));
    final settings =
        ref.watch(calendarSettingsProvider).value ?? const CalendarSettings();
    final sessions = settings.showPomodoros
        ? ref.watch(focusSessionsProvider(_range)).value ?? const []
        : const <PomodoroSession>[];
    final tagColors = ref.watch(tagColorByTaskProvider);
    final hourHeight = ref.watch(hourHeightProvider);
    final today = ref.watch(todayProvider);
    final list = entries.value ?? const <CalendarEntry>[];

    return Column(
      children: [
        _DaysHeader(
          days: widget.days,
          today: today,
          onOpenDay: widget.onOpenDay,
        ),
        _AllDayStrip(
          days: widget.days,
          entries: list,
          tagColors: tagColors,
          expanded: _allDayExpanded,
          onToggle: () => setState(() => _allDayExpanded = !_allDayExpanded),
        ),
        const Divider(height: 1),
        Expanded(
          child: Listener(
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: _pinchStartDistance != null || _drag != null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              // Folga no fim para o aviso de próxima tarefa e o botão +.
              padding: const EdgeInsets.only(bottom: 80),
              child: SizedBox(
                width: double.infinity,
                height: 24 * hourHeight,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final dayWidth =
                        (box.maxWidth - _gutter) / widget.days.length;
                    return _buildGrid(
                      context,
                      list,
                      sessions,
                      tagColors,
                      hourHeight,
                      dayWidth,
                      settings.showPomodoros,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<CalendarEntry> entries,
    List<PomodoroSession> sessions,
    Map<String, int> tagColors,
    double hourHeight,
    double dayWidth,
    bool pomodoroLayer,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final lane = pomodoroLayer ? _pomodoroLane + 2 : 0.0;
    final children = <Widget>[];
    final drag = _drag;

    for (final (i, day) in widget.days.indexed) {
      final timed = entriesOfDay(entries, day).timed;
      final dayEnd = addDays(day, 1);
      final spans = [
        for (final e in timed)
          (
            start: e.start.isBefore(day) ? day : e.start,
            end: e.end.isAfter(dayEnd) ? dayEnd : e.end,
          ),
      ];
      final slots = layoutOverlaps(spans);
      final usable = dayWidth - lane - 2;
      for (final (j, e) in timed.indexed) {
        final top = minutesFrom(day, spans[j].start) * hourHeight / 60;
        final height = math.max(
          minutesFrom(day, spans[j].end) * hourHeight / 60 - top,
          hourHeight / 4,
        );
        final width = usable / slots[j].columns;
        final dragging =
            drag?.entry.key == e.key && drag?.entry.start == e.start;
        children.add(
          Positioned(
            key: ValueKey('bloco-${e.key}-${day.day}'),
            left: _gutter + i * dayWidth + slots[j].column * width + 1,
            top: top,
            width: width - 2,
            height: height - 1,
            child: Opacity(
              opacity: dragging ? 0.35 : 1,
              child: _Block(
                entry: e,
                color: entryColor(e.task, tagColors),
                hourHeight: hourHeight,
                onTap: () => context.push(Routes.task(e.task.id)),
                onDragStart: e.movable ? (mode) => _startDrag(e, mode) : null,
                onDragUpdate: _updateDrag,
                onDragEnd: () => _endDrag(hourHeight, dayWidth),
              ),
            ),
          ),
        );
      }

      if (pomodoroLayer) {
        final now = ref.read(clockProvider)();
        for (final s in sessions) {
          final end = s.endedAt ?? now;
          if (!s.startedAt.isBefore(dayEnd) || !end.isAfter(day)) continue;
          final from = s.startedAt.isBefore(day) ? day : s.startedAt;
          final to = end.isAfter(dayEnd) ? dayEnd : end;
          final top = minutesFrom(day, from) * hourHeight / 60;
          children.add(
            Positioned(
              left: _gutter + (i + 1) * dayWidth - _pomodoroLane - 1,
              top: top,
              width: _pomodoroLane,
              height: math.max(minutesFrom(day, to) * hourHeight / 60 - top, 3),
              child: Tooltip(
                message: 'Foco ${formatTime(s.startedAt)}–${formatTime(to)}',
                child: CustomPaint(painter: _HatchPainter(scheme.tertiary)),
              ),
            ),
          );
        }
      }
    }

    // Prévia do bloco arrastado.
    if (drag != null) {
      final target = _dropTarget(drag, hourHeight, dayWidth);
      final dayIndex = widget.days.indexWhere(
        (d) => isSameDay(d, target.start),
      );
      if (dayIndex >= 0) {
        final day = widget.days[dayIndex];
        final top = minutesFrom(day, target.start) * hourHeight / 60;
        final bottom = minutesFrom(day, target.end) * hourHeight / 60;
        children.add(
          Positioned(
            left: _gutter + dayIndex * dayWidth + 1,
            top: top,
            width: dayWidth - lane - 3,
            height: math.max(bottom - top, hourHeight / 4),
            child: IgnorePointer(
              child: _Block(
                entry: drag.entry,
                color: entryColor(drag.entry.task, tagColors),
                hourHeight: hourHeight,
                timeOverride: target,
                elevated: true,
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // Fundo: grade de horas; toque longo cria tarefa naquele horário.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (d) {
              final i = ((d.localPosition.dx - _gutter) / dayWidth).floor();
              if (i < 0 || i >= widget.days.length) return;
              final minutes = floorToStep(
                (d.localPosition.dy / hourHeight * 60).floor(),
              ).clamp(0, 24 * 60 - 15);
              HapticFeedback.selectionClick();
              context.push(
                Routes.newTask(
                  at: widget.days[i].add(Duration(minutes: minutes)),
                ),
              );
            },
            child: CustomPaint(
              painter: _GridPainter(
                hourHeight: hourHeight,
                days: widget.days.length,
                lineColor: scheme.outlineVariant.withValues(alpha: 0.6),
                labelStyle: Theme.of(context).textTheme.labelSmall!
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        ...children,
        _NowLine(days: widget.days, hourHeight: hourHeight, dayWidth: dayWidth),
      ],
    );
  }
}

/// Bloco de uma tarefa: fundo claro, barra colorida à esquerda e título na
/// cor da barra.
class _Block extends StatelessWidget {
  const _Block({
    required this.entry,
    required this.color,
    required this.hourHeight,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.timeOverride,
    this.elevated = false,
  });

  final CalendarEntry entry;
  final Color color;
  final double hourHeight;
  final VoidCallback? onTap;
  final void Function(_DragMode mode)? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final ({DateTime start, DateTime end})? timeOverride;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = entryTextColor(color, scheme.brightness);
    final start = timeOverride?.start ?? entry.start;
    final end = timeOverride?.end ?? entry.end;
    final done = entry.done;
    final titleStyle = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: text,
      fontWeight: FontWeight.w600,
      decoration: done ? TextDecoration.lineThrough : null,
      decorationColor: text,
    );

    final block = LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxHeight >= 34;
        return Material(
          color: entryBackground(color, scheme),
          elevation: elevated ? 4 : 0,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(4, 1, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (entry.isRoutine)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(Icons.repeat, size: 11, color: text),
                      ),
                    Expanded(
                      child: Text(
                        entry.task.title,
                        maxLines: roomy ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
                if (roomy)
                  Text(
                    '${formatTime(start)}–${formatTime(end)}',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall!
                        .copyWith(color: text.withValues(alpha: 0.85)),
                  ),
              ],
            ),
          ),
        );
      },
    );

    final content = Semantics(
      button: true,
      label:
          '${entry.task.title}, ${formatTime(start)} a ${formatTime(end)}'
          '${done ? ', concluída' : ''}',
      excludeSemantics: true,
      child: Opacity(opacity: done ? 0.55 : 1, child: block),
    );
    if (onTap == null) return content;

    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        onTap: onTap,
        onLongPressStart: onDragStart == null
            ? null
            : (d) => onDragStart!(
                box.maxHeight >= 2 * _resizeZone &&
                        d.localPosition.dy > box.maxHeight - _resizeZone
                    ? _DragMode.resize
                    : _DragMode.move,
              ),
        onLongPressMoveUpdate: onDragStart == null
            ? null
            : (d) => onDragUpdate?.call(d.offsetFromOrigin),
        onLongPressEnd: onDragStart == null ? null : (_) => onDragEnd?.call(),
        onLongPressCancel: onDragStart == null ? null : onDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            // Alça visual do redimensionamento.
            if (onDragStart != null && box.maxHeight >= 2 * _resizeZone)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 16,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho com dia da semana e número; hoje em destaque.
class _DaysHeader extends StatelessWidget {
  const _DaysHeader({required this.days, required this.today, this.onOpenDay});

  final List<DateTime> days;
  final DateTime today;
  final ValueChanged<DateTime>? onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: _gutter),
          for (final day in days)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onOpenDay == null || days.length == 1
                    ? null
                    : () => onOpenDay!(day),
                child: Column(
                  children: [
                    Text(
                      weekdayShort[day.weekday - 1],
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: isSameDay(day, today)
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: isSameDay(day, today)
                          ? BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: isSameDay(day, today)
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Faixa de tarefas de dia inteiro, recolhível quando passa de 2 por dia.
class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip({
    required this.days,
    required this.entries,
    required this.tagColors,
    required this.expanded,
    required this.onToggle,
  });

  static const _collapsed = 2;

  final List<DateTime> days;
  final List<CalendarEntry> entries;
  final Map<String, int> tagColors;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final perDay = [for (final d in days) entriesOfDay(entries, d).allDay];
    if (perDay.every((l) => l.isEmpty)) return const SizedBox.shrink();
    final canToggle = perDay.any((l) => l.length > _collapsed);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _gutter,
            child: canToggle
                ? IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    tooltip: expanded
                        ? 'Recolher dia inteiro'
                        : 'Expandir dia inteiro',
                    onPressed: onToggle,
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'dia\ninteiro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
          ),
          for (final list in perDay)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in expanded ? list : list.take(_collapsed))
                      EntryChip(entry: e, color: entryColor(e.task, tagColors)),
                    if (!expanded && list.length > _collapsed)
                      InkWell(
                        onTap: onToggle,
                        child: Text(
                          '+${list.length - _collapsed}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Item compacto (dia inteiro e visão Mês). [dense] usa altura fixa de
/// [EntryChip.denseHeight] (grade do mês).
class EntryChip extends StatelessWidget {
  const EntryChip({
    required this.entry,
    required this.color,
    this.dense = false,
    super.key,
  });

  static const denseHeight = 16.0;

  final CalendarEntry entry;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = entryTextColor(color, scheme.brightness);
    final chip = Material(
      color: entryBackground(color, scheme),
      borderRadius: BorderRadius.circular(3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dense ? null : () => context.push(Routes.task(entry.task.id)),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 3, vertical: dense ? 0 : 1),
          child: Text(
            entry.task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 10 : null,
              height: dense ? 1.2 : null,
              decoration: entry.done ? TextDecoration.lineThrough : null,
              decorationColor: text,
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Opacity(
        opacity: entry.done ? 0.55 : 1,
        child: dense ? SizedBox(height: denseHeight - 2, child: chip) : chip,
      ),
    );
  }
}

/// Linha da hora atual, redesenhada a cada minuto.
class _NowLine extends ConsumerWidget {
  const _NowLine({
    required this.days,
    required this.hourHeight,
    required this.dayWidth,
  });

  final List<DateTime> days;
  final double hourHeight;
  final double dayWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider.select((t) => t.value?.minute));
    final now = ref.watch(clockProvider)();
    final i = days.indexWhere((d) => isSameDay(d, now));
    // Sempre posicionado: um filho solto faria o Stack medir 0 de largura.
    if (i < 0) return const Positioned(left: 0, top: 0, child: SizedBox());
    final color = Theme.of(context).colorScheme.error;
    final top = minutesFrom(days[i], now) * hourHeight / 60;
    return Positioned(
      left: _gutter + i * dayWidth - 4,
      width: dayWidth + 4,
      top: top - 4,
      height: 8,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(child: Container(height: 2, color: color)),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.hourHeight,
    required this.days,
    required this.lineColor,
    required this.labelStyle,
  });

  final double hourHeight;
  final int days;
  final Color lineColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final dayWidth = (size.width - _gutter) / days;
    for (var h = 0; h < 24; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(_gutter, y), Offset(size.width, y), line);
      if (h == 0) continue;
      final label = TextPainter(
        text: TextSpan(text: '${two(h)}:00', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(_gutter - label.width - 6, y - label.height / 2),
      );
    }
    for (var i = 0; i <= days; i++) {
      final x = _gutter + i * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.hourHeight != hourHeight ||
      old.days != days ||
      old.lineColor != lineColor ||
      old.labelStyle != labelStyle;
}

/// Hachura diagonal das sessões de foco.
class _HatchPainter extends CustomPainter {
  _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.15));
    canvas.save();
    canvas.clipRect(rect);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    for (var y = -size.width; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y + size.width), Offset(size.width, y), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}
