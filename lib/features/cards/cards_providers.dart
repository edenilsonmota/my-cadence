import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../tasks/hub/hub_providers.dart';
import '../tasks/task_providers.dart';
import 'review_queue.dart';

/// Escopo da revisão: tudo, um deck ou uma tarefa (com as subtarefas).
typedef ReviewScope = ({String? deckId, String? taskId});

const ReviewScope allCardsScope = (deckId: null, taskId: null);

final cardSettingsProvider = StreamProvider<CardSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(CardSettings.prefix)
      .map(CardSettings.fromMap),
);

final allCardsProvider = StreamProvider.autoDispose<List<Flashcard>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchCards(),
);

final scopeCardsProvider = Provider.autoDispose
    .family<AsyncValue<List<Flashcard>>, ReviewScope>((ref, scope) {
      if (scope.taskId case final taskId?) {
        return ref.watch(taskCardsProvider(taskId));
      }
      final all = ref.watch(allCardsProvider);
      final deckId = scope.deckId;
      return deckId == null
          ? all
          : all.whenData(
              (cards) => [
                for (final c in cards)
                  if (c.deckId == deckId) c,
              ],
            );
    });

/// Cards novos com a primeira revisão hoje (para o limite diário).
final newStudiedTodayProvider = StreamProvider.autoDispose<int>(
  (ref) => ref
      .watch(cardsRepositoryProvider)
      .watchNewStudiedSince(ref.watch(todayProvider)),
);

/// "Agora" que avança a cada segundo enquanto alguém observa (cards em passos
/// de aprendizado voltam à fila em 1 ou 10 min).
final reviewNowProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(tickerProvider).value ?? ref.read(clockProvider)(),
);

/// Fila de revisão do escopo, respeitando o limite de novos do dia.
final reviewQueueProvider = Provider.autoDispose
    .family<AsyncValue<List<Flashcard>>, ReviewScope>((ref, scope) {
      final cards = ref.watch(scopeCardsProvider(scope));
      final settings = ref.watch(cardSettingsProvider);
      final newToday = ref.watch(newStudiedTodayProvider);
      final now = ref.watch(reviewNowProvider);
      if (cards case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final list = cards.value;
      if (list == null || !settings.hasValue || !newToday.hasValue) {
        return const AsyncLoading();
      }
      return AsyncData(
        buildQueue(
          list,
          now,
          newPerDay: settings.requireValue.newPerDay,
          newStudiedToday: newToday.requireValue,
        ),
      );
    });

/// Quantos cards há para revisar agora (badge da aba Revisar).
final dueCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(reviewQueueProvider(allCardsScope)).value?.length ?? 0,
);
