/// Preferências de aparência do aparelho (modo de tema e Lights out). Puro,
/// sem Flutter.
library;

/// Chaves em `AppSettings` (prefixo `device.` → ficam só neste aparelho).
const themeModeSettingKey = 'device.themeMode';
const lightsOutSettingKey = 'device.lightsOut';

/// Modo de tema escolhido pelo usuário.
enum AppThemeMode {
  system('Automático'),
  light('Claro'),
  dark('Escuro');

  const AppThemeMode(this.label);

  final String label;
}

/// Preferências atuais de tema do aparelho.
class ThemeSettings {
  const ThemeSettings({
    this.mode = AppThemeMode.system,
    this.lightsOut = false,
  });

  factory ThemeSettings.fromMap(Map<String, String> map) => ThemeSettings(
    mode: parseThemeMode(map[themeModeSettingKey]),
    lightsOut: parseLightsOut(map[lightsOutSettingKey]),
  );

  final AppThemeMode mode;

  /// Preto puro (OLED) e alto contraste no modo escuro.
  final bool lightsOut;

  static AppThemeMode parseThemeMode(String? raw) =>
      AppThemeMode.values.asNameMap()[raw?.trim()] ?? AppThemeMode.system;

  static bool parseLightsOut(String? raw) => raw?.trim() == 'true';

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.mode == mode &&
      other.lightsOut == lightsOut;

  @override
  int get hashCode => Object.hash(mode, lightsOut);
}
