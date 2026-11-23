import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/database.dart';
import 'repositories/books_repository.dart';
import 'repositories/cards_repository.dart';
import 'repositories/pomodoro_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/tasks_repository.dart';

/// Banco do app. Nos testes, sobrescrever com
/// `AppDatabase(NativeDatabase.memory())`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TasksRepository(db.tasksDao, db.tagsDao);
});

final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => PomodoroRepository(ref.watch(databaseProvider).pomodoroDao),
);

final cardsRepositoryProvider = Provider<CardsRepository>(
  (ref) => CardsRepository(ref.watch(databaseProvider).cardsDao),
);

final booksRepositoryProvider = Provider<BooksRepository>(
  (ref) => BooksRepository(ref.watch(databaseProvider).booksDao),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider).settingsDao),
);
