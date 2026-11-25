import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/theme_settings.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';

void main() {
  test('padrão é automático, azul, sem lights out e ajustes são locais', () {
    const defaults = ThemeSettings();
    expect(defaults.mode, AppThemeMode.system);
    expect(defaults.accent, AppAccentColor.azul);
    expect(defaults.lightsOut, isFalse);
    expect(isLocalSetting(themeModeSettingKey), isTrue);
    expect(isLocalSetting(accentColorSettingKey), isTrue);
    expect(isLocalSetting(lightsOutSettingKey), isTrue);
  });

  test(
    'fromMap interpreta modo, cor e lights out e ignora valores inválidos',
    () {
      expect(ThemeSettings.fromMap(const {}), const ThemeSettings());
      expect(
        ThemeSettings.fromMap({
          themeModeSettingKey: 'dark',
          accentColorSettingKey: 'rosa',
          lightsOutSettingKey: 'true',
        }),
        const ThemeSettings(
          mode: AppThemeMode.dark,
          accent: AppAccentColor.rosa,
          lightsOut: true,
        ),
      );
      expect(
        ThemeSettings.fromMap({
          themeModeSettingKey: 'light',
          accentColorSettingKey: 'violeta',
          lightsOutSettingKey: 'false',
        }),
        const ThemeSettings(
          mode: AppThemeMode.light,
          accent: AppAccentColor.violeta,
        ),
      );
      expect(
        ThemeSettings.fromMap({
          themeModeSettingKey: 'invalido',
          accentColorSettingKey: 'desconhecida',
          lightsOutSettingKey: 'sim',
        }),
        const ThemeSettings(),
      );
    },
  );
}
