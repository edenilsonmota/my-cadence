import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/locale_providers.dart';
import '../../core/dates.dart';
import '../../data/providers.dart';
import '../cards/review_queue.dart';
import 'alarms.dart';
import 'daily_reminders.dart';

/// Preferências dos avisos diários (revisão de cards e resumo de tarefas).
final dailyReminderSettingsProvider = StreamProvider<DailyReminderSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(DailyReminderSettings.prefix)
      .map(DailyReminderSettings.fromMap),
);

/// Mantém os avisos diários reagendados sempre que tarefas, flashcards ou
/// ajustes mudam. Basta ler uma vez (em `main`).
final dailyReminderSyncProvider = Provider<DailyReminderSync>((ref) {
  final clock = ref.watch(clockProvider);
  final sync = DailyReminderSync(
    ref.watch(alarmSchedulerProvider),
    clock: clock,
  );
  final tasksSub = ref
      .watch(tasksRepositoryProvider)
      .watchAllTasks()
      .listen((tasks) => sync.update(tasks: tasks));
  final cardsSub = ref
      .watch(cardsRepositoryProvider)
      .watchCards()
      .listen((cards) => sync.update(cards: cards));
  final studiedSub = ref
      .watch(cardsRepositoryProvider)
      .watchNewStudiedSince(startOfDay(clock()))
      .listen((n) => sync.update(newStudiedToday: n));
  final cardSettingsSub = ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(CardSettings.prefix)
      .map(CardSettings.fromMap)
      .listen((s) => sync.update(cardSettings: s));
  final dailySettingsSub = ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(DailyReminderSettings.prefix)
      .map(DailyReminderSettings.fromMap)
      .listen((s) => sync.update(settings: s));

  sync.update(lang: langOfLocale(ref.read(appLocaleProvider)));
  ref.listen(
    appLocaleProvider,
    (_, next) => sync.update(lang: langOfLocale(next)),
  );

  ref.onDispose(() {
    tasksSub.cancel();
    cardsSub.cancel();
    studiedSub.cancel();
    cardSettingsSub.cancel();
    dailySettingsSub.cancel();
  });
  return sync;
});
