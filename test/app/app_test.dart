import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/app.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // Largura mínima suportada pelo app (360 dp).
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: CadenceApp()));
  await tester.pumpAndSettle();
}

Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  testWidgets('abre na aba Hoje com as 5 abas', (tester) async {
    await pumpApp(tester);

    expect(appBarTitle('Hoje'), findsOneWidget);
    for (final label in ['Hoje', 'Tarefas', 'Agenda', 'Revisar', 'Books']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('troca de aba pela barra de navegação', (tester) async {
    await pumpApp(tester);

    for (final label in ['Tarefas', 'Agenda', 'Revisar', 'Books', 'Hoje']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(appBarTitle(label), findsOneWidget);
    }
  });

  testWidgets('menu lateral abre Métricas e Ajustes', (tester) async {
    await pumpApp(tester);

    for (final label in ['Métricas', 'Ajustes']) {
      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(appBarTitle(label), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(appBarTitle('Hoje'), findsOneWidget);
    }
  });

  testWidgets('usa pt_BR e tem tema claro e escuro', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('pt', 'BR'));
    expect(app.theme!.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme!.colorScheme.brightness, Brightness.dark);
  });
}
