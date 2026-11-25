import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/appearance_picker.dart';
import '../../shared/widgets/number_stepper.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tag_chip.dart';
import '../../shared/widgets/text_input_dialog.dart';
import '../books/books_providers.dart';
import '../cards/card_form_sheet.dart' show decksProvider;
import 'alarm_diagnostics.dart';
import 'alarms.dart';
import 'reminder_offsets.dart';
import 'task_appearance.dart';
import 'task_draft.dart';
import 'task_labels.dart';
import 'task_providers.dart';

/// Criar ou editar uma tarefa. Com [taskId], edita; com [parentId], cria
/// uma subtarefa.
class TaskFormPage extends ConsumerStatefulWidget {
  const TaskFormPage({
    this.taskId,
    this.parentId,
    this.dueToday = false,
    this.date,
    this.startAt,
    this.initialTitle,
    this.initialDraft,
    super.key,
  });

  final String? taskId;
  final String? parentId;

  /// Nova tarefa já com prazo hoje (atalho da aba Hoje).
  final bool dueToday;

  /// Nova tarefa de dia inteiro com prazo neste dia (agenda).
  final DateTime? date;

  /// Nova tarefa com hora: começa aqui e termina 1 h depois (toque longo na
  /// agenda).
  final DateTime? startAt;

  /// Título já digitado (link com `titulo`).
  final String? initialTitle;

  /// O que já foi escolhido na adição rápida ("Mais opções").
  final TaskDraft? initialDraft;

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TaskDraft? _draft;
  Task? _original;
  bool _saving = false;
  bool _canUseFullScreenIntent = true;

