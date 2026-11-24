import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../data/repositories/books_repository.dart';
import '../../shared/debounced_saver.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../cards/card_form_sheet.dart';
import '../tasks/widgets/task_picker.dart';
import 'book_actions.dart';
import 'book_markdown.dart';
import 'books_providers.dart';
import 'editor_toolbar_items.dart';

/// Página de um caderno com o editor AppFlowy.
///
/// O JSON do editor é a fonte da verdade (coluna `content`). Salva sozinho
/// 800 ms depois da última mudança e também ao sair da tela.
class PageEditorPage extends ConsumerStatefulWidget {
  const PageEditorPage({
    required this.pageId,
    this.startEditing = false,
    super.key,
  });

  final String pageId;

  /// Abre direto no modo edição (página recém-criada).
  final bool startEditing;

  @override
  ConsumerState<PageEditorPage> createState() => _PageEditorPageState();
}

class _PageEditorPageState extends ConsumerState<PageEditorPage> {
  late final BooksRepository _repo = ref.read(booksRepositoryProvider);
  late final DebouncedSaver _saver = DebouncedSaver(_save);
  final _title = TextEditingController();

  NotePage? _page;
  EditorState? _editor;
  EditorScrollController? _scroll;
  StreamSubscription<EditorTransactionValue>? _changes;
  late bool _editing = widget.startEditing;
  bool _missing = false;

