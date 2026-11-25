/// Preferências de aparência do aparelho (modo de tema, cor de destaque e
/// Lights out). Puro, sem Flutter.
library;

/// Chaves em `AppSettings` (prefixo `device.` → ficam só neste aparelho).
const themeModeSettingKey = 'device.themeMode';
const accentColorSettingKey = 'device.accentColor';
const lightsOutSettingKey = 'device.lightsOut';

/// Modo de tema escolhido pelo usuário.
enum AppThemeMode {
  system('Automático'),
  light('Claro'),
  dark('Escuro');

  const AppThemeMode(this.label);

  final String label;
}

/// Cores de destaque disponíveis para botões, abas ativas e interruptores.
enum AppAccentColor {
  azul('Azul', 0xFF1D9BF0),
  amarelo('Amarelo', 0xFFEAB308),
  rosa('Rosa', 0xFFF91880),
  violeta('Violeta', 0xFF7856FF),
  laranja('Laranja', 0xFFFF7A00),
  verde('Verde', 0xFF00BA7C);

  const AppAccentColor(this.label, this.argb);

  final String label;
  final int argb;
}

/// Preferências atuais de tema do aparelho.
class ThemeSettings {
  const ThemeSettings({
    this.mode = AppThemeMode.system,
    this.accent = AppAccentColor.azul,
    this.lightsOut = false,
  });

  factory ThemeSettings.fromMap(Map<String, String> map) => ThemeSettings(
    mode: parseThemeMode(map[themeModeSettingKey]),
    accent: parseAccentColor(map[accentColorSettingKey]),
    lightsOut: parseLightsOut(map[lightsOutSettingKey]),
  );

  final AppThemeMode mode;

  /// Cor de destaque de botões, FAB, aba ativa e interruptores.
  final AppAccentColor accent;

  /// Preto puro (OLED) e alto contraste no modo escuro.
  final bool lightsOut;

  static AppThemeMode parseThemeMode(String? raw) =>
      AppThemeMode.values.asNameMap()[raw?.trim()] ?? AppThemeMode.system;

  static AppAccentColor parseAccentColor(String? raw) =>
      AppAccentColor.values.asNameMap()[raw?.trim()] ?? AppAccentColor.azul;

  static bool parseLightsOut(String? raw) => raw?.trim() == 'true';

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.mode == mode &&
      other.accent == accent &&
      other.lightsOut == lightsOut;

  @override
  int get hashCode => Object.hash(mode, accent, lightsOut);
}
