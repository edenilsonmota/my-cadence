import 'package:my_cadence/data/db/card_schedule.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

final _now = DateTime(2026, 11, 24, 12);

/// Um pouco de tudo, em todas as tabelas sincronizadas.
Future<void> seedEverything(AppDatabase db) async {
  final tasks = TasksRepository(db.tasksDao, db.tagsDao);
  final books = BooksRepository(db.booksDao);
  final cards = CardsRepository(db.cardsDao);
  final pomodoro = PomodoroRepository(db.pomodoroDao);
  final settings = SettingsRepository(db.settingsDao);

  final parent = await tasks.createTask(
    title: 'Estudar',
    kind: TaskKind.estudo,
    dueAt: DateTime(2026, 11, 25, 14),
    hasTime: true,
    recurrenceRule: 'FREQ=DAILY',
    reminderMinutesBefore: 15,
    reminderMode: ReminderMode.alarme,
    colorKey: 'violeta',
    iconKey: 'brain',
    estimatedPomodoros: 4,
  );
  final child = await tasks.createTask(title: 'Parte 1', parentId: parent);
  await tasks.setStatus(child, TaskStatus.feita, now: _now);
  final gone = await tasks.createTask(title: 'Excluída');
  await tasks.deleteTask(gone);
  final tag = await tasks.createTag(name: 'Faculdade', colorKey: 'azul');
  await tasks.setTaskTags(parent, {tag});
  await tasks.addCompletion(parent, DateTime(2026, 11, 23, 14));

  final session = await pomodoro.startSession(
    kind: PomodoroKind.foco,
    plannedMinutes: 25,
    startedAt: DateTime(2026, 11, 24, 9),
    taskId: parent,
  );
  await pomodoro.finishSession(
    session,
    endedAt: DateTime(2026, 11, 24, 9, 25),
    completed: true,
  );

  final deck = await cards.createDeck(name: 'Inglês');
  final card = await cards.createCard(
    front: 'cat',
    back: 'gato',
    now: _now,
    deckId: deck,
    taskId: parent,
  );
  await cards.applyReview(
    cardId: card,
    next: CardSchedule(
      state: CardState.review,
      due: DateTime(2026, 11, 27),
      stability: 3.25,
      difficulty: 5.5,
      lastReview: _now,
    ),
    rating: 3,
    reviewedAt: _now,
    durationMs: 4200,
  );

  final book = await books.createBook(title: 'Física', colorKey: 'teal');
  final page = await books.createPage(notebookId: book, title: 'Leis');
  await books.createPage(
    notebookId: book,
    title: 'Primeira lei',
    parentPageId: page,
    content: '{"document":{}}',
  );
  await books.linkPage(parent, page);

  await settings.setString('pomodoro.focus', '30');
  await settings.setString('calendar.mode', 'mes'); // do aparelho
}
