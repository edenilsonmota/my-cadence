import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/theme_settings.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';

import '../../helpers/pump_app.dart';

MaterialApp currentApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  testWidgets(
    'Ajustes permite alternar Automático, Claro, Escuro e Lights out',
    (tester) async {
      final db = await pumpApp(tester);
      expect(currentApp(tester).themeMode, ThemeMode.system);
      expect(
        currentApp(tester).darkTheme!.colorScheme.surface,
        isNot(const Color(0xFF000000)),
      );

      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await settle(tester);
      await tester.tap(find.text('Ajustes'));
      await settle(tester);

      // Troca para Claro.
      await tester.tap(find.text('Claro'));
      await settle(tester);
      expect(currentApp(tester).themeMode, ThemeMode.light);

      // Troca para Escuro e ativa Lights out.
      await tester.tap(find.text('Escuro'));
      await settle(tester);
      expect(currentApp(tester).themeMode, ThemeMode.dark);

      await tester.tap(find.text('Lights out (alto contraste)'));
      await settle(tester);
      expect(
        currentApp(tester).darkTheme!.colorScheme.surface,
        const Color(0xFF000000),
      );

      final repo = SettingsRepository(db.settingsDao);
      expect(
        await tester.runAsync(() => repo.getString(themeModeSettingKey)),
        'dark',
      );
      expect(
        await tester.runAsync(() => repo.getString(lightsOutSettingKey)),
        'true',
      );
    },
  );

  testWidgets('reabre já com o tema e Lights out salvos no aparelho', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = SettingsRepository(db.settingsDao);
        await repo.setString(themeModeSettingKey, 'dark');
        await repo.setString(lightsOutSettingKey, 'true');
      },
    );

    final app = currentApp(tester);
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.colorScheme.surface, const Color(0xFF000000));
  });
}