  bool get _editing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else if (widget.initialDraft case final draft?) {
      _draft = draft;
      _title.text = draft.title;
    } else {
      _title.text = widget.initialTitle ?? '';
      final start = widget.startAt;
      final end = start?.add(const Duration(hours: 1));
      _draft = start != null && end != null
          ? TaskDraft(
              allDay: false,
              startDate: startOfDay(start),
              startTime: (hour: start.hour, minute: start.minute),
              dueDate: startOfDay(end),
              dueTime: (hour: end.hour, minute: end.minute),
            )
          : TaskDraft(
              dueDate: widget.dueToday
                  ? ref.read(todayProvider)
                  : widget.date == null
                  ? null
                  : startOfDay(widget.date!),
            );
    }
  }

  Future<void> _load() async {
    final repo = ref.read(tasksRepositoryProvider);
    final task = await repo.getTask(widget.taskId!);
    final tags = await repo.watchTagsOfTask(widget.taskId!).first;
    final books = await ref
        .read(booksRepositoryProvider)
        .watchLinkedNotebooks(widget.taskId!)
        .first;
    final decks = await ref
        .read(cardsRepositoryProvider)
        .watchLinkedDecks(widget.taskId!)
        .first;
    if (!mounted) return;
    if (task == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _original = task;
      _draft = TaskDraft.fromTask(
        task,
        {for (final t in tags) t.id},
        notebookIds: {for (final b in books) b.id},
        deckIds: {for (final d in decks) d.id},
      );
      _title.text = task.title;
      _notes.text = task.notes ?? '';
    });
    if (task.reminderMode == ReminderMode.alarme) {
      await _refreshFullScreenIntent();
    }
  }

  Future<void> _refreshFullScreenIntent() async {
    final granted = await ref
        .read(alarmSchedulerProvider)
        .canUseFullScreenIntent();
    if (mounted) setState(() => _canUseFullScreenIntent = granted);
  }

  Future<void> _requestFullScreenIntent() async {
    final granted = await ref
        .read(alarmSchedulerProvider)
        .requestFullScreenIntentPermission();
    if (mounted) setState(() => _canUseFullScreenIntent = granted);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _edit(void Function(TaskDraft d) change) =>
      setState(() => change(_draft!));

  Future<void> _save() async {
    final draft = _draft!
      ..title = _title.text
      ..notes = _notes.text;
    final now = ref.read(todayProvider);
    final error = draft.validate(now);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(tasksRepositoryProvider);
    final f = draft.toFields(now);
    final String id;
    if (_original case final original?) {
      id = original.id;
      await repo.saveTask(f.applyTo(original));
    } else {
      id = await repo.createTask(
        title: f.title,
        parentId: widget.parentId,
        kind: f.kind,
        notes: f.notes,
        priority: f.priority,
        startAt: f.startAt,
        dueAt: f.dueAt,
        hasTime: f.hasTime,
        recurrenceRule: f.recurrenceRule,
        reminderMinutesBefore: f.reminderMinutesBefore,
        reminderOffsets: f.reminderOffsets,
        reminderMode: f.reminderMode,
        nagIntervalMinutes: f.nagIntervalMinutes,
        estimatedPomodoros: f.estimatedPomodoros,
        colorKey: f.colorKey,
        iconKey: f.iconKey,
      );
    }
    await repo.setTaskTags(id, draft.tagIds);
    await ref
        .read(booksRepositoryProvider)
        .setTaskNotebooks(id, draft.notebookIds);
    await ref.read(cardsRepositoryProvider).setTaskDecks(id, draft.deckIds);
    if (f.reminderMinutesBefore != null || f.reminderOffsets != null) {
      // Android 13+ e iOS pedem permissão para notificar; pergunta na hora em
      // que o primeiro lembrete é criado.
      await ref.read(alarmSchedulerProvider).requestPermission();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = _draft;
    final title = _editing
        ? l10n.tasksEdit
        : widget.parentId != null
        ? l10n.tasksNewSubtask
        : l10n.tasksNew;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.actionCancel,
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.formInfoTooltip,
            icon: const Icon(AppIcons.info),
            onPressed: () => _showInfo(context),
          ),
          TextButton(
            onPressed: draft == null || _saving ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
      body: draft == null ? const SkeletonPage() : _buildForm(context, draft),
    );
  }

  /// Um só "i" na barra: explica para que serve cada campo do formulário.
  void _showInfo(BuildContext context) {
    _dropFocus();
    final l10n = context.l10n;
    final sections = [
      (l10n.formInfoDatesTitle, l10n.datesHint),
      (
        l10n.formInfoRepeatTitle,
        '${l10n.repeatDatesHint} ${l10n.repeatTimeHint}',
      ),
      (l10n.formInfoRemindersTitle, l10n.formInfoReminders),
      (
        l10n.formInfoModesTitle,
        '${l10n.reminderModeNotification}: '
            '${l10n.reminderModeNotificationHint}\n'
            '${l10n.reminderModeAlarm}: ${l10n.reminderModeAlarmHint}',
      ),
      (l10n.formInfoNagTitle, l10n.nagHint(maxNagRepeats)),
      (l10n.formInfoStudyTitle, l10n.studyHint),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            context.space.page,
            0,
            context.space.page,
            context.space.xxl,
          ),
          children: [
            Text(l10n.formInfoTooltip, style: context.text.titleMedium),
            for (final (title, body) in sections) ...[
              _Label(title),
              Text(body, style: context.text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, TaskDraft d) {
    final l10n = context.l10n;
    final space = context.space;
    final hasDate =
        d.dueDate != null || (!d.allDay && d.startDate != null) || d.repeats;
    return ListView(
      padding: EdgeInsets.fromLTRB(space.page, space.sm, space.page, space.xxl),
      children: [
        _AppearanceField(
          draft: d,
          parentId: _original?.parentId ?? widget.parentId,
          onChanged: (c) => _edit((d) {
            d.colorKey = c.colorKey;
            d.iconKey = c.iconKey;
          }),
        ),
        SizedBox(height: space.sm),
        TextField(
          controller: _title,
          autofocus: !_editing,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.fieldTitle),
        ),
        SizedBox(height: space.md),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.fieldNotes),
        ),
        _Section(l10n.fieldWhen),
        ..._whenFields(context, d),
        _Section(l10n.fieldReminders),
        if (!hasDate)
          _Hint(l10n.remindersNeedDate)
        else
          ..._reminderFields(context, d),
        _Section(l10n.fieldStudy),
        _LinkedStudy(
          notebookIds: d.notebookIds,
          deckIds: d.deckIds,
          onBooks: (ids) => _edit((d) => d.notebookIds = ids),
          onDecks: (ids) => _edit((d) => d.deckIds = ids),
        ),
        _Section(l10n.fieldDetails),
        _Label(l10n.fieldPriority, first: true),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var p = 0; p < priorityLabels.length; p++)
              ButtonSegment(value: p, label: Text(priorityLabel(p, l10n))),
          ],
          selected: {d.priority},
          onSelectionChanged: (s) => _edit((d) => d.priority = s.single),
        ),
        _Label(l10n.fieldEstimatedPomodoros),
        NumberStepper(
          value: d.estimatedPomodoros ?? 0,
          min: 0,
          onChanged: (v) =>
              _edit((d) => d.estimatedPomodoros = v == 0 ? null : v),
          semanticLabel: l10n.fieldEstimatedPomodoros,
        ),
        _Label(l10n.fieldTags),
        _TagPicker(
          selected: d.tagIds,
          onChanged: (ids) => _edit((d) => d.tagIds = ids),
        ),
      ],
    );
  }

  /// Repetição primeiro, porque ela muda o sentido das datas: sem repetir há
  /// início e prazo; repetindo há só "Começa" (a 1ª vez), o horário de cada
  /// repetição e "Termina".
  List<Widget> _whenFields(BuildContext context, TaskDraft d) {
    final l10n = context.l10n;
    return [
      _Label(l10n.fieldRepeat, first: true),
      SegmentedButton<Repeat>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: Repeat.nenhuma, label: Text(l10n.repeatNo)),
          ButtonSegment(value: Repeat.diaria, label: Text(l10n.repeatDaily)),
          ButtonSegment(value: Repeat.semanal, label: Text(l10n.repeatWeekly)),
        ],
        selected: {d.repeat},
        onSelectionChanged: (s) => _edit((d) => d.repeat = s.single),
      ),
      SizedBox(height: context.space.xs),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.fieldAllDay),
        value: d.allDay,
        onChanged: (v) => _edit((d) => d.setAllDay(v)),
      ),
      if (!d.repeats) ...[
        _DateTimeRow(
          label: l10n.fieldStart,
          date: d.startDate,
          time: d.startTime,
          allDay: d.allDay,
          onDate: (v) => _edit((d) => d.startDate = v),
          onTime: (v) => _edit((d) => d.startTime = v),
        ),
        _DateTimeRow(
          label: l10n.fieldDue,
          date: d.dueDate,
          time: d.dueTime,
          allDay: d.allDay,
          onDate: (v) => _edit((d) => d.dueDate = v),
          onTime: (v) => _edit((d) => d.dueTime = v),
        ),
      ] else ...[
        _DateTimeRow(
          label: l10n.repeatStarts,
          date: d.dueDate,
          allDay: true,
          placeholder: l10n.quickDateToday,
          onDate: (v) => _edit((d) => d.dueDate = v),
        ),
        if (!d.allDay)
          _TimeRangeRow(
            label: l10n.fieldTimeRange,
            start: d.startTime,
            end: d.dueTime,
            onStart: (v) => _edit((d) => d.startTime = v),
            onEnd: (v) => _edit((d) => d.dueTime = v),
          ),
        ..._repeatFields(context, d),
      ],
    ];
  }

  List<Widget> _repeatFields(BuildContext context, TaskDraft d) {
    final l10n = context.l10n;
    final lang = context.lang;
    final space = context.space;
    final weekdays = weekdaysShortFor(lang);
    final weekly = d.repeat == Repeat.semanal;
    return [
      SizedBox(height: space.sm),
      Row(
        children: [
          SizedBox(width: _rowLabelWidth, child: Text(l10n.repeatEvery)),
          NumberStepper(
            value: d.interval,
            min: 1,
            onChanged: (v) => _edit((d) => d.interval = v),
            semanticLabel: l10n.repeatIntervalSemantics,
          ),
          SizedBox(width: space.sm),
          Text(
            weekly
                ? (d.interval == 1 ? l10n.unitWeek : l10n.unitWeeks)
                : (d.interval == 1 ? l10n.unitDay : l10n.unitDays),
          ),
        ],
      ),
      if (weekly) ...[
        SizedBox(height: space.sm),
        Wrap(
          spacing: space.xs,
          runSpacing: space.xs,
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              FilterChip(
                label: Text(weekdays[day - 1]),
                selected: d.weekdays.contains(day),
                onSelected: (on) => _edit(
                  (d) => on ? d.weekdays.add(day) : d.weekdays.remove(day),
                ),
              ),
          ],
        ),
      ],
      SizedBox(height: space.sm),
      _DateTimeRow(
        label: l10n.repeatEnds,
        date: d.until,
        allDay: true,
        placeholder: l10n.repeatNever,
        onDate: (v) => _edit((d) => d.until = v),
      ),
      SizedBox(height: space.xs),
      Text(
        d.recurrence!.describe(lang: lang),
        style: context.text.bodySmall!.copyWith(color: context.colors.primary),
      ),
    ];
  }

  List<Widget> _reminderFields(BuildContext context, TaskDraft d) {
    final l10n = context.l10n;
    final lang = context.lang;
    final space = context.space;
    final hour =
        ref.watch(allDayReminderHourProvider).value ?? allDayReminderHour;
    final fields = d.toFields(ref.read(todayProvider));
    final times = draftReminderTimes(fields, allDayHour: hour);
    final now = ref.read(clockProvider)();
    final base = d.allDay
        ? l10n.remindersBaseAllDay(hour)
        : fields.startAt != null
        ? l10n.remindersBaseStart
        : l10n.remindersBaseDue;
    final hasReminders = d.reminderOffsets.isNotEmpty;
    final diagnostics =
        ref.watch(alarmDiagnosticsProvider).value ?? AlarmDiagnostics.allGood;
    final preview = times
        .map((t) => formatRelative(t, now, withTime: true, lang: lang))
        .join(' · ');
    return [
      Wrap(
        spacing: space.sm,
        runSpacing: space.xs,
        children: [
          for (final minutes in reminderChoicesFor(
            allDay: d.allDay,
            selected: d.reminderOffsets,
          ))
            FilterChip(
              label: Text(
                reminderOffsetLabel(
                  minutes,
                  l10n,
                  allDay: d.allDay,
                  allDayHour: hour,
                ),
              ),
              selected: d.reminderOffsets.contains(minutes),
              onSelected: (on) => _edit((d) {
                if (on) {
                  d.reminderOffsets.add(minutes);
                } else {
                  d.reminderOffsets.remove(minutes);
                }
              }),
            ),
        ],
      ),
      _Hint(d.repeats ? '$base ${l10n.remindersEachRepeat}' : base),
      if (times.isNotEmpty)
        _Hint(
          d.repeats
              ? l10n.remindersPreviewFirst(preview)
              : l10n.remindersPreview(preview),
          highlight: true,
        ),
      if (hasReminders) ...[
        if (diagnostics.hasBlockingIssueFor(d.reminderMode)) ...[
          SizedBox(height: space.md),
          _DiagnosticsWarningBanner(
            onOpen: () async {
              await context.push(Routes.alarmDiagnostics);
              if (mounted) ref.invalidate(alarmDiagnosticsProvider);
            },
          ),
        ],
        SizedBox(height: space.md),
        SegmentedButton<ReminderMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ReminderMode.notificacao,
              icon: const Icon(AppIcons.notification),
              label: Text(ReminderMode.notificacao.labelFor(l10n)),
            ),
            ButtonSegment(
              value: ReminderMode.alarme,
              icon: const Icon(AppIcons.alarm),
              label: Text(ReminderMode.alarme.labelFor(l10n)),
            ),
          ],
          selected: {d.reminderMode},
          onSelectionChanged: (s) {
            final mode = s.single;
            _edit((d) => d.reminderMode = mode);
            if (mode == ReminderMode.alarme) _refreshFullScreenIntent();
          },
        ),
        _Hint(
          d.reminderMode == ReminderMode.alarme
              ? l10n.reminderModeAlarmHint
              : l10n.reminderModeNotificationHint,
        ),
        if (d.reminderMode == ReminderMode.alarme &&
            !_canUseFullScreenIntent) ...[
          SizedBox(height: space.sm),
          _FullScreenPermissionBanner(onAllow: _requestFullScreenIntent),
        ],
        _Label(l10n.fieldNagIfOverdue),
        Wrap(
          spacing: space.sm,
          runSpacing: space.xs,
          children: [
            for (final minutes in nagIntervalChoices)
              ChoiceChip(
                label: Text(
                  minutes == null ? l10n.nagOff : l10n.nagEveryMinutes(minutes),
                ),
                selected: d.nagIntervalMinutes == minutes,
                onSelected: (_) => _edit((d) => d.nagIntervalMinutes = minutes),
              ),
          ],
        ),
        if (d.nagIntervalMinutes != null) _Hint(l10n.nagHint(maxNagRepeats)),
      ],
    ];
  }
}

