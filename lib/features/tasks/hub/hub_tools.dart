import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/clock.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/dates.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../../cards/card_form_sheet.dart';
import '../../pomodoro/manual_time_sheet.dart';
import 'hub_providers.dart';
import 'hub_stats.dart';

/// Quais ferramentas aparecem como seção. Tarefa de estudo mostra sempre as
/// três; nos outros tipos, só as que já têm conteúdo (as demais viram atalho).
({bool cards, bool pomodoro, bool pages}) visibleTools({
  required TaskKind kind,
  required bool hasCards,
  required bool hasPomodoro,
  required bool hasPages,
}) {
  final always = kind == TaskKind.estudo;
  return (
    cards: always || hasCards,
    pomodoro: always || hasPomodoro,
    pages: always || hasPages,
  );
}

enum HubToolsPart { shortcuts, sections }

/// Ferramentas do hub: Flashcards, Pomodoro e Páginas. [part] escolhe se
/// mostra os atalhos das ferramentas ocultas ou as seções visíveis.
class HubTools extends ConsumerWidget {
  const HubTools({required this.task, required this.part, super.key});

  final Task task;
  final HubToolsPart part;

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final card = await showCardForm(context, taskId: task.id);
    if (card == null) return;
    await ref
        .read(cardsRepositoryProvider)
        .createCard(
          front: card.front,
          back: card.back,
          now: ref.read(clockProvider)(),
          deckId: card.deckId,
          taskId: card.taskId,
        );
  }

  Future<void> _addPage(BuildContext context, WidgetRef ref, int order) async {
    final l10n = context.l10n;
    final title = await showTextInputDialog(
      context,
      title: l10n.hubNewPage,
      label: l10n.fieldTitle,
    );
    if (title == null) return;
    final books = ref.read(booksRepositoryProvider);
    final notebookId = await books.taskNotebookId(task.id, title: task.title);
    await books.createPage(
      notebookId: notebookId,
      title: title,
      sortOrder: order,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final cards = ref.watch(taskCardsProvider(task.id)).value ?? const [];
    final sessions = ref.watch(taskSessionsProvider(task.id)).value ?? const [];
    final notebook = ref.watch(taskNotebookProvider(task.id)).value;
    final ownPages = notebook == null
        ? const <NotePage>[]
        : ref.watch(notebookPagesProvider(notebook.id)).value ?? const [];
    final linked = ref.watch(linkedPagesProvider(task.id)).value ?? const [];
    final linkedBooks =
        ref.watch(linkedNotebooksProvider(task.id)).value ?? const [];
    final linkedDecks =
        ref.watch(linkedDecksProvider(task.id)).value ?? const [];

    final visible = visibleTools(
      kind: task.kind,
      hasCards: cards.isNotEmpty || linkedDecks.isNotEmpty,
      hasPomodoro: sessions.isNotEmpty || task.estimatedPomodoros != null,
      hasPages:
          ownPages.isNotEmpty || linked.isNotEmpty || linkedBooks.isNotEmpty,
    );

    void addCard() => _addCard(context, ref);
    void startFocus() => context.push(Routes.pomodoro(taskId: task.id));
    void addPage() => _addPage(context, ref, ownPages.length);
    void logTime() => showManualTimeSheet(context, taskId: task.id);

    final shortcuts = [
      if (!visible.cards)
        ActionChip(
          avatar: const Icon(AppIcons.flashcard),
          label: Text(l10n.hubFlashcard),
          onPressed: addCard,
        ),
      if (!visible.pomodoro) ...[
        ActionChip(
          avatar: const Icon(AppIcons.pomodoro),
          label: Text(l10n.navPomodoro),
          onPressed: startFocus,
        ),
        ActionChip(
          avatar: const Icon(AppIcons.time),
          label: Text(l10n.manualTimeLog),
          onPressed: logTime,
        ),
      ],
      if (!visible.pages)
        ActionChip(
          avatar: const Icon(AppIcons.page),
          label: Text(l10n.hubPage),
          onPressed: addPage,
        ),
    ];

    if (part == HubToolsPart.shortcuts) {
      return shortcuts.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(
                context.space.page,
                0,
                context.space.page,
                context.space.sm,
              ),
              child: Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.hubAdd, style: context.type.section),
                  ...shortcuts,
                ],
              ),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.cards)
          _CardsSection(
            taskId: task.id,
            decks: linkedDecks,
            counts: countCards(cards, now),
            onAdd: addCard,
            onReview: () => context.push(Routes.reviewTask(task.id)),
          ),
        if (visible.pomodoro)
          _PomodoroSection(
            summary: summarizeFocus(sessions, now),
            estimated: task.estimatedPomodoros,
            manual: [
              for (final s in sessions)
                if (s.manual && s.taskId == task.id) s,
            ]..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
            onStart: startFocus,
            onLogTime: logTime,
          ),
        if (visible.pages)
          _PagesSection(
            taskId: task.id,
            notebookId: notebook?.id,
            ownPages: ownPages,
            linked: linked,
            books: linkedBooks,
            onAdd: addPage,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;

  /// Mantido para quem chama; a seção usa só o rótulo (menos ruído).
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionHeader(title), ...children],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.space.page,
        context.space.xs,
        context.space.page,
        0,
      ),
      child: Wrap(
        spacing: context.space.sm,
        runSpacing: context.space.xs,
        children: children,
      ),
    );
  }
}

