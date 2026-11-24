import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../data/repositories/books_repository.dart';
import '../../shared/widgets/appearance_picker.dart';
import '../../shared/widgets/text_input_dialog.dart';
import 'book_markdown.dart';

typedef PickedFile = ({String name, Uint8List bytes});

/// Escolhe arquivos para importar (Markdown, texto ou zip). Os testes trocam
/// por arquivos fixos.
final importFilesPickerProvider = Provider<Future<List<PickedFile>> Function()>(
  (ref) => () async {
    // FileType.any: no Android, ".md" nem sempre tem tipo MIME conhecido.
    final files = await FilePicker.pickFiles();
    return [
      for (final f in files) (name: f.name, bytes: await f.xFile.readAsBytes()),
    ];
  },
);

/// Salva um arquivo onde o usuário escolher. Devolve se salvou.
final fileSaverProvider =
    Provider<Future<bool> Function(String fileName, Uint8List bytes)>(
      (ref) =>
          (fileName, bytes) async =>
              await FilePicker.saveFile(fileName: fileName, bytes: bytes) !=
              null,
    );

void _snack(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

// ─── Books ───────────────────────────────────────────────────────────────────

Future<void> createBookFlow(BuildContext context, WidgetRef ref) async {
  final title = await showTextInputDialog(
    context,
    title: 'Novo book',
    label: 'Título',
  );
  if (title == null) return;
  final id = await ref.read(booksRepositoryProvider).createBook(title: title);
  if (context.mounted) await context.push(Routes.book(id));
}

Future<void> renameBookFlow(
  BuildContext context,
  WidgetRef ref,
  Notebook book,
) async {
  final title = await showTextInputDialog(
    context,
    title: 'Renomear book',
    label: 'Título',
    confirmLabel: 'Salvar',
    initialValue: book.title,
  );
  if (title == null) return;
  await ref
      .read(booksRepositoryProvider)
      .saveNotebook(book.copyWith(title: title));
}

/// Cor padrão dos books (sem cor própria).
const defaultBookColor = 'ardosia';

/// Ícone do book: o do catálogo, ou o ícone de book.
IconData bookIcon(Notebook book) =>
    AppIcons.of(book.iconKey, fallback: AppIcons.book);

Future<void> pickBookIconFlow(
  BuildContext context,
  WidgetRef ref,
  Notebook book,
) async {
  final choice = await showAppearancePicker(
    context,
    colorKey: book.colorKey,
    iconKey: book.iconKey,
    inheritedColor: defaultBookColor,
    inheritedIcon: AppIcons.book,
  );
  if (choice == null) return;
  await ref
      .read(booksRepositoryProvider)
      .saveNotebook(
        book.copyWith(
          colorKey: Value(choice.colorKey),
          iconKey: Value(choice.iconKey),
        ),
      );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ==
    true;

Future<void> exportBookFlow(
  BuildContext context,
  WidgetRef ref,
  Notebook book,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final pages = await ref
      .read(booksRepositoryProvider)
      .watchPages(book.id)
      .first;
  final saved = await ref.read(fileSaverProvider)(
    '${safeFileName(book.title)}.zip',
    bookZip(pages),
  );
  if (saved) _snack(messenger, 'Book exportado (${pages.length} páginas).');
}

// ─── Importar ────────────────────────────────────────────────────────────────

/// Cria as páginas importadas (e subpáginas) no caderno.
Future<int> _createPages(
  BooksRepository repo,
  String notebookId,
  List<ImportedPage> pages, {
  String? parentId,
  int firstOrder = 0,
}) async {
  var count = 0;
  for (final (index, page) in pages.indexed) {
    final id = await repo.createPage(
      notebookId: notebookId,
      title: page.title,
      content: page.content,
      parentPageId: parentId,
      sortOrder: firstOrder + index,
    );
    count++;
    count += await _createPages(repo, notebookId, page.children, parentId: id);
  }
  return count;
}

Map<String, String> _markdownFiles(List<PickedFile> files) {
  final out = <String, String>{};
  for (final file in files) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.zip')) {
      out.addAll(markdownFilesFromZip(file.bytes));
    } else if (name.endsWith('.md') ||
        name.endsWith('.markdown') ||
        name.endsWith('.txt')) {
      out[file.name] = utf8.decode(file.bytes, allowMalformed: true);
    }
  }
  return out;
}