/// Largura do rótulo à esquerda das linhas de data e hora.
const double _rowLabelWidth = 72;

/// Título de um grupo do formulário (Quando, Lembretes, Estudo, Detalhes).
class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title,
      padding: EdgeInsets.only(
        top: context.space.xxl,
        bottom: context.space.xs,
      ),
    );
  }
}

/// Texto de apoio abaixo de um campo; [highlight] usa a cor de destaque.
class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.space.xs),
      child: Text(
        text,
        style: context.text.bodySmall!.copyWith(
          color: highlight
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.first = false});

  final String text;

  /// Primeiro campo do grupo: menos espaço acima (o título do grupo já separa).
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? context.space.sm : context.space.lg,
        bottom: context.space.sm,
      ),
      child: Text(text, style: context.text.titleSmall),
    );
  }
}

/// Horário de cada repetição: "Horário [início] – [fim]". O início é opcional.
class _TimeRangeRow extends StatelessWidget {
  const _TimeRangeRow({
    required this.label,
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
  });

  final String label;
  final ClockTime? start;
  final ClockTime? end;
  final ValueChanged<ClockTime?> onStart;
  final ValueChanged<ClockTime?> onEnd;

  Future<void> _pick(
    BuildContext context,
    ClockTime? current,
    ValueChanged<ClockTime?> onPicked,
  ) async {
    _dropFocus();
    final t = current ?? defaultTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
    );
    if (picked != null) onPicked((hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = end ?? defaultTime;
    return Row(
      children: [
        SizedBox(width: _rowLabelWidth, child: Text(label)),
        Expanded(
          child: Wrap(
            spacing: context.space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(AppIcons.time, size: AppIconSize.meta),
                label: Text(
                  start == null
                      ? l10n.timeRangeFrom
                      : '${two(start!.hour)}:${two(start!.minute)}',
                ),
                onPressed: () => _pick(context, start, onStart),
              ),
              const Text('–'),
              Semantics(
                label: l10n.timeRangeTo,
                child: OutlinedButton(
                  onPressed: () => _pick(context, end, onEnd),
                  child: Text('${two(e.hour)}:${two(e.minute)}'),
                ),
              ),
            ],
          ),
        ),
        if (start != null)
          IconButton(
            tooltip: l10n.fieldClearLabel(l10n.timeRangeFrom),
            icon: const Icon(AppIcons.close),
            onPressed: () => onStart(null),
          ),
      ],
    );
  }
}

