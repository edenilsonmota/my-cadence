import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/text_input_dialog.dart';
import '../tasks/task_providers.dart';
import 'card_actions.dart';
import 'card_form_sheet.dart';
import 'card_speaker.dart';
import 'cards_providers.dart';
import 'review_queue.dart';

/// Cards de um deck ([deckId]) ou todos, com editar, suspender e excluir.
class CardsListPage extends ConsumerWidget {
  const CardsListPage({this.deckId, super.key});

  final String? deckId;

  Future<void> _renameDeck(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final name = await showTextInputDialog(
      context,
      title: context.l10n.deckRename,
      label: context.l10n.reviewNameLabel,
      confirmLabel: context.l10n.actionSave,
      initialValue: deck.name,
    );
    if (name != null) {
      await ref
          .read(cardsRepositoryProvider)
          .saveDeck(deck.copyWith(name: name));
    }
  }

  Future<void> _deleteDeck(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deckDeleteTitle(deck.name)),
        content: Text(context.l10n.deckDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(cardsRepositoryProvider).deleteDeck(deck.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    final scope = (deckId: deckId, taskId: null);
    final cards = ref.watch(scopeCardsProvider(scope));
    final due = ref.watch(reviewQueueProvider(scope)).value?.length ?? 0;
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.name ?? context.l10n.reviewAllCards),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.l10n.deckOptions,
            onSelected: (v) => switch (v) {
              'voz' => showDeckSpeechSheet(context, deckId),
              'renomear' => _renameDeck(context, ref, deck!),
              _ => _deleteDeck(context, ref, deck!),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'voz', child: Text(context.l10n.deckSpeech)),
              if (deck != null) ...[
                PopupMenuItem(
                  value: 'renomear',
                  child: Text(context.l10n.actionRename),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: Text(context.l10n.deckDelete),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        tooltip: context.l10n.reviewNewCard,
        onPressed: () => createCardFlow(context, ref, deckId: deckId),
        child: const Icon(AppIcons.add),
      ),
      body: cards.when(
        loading: () => const SkeletonList(),
        error: (_, _) => EmptyState(
          icon: AppIcons.error,
          message: context.l10n.reviewLoadError,
        ),
        data: (cards) => cards.isEmpty
            ? EmptyState(
                icon: AppIcons.flashcard,
                message: context.l10n.cardsEmptyHere,
                action: FilledButton.tonal(
                  onPressed: () => createCardFlow(context, ref, deckId: deckId),
                  child: Text(context.l10n.cardCreate),
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  if (due > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: FilledButton.tonalIcon(
                        icon: const Icon(AppIcons.play),
                        label: Text(context.l10n.cardsReviewCount(due)),
                        onPressed: () =>
                            context.push(Routes.reviewSession(deckId: deckId)),
                      ),
                    ),
                  for (final card in cards) _CardTile(card: card, today: today),
                ],
              ),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card, required this.today});

  final Flashcard card;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final status = card.suspended
        ? context.l10n.cardSuspended
        : isNewCard(card)
        ? context.l10n.cardNew
        : context.l10n.cardNextReview(
            formatRelative(
              card.due,
              today,
              withTime: card.due.difference(today).inDays < 2,
              lang: context.lang,
            ),
          );
    return ListTile(
      title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        status,
        style: TextStyle(color: card.suspended ? colors.outline : null),
      ),
      onTap: () => editCardFlow(context, ref, card),
      trailing: PopupMenuButton<String>(
        tooltip: context.l10n.cardOptions,
        onSelected: (v) => switch (v) {
          'editar' => editCardFlow(context, ref, card),
          'suspender' =>
            ref
                .read(cardsRepositoryProvider)
                .saveCard(card.copyWith(suspended: !card.suspended)),
          'excluir' => deleteCardWithUndo(
            ScaffoldMessenger.of(context),
            ref,
            card,
          ),
          _ => null,
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'editar', child: Text(context.l10n.actionEdit)),
          PopupMenuItem(
            value: 'suspender',
            child: Text(
              card.suspended
                  ? context.l10n.cardReactivate
                  : context.l10n.cardSuspend,
            ),
          ),
          PopupMenuItem(
            value: 'excluir',
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
