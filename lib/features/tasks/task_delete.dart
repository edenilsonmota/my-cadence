import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';

/// O que excluir junto com a tarefa (books com as páginas, páginas de outros
/// books vinculadas e decks). Vazio = só a tarefa.
class TaskDeletePlan {
  const TaskDeletePlan({
    this.notebookIds = const [],
    this.pageIds = const [],
    this.deckIds = const [],
  });

  static const none = TaskDeletePlan();

  final List<String> notebookIds;
  final List<String> pageIds;
  final List<String> deckIds;

  bool get isEmpty => notebookIds.isEmpty && pageIds.isEmpty && deckIds.isEmpty;
}

/// Pergunta se exclui também o que está vinculado à tarefa. Sem nada
/// vinculado, não pergunta e devolve [TaskDeletePlan.none]. `null` = cancelou.
Future<TaskDeletePlan?> askDeleteExtras(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final books = ref.read(booksRepositoryProvider);
  final cards = ref.read(cardsRepositoryProvider);
  final own = await books.watchTaskNotebook(task.id).first;
  final linkedBooks = await books.watchLinkedNotebooks(task.id).first;
  final pages = await books.watchLinkedPages(task.id).first;
  final decks = await cards.watchLinkedDecks(task.id).first;
  final linked = TaskDeletePlan(
    notebookIds: [?own?.id, for (final b in linkedBooks) b.id],
    pageIds: [for (final p in pages) p.id],
    deckIds: [for (final d in decks) d.id],
  );
  if (linked.isEmpty) return TaskDeletePlan.none;
  if (!context.mounted) return null;
  return showDialog<TaskDeletePlan>(
    context: context,
    builder: (_) => _DeleteTaskDialog(linked: linked),
  );
}

class _DeleteTaskDialog extends StatefulWidget {
  const _DeleteTaskDialog({required this.linked});

  final TaskDeletePlan linked;

  @override
  State<_DeleteTaskDialog> createState() => _DeleteTaskDialogState();
}

class _DeleteTaskDialogState extends State<_DeleteTaskDialog> {
  bool _books = false;
  bool _pages = false;
  bool _decks = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final linked = widget.linked;
    final any = _books || _pages || _decks;
    Widget option(String label, bool value, ValueChanged<bool> onChanged) =>
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          title: Text(label),
          onChanged: (v) => setState(() => onChanged(v ?? false)),
        );
    return AlertDialog(
      title: Text(l10n.deleteTaskTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteTaskAlsoHint),
          SizedBox(height: context.space.sm),
          if (linked.notebookIds.isNotEmpty)
            option(
              l10n.deleteAlsoBooks(linked.notebookIds.length),
              _books,
              (v) => _books = v,
            ),
          if (linked.pageIds.isNotEmpty)
            option(
              l10n.deleteAlsoPages(linked.pageIds.length),
              _pages,
              (v) => _pages = v,
            ),
          if (linked.deckIds.isNotEmpty)
            option(
              l10n.deleteAlsoDecks(linked.deckIds.length),
              _decks,
              (v) => _decks = v,
            ),
          if (any) ...[
            SizedBox(height: context.space.xs),
            Text(
              l10n.deleteAlsoNoUndo,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            TaskDeletePlan(
              notebookIds: _books ? linked.notebookIds : const [],
              pageIds: _pages ? linked.pageIds : const [],
              deckIds: _decks ? linked.deckIds : const [],
            ),
          ),
          child: Text(l10n.actionDelete),
        ),
      ],
    );
  }
}