/// Books e decks já existentes ligados à tarefa: chips para desvincular,
/// "Vincular" abre a lista e "Novo" cria na hora e já vincula.
class _LinkedStudy extends ConsumerWidget {
  const _LinkedStudy({
    required this.notebookIds,
    required this.deckIds,
    required this.onBooks,
    required this.onDecks,
  });

  final Set<String> notebookIds;
  final Set<String> deckIds;
  final ValueChanged<Set<String>> onBooks;
  final ValueChanged<Set<String>> onDecks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final books = ref.watch(booksProvider).value ?? const <Notebook>[];
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];

    Future<void> createBook() async {
      final title = await showTextInputDialog(
        context,
        title: l10n.newBook,
        label: l10n.fieldTitle,
      );
      if (title == null || title.trim().isEmpty) return;
      final id = await ref
          .read(booksRepositoryProvider)
          .createBook(title: title.trim());
      onBooks({...notebookIds, id});
    }

    Future<void> createDeck() async {
      final name = await showTextInputDialog(
        context,
        title: l10n.newDeck,
        label: l10n.reviewNameLabel,
      );
      if (name == null || name.trim().isEmpty) return;
      final id = await ref
          .read(cardsRepositoryProvider)
          .createDeck(name: name.trim());
      onDecks({...deckIds, id});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(l10n.fieldBooks),
        _LinkChips(
          items: [for (final b in books) (id: b.id, label: b.title)],
          selected: notebookIds,
          icon: AppIcons.book,
          linkLabel: l10n.linkBook,
          newLabel: l10n.newBook,
          pickerTitle: l10n.linkBooksTitle,
          emptyLabel: l10n.noBooksYet,
          onChanged: onBooks,
          onCreate: createBook,
        ),
        _Label(l10n.fieldDecks),
        _LinkChips(
          items: [for (final d in decks) (id: d.id, label: d.name)],
          selected: deckIds,
          icon: AppIcons.deck,
          linkLabel: l10n.linkDeck,
          newLabel: l10n.newDeck,
          pickerTitle: l10n.linkDecksTitle,
          emptyLabel: l10n.noDecksYet,
          onChanged: onDecks,
          onCreate: createDeck,
        ),
      ],
    );
  }
}

