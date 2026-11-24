import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';

import '../../helpers/pump_app.dart';

Future<Task> taskNamed(WidgetTester tester, AppDatabase db, String t) async =>
    (await tester.runAsync(
      () => (db.select(db.tasks)..where((x) => x.title.equals(t))).getSingle(),
    ))!;

/// A lista da folha do seletor (a do formulário fica atrás).
Finder sheetList() => find
    .descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable))
    .first;

void main() {
  testWidgets('formulário escolhe ícone e cor; "Usar padrão" volta à herança', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Ler');
    await settle(tester);
    await tester.dragUntilVisible(
      find.text('Padrão'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    await tester.tap(find.text('Padrão'));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Rosa'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar ícone'),
      'cerebro',
    );
    await settle(tester);
    await tester.tap(find.byTooltip('cérebro'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Aplicar'),
      200,
      scrollable: sheetList(),
    );
    await tester.tap(find.text('Aplicar'));
    await settle(tester);
    expect(find.text('Personalizado'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await settle(tester);
    var task = await taskNamed(tester, db, 'Ler');
    expect((task.colorKey, task.iconKey), ('rosa', 'brain'));

    // Editar e voltar ao padrão.
    await tester.tap(find.text('Ler'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);
    await tester.dragUntilVisible(
      find.text('Personalizado'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    await tester.tap(find.text('Personalizado'));
    await settle(tester);
    await tester.tap(find.text('Usar padrão'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Aplicar'),
      200,
      scrollable: sheetList(),
    );
    await tester.tap(find.text('Aplicar'));
    await settle(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    task = await taskNamed(tester, db, 'Ler');
    expect((task.colorKey, task.iconKey), (null, null));
  });

  testWidgets('book ganha ícone e cor pelo menu', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => BooksRepository(db.booksDao).createBook(title: 'Física'),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Books'),
      ),
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Opções do book'));
    await settle(tester);
    await tester.tap(find.text('Ícone e cor'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Verde'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar ícone'),
      'ciencia',
    );
    await settle(tester);
    await tester.tap(find.byTooltip('microscópio'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Aplicar'),
      200,
      scrollable: sheetList(),
    );
    await tester.tap(find.text('Aplicar'));
    await settle(tester);

    final book = (await tester.runAsync(
      () => db.select(db.notebooks).getSingle(),
    ))!;
    expect((book.colorKey, book.iconKey), ('verde', 'microscope'));
  });
}
