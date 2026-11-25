import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/app_theme.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';

import '../../helpers/pump_app.dart';

MaterialApp currentApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  testWidgets(
    'Ajustes permite alternar Automático, Claro, Escuro, Cor e Lights out',
    (tester) async {
      final db = await pumpApp(tester);
      expect(currentApp(tester).themeMode, ThemeMode.system);
      expect(
        currentApp(tester).darkTheme!.colorScheme.surface,
        isNot(const Color(0xFF000000)),
      );
      final initialPrimary = currentApp(tester).darkTheme!.colorScheme.primary;

      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await settle(tester);
      await tester.tap(find.text('Ajustes'));
      await settle(tester);

      // Troca para Claro.
      await tester.tap(find.text('Claro'));
      await settle(tester);
      expect(currentApp(tester).themeMode, ThemeMode.light);

      // Troca a cor de destaque para Rosa.
      await tester.tap(find.byTooltip('Rosa'));
      await settle(tester);
      expect(
        currentApp(tester).darkTheme!.colorScheme.primary,
        isNot(initialPrimary),
      );
      expect(
        currentApp(tester).darkTheme!.colorScheme.primary,
        buildTheme(
          Brightness.dark,
          accent: AppAccentColor.rosa,
        ).colorScheme.primary,
      );

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
        await tester.runAsync(() => repo.getString(accentColorSettingKey)),
        'rosa',
      );
      expect(
        await tester.runAsync(() => repo.getString(lightsOutSettingKey)),
        'true',
      );
    },
  );

  testWidgets('reabre já com o tema, cor e Lights out salvos no aparelho', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = SettingsRepository(db.settingsDao);
        await repo.setString(themeModeSettingKey, 'dark');
        await repo.setString(accentColorSettingKey, 'violeta');
        await repo.setString(lightsOutSettingKey, 'true');
      },
    );

    final app = currentApp(tester);
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.colorScheme.surface, const Color(0xFF000000));
    expect(
      app.darkTheme!.colorScheme.primary,
      buildTheme(
        Brightness.dark,
        accent: AppAccentColor.violeta,
        lightsOut: true,
      ).colorScheme.primary,
    );
  });
}
