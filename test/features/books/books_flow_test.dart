import 'dart:typed_data';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/books/book_actions.dart';
import 'package:my_cadence/features/books/book_markdown.dart';

import '../../helpers/pump_app.dart';

BooksRepository booksOf(AppDatabase db) => BooksRepository(db.booksDao);

Future<void> goToBooks(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Books'),
    ),
  );
  await settle(tester);
}

Future<List<NotePage>> pagesIn(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.notePages).get()))!
        .where((p) => p.deletedAt == null)
        .toList();

EditorState editorOf(WidgetTester tester) =>
    tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;

void main() {
  testWidgets('cria book e página; título e texto salvam sozinhos', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await goToBooks(tester);
    expect(
      find.text('Nenhum book criado.\nCrie um no + ou importe arquivos .md.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Novo book'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Cálculo');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);
    expect(find.text('Cálculo'), findsOneWidget); // abriu o book

    await tester.tap(find.byTooltip('Nova página'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Derivadas');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);

    // Editor aberto em modo edição, com o título.
    expect(find.byType(AppFlowyEditor), findsOneWidget);
    expect(find.byTooltip('Modo leitura'), findsOneWidget);

    // Muda o título e escreve no editor.
    await tester.enterText(
      find.widgetWithText(TextField, 'Derivadas'),
      'Regras',
    );
    final editor = editorOf(tester);
    final node = editor.document.root.children.first;
    await editor.apply(
      editor.transaction..insertText(node, 0, 'Regra da cadeia'),
    );
    await tester.pump(const Duration(milliseconds: 900)); // debounce
    await settle(tester);

    final page = (await pagesIn(tester, db)).single;
    expect(page.title, 'Regras');
    expect(
      documentFromContent(page.content).root.children.first.delta!
          .toPlainText(),
      'Regra da cadeia',
    );
  });

  testWidgets('modo leitura mostra o conteúdo; sair salva o pendente', (
    tester,
  ) async {
    late String pageId;
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final books = booksOf(db);
        final book = await books.createBook(title: 'Física');
        pageId = await books.createPage(
          notebookId: book,
          title: 'Leis de Newton',
          content: contentFromDocument(
            markdownToDocument('Primeira **lei**\n\n- inércia'),
          ),
        );
      },
    );
    await goToBooks(tester);
    await tester.tap(find.text('Física'));
    await settle(tester);
    await tester.tap(find.text('Leis de Newton'));
    await settle(tester);

    // Abre em leitura, com o texto renderizado.
    expect(find.byTooltip('Editar'), findsOneWidget);
    expect(find.textContaining('Primeira', findRichText: true), findsWidgets);
    expect(find.textContaining('inércia', findRichText: true), findsWidgets);

    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);
    final editor = editorOf(tester);
    final node = editor.document.root.children.first;
    await editor.apply(editor.transaction..insertText(node, 0, 'A '));
    // Sai antes dos 800 ms: o dispose salva.
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);

    final page = (await pagesIn(tester, db)).firstWhere((p) => p.id == pageId);
    expect(
      documentFromContent(page.content).root.children.first.delta!
          .toPlainText(),
      'A Primeira lei',
    );
  });

  testWidgets('seleção vira frente de um flashcard ligado à página', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final books = booksOf(db);
        final book = await books.createBook(title: 'Bio');
        await books.createPage(
          notebookId: book,
          title: 'Célula',
          content: contentFromDocument(
            markdownToDocument('Mitocôndria gera energia'),
          ),
        );
      },
    );
    await goToBooks(tester);
    await tester.tap(find.text('Bio'));
    await settle(tester);
    await tester.tap(find.text('Célula'));
    await settle(tester);

    final editor = editorOf(tester);
    editor.selection = Selection(
      start: Position(path: [0], offset: 0),
      end: Position(path: [0], offset: 11),
    );
    await tester.tap(find.byTooltip('Opções da página'));
    await settle(tester);
    await tester.tap(find.text('Criar flashcard da seleção'));
    await settle(tester);
    await tester.tap(find.text('Usar como frente'));
    await settle(tester);

    expect(find.widgetWithText(TextField, 'Mitocôndria'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Verso'), 'Organela');
    await settle(tester);
    await tester.tap(find.text('Salvar card'));
    await settle(tester);

    final card = (await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchCards().first,
    ))!.single;
    final page = (await pagesIn(tester, db)).single;
    expect(card.front, 'Mitocôndria');
    expect(card.back, 'Organela');
    expect(card.sourcePageId, page.id);
  });

  testWidgets('sem seleção, criar flashcard avisa', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final books = booksOf(db);
        final book = await books.createBook(title: 'Bio');
        await books.createPage(notebookId: book, title: 'Célula');
      },
    );
    await goToBooks(tester);
    await tester.tap(find.text('Bio'));
    await settle(tester);
    await tester.tap(find.text('Célula'));
    await settle(tester);
    await tester.tap(find.byTooltip('Opções da página'));
    await settle(tester);
    await tester.tap(find.text('Criar flashcard da seleção'));
    await settle(tester);
    expect(find.text('Selecione um trecho do texto primeiro.'), findsOneWidget);
  });

  testWidgets('vincula a página a uma tarefa e mostra a tarefa na página', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await TasksRepository(
          db.tasksDao,
          db.tagsDao,
        ).createTask(title: 'Prova');
        final books = booksOf(db);
        final book = await books.createBook(title: 'Bio');
        await books.createPage(notebookId: book, title: 'Célula');
      },
    );
    await goToBooks(tester);
    await tester.tap(find.text('Bio'));
    await settle(tester);
    await tester.tap(find.text('Célula'));
    await settle(tester);
    await tester.tap(find.byTooltip('Opções da página'));
    await settle(tester);
    await tester.tap(find.text('Vincular a tarefa'));
    await settle(tester);
    await tester.tap(find.text('Prova'));
    await settle(tester);

    expect(find.widgetWithText(ActionChip, 'Prova'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Prova'));
    await settle(tester);
    expect(find.text('Tarefa'), findsOneWidget); // hub da tarefa
  });

  testWidgets('subpágina, mover para cima e exportar/reimportar o book', (
    tester,
  ) async {
    Uint8List? saved;
    String? savedName;
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final books = booksOf(db);
        final book = await books.createBook(title: 'Notas');
        await books.createPage(
          notebookId: book,
          title: 'Primeira',
          sortOrder: 0,
        );
        await books.createPage(
          notebookId: book,
          title: 'Segunda',
          sortOrder: 1,
          content: contentFromDocument(markdownToDocument('P1\n\nP2')),
        );
      },
      overrides: [
        fileSaverProvider.overrideWithValue((name, bytes) async {
          savedName = name;
          saved = bytes;
          return true;
        }),
      ],
    );
    await goToBooks(tester);
    await tester.tap(find.text('Notas'));
    await settle(tester);

    // "Segunda" sobe para o topo.
    await tester.tap(find.byTooltip('Opções da página').at(1));
    await settle(tester);
    await tester.tap(find.text('Mover para cima'));
    await settle(tester);
    // Subpágina em "Segunda" (agora a primeira da lista).
    await tester.tap(find.byTooltip('Opções da página').first);
    await settle(tester);
    await tester.tap(find.text('Nova subpágina'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Detalhe');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);

    final titles = [
      for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
        if (t.title case Text(:final data?)) data,
    ];
    expect(titles, ['Segunda', 'Detalhe', 'Primeira']);

    // Exporta o book.
    await tester.tap(find.byTooltip('Opções do book'));
    await settle(tester);
    await tester.tap(find.text('Exportar (.zip)'));
    await settle(tester);
    expect(savedName, 'Notas.zip');
    expect(markdownFilesFromZip(saved!).keys, [
      '01 - Segunda.md',
      '01.01 - Detalhe.md',
      '02 - Primeira.md',
    ]);
    expect(
      markdownFilesFromZip(saved!)['01 - Segunda.md'],
      '# Segunda\n\nP1\n\nP2\n',
    );
    expect(find.text('Book exportado (3 páginas).'), findsOneWidget);

    // Reimporta pela aba Books (o zip vira um book novo).
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    final pages = await pagesIn(tester, db);
    expect(pages, hasLength(3));
  });

  testWidgets('importa zip exportado como book novo, com a mesma árvore', (
    tester,
  ) async {
    final source = [
      NotePage(
        id: 'a',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        dirty: true,
        notebookId: 'x',
        title: 'Capítulo 1',
        content: contentFromDocument(markdownToDocument('Texto **um**')),
        sortOrder: 0,
      ),
      NotePage(
        id: 'b',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        dirty: true,
        notebookId: 'x',
        parentPageId: 'a',
        title: 'Seção 1.1',
        content: contentFromDocument(markdownToDocument('- item')),
        sortOrder: 0,
      ),
    ];
    final db = await pumpApp(
      tester,
      overrides: [
        importFilesPickerProvider.overrideWithValue(
          () async => [(name: 'Livro.zip', bytes: bookZip(source))],
        ),
      ],
    );
    await goToBooks(tester);
    await tester.tap(find.byTooltip('Importar Markdown'));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Livro'), findsOneWidget);
    await tester.tap(find.text('Importar'));
    await settle(tester);

    expect(find.text('2 páginas importadas.'), findsOneWidget);
    expect(find.text('Capítulo 1'), findsOneWidget);
    expect(find.text('Seção 1.1'), findsOneWidget);

    final pages = await pagesIn(tester, db);
    final chapter = pages.firstWhere((p) => p.title == 'Capítulo 1');
    final section = pages.firstWhere((p) => p.title == 'Seção 1.1');
    expect(section.parentPageId, chapter.id);
    expect(chapter.content, source[0].content);
    expect(section.content, source[1].content);
  });
}
