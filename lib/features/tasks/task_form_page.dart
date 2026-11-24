import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/appearance_picker.dart';
import '../../shared/widgets/number_stepper.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tag_chip.dart';
import 'alarms.dart';
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

  /// Título já digitado na adição rápida ("Mais opções").
  final String? initialTitle;

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
        reminderMode: f.reminderMode,
        estimatedPomodoros: f.estimatedPomodoros,
        colorKey: f.colorKey,
        iconKey: f.iconKey,
      );
    }
    await repo.setTaskTags(id, draft.tagIds);
    if (f.reminderMinutesBefore != null) {
      // Android 13+ e iOS pedem permissão para notificar; pergunta na hora em
      // que o primeiro lembrete é criado.
      await ref.read(alarmSchedulerProvider).requestPermission();
    }
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
          icon: const Icon(AppIcons.close),
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
      body: draft == null ? const SkeletonPage() : _buildForm(context, draft),
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
        if (hasDate && d.reminderMinutesBefore != null) ...[
          SizedBox(height: context.space.md),
          SegmentedButton<ReminderMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ReminderMode.notificacao,
                icon: const Icon(AppIcons.notification),
                label: Text(ReminderMode.notificacao.label),
              ),
              ButtonSegment(
                value: ReminderMode.alarme,
                icon: const Icon(AppIcons.alarm),
                label: Text(ReminderMode.alarme.label),
              ),
            ],
            selected: {d.reminderMode},
            onSelectionChanged: (s) {
              final mode = s.single;
              _edit((d) => d.reminderMode = mode);
              if (mode == ReminderMode.alarme) _refreshFullScreenIntent();
            },
          ),
          SizedBox(height: context.space.xs),
          Text(
            d.reminderMode == ReminderMode.alarme
                ? 'Toca como despertador (mesmo no silencioso) até você '
                      'interagir.'
                : 'Aviso discreto na barra de notificações.',
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (d.reminderMode == ReminderMode.alarme &&
              !_canUseFullScreenIntent) ...[
            SizedBox(height: context.space.sm),
            _FullScreenPermissionBanner(onAllow: _requestFullScreenIntent),
          ],
        ],
        const _Label('Pomodoros estimados'),
        NumberStepper(
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
        const _Label('Ícone e cor'),
        _AppearanceField(
          draft: d,
          parentId: _original?.parentId ?? widget.parentId,
          onChanged: (c) => _edit((d) {
            d.colorKey = c.colorKey;
            d.iconKey = c.iconKey;
          }),
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
          NumberStepper(
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
      padding: EdgeInsets.only(top: context.space.xl, bottom: context.space.sm),
      child: Text(text, style: context.text.titleSmall),
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
                icon: const Icon(AppIcons.date, size: 18),
                label: Text(
                  date == null
                      ? placeholder ?? 'Sem data'
                      : formatDate(date!, today),
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
            tooltip: 'Limpar $label',
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
    final palette = context.palette;
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
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
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
    // O que valeria sem escolha própria: mãe, 1ª tag escolhida, tipo.
    final parent = parentId == null
        ? null
        : (ref.watch(allTasksProvider).value ?? const <Task>[])
              .where((t) => t.id == parentId)
              .firstOrNull;
    final firstTag = tags.where((t) => draft.tagIds.contains(t.id)).firstOrNull;
    final inheritedColor = parent != null && parent.colorKey != null
        ? resolver.colorKeyOf(parent)
        : firstTag?.colorKey ?? kindColorKey(draft.kind);
    final inheritedIcon = parent == null
        ? AppIcons.kind(draft.kind)
        : AppIcons.of(resolver.iconKeyOf(parent));
    final color = draft.colorKey ?? inheritedColor;
    final icon = IconCatalog.tryIcon(draft.iconKey) ?? inheritedIcon;
    final custom = draft.colorKey != null || draft.iconKey != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppearanceBadge(colorKey: color, icon: icon),
      title: Text(custom ? 'Personalizado' : 'Padrão'),
      subtitle: Text(
        custom ? 'Toque para trocar' : 'Herda da tarefa mãe, da tag ou do tipo',
      ),
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
                  'Para abrir na tela bloqueada, permita notificações em tela '
                  'cheia nas configurações do Android.',
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
              child: const Text('Permitir tela cheia'),
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
