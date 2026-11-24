import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
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
    final name = await showTextInputDialog(
      context,
      title: 'Novo deck',
      label: 'Nome',
    );
    if (name != null) {
      await ref.read(cardsRepositoryProvider).createDeck(name: name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(allCardsProvider);
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final due = ref.watch(dueCountProvider);
    final now = ref.watch(reviewNowProvider);

    return TabScaffold(
      title: 'Revisar',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Mais opções',
          onSelected: (v) => switch (v) {
            'deck' => _newDeck(context, ref),
            'csv' => importCsvFlow(context, ref),
            _ => null,
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'deck', child: Text('Novo deck')),
            PopupMenuItem(value: 'csv', child: Text('Importar CSV')),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: null, // abas vivas no IndexedStack; ver CLAUDE.md
        tooltip: 'Novo card',
        onPressed: () => createCardFlow(context, ref),
        child: const Icon(Icons.add),
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          message: 'Não foi possível carregar os cards.',
        ),
        data: (all) {
          if (all.isEmpty && decks.isEmpty) {
            return EmptyState(
              icon: Icons.style_outlined,
              message:
                  'Nenhum card ainda.\nCrie um card no + ou importe um CSV.',
              action: FilledButton.tonal(
                onPressed: () => _newDeck(context, ref),
                child: const Text('Criar deck'),
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
                        'Decks',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Novo deck',
                      icon: const Icon(Icons.create_new_folder_outlined),
                      onPressed: () => _newDeck(context, ref),
                    ),
                  ],
                ),
              ),
              for (final deck in decks) _DeckTile(deck: deck, cards: all),
              ListTile(
                leading: const Icon(Icons.view_list_outlined),
                title: const Text('Todos os cards'),
                subtitle: Text(
                  '${all.length} ${all.length == 1 ? 'card' : 'cards'}',
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
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              due == 0 ? 'Nada para revisar agora' : '$due para revisar agora',
              style: theme.textTheme.titleLarge,
            ),
            if (soonMinutes case final m?)
              Text('Próximo card em ${m <= 1 ? '1 min' : '$m min'}.'),
            if (due > 0) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Revisar tudo'),
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
    final total = cards.where((c) => c.deckId == deck.id).length;
    final due =
        ref
            .watch(reviewQueueProvider((deckId: deck.id, taskId: null)))
            .value
            ?.length ??
        0;
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(deck.name),
      subtitle: Text(
        '$total ${total == 1 ? 'card' : 'cards'}'
        '${due > 0 ? ' · $due para revisar' : ''}',
      ),
      onTap: () => context.push(Routes.cards(deckId: deck.id)),
    );
  }
}
