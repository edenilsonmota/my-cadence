import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
import '../../shared/widgets/text_input_dialog.dart';
import 'card_actions.dart';
import 'card_form_sheet.dart';
import 'cards_providers.dart';
import 'review_queue.dart';

/// Aba Revisar: o que vence agora, decks e acesso aos cards.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  Future<void> _newDeck(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(
      context,
      title: l10n.reviewNewDeck,
      label: l10n.reviewNameLabel,
    );
    if (name != null) {
      await ref.read(cardsRepositoryProvider).createDeck(name: name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = ref.watch(allCardsProvider);
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final due = ref.watch(dueCountProvider);
    final now = ref.watch(reviewNowProvider);

    return TabScaffold(
      title: l10n.navReview,
      actions: [
        PopupMenuButton<String>(
          tooltip: l10n.actionMoreOptions,
          onSelected: (v) => switch (v) {
            'deck' => _newDeck(context, ref),
            'csv' => importCsvFlow(context, ref),
            _ => null,
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'deck', child: Text(l10n.reviewNewDeck)),
            PopupMenuItem(value: 'csv', child: Text(l10n.reviewImportCsv)),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: null, // abas vivas no IndexedStack; ver CLAUDE.md
        tooltip: l10n.reviewNewCard,
        onPressed: () => createCardFlow(context, ref),
        child: const Icon(AppIcons.add),
      ),
      body: cards.when(
        loading: () => const SkeletonList(),
        error: (_, _) =>
            EmptyState(icon: AppIcons.error, message: l10n.reviewLoadError),
        data: (all) {
          if (all.isEmpty && decks.isEmpty) {
            return EmptyState(
              icon: AppIcons.flashcard,
              message: l10n.reviewEmptyAlt,
              action: FilledButton.tonal(
                onPressed: () => _newDeck(context, ref),
                child: Text(l10n.reviewEmptyAction),
              ),
            );
          }
          final soon = due == 0 ? nextDueSoon(all, now) : null;
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              _DueCard(
                due: due,
                soonMinutes: soon == null
                    ? null
                    : (soon.difference(now).inSeconds / 60).ceil(),
                onReview: () => context.push(Routes.reviewSession()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reviewDecks,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.reviewNewDeck,
                      icon: const Icon(AppIcons.newDeck),
                      onPressed: () => _newDeck(context, ref),
                    ),
                  ],
                ),
              ),
              for (final deck in decks) _DeckTile(deck: deck, cards: all),
              ListTile(
                leading: const Icon(AppIcons.viewList),
                title: Text(l10n.reviewAllCards),
                subtitle: Text(
                  '${all.length} ${all.length == 1 ? l10n.unitCard : l10n.unitCards}',
                ),
                onTap: () => context.push(Routes.cards()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({
    required this.due,
    required this.soonMinutes,
    required this.onReview,
  });

  final int due;
  final int? soonMinutes;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              due == 0 ? l10n.reviewNothingDue : l10n.reviewDueNow(due),
              style: theme.textTheme.titleLarge,
            ),
            if (soonMinutes case final m?)
              Text(l10n.reviewNextIn(m <= 1 ? 1 : m)),
            if (due > 0) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(AppIcons.play),
                label: Text(l10n.reviewAll),
                onPressed: onReview,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckTile extends ConsumerWidget {
  const _DeckTile({required this.deck, required this.cards});

  final Deck deck;
  final List<Flashcard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final total = cards.where((c) => c.deckId == deck.id).length;
    final due =
        ref
            .watch(reviewQueueProvider((deckId: deck.id, taskId: null)))
            .value
            ?.length ??
        0;
    return ListTile(
      leading: const Icon(AppIcons.deck),
      title: Text(deck.name),
      subtitle: Text(
        '$total ${total == 1 ? l10n.unitCard : l10n.unitCards}'
        '${due > 0 ? ' · ${l10n.reviewDeckDueSuffix(due)}' : ''}',
      ),
      onTap: () => context.push(Routes.cards(deckId: deck.id)),
    );
  }
}