class _CardsSection extends ConsumerWidget {
  const _CardsSection({
    required this.taskId,
    required this.decks,
    required this.counts,
    required this.onAdd,
    required this.onReview,
  });

  final String taskId;
  final List<Deck> decks;
  final CardCounts counts;
  final VoidCallback onAdd;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final total = counts.total;
    return _Section(
      title: l10n.settingsFlashcards,
      icon: AppIcons.flashcard,
      children: [
        ListTile(
          title: Text(
            total == 0
                ? l10n.hubNoCardsYet
                : '$total ${total == 1 ? l10n.unitCard : l10n.unitCards}',
          ),
          subtitle: total == 0
              ? null
              : Text(
                  counts.due == 0
                      ? l10n.reviewNothingDue
                      : l10n.reviewDueNow(counts.due),
                ),
        ),
        for (final deck in decks)
          ListTile(
            leading: const Icon(AppIcons.deck),
            title: Text(deck.name),
            subtitle: Text(l10n.hubLinkedDecks),
            trailing: IconButton(
              tooltip: l10n.unlinkItem(deck.name),
              icon: const Icon(AppIcons.unlink),
              onPressed: () =>
                  ref.read(cardsRepositoryProvider).unlinkDeck(taskId, deck.id),
            ),
            onTap: () => context.push(Routes.cards(deckId: deck.id)),
          ),
        _Actions([
          if (total > 0)
            FilledButton.tonalIcon(
              icon: const Icon(AppIcons.play),
              label: Text(l10n.hubReviewTask),
              onPressed: onReview,
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.add),
            label: Text(l10n.hubCard),
            onPressed: onAdd,
          ),
        ]),
      ],
    );
  }
}

class _PomodoroSection extends ConsumerWidget {
  const _PomodoroSection({
    required this.summary,
    required this.estimated,
    required this.manual,
    required this.onStart,
    required this.onLogTime,
  });

  final FocusSummary summary;
  final int? estimated;

  /// Registros manuais da própria tarefa, do mais recente ao mais antigo.
  final List<PomodoroSession> manual;
  final VoidCallback onStart;
  final VoidCallback onLogTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.lang;
    final now = ref.watch(clockProvider)();
    final sessions = summary.sessions;
    return _Section(
      title: l10n.navPomodoro,
      icon: AppIcons.pomodoro,
      children: [
        ListTile(
          title: Text(l10n.hubFocusTimeValue(formatDuration(summary.total))),
          subtitle: Text(
            sessions == 0
                ? l10n.hubNoSessionsYet
                : l10n.hubFocusSessions(
                    sessions,
                    sessions == 1 ? l10n.unitSession : l10n.unitSessions,
                  ),
          ),
        ),
        if (estimated case final est?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.hubEstimatedVsDone(summary.completed, est)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: est == 0 ? 0 : (summary.completed / est).clamp(0, 1),
                  semanticsLabel: l10n.agendaCompletedPomodoros,
                ),
              ],
            ),
          ),
        if (manual.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.space.page,
              context.space.sm,
              context.space.page,
              0,
            ),
            child: Text(l10n.manualTimeEntries, style: context.type.section),
          ),
          for (final s in manual.take(5))
            ListTile(
              dense: true,
              leading: const Icon(AppIcons.time, size: AppIconSize.standard),
              title: Text(formatDuration(s.endedAt!.difference(s.startedAt))),
              subtitle: Text(
                formatRelative(s.startedAt, now, withTime: true, lang: lang),
              ),
              trailing: IconButton(
                tooltip: l10n.manualTimeDelete,
                icon: const Icon(AppIcons.delete),
                onPressed: () =>
                    ref.read(pomodoroRepositoryProvider).deleteSession(s.id),
              ),
            ),
        ],
        _Actions([
          FilledButton.tonalIcon(
            icon: const Icon(AppIcons.play),
            label: Text(l10n.statsStartFocus),
            onPressed: onStart,
          ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.time),
            label: Text(l10n.manualTimeLog),
            onPressed: onLogTime,
          ),
        ]),
      ],
    );
  }
}