typedef _LinkItem = ({String id, String label});

class _LinkChips extends StatelessWidget {
  const _LinkChips({
    required this.items,
    required this.selected,
    required this.icon,
    required this.linkLabel,
    required this.newLabel,
    required this.pickerTitle,
    required this.emptyLabel,
    required this.onChanged,
    required this.onCreate,
  });

  final List<_LinkItem> items;
  final Set<String> selected;
  final IconData icon;
  final String linkLabel;
  final String newLabel;
  final String pickerTitle;
  final String emptyLabel;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onCreate;

  Future<void> _pick(BuildContext context) async {
    _dropFocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PickManySheet(
        title: pickerTitle,
        items: items,
        initial: selected,
        icon: icon,
        emptyLabel: emptyLabel,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final linked = items.where((i) => selected.contains(i.id));
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.xs,
      children: [
        for (final item in linked)
          InputChip(
            avatar: Icon(icon),
            label: Text(item.label),
            deleteIcon: const Icon(AppIcons.close, size: AppIconSize.meta),
            deleteButtonTooltipMessage: l10n.unlinkItem(item.label),
            onDeleted: () => onChanged({...selected}..remove(item.id)),
          ),
        ActionChip(
          avatar: const Icon(AppIcons.link),
          label: Text(linkLabel),
          onPressed: () => _pick(context),
        ),
        ActionChip(
          avatar: const Icon(AppIcons.add),
          label: Text(newLabel),
          onPressed: onCreate,
        ),
      ],
    );
  }
}

