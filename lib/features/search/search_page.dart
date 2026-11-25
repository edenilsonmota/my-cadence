import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../cards/card_actions.dart';
import '../cards/card_form_sheet.dart' show decksProvider;
import '../cards/cards_providers.dart';
import '../tasks/task_providers.dart';
import 'search_logic.dart';

final _allPagesProvider =
    StreamProvider.autoDispose<List<(NotePage, Notebook)>>(
      (ref) => ref.watch(booksRepositoryProvider).watchAllPages(),
    );

/// Busca geral: tarefas, páginas dos books e cards.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
    final pages = ref.watch(_allPagesProvider).value ?? const [];
    final cards = ref.watch(allCardsProvider).value ?? const <Flashcard>[];
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final hits = searchAll(
      _query.text,
      tasks: tasks,
      pages: pages,
      cards: cards,
      deckNames: {for (final d in decks) d.id: d.name},
    );
    final byKind = {
      for (final kind in SearchKind.values)
        kind: [
          for (final h in hits)
            if (h.kind == kind) h,
        ],
    };

    String sectionName(SearchKind kind) => switch (kind) {
      SearchKind.task => l10n.navTasks,
      SearchKind.page => l10n.hubPages,
      SearchKind.card => l10n.settingsFlashcards,
    };
    IconData iconOf(SearchKind kind) => switch (kind) {
      SearchKind.task => AppIcons.tasks,
      SearchKind.page => AppIcons.page,
      SearchKind.card => AppIcons.flashcard,
    };

    void open(SearchHit hit) {
      switch (hit.kind) {
        case SearchKind.task:
          context.push(Routes.task(hit.id));
        case SearchKind.page:
          context.push(Routes.page(hit.id));
        case SearchKind.card:
          final card = cards.where((c) => c.id == hit.id).firstOrNull;
          if (card != null) editCardFlow(context, ref, card);
      }
    }

    final query = _query.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              tooltip: l10n.searchClear,
              icon: const Icon(AppIcons.close),
              onPressed: _query.clear,
            ),
        ],
      ),
      body: query.length < 2
          ? EmptyState(icon: AppIcons.search, message: l10n.searchIntro)
          : hits.isEmpty
          ? EmptyState(icon: AppIcons.search, message: l10n.searchNoResults)
          : ListView(
              padding: EdgeInsets.only(bottom: context.space.xxl),
              children: [
                for (final kind in SearchKind.values)
                  if (byKind[kind]!.isNotEmpty) ...[
                    SectionHeader(
                      sectionName(kind),
                      detail: '${byKind[kind]!.length}',
                    ),
                    for (final hit in byKind[kind]!)
                      ListTile(
                        leading: Icon(iconOf(kind)),
                        title: Text(
                          hit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: hit.snippet == null && hit.place == null
                            ? null
                            : Text(
                                [?hit.place, ?hit.snippet].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () => open(hit),
                      ),
                  ],
              ],
            ),
    );
  }
}
