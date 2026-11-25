import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/appearance_picker.dart';
import 'task_appearance.dart';
import 'task_draft.dart';
import 'task_labels.dart';
import 'task_providers.dart';

/// Adição rápida: título e pílulas (data, tag, prioridade, ícone/cor, mais).
/// Enter salva e deixa pronto para a próxima.
Future<void> showQuickAdd(BuildContext context, {bool dueToday = false}) =>
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuickAdd(dueToday: dueToday),
    );

class _QuickAdd extends ConsumerStatefulWidget {
  const _QuickAdd({required this.dueToday});

  final bool dueToday;

  @override
  ConsumerState<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends ConsumerState<_QuickAdd> {
  final _title = TextEditingController();
  final _focus = FocusNode();
  DateTime? _due;
  Set<String> _tagIds = {};
  int _priority = 0;
  String? _colorKey;
  String? _iconKey;
  String? _lastCreated;

  @override
  void initState() {
    super.initState();
    if (widget.dueToday) _due = ref.read(todayProvider);
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final repo = ref.read(tasksRepositoryProvider);
    final id = await repo.createTask(
      title: title,
      dueAt: _due,
      priority: _priority,
      colorKey: _colorKey,
      iconKey: _iconKey,
    );
    if (_tagIds.isNotEmpty) await repo.setTaskTags(id, _tagIds);
    if (!mounted) return;
    setState(() {
      _lastCreated = title;
      _title.clear();
    });
    _focus.requestFocus();
  }

  /// Abre o formulário completo levando tudo o que já foi escolhido aqui
  /// (título, data, tags, prioridade, ícone e cor).
  void _moreOptions() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      Routes.newTask(),
      extra: TaskDraft(
        title: _title.text.trim(),
        dueDate: _due == null ? null : startOfDay(_due!),
        priority: _priority,
        colorKey: _colorKey,
        iconKey: _iconKey,
        tagIds: {..._tagIds},
      ),
    );
  }

  Future<void> _pickAppearance() async {
    final tags = ref.read(tagsProvider).value ?? const <Tag>[];
    final firstTag = tags.where((t) => _tagIds.contains(t.id)).firstOrNull;
    final choice = await showAppearancePicker(
      context,
      colorKey: _colorKey,
      iconKey: _iconKey,
      inheritedColor: firstTag?.colorKey ?? kindColorKey(TaskKind.simples),
      inheritedIcon: AppIcons.kind(TaskKind.simples),
    );
    if (choice != null) {
      setState(() {
        _colorKey = choice.colorKey;
        _iconKey = choice.iconKey;
      });
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.lang;
    final space = context.space;
    final today = ref.watch(todayProvider);
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final firstTag = tags.where((t) => _tagIds.contains(t.id)).firstOrNull;
    final color =
        _colorKey ?? firstTag?.colorKey ?? kindColorKey(TaskKind.simples);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        space.page,
        0,
        space.page,
        MediaQuery.viewInsetsOf(context).bottom + space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _title,
                  focusNode: _focus,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  style: context.text.titleLarge,
                  decoration: InputDecoration(
                    hintText: l10n.tasksNew,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
              IconButton.filled(
                tooltip: l10n.tasksAdd,
                onPressed: _title.text.trim().isEmpty ? null : _save,
                icon: const Icon(AppIcons.send),
              ),
            ],
          ),
          SizedBox(height: space.sm),
          Wrap(
            runSpacing: space.xs,
            children: [
              _MenuPill<DateTime?>(
                icon: AppIcons.date,
                label: _due == null
                    ? l10n.fieldDate
                    : formatRelative(_due!, today, lang: lang),
                active: _due != null,
                items: [
                  (today, l10n.quickDateToday),
                  (addDays(today, 1), l10n.quickDateTomorrow),
                  (addDays(today, 7), l10n.quickDateNextWeek),
                  (null, l10n.fieldNoDate),
                ],
                onSelected: (d) => setState(() => _due = d),
              ),
              if (tags.isNotEmpty)
                _MenuPill<String>(
                  icon: AppIcons.tag,
                  label: firstTag == null
                      ? l10n.taskTagSingle
                      : _tagIds.length == 1
                      ? firstTag.name
                      : l10n.taskTagCount(_tagIds.length),
                  active: _tagIds.isNotEmpty,
                  items: [
                    for (final t in tags)
                      (t.id, '${_tagIds.contains(t.id) ? '✓ ' : ''}${t.name}'),
                  ],
                  onSelected: (id) => setState(() {
                    _tagIds = _tagIds.contains(id)
                        ? ({..._tagIds}..remove(id))
                        : {..._tagIds, id!};
                  }),
                ),
              _MenuPill<int>(
                icon: AppIcons.priority,
                label: _priority == 0
                    ? l10n.fieldPriority
                    : priorityLabel(_priority, l10n),
                active: _priority > 0,
                items: [
                  for (var i = 0; i < priorityLabels.length; i++)
                    (i, priorityLabel(i, l10n)),
                ],
                onSelected: (p) => setState(() => _priority = p ?? 0),
              ),
              Padding(
                padding: EdgeInsets.only(right: space.sm),
                child: ActionChip(
                  avatar: AppearanceBadge(
                    colorKey: color,
                    icon: AppIcons.of(
                      _iconKey,
                      fallback: AppIcons.kind(TaskKind.simples),
                    ),
                    size: 10,
                  ),
                  label: Text(l10n.fieldIconAndColor),
                  onPressed: _pickAppearance,
                ),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.more),
                label: Text(l10n.actionMoreOptions),
                onPressed: _moreOptions,
              ),
            ],
          ),
          if (_lastCreated case final last?) ...[
            SizedBox(height: space.sm),
            Text(
              l10n.tasksCreated(last),
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pílula que abre um menu de opções.
class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool active;
  final List<(T?, String)> items;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.space.sm),
      child: PopupMenuButton<int>(
        tooltip: label,
        onSelected: (i) => onSelected(items[i].$1),
        itemBuilder: (_) => [
          for (final (i, (_, text)) in items.indexed)
            PopupMenuItem(value: i, child: Text(text)),
        ],
        child: IgnorePointer(
          child: FilterChip(
            selected: active,
            showCheckmark: false,
            avatar: Icon(icon),
            label: Text(label),
            onSelected: (_) {},
          ),
        ),
      ),
    );
  }
}