/// Lista com caixas de seleção; cada toque já aplica (fechar só sai).
class _PickManySheet extends StatefulWidget {
  const _PickManySheet({
    required this.title,
    required this.items,
    required this.initial,
    required this.icon,
    required this.emptyLabel,
    required this.onChanged,
  });

  final String title;
  final List<_LinkItem> items;
  final Set<String> initial;
  final IconData icon;
  final String emptyLabel;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_PickManySheet> createState() => _PickManySheetState();
}

class _PickManySheetState extends State<_PickManySheet> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.space.page,
              0,
              context.space.page,
              context.space.sm,
            ),
            child: Text(widget.title, style: context.text.titleMedium),
          ),
          if (widget.items.isEmpty)
            ListTile(
              leading: Icon(widget.icon),
              title: Text(widget.emptyLabel),
            ),
          for (final item in widget.items)
            CheckboxListTile(
              value: _selected.contains(item.id),
              secondary: Icon(widget.icon),
              title: Text(item.label),
              onChanged: (on) {
                setState(
                  () => on == true
                      ? _selected.add(item.id)
                      : _selected.remove(item.id),
                );
                widget.onChanged({..._selected});
              },
            ),
        ],
      ),
    );
  }
}

/// Linha "Rótulo: [data] [hora] [x]" com seletores do sistema.
class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.allDay,
    required this.onDate,
    this.time,
    this.onTime,
    this.placeholder,
  });

  final String label;
  final DateTime? date;
  final ClockTime? time;
  final bool allDay;
  final ValueChanged<DateTime?> onDate;
  final ValueChanged<ClockTime?>? onTime;

  /// Texto quando não há data (padrão: "Sem data").
  final String? placeholder;

  Future<void> _pickDate(BuildContext context) async {
    _dropFocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDate(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    _dropFocus();
    final current = time ?? defaultTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) onTime!((hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.lang;
    final today = DateTime.now();
    final t = time ?? defaultTime;
    return Row(
      children: [
        SizedBox(width: _rowLabelWidth, child: Text(label)),
        Expanded(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(AppIcons.date, size: 18),
                label: Text(
                  date == null
                      ? placeholder ?? l10n.fieldNoDate
                      : formatDate(date!, today, lang: lang),
                ),
                onPressed: () => _pickDate(context),
              ),
              if (!allDay && date != null && onTime != null)
                OutlinedButton.icon(
                  icon: const Icon(AppIcons.time, size: 18),
                  label: Text('${two(t.hour)}:${two(t.minute)}'),
                  onPressed: () => _pickTime(context),
                ),
            ],
          ),
        ),
        if (date != null)
          IconButton(
            tooltip: l10n.fieldClearLabel(label),
            icon: const Icon(AppIcons.close),
            onPressed: () {
              onDate(null);
              onTime?.call(null);
            },
          ),
      ],
    );
  }
}