  /// Último trecho selecionado. Ao tocar no menu, o editor perde o foco e
  /// limpa a seleção (achado ao testar); o trecho fica guardado aqui.
  String? _lastSelectedText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await _repo.getPage(widget.pageId);
    if (!mounted) return;
    if (page == null) {
      setState(() => _missing = true);
      return;
    }
    final editor = EditorState(document: documentFromContent(page.content));
    _changes = editor.transactionStream.listen((value) {
      final (time, transaction, _) = value;
      // Só mudanças de conteúdo (mover o cursor também gera transação).
      if (time == TransactionTime.after && transaction.operations.isNotEmpty) {
        _saver.schedule();
      }
    });
    editor.selectionNotifier.addListener(() {
      final selection = editor.selection;
      if (selection == null) return; // perdeu o foco: mantém o último trecho
      if (!_editing && selection.isCollapsed) {
        // Leitura: tocar no texto não deixa cursor (só seleção de trecho).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_editing && editor.selection == selection) {
            editor.selection = null;
          }
        });
        return;
      }
      _lastSelectedText = selection.isCollapsed ? null : _selectedText();
    });
    _title.text = page.title;
    setState(() {
      _page = page;
      _editor = editor;
      _scroll = EditorScrollController(editorState: editor);
    });
  }

  Future<void> _save() async {
    final editor = _editor;
    if (editor == null) return;
    final title = _title.text.trim();
    await _repo.savePageContent(
      widget.pageId,
      title: title.isEmpty ? 'Sem título' : title,
      content: contentFromDocument(editor.document),
    );
  }

  @override
  void dispose() {
    // Salva o que estiver pendente ao sair (o repositório foi guardado no
    // início; o `ref` não vale mais aqui).
    unawaited(_saver.flush());
    _changes?.cancel();
    _scroll?.dispose();
    _editor?.dispose();
    _title.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_editing) {
      _editor?.selection = null;
      unawaited(_saver.flush());
    }
    setState(() => _editing = !_editing);
  }

  /// Texto selecionado no editor, ou `null` se não há seleção.
  String? _selectedText() {
    final editor = _editor;
    final selection = editor?.selection;
    if (editor == null || selection == null || selection.isCollapsed) {
      return null;
    }
    final text = editor.getTextInSelection(selection).join('\n').trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _createCardFromSelection() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = _selectedText() ?? _lastSelectedText;
    if (text == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Selecione um trecho do texto primeiro.'),
          ),
        );
      return;
    }
    final side = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.cardFront),
              title: const Text('Usar como frente'),
              onTap: () => Navigator.of(context).pop('frente'),
            ),
            ListTile(
              leading: const Icon(AppIcons.cardBack),
              title: const Text('Usar como verso'),
              onTap: () => Navigator.of(context).pop('verso'),
            ),
          ],
        ),
      ),
    );
    if (side == null || !mounted) return;
    final book = await _repo.watchNotebook(_page!.notebookId).first;
    if (!mounted) return;
    final card = await showCardForm(
      context,
      taskId: book?.taskId,
      initialFront: side == 'frente' ? text : null,
      initialBack: side == 'verso' ? text : null,
    );
    if (card == null) return;
    await ref
        .read(cardsRepositoryProvider)
        .createCard(
          front: card.front,
          back: card.back,
          now: ref.read(clockProvider)(),
          deckId: card.deckId,
          taskId: card.taskId,
          sourcePageId: widget.pageId,
        );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Flashcard criado.')));
  }

  Future<void> _linkTask() async {
    final picked = await pickTask(
      context,
      current: null,
      title: 'Vincular a tarefa',
    );
    final taskId = picked?.id;
    if (taskId == null) return;
    await _repo.linkPage(taskId, widget.pageId);
  }

  /// Tema do editor alinhado ao app: corpo na serifada de leitura, títulos
  /// na escala do TextTheme, código em JetBrains Mono, seleção na cor de
  /// destaque.
  EditorStyle _style(BuildContext context) {
    final colors = context.colors;
    final reading = context.type.reading;
    return EditorStyle.mobile(
      padding: EdgeInsets.symmetric(horizontal: context.space.page),
      cursorColor: colors.primary,
      dragHandleColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.25),
      textStyleConfiguration: TextStyleConfiguration(
        text: reading,
        lineHeight: 1.6,
        code: context.type.code.copyWith(
          backgroundColor: colors.surfaceContainerHighest,
        ),
        href: TextStyle(
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
      ),
    );
  }

  Map<String, BlockComponentBuilder> _blocks(
    BuildContext context,
    Color bookColor,
  ) {
    final text = context.text;
    final onSurface = context.colors.onSurface;
    return {
      ...standardBlockComponentBuilderMap,
      ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
        configuration: BlockComponentConfiguration(
          placeholderText: (_) => _editing ? 'Escreva aqui…' : '',
        ),
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        textStyleBuilder: (level) => switch (level) {
          1 => text.headlineMedium!,
          2 => text.titleLarge!,
          3 => text.titleMedium!,
          _ => text.titleSmall!,
        }.copyWith(color: onSurface),
      ),
      // Citação com a barra lateral na cor do book.
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        iconBuilder: (context, node) => Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
          padding: EdgeInsets.only(right: context.space.sm),
          child: Container(width: 3, color: bookColor),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final editor = _editor;
    if (_missing) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: AppIcons.searchEmpty,
          message: 'Página não encontrada.',
        ),
      );
    }
    if (page == null || editor == null) {
      return Scaffold(appBar: AppBar(), body: const SkeletonPage());
    }

    final book = ref.watch(notebookProvider(page.notebookId)).value;
    final bookColor = context.palette
        .byName(book?.colorKey ?? defaultBookColor)
        .strong;
    final header = _Header(
      pageId: widget.pageId,
      title: _title,
      editing: _editing,
      onTitleChanged: (_) => _saver.schedule(),
    );
    // Largura de leitura limitada (~680 px) em telas largas.
    final appFlowy = _ReadingWidth(
      child: AppFlowyEditor(
        key: ValueKey('editor-$_editing'),
        editorState: editor,
        editorScrollController: _scroll,
        editable: _editing,
        // Leitura: sem teclado (tocar no texto não deve abrir o IME).
        disableKeyboardService: !_editing,
        // Página nova (aberta já em edição) começa com o cursor e o teclado.
        autoFocus: widget.startEditing && _editing,
        editorStyle: _style(context),
        blockComponentBuilders: _blocks(context, bookColor),
        header: header,
        footer: const SizedBox(height: 120),
      ),
    );

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _editing ? 'Modo leitura' : 'Editar',
            icon: Icon(_editing ? AppIcons.read : AppIcons.edit),
            onPressed: _toggleEditing,
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções da página',
            onSelected: (v) => switch (v) {
              'card' => _createCardFromSelection(),
              'vincular' => _linkTask(),
              'exportar' => _saver.flush().then((_) async {
                final fresh = await _repo.getPage(widget.pageId);
                if (fresh != null && context.mounted) {
                  await exportPageFlow(context, ref, fresh);
                }
              }),
              'excluir' => () {
                _saver.cancel();
                return deletePageFlow(context, ref, page, popAfter: true);
              }(),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'card',
                child: Text('Criar flashcard da seleção'),
              ),
              PopupMenuItem(
                value: 'vincular',
                child: Text('Vincular a tarefa'),
              ),
              PopupMenuItem(value: 'exportar', child: Text('Exportar (.md)')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir página')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _editing
            ? MobileToolbarV2(
                toolbarHeight: 48,
                editorState: editor,
                // Cores do tema (o padrão do pacote é sempre claro).
                backgroundColor: colors.surfaceContainer,
                foregroundColor: colors.onSurfaceVariant,
                iconColor: colors.onSurface,
                itemHighlightColor: colors.primary,
                itemOutlineColor: colors.outlineVariant,
                tabBarSelectedBackgroundColor: colors.secondaryContainer,
                tabBarSelectedForegroundColor: colors.onSecondaryContainer,
                primaryColor: colors.primary,
                onPrimaryColor: colors.onPrimary,
                outlineColor: colors.outlineVariant,
                toolbarItems: [
                  textDecorationMobileToolbarItemV2,
                  buildTextAndBackgroundColorMobileToolbarItem(),
                  blocksMobileToolbarItem,
                  linkMobileToolbarItem,
                  codeMobileToolbarItem,
                  dividerMobileToolbarItem,
                  tableMobileToolbarItem,
                  imageMobileToolbarItem,
                ],
                child: Column(
                  children: [
                    Expanded(
                      child: MobileFloatingToolbar(
                        editorState: editor,
                        editorScrollController: _scroll!,
                        floatingToolbarHeight: 32,
                        toolbarBuilder: (context, anchor, closeToolbar) =>
                            AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: TextSelectionToolbarAnchors(
                                primaryAnchor: anchor,
                              ),
                              buttonItems: [
                                ContextMenuButtonItem(
                                  label: 'Copiar',
                                  onPressed: () {
                                    copyCommand.execute(editor);
                                    closeToolbar();
                                  },
                                ),
                                ContextMenuButtonItem(
                                  label: 'Recortar',
                                  onPressed: () {
                                    cutCommand.execute(editor);
                                    closeToolbar();
                                  },
                                ),
                                ContextMenuButtonItem(
                                  label: 'Colar',
                                  onPressed: () {
                                    pasteCommand.execute(editor);
                                    closeToolbar();
                                  },
                                ),
                                ContextMenuButtonItem(
                                  label: 'Criar flashcard',
                                  onPressed: () {
                                    closeToolbar();
                                    _createCardFromSelection();
                                  },
                                ),
                              ],
                            ),
                        child: appFlowy,
                      ),
                    ),
                  ],
                ),
              )
            : appFlowy,
      ),
    );
  }
}

/// Título e tarefas vinculadas, acima do texto.
class _Header extends ConsumerWidget {
  const _Header({
    required this.pageId,
    required this.title,
    required this.editing,
    required this.onTitleChanged,
  });

  final String pageId;
  final TextEditingController title;
  final bool editing;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks =
        ref.watch(tasksOfPageProvider(pageId)).value ?? const <Task>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editing)
            TextField(
              controller: title,
              style: theme.textTheme.headlineSmall,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
              ),
              onChanged: onTitleChanged,
            )
          else
            Text(title.text, style: theme.textTheme.headlineSmall),
          if (tasks.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final task in tasks)
                  ActionChip(
                    avatar: const Icon(AppIcons.task, size: 18),
                    label: Text(task.title),
                    onPressed: () => context.push(Routes.task(task.id)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Centraliza o conteúdo com largura máxima de leitura.
class _ReadingWidth extends StatelessWidget {
  const _ReadingWidth({required this.child});

  static const maxWidth = 680.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
