import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/l10n/locale_settings.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';

import '../../helpers/pump_app.dart';

MaterialApp _currentApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  testWidgets(
    'Ajustes permite trocar idioma ao vivo entre Português, English e Español',
    (tester) async {
      final db = await pumpApp(tester);
      expect(_currentApp(tester).locale, const Locale('pt', 'BR'));

      // Abre Ajustes pelo menu lateral.
      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await settle(tester);
      await tester.tap(find.text('Ajustes'));
      await settle(tester);

      // Troca para English.
      await tester.tap(find.text('Idioma'));
      await settle(tester);
      await tester.tap(find.text('English'));
      await settle(tester);

      expect(_currentApp(tester).locale, const Locale('en'));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Navigation bar'), findsOneWidget);

      // Troca para Español.
      await tester.tap(find.text('Language'));
      await settle(tester);
      await tester.tap(find.text('Español'));
      await settle(tester);

      expect(_currentApp(tester).locale, const Locale('es'));
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('APARIENCIA'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Barra de navegación'), findsOneWidget);

      // Confere persistência em device.locale.
      final repo = SettingsRepository(db.settingsDao);
      expect(
        await tester.runAsync(() => repo.getString(appLocaleSettingKey)),
        'es',
      );

      // Volta para a tela inicial (também confirma Material em espanhol) e
      // verifica tradução da barra e da aba Hoje.
      await tester.tap(find.byTooltip('Atrás'));
      await settle(tester);
      expect(find.text('Hoy'), findsWidgets);
      expect(find.text('Tareas'), findsOneWidget);
      expect(find.text('Nada para hoy todavía.'), findsOneWidget);
    },
  );

  testWidgets('reabre já no idioma salvo no aparelho', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await SettingsRepository(db.settingsDao)
            .setString(appLocaleSettingKey, 'en');
      },
    );

    expect(_currentApp(tester).locale, const Locale('en'));
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Nothing for today yet.'), findsOneWidget);
  });
}
