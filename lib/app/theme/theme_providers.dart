import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'theme_settings.dart';

/// Preferências iniciais carregadas antes da abertura do app (`main.dart` e
/// `pumpApp`), para evitar piscar o tema errado no primeiro quadro.
final initialThemeSettingsProvider = Provider<ThemeSettings>(
  (ref) => const ThemeSettings(),
);

final _themeSettingsStreamProvider = StreamProvider<ThemeSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchPrefix('device.')
      .map(ThemeSettings.fromMap),
);

/// Preferências reativas de tema (modo + Lights out).
final themeSettingsProvider = Provider<ThemeSettings>(
  (ref) =>
      ref.watch(_themeSettingsStreamProvider).value ??
      ref.watch(initialThemeSettingsProvider),
);

/// Converte [AppThemeMode] para o [ThemeMode] do MaterialApp.
extension AppThemeModeFlutter on AppThemeMode {
  ThemeMode get material => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
