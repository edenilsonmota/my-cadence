import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/theme_settings.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';

void main() {
  test(
    'padrão é automático sem lights out e ajustes são locais do aparelho',
    () {
      const defaults = ThemeSettings();
      expect(defaults.mode, AppThemeMode.system);
      expect(defaults.lightsOut, isFalse);
      expect(isLocalSetting(themeModeSettingKey), isTrue);
      expect(isLocalSetting(lightsOutSettingKey), isTrue);
    },
  );

  test('fromMap interpreta modo e lights out e ignora valores inválidos', () {
    expect(ThemeSettings.fromMap(const {}), const ThemeSettings());
    expect(
      ThemeSettings.fromMap({
        themeModeSettingKey: 'dark',
        lightsOutSettingKey: 'true',
      }),
      const ThemeSettings(mode: AppThemeMode.dark, lightsOut: true),
    );
    expect(
      ThemeSettings.fromMap({
        themeModeSettingKey: 'light',
        lightsOutSettingKey: 'false',
      }),
      const ThemeSettings(mode: AppThemeMode.light),
    );
    expect(
      ThemeSettings.fromMap({
        themeModeSettingKey: 'invalido',
        lightsOutSettingKey: 'sim',
      }),
      const ThemeSettings(),
    );
  });
}
