import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/text_input_dialog.dart';
import 'task_template.dart';

final templatesProvider = StreamProvider.autoDispose<List<TaskTemplate>>(
  (ref) => ref.watch(templatesRepositoryProvider).watchTemplates(),
);

/// Pergunta o nome e salva [task] como modelo (com tags, books, decks e os
/// títulos das subtarefas).
Future<void> saveTaskAsTemplate(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final tasks = ref.read(tasksRepositoryProvider);
  final books = ref.read(booksRepositoryProvider);
  final cards = ref.read(cardsRepositoryProvider);
  final templates = ref.read(templatesRepositoryProvider);
  final name = await showTextInputDialog(
    context,
    title: l10n.templateSave,
    label: l10n.templateName,
    initialValue: task.title,
    confirmLabel: l10n.actionSave,
  );
  if (name == null || name.trim().isEmpty) return;
  final data = TaskTemplateData.fromTask(
    task,
    tagIds: [for (final t in await tasks.watchTagsOfTask(task.id).first) t.id],
    notebookIds: [
      for (final b in await books.watchLinkedNotebooks(task.id).first) b.id,
    ],
    deckIds: [
      for (final d in await cards.watchLinkedDecks(task.id).first) d.id,
    ],
    subtasks: [
      for (final s in await tasks.watchSubtasks(task.id).first) s.title,
    ],
  );
  await templates.createTemplate(name: name.trim(), payload: data.encode());
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.templateSaved(name.trim()))));
}

/// Cria a tarefa do modelo (vínculos só com o que ainda existe) e devolve o
/// id. Recebe o [container] (e não um `ref` de widget) porque costuma rodar
/// depois que a folha que chamou já fechou.
Future<String> createTaskFromTemplate(
  ProviderContainer container,
  TaskTemplateData data,
) async {
  final tasks = container.read(tasksRepositoryProvider);
  final books = container.read(booksRepositoryProvider);
  final cards = container.read(cardsRepositoryProvider);
  final offsets = data.reminderOffsets;
  final id = await tasks.createTask(
    title: data.title,
    notes: data.notes,
    priority: data.priority,
    hasTime: data.hasTime,
    reminderOffsets: offsets,
    reminderMinutesBefore: offsets == null || offsets.isEmpty
        ? null
        : int.tryParse(offsets.split(',').first),
    reminderMode: data.reminderMode,
    nagIntervalMinutes: data.nagIntervalMinutes,
    estimatedMinutes: data.estimatedMinutes,
    colorKey: data.colorKey,
    iconKey: data.iconKey,
  );
  final liveTags = {for (final t in await tasks.watchTags().first) t.id};
  await tasks.setTaskTags(id, {
    for (final t in data.tagIds)
      if (liveTags.contains(t)) t,
  });
  final liveBooks = {for (final b in await books.watchBooks().first) b.id};
  await books.setTaskNotebooks(id, {
    for (final b in data.notebookIds)
      if (liveBooks.contains(b)) b,
  });
  final liveDecks = {for (final d in await cards.watchDecks().first) d.id};
  await cards.setTaskDecks(id, {
    for (final d in data.deckIds)
      if (liveDecks.contains(d)) d,
  });
  for (final title in data.subtasks) {
    await tasks.createTask(title: title, parentId: id);
  }
  return id;
}

/// Lista os modelos; ao escolher, chama [beforeCreate] (ex.: fechar a
/// adição rápida), cria a tarefa e abre o formulário para ajustar as datas.
Future<void> showTemplatePicker(
  BuildContext context, {
  VoidCallback? beforeCreate,
}) async {
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context);
  final picked = await showModalBottomSheet<TaskTemplate>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _TemplatePickerSheet(),
  );
  if (picked == null) return;
  beforeCreate?.call();
  final id = await createTaskFromTemplate(
    container,
    TaskTemplateData.decode(picked.payload, fallbackTitle: picked.name),
  );
  unawaited(router.push(Routes.editTask(id)));
}

class _TemplatePickerSheet extends ConsumerWidget {
  const _TemplatePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final space = context.space;
    final templates = ref.watch(templatesProvider).value ?? const [];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.page),
            child: Text(
              l10n.templatePickTitle,
              style: context.text.titleMedium,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              space.page,
              space.xs,
              space.page,
              space.sm,
            ),
            child: Text(
              l10n.templatePickHint,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final t in templates)
            ListTile(
              leading: const Icon(AppIcons.template),
              title: Text(t.name),
              subtitle: Text(
                l10n.templateSubtasks(
                  TaskTemplateData.decode(t.payload).subtasks.length,
                ),
              ),
              trailing: IconButton(
                tooltip: l10n.templateDelete,
                icon: const Icon(AppIcons.delete),
                onPressed: () =>
                    ref.read(templatesRepositoryProvider).deleteTemplate(t.id),
              ),
              onTap: () => Navigator.of(context).pop(t),
            ),
        ],
      ),
    );
  }
}
