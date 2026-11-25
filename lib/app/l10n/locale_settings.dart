/// Preferência de idioma do aparelho (`device.locale`). Puro, sem Flutter.
library;

/// Chave em `AppSettings` (prefixo `device.` → fica só neste aparelho).
const appLocaleSettingKey = 'device.locale';

/// Idioma escolhido pelo usuário.
enum AppLocale {
  system('Automático'),
  pt('Português (Brasil)'),
  en('English'),
  es('Español');

  const AppLocale(this.nativeLabel);

  /// Nome no próprio idioma (para sempre ser reconhecível no seletor).
  final String nativeLabel;
}

/// Interpreta o valor salvo; desconhecido ou nulo volta para [AppLocale.system].
AppLocale parseAppLocale(String? raw) =>
    AppLocale.values.asNameMap()[raw?.trim()] ?? AppLocale.system;

/// Código do idioma efetivo (`pt`, `en` ou `es`). Em [AppLocale.system], usa
/// o idioma do aparelho ([systemCode]); fora dos três, português.
String resolveLangCode(AppLocale locale, {required String systemCode}) {
  final code = switch (locale) {
    AppLocale.pt => 'pt',
    AppLocale.en => 'en',
    AppLocale.es => 'es',
    AppLocale.system => systemCode,
  };
  return switch (code) {
    'en' => 'en',
    'es' => 'es',
    _ => 'pt',
  };
}
