import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/providers.dart';
import '../task_providers.dart';
import 'hub_stats.dart';

/// Ids da tarefa e de todas as subtarefas (só a própria, até a lista carregar).
final taskTreeIdsProvider = Provider.autoDispose.family<List<String>, String>((
  ref,
  id,
) {
  final tasks = ref.watch(allTasksProvider).value;
  return tasks == null ? [id] : subtreeIds(tasks, id);
});

/// Mesmo que [taskTreeIdsProvider], mas só muda quando os ids mudam (a
/// lista de tarefas emite a cada edição).
List<String> _treeIds(Ref ref, String id) => ref
    .watch(taskTreeIdsProvider(id).select((ids) => ids.join(',')))
    .split(',');

/// Cards da tarefa e das subtarefas.
final taskCardsProvider = StreamProvider.autoDispose
    .family<List<Flashcard>, String>(
      (ref, id) => ref
          .watch(cardsRepositoryProvider)
          .watchCardsOfTasks(_treeIds(ref, id)),
    );

/// Sessões de pomodoro da tarefa e das subtarefas.
final taskSessionsProvider = StreamProvider.autoDispose
    .family<List<PomodoroSession>, String>(
      (ref, id) => ref
          .watch(pomodoroRepositoryProvider)
          .watchSessionsOfTasks(_treeIds(ref, id)),
    );

final taskNotebookProvider = StreamProvider.autoDispose
    .family<Notebook?, String>(
      (ref, taskId) =>
          ref.watch(booksRepositoryProvider).watchTaskNotebook(taskId),
    );

final notebookPagesProvider = StreamProvider.autoDispose
    .family<List<NotePage>, String>(
      (ref, notebookId) =>
          ref.watch(booksRepositoryProvider).watchPages(notebookId),
    );

/// Páginas de books vinculadas à tarefa.
final linkedPagesProvider = StreamProvider.autoDispose
    .family<List<NotePage>, String>(
      (ref, taskId) =>
          ref.watch(booksRepositoryProvider).watchLinkedPages(taskId),
    );

/// Books inteiros vinculados à tarefa.
final linkedNotebooksProvider = StreamProvider.autoDispose
    .family<List<Notebook>, String>(
      (ref, taskId) =>
          ref.watch(booksRepositoryProvider).watchLinkedNotebooks(taskId),
    );

/// Decks vinculados à tarefa.
final linkedDecksProvider = StreamProvider.autoDispose
    .family<List<Deck>, String>(
      (ref, taskId) =>
          ref.watch(cardsRepositoryProvider).watchLinkedDecks(taskId),
    );

/// Todas as páginas de books, para escolher qual vincular.
final bookPagesProvider =
    StreamProvider.autoDispose<List<(NotePage, Notebook)>>(
      (ref) => ref.watch(booksRepositoryProvider).watchBookPages(),
    );