class _PagesSection extends ConsumerWidget {
  const _PagesSection({
    required this.taskId,
    required this.notebookId,
    required this.ownPages,
    required this.linked,
    required this.books,
    required this.onAdd,
  });

  final String taskId;
  final String? notebookId;
  final List<NotePage> ownPages;
  final List<NotePage> linked;
  final List<Notebook> books;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final booksRepo = ref.read(booksRepositoryProvider);
    Widget pageTile(NotePage page, {Widget? trailing}) => ListTile(
      leading: const Icon(AppIcons.page),
      title: Text(page.title),
      trailing: trailing,
      onTap: () => context.push(Routes.page(page.id)),
    );

    return _Section(
      title: l10n.hubPages,
      icon: AppIcons.page,
      children: [
        if (ownPages.isEmpty && linked.isEmpty && books.isEmpty)
          ListTile(title: Text(l10n.hubNoPagesYet)),
        for (final book in books)
          ListTile(
            leading: const Icon(AppIcons.book),
            title: Text(book.title),
            subtitle: Text(l10n.hubLinkedBooks),
            trailing: IconButton(
              tooltip: l10n.unlinkItem(book.title),
              icon: const Icon(AppIcons.unlink),
              onPressed: () => booksRepo.unlinkNotebook(taskId, book.id),
            ),
            onTap: () => context.push(Routes.book(book.id)),
          ),
        for (final page in ownPages) pageTile(page),
        for (final page in linked)
          pageTile(
            page,
            trailing: IconButton(
              tooltip: l10n.hubUnlink,
              icon: const Icon(AppIcons.unlink),
              onPressed: () => booksRepo.unlinkPage(taskId, page.id),
            ),
          ),
        _Actions([
          OutlinedButton.icon(
            icon: const Icon(AppIcons.add),
            label: Text(l10n.hubPage),
            onPressed: onAdd,
          ),
          if (notebookId case final id?)
            OutlinedButton.icon(
              icon: const Icon(AppIcons.book),
              label: Text(l10n.hubOpenNotebook),
              onPressed: () => context.push(Routes.book(id)),
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.link),
            label: Text(l10n.hubLinkExistingPage),
            onPressed: () => showModalBottomSheet<void>(
              useRootNavigator: true,
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _LinkPageSheet(taskId: taskId),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Lista as páginas dos books para vincular ou desvincular da tarefa.
class _LinkPageSheet extends ConsumerWidget {
  const _LinkPageSheet({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pages = ref.watch(bookPagesProvider).value ?? const [];
    final linkedIds = {
      for (final p
          in ref.watch(linkedPagesProvider(taskId)).value ?? const <NotePage>[])
        p.id,
    };
    final books = ref.read(booksRepositoryProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.hubLinkPage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (pages.isEmpty)
            ListTile(
              leading: const Icon(AppIcons.book),
              title: Text(l10n.hubNoBookPages),
              subtitle: Text(l10n.hubNoBookPagesHint),
            ),
          for (final (page, book) in pages)
            CheckboxListTile(
              value: linkedIds.contains(page.id),
              title: Text(page.title),
              subtitle: Text(book.title),
              onChanged: (on) => on == true
                  ? books.linkPage(taskId, page.id)
                  : books.unlinkPage(taskId, page.id),
            ),
        ],
      ),
    );
  }
}