String _withoutExtension(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

/// Na lista de books: um zip ou vários arquivos viram um book novo; um
/// arquivo só vira um book com uma página.
Future<void> importBookFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final files = await ref.read(importFilesPickerProvider)();
  if (files.isEmpty) return;
  final markdown = _markdownFiles(files);
  if (markdown.isEmpty) {
    _snack(messenger, 'Nenhum arquivo .md encontrado.');
    return;
  }
  final pages = importBookPages(markdown);
  final suggested = files.length == 1
      ? _withoutExtension(files.single.name)
      : 'Importado';
  if (!context.mounted) return;
  final title = await showTextInputDialog(
    context,
    title: 'Importar como book',
    label: 'Título do book',
    confirmLabel: 'Importar',
    initialValue: suggested,
  );
  if (title == null) return;
  final repo = ref.read(booksRepositoryProvider);
  final (bookId, count) = await repo.transaction(() async {
    final bookId = await repo.createBook(title: title);
    return (bookId, await _createPages(repo, bookId, pages));
  });
  _snack(
    messenger,
    '$count ${count == 1 ? 'página importada' : 'páginas importadas'}.',
  );
  if (context.mounted) await context.push(Routes.book(bookId));
}

/// Dentro de um book: cada arquivo vira uma página (o zip mantém a árvore).
Future<void> importPagesFlow(
  BuildContext context,
  WidgetRef ref,
  String notebookId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final files = await ref.read(importFilesPickerProvider)();
  if (files.isEmpty) return;
  final markdown = _markdownFiles(files);
  if (markdown.isEmpty) {
    _snack(messenger, 'Nenhum arquivo .md encontrado.');
    return;
  }
  final repo = ref.read(booksRepositoryProvider);
  final existing = await repo.watchPages(notebookId).first;
  final roots = existing.where((p) => p.parentPageId == null).length;
  final count = await repo.transaction(
    () => _createPages(
      repo,
      notebookId,
      importBookPages(markdown),
      firstOrder: roots,
    ),
  );
  _snack(
    messenger,
    '$count ${count == 1 ? 'página importada' : 'páginas importadas'}.',
  );
}

// ─── Páginas ─────────────────────────────────────────────────────────────────

Future<void> createPageFlow(
  BuildContext context,
  WidgetRef ref, {
  required String notebookId,
  String? parentId,
}) async {
  final title = await showTextInputDialog(
    context,
    title: parentId == null ? 'Nova página' : 'Nova subpágina',
    label: 'Título',
  );
  if (title == null) return;
  final repo = ref.read(booksRepositoryProvider);
  final pages = await repo.watchPages(notebookId).first;
  final id = await repo.createPage(
    notebookId: notebookId,
    title: title,
    parentPageId: parentId,
    sortOrder: pages.where((p) => p.parentPageId == parentId).length,
  );
  if (context.mounted) await context.push(Routes.page(id, edit: true));
}

Future<void> renamePageFlow(
  BuildContext context,
  WidgetRef ref,
  NotePage page,
) async {
  final title = await showTextInputDialog(
    context,
    title: 'Renomear página',
    label: 'Título',
    confirmLabel: 'Salvar',
    initialValue: page.title,
  );
  if (title == null) return;
  await ref.read(booksRepositoryProvider).savePage(page.copyWith(title: title));
}

/// Sobe (`-1`) ou desce (`+1`) a página entre as irmãs.
Future<void> movePage(
  WidgetRef ref,
  NotePage page,
  List<NotePage> allPages,
  int delta,
) async {
  final siblings = siblingsOf(page, allPages);
  final from = siblings.indexWhere((p) => p.id == page.id);
  final to = from + delta;
  if (from < 0 || to < 0 || to >= siblings.length) return;
  final moved = siblings.removeAt(from);
  siblings.insert(to, moved);
  await ref.read(booksRepositoryProvider).reorderPages([
    for (final p in siblings) p.id,
  ]);
}

Future<void> deletePageFlow(
  BuildContext context,
  WidgetRef ref,
  NotePage page, {
  bool popAfter = false,
}) async {
  final ok = await confirmDelete(
    context,
    title: 'Excluir "${page.title}"?',
    message: 'As subpáginas também serão excluídas.',
  );
  if (!ok || !context.mounted) return;
  if (popAfter) Navigator.of(context).pop();
  await ref.read(booksRepositoryProvider).deletePage(page.id);
}

Future<void> exportPageFlow(
  BuildContext context,
  WidgetRef ref,
  NotePage page,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await ref.read(fileSaverProvider)(
    '${safeFileName(page.title)}.md',
    Uint8List.fromList(utf8.encode(pageToMarkdown(page.title, page.content))),
  );
  if (saved) _snack(messenger, 'Página exportada.');
}
