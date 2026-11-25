import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/providers.dart';
import '../../shared/widgets/number_stepper.dart';
import '../tasks/hub/hub_stats.dart' show formatDuration;

/// Durações prontas (minutos) para registrar com um toque.
const manualTimePresets = [15, 30, 45, 60, 90, 120];

/// Início sugerido: hoje, terminando agora; em outro dia, às 9h.
DateTime suggestedManualStart({
  required DateTime day,
  required Duration duration,
  required DateTime now,
}) => isSameDay(day, now)
    ? now.subtract(duration)
    : DateTime(day.year, day.month, day.day, 9);

/// Folha para registrar à mão um tempo de foco já feito na tarefa [taskId].
Future<void> showManualTimeSheet(BuildContext context, {String? taskId}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ManualTimeSheet(taskId: taskId),
    );

class _ManualTimeSheet extends ConsumerStatefulWidget {
  const _ManualTimeSheet({required this.taskId});

  final String? taskId;

  @override
  ConsumerState<_ManualTimeSheet> createState() => _ManualTimeSheetState();
}

class _ManualTimeSheetState extends ConsumerState<_ManualTimeSheet> {
  int _hours = 0;
  int _minutes = 30;
  late DateTime _day = startOfDay(ref.read(clockProvider)());

  /// `null` = início sugerido ([suggestedManualStart]).
  TimeOfDay? _start;
  bool _saving = false;

  Duration get _duration => Duration(hours: _hours, minutes: _minutes);

  DateTime get _startAt {
    if (_start case final t?) {
      return DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);
    }
    return suggestedManualStart(
      day: _day,
      duration: _duration,
      now: ref.read(clockProvider)(),
    );
  }

  Future<void> _pickDay() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _day = startOfDay(picked));
  }

  Future<void> _pickStart() async {
    final current = _startAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _save() async {
    if (_duration == Duration.zero || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await ref
        .read(pomodoroRepositoryProvider)
        .logManualFocus(
          taskId: widget.taskId,
          startedAt: _startAt,
          duration: _duration,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.manualTimeSaved(formatDuration(_duration))),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.lang;
    final space = context.space;
    final now = ref.watch(clockProvider)();
    final total = _hours * 60 + _minutes;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          space.page,
          0,
          space.page,
          space.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.manualTimeTitle, style: context.text.titleMedium),
            SizedBox(height: space.xs),
            Text(
              l10n.manualTimeHint,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: space.md),
            Wrap(
              spacing: space.sm,
              runSpacing: space.xs,
              children: [
                for (final m in manualTimePresets)
                  ChoiceChip(
                    label: Text(formatDuration(Duration(minutes: m))),
                    selected: total == m,
                    onSelected: (_) => setState(() {
                      _hours = m ~/ 60;
                      _minutes = m % 60;
                    }),
                  ),
              ],
            ),
            SizedBox(height: space.md),
            Row(
              children: [
                Expanded(child: Text(l10n.manualTimeHours)),
                NumberStepper(
                  value: _hours,
                  min: 0,
                  max: 23,
                  onChanged: (v) => setState(() => _hours = v),
                  semanticLabel: l10n.manualTimeHours,
                ),
              ],
            ),
            SizedBox(height: space.sm),
            Row(
              children: [
                Expanded(child: Text(l10n.manualTimeMinutes)),
                NumberStepper(
                  value: _minutes,
                  min: 0,
                  max: 59,
                  onChanged: (v) => setState(() => _minutes = v),
                  semanticLabel: l10n.manualTimeMinutes,
                ),
              ],
            ),
            SizedBox(height: space.md),
            Wrap(
              spacing: space.sm,
              runSpacing: space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(AppIcons.date, size: AppIconSize.meta),
                  label: Text(
                    '${l10n.manualTimeDay}: '
                    '${formatRelative(_day, now, lang: lang)}',
                  ),
                  onPressed: _pickDay,
                ),
                OutlinedButton.icon(
                  icon: const Icon(AppIcons.time, size: AppIconSize.meta),
                  label: Text(
                    '${l10n.manualTimeStart} ${formatTime(_startAt)}',
                  ),
                  onPressed: _pickStart,
                ),
              ],
            ),
            SizedBox(height: space.lg),
            FilledButton(
              onPressed: total == 0 || _saving ? null : _save,
              child: Text(l10n.manualTimeLog),
            ),
          ],
        ),
      ),
    );
  }
}
