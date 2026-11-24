import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';

final booksProvider = StreamProvider.autoDispose<List<Notebook>>(
  (ref) => ref.watch(booksRepositoryProvider).watchBooks(),
);

final notebookProvider = StreamProvider.autoDispose.family<Notebook?, String>(
  (ref, id) => ref.watch(booksRepositoryProvider).watchNotebook(id),
);

final pagesOfNotebookProvider = StreamProvider.autoDispose
    .family<List<NotePage>, String>(
      (ref, notebookId) =>
          ref.watch(booksRepositoryProvider).watchPages(notebookId),
    );

final pageProvider = StreamProvider.autoDispose.family<NotePage?, String>(
  (ref, id) => ref.watch(booksRepositoryProvider).watchPage(id),
);

/// Tarefas vinculadas à página.
final tasksOfPageProvider = StreamProvider.autoDispose
    .family<List<Task>, String>(
      (ref, pageId) =>
          ref.watch(booksRepositoryProvider).watchTasksLinkedToPage(pageId),
    );