class _TagPicker extends ConsumerWidget {
  const _TagPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  Future<void> _createTag(BuildContext context, WidgetRef ref) async {
    _dropFocus();
    final created = await showDialog<({String name, String colorKey})>(
      context: context,
      builder: (_) => const _NewTagDialog(),
    );
    if (created == null) return;
    final id = await ref
        .read(tasksRepositoryProvider)
        .createTag(name: created.name, colorKey: created.colorKey);
    onChanged({...selected, id});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).value ?? const [];
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.xs,
      children: [
        for (final tag in tags)
          TagChip(
            name: tag.name,
            colorKey: tag.colorKey,
            selected: selected.contains(tag.id),
            onSelected: (on) => onChanged(
              on ? {...selected, tag.id} : ({...selected}..remove(tag.id)),
            ),
          ),
        ActionChip(
          avatar: const Icon(AppIcons.add),
          label: Text(context.l10n.tagNew),
          onPressed: () => _createTag(context, ref),
        ),
      ],
    );
  }
}

class _NewTagDialog extends StatefulWidget {
  const _NewTagDialog();

  @override
  State<_NewTagDialog> createState() => _NewTagDialogState();
}

class _NewTagDialogState extends State<_NewTagDialog> {
  final _name = TextEditingController();
  PaletteKey _color = PaletteKey.azul;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, colorKey: _color.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return AlertDialog(
      title: Text(l10n.tagNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.reviewNameLabel),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: context.space.lg),
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.sm,
            children: [
              for (final key in PaletteKey.values)
                Semantics(
                  button: true,
                  selected: key == _color,
                  label: key.label,
                  child: InkResponse(
                    onTap: () => setState(() => _color = key),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: palette.of(key).strong,
                      child: key == _color
                          ? Icon(
                              AppIcons.check,
                              color: context.colors.surface,
                              size: AppIconSize.standard,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionCreate)),
      ],
    );
  }
}

