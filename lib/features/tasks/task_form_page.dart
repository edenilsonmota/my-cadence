import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
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
    super.key,
  });

  final String? taskId;
  final String? parentId;

  /// Nova tarefa já com prazo hoje (atalho da aba Hoje).
  final bool dueToday;

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TaskDraft? _draft;
  Task? _original;
  bool _saving = false;

  bool get _editing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else {
      _draft = TaskDraft(
        dueDate: widget.dueToday ? ref.read(todayProvider) : null,
      );
    }
  }

  Future<void> _load() async {
    final repo = ref.read(tasksRepositoryProvider);
    final task = await repo.getTask(widget.taskId!);
    final tags = await repo.watchTagsOfTask(widget.taskId!).first;
    if (!mounted) return;
    if (task == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _original = task;
      _draft = TaskDraft.fromTask(task, {for (final t in tags) t.id});
      _title.text = task.title;
      _notes.text = task.notes ?? '';
    });
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
        estimatedPomodoros: f.estimatedPomodoros,
      );
    }
    await repo.setTaskTags(id, draft.tagIds);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final title = _editing
        ? 'Editar tarefa'
        : widget.parentId != null
        ? 'Nova subtarefa'
        : 'Nova tarefa';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
        actions: [
          TextButton(
            onPressed: draft == null || _saving ? null : _save,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: draft == null
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(context, draft),
    );
  }

  Widget _buildForm(BuildContext context, TaskDraft d) {
    final hasDate = d.dueDate != null || d.repeat != Repeat.nenhuma;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: _title,
          autofocus: !_editing,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Notas'),
        ),
        const _Label('Tipo'),
        SegmentedButton<TaskKind>(
          showSelectedIcon: false,
          segments: [
            for (final kind in TaskKind.values)
              ButtonSegment(value: kind, label: Text(kind.label)),
          ],
          selected: {d.kind},
          onSelectionChanged: (s) => _edit((d) => d.kind = s.single),
        ),
        const _Label('Prioridade'),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var p = 0; p < priorityLabels.length; p++)
              ButtonSegment(value: p, label: Text(priorityLabels[p])),
          ],
          selected: {d.priority},
          onSelectionChanged: (s) => _edit((d) => d.priority = s.single),
        ),
        const _Label('Datas'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dia inteiro'),
          value: d.allDay,
          onChanged: (v) => _edit((d) => d.allDay = v),
        ),
        _DateTimeRow(
          label: 'Início',
          date: d.startDate,
          time: d.startTime,
          allDay: d.allDay,
          onDate: (v) => _edit((d) => d.startDate = v),
          onTime: (v) => _edit((d) => d.startTime = v),
        ),
        _DateTimeRow(
          label: 'Prazo',
          date: d.dueDate,
          time: d.dueTime,
          allDay: d.allDay,
          placeholder: d.repeat != Repeat.nenhuma ? 'Hoje' : null,
          onDate: (v) => _edit((d) => d.dueDate = v),
          onTime: (v) => _edit((d) => d.dueTime = v),
        ),
        const _Label('Repetir'),
        SegmentedButton<Repeat>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: Repeat.nenhuma, label: Text('Não')),
            ButtonSegment(value: Repeat.diaria, label: Text('Diária')),
            ButtonSegment(value: Repeat.semanal, label: Text('Semanal')),
          ],
          selected: {d.repeat},
          onSelectionChanged: (s) => _edit((d) => d.repeat = s.single),
        ),
        if (d.repeat != Repeat.nenhuma) ..._repeatFields(context, d),
        const _Label('Alarme'),
        DropdownButtonFormField<int?>(
          initialValue: d.reminderMinutesBefore,
          decoration: InputDecoration(
            helperText: hasDate ? null : 'Defina um prazo para usar alarme.',
          ),
          items: [
            for (final MapEntry(:key, :value) in reminderOptions.entries)
              DropdownMenuItem(value: key, child: Text(value)),
          ],
          onChanged: hasDate
              ? (v) => _edit((d) => d.reminderMinutesBefore = v)
              : null,
        ),
        const _Label('Pomodoros estimados'),
        _Stepper(
          value: d.estimatedPomodoros ?? 0,
          min: 0,
          onChanged: (v) =>
              _edit((d) => d.estimatedPomodoros = v == 0 ? null : v),
          semanticLabel: 'Pomodoros estimados',
        ),
        const _Label('Tags'),
        _TagPicker(
          selected: d.tagIds,
          onChanged: (ids) => _edit((d) => d.tagIds = ids),
        ),
      ],
    );
  }

  List<Widget> _repeatFields(BuildContext context, TaskDraft d) {
    final weekly = d.repeat == Repeat.semanal;
    return [
      const SizedBox(height: 12),
      Row(
        children: [
          const Text('A cada'),
          const SizedBox(width: 8),
          _Stepper(
            value: d.interval,
            min: 1,
            onChanged: (v) => _edit((d) => d.interval = v),
            semanticLabel: 'Intervalo da repetição',
          ),
          const SizedBox(width: 8),
          Text(
            weekly
                ? (d.interval == 1 ? 'semana' : 'semanas')
                : (d.interval == 1 ? 'dia' : 'dias'),
          ),
        ],
      ),
      if (weekly) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              FilterChip(
                label: Text(weekdayShort[day - 1]),
                selected: d.weekdays.contains(day),
                onSelected: (on) => _edit(
                  (d) => on ? d.weekdays.add(day) : d.weekdays.remove(day),
                ),
              ),
          ],
        ),
      ],
      _DateTimeRow(
        label: 'Até',
        date: d.until,
        allDay: true,
        placeholder: 'Sem fim',
        onDate: (v) => _edit((d) => d.until = v),
      ),
      Text(
        d.recurrence!.describe(),
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ];
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
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
    final current = time ?? defaultTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) onTime!((hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final t = time ?? defaultTime;
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  date == null
                      ? placeholder ?? 'Sem data'
                      : formatDate(date!, today),
                ),
                onPressed: () => _pickDate(context),
              ),
              if (!allDay && date != null && onTime != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text('${two(t.hour)}:${two(t.minute)}'),
                  onPressed: () => _pickTime(context),
                ),
            ],
          ),
        ),
        if (date != null)
          IconButton(
            tooltip: 'Limpar $label',
            icon: const Icon(Icons.clear),
            onPressed: () {
              onDate(null);
              onTime?.call(null);
            },
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.onChanged,
    required this.semanticLabel,
  });

  final int value;
  final int min;
  final ValueChanged<int> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Diminuir',
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            semanticsLabel: '$semanticLabel: $value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
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
    final created = await showDialog<({String name, int color})>(
      context: context,
      builder: (_) => const _NewTagDialog(),
    );
    if (created == null) return;
    final id = await ref
        .read(tasksRepositoryProvider)
        .createTag(name: created.name, color: created.color);
    onChanged({...selected, id});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).value ?? const [];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final tag in tags)
          FilterChip(
            avatar: CircleAvatar(backgroundColor: Color(tag.color)),
            label: Text(tag.name),
            selected: selected.contains(tag.id),
            onSelected: (on) => onChanged(
              on ? {...selected, tag.id} : ({...selected}..remove(tag.id)),
            ),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Nova tag'),
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
  int _color = tagPalette.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in tagPalette)
                InkResponse(
                  onTap: () => setState(() => _color = color),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(color),
                    child: color == _color
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
      ],
    );
  }
}