/// Prévia do ícone e da cor; toque abre o seletor.
class _AppearanceField extends ConsumerWidget {
  const _AppearanceField({
    required this.draft,
    required this.parentId,
    required this.onChanged,
  });

  final TaskDraft draft;
  final String? parentId;
  final ValueChanged<AppearanceChoice> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(appearanceResolverProvider);
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    // O que valeria sem escolha própria: mãe, 1ª tag escolhida, padrão.
    final parent = parentId == null
        ? null
        : (ref.watch(allTasksProvider).value ?? const <Task>[])
              .where((t) => t.id == parentId)
              .firstOrNull;
    final firstTag = tags.where((t) => draft.tagIds.contains(t.id)).firstOrNull;
    final inheritedColor = parent != null && parent.colorKey != null
        ? resolver.colorKeyOf(parent)
        : firstTag?.colorKey ?? defaultColorKeyFor(repeats: draft.repeats);
    final inheritedIcon = parent == null
        ? AppIcons.taskDefault(repeats: draft.repeats)
        : AppIcons.of(resolver.iconKeyOf(parent));
    final color = draft.colorKey ?? inheritedColor;
    final icon = IconCatalog.tryIcon(draft.iconKey) ?? inheritedIcon;
    final custom = draft.colorKey != null || draft.iconKey != null;

    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppearanceBadge(colorKey: color, icon: icon),
      title: Text(l10n.fieldIconAndColor),
      subtitle: Text(custom ? l10n.appearanceCustom : l10n.appearanceInherited),
      trailing: const Icon(AppIcons.edit),
      onTap: () async {
        final choice = await showAppearancePicker(
          context,
          colorKey: draft.colorKey,
          iconKey: draft.iconKey,
          inheritedColor: inheritedColor,
          inheritedIcon: inheritedIcon,
        );
        if (choice != null) onChanged(choice);
      },
    );
  }
}

/// Aviso contextual no formulário quando o diagnóstico indica que o lembrete
/// provavelmente não vai tocar (notificações desligadas, canal silenciado ou
/// alarme exato negado).
class _DiagnosticsWarningBanner extends StatelessWidget {
  const _DiagnosticsWarningBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final danger = context.palette.danger;
    final space = context.space;
    return Container(
      padding: EdgeInsets.all(space.md),
      decoration: BoxDecoration(
        color: danger.tint,
        borderRadius: context.radius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                AppIcons.diagnostics,
                size: AppIconSize.standard,
                color: danger.onTint,
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Text(
                  l10n.formDiagnosticsWarning,
                  style: context.text.bodySmall!.copyWith(color: danger.onTint),
                ),
              ),
            ],
          ),
          SizedBox(height: space.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: Text(l10n.formDiagnosticsAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso contextual no Android 14+ quando `USE_FULL_SCREEN_INTENT` ainda não
/// foi concedida para o modo alarme.
class _FullScreenPermissionBanner extends StatelessWidget {
  const _FullScreenPermissionBanner({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final warn = context.palette.warning;
    final space = context.space;
    return Container(
      padding: EdgeInsets.all(space.md),
      decoration: BoxDecoration(
        color: warn.tint,
        borderRadius: context.radius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                AppIcons.alarm,
                size: AppIconSize.standard,
                color: warn.onTint,
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Text(
                  context.l10n.reminderFullScreenBanner,
                  style: context.text.bodySmall!.copyWith(color: warn.onTint),
                ),
              ),
            ],
          ),
          SizedBox(height: space.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAllow,
              child: Text(context.l10n.reminderAllowFullScreen),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tira o foco do campo de texto antes de abrir um seletor. Sem isso, ao
/// fechar o diálogo o Flutter devolve o foco ao título e o teclado sobe.
void _dropFocus() => FocusManager.instance.primaryFocus?.unfocus();
