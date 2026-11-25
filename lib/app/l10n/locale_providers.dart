import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'locale_settings.dart';

/// Idioma inicial carregado antes da abertura do app (`main.dart` e `pumpApp`).
final initialLocaleProvider = Provider<AppLocale>((ref) => AppLocale.system);

final _appLocaleStreamProvider = StreamProvider<AppLocale?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchString(appLocaleSettingKey)
      .map((raw) => raw == null ? null : parseAppLocale(raw)),
);

/// Idioma reativo escolhido no aparelho.
final appLocaleProvider = Provider<AppLocale>(
  (ref) =>
      ref.watch(_appLocaleStreamProvider).value ??
      ref.watch(initialLocaleProvider),
);

/// Conversão para o [Locale] do `MaterialApp`.
extension AppLocaleFlutter on AppLocale {
  Locale? get materialLocale => switch (this) {
    AppLocale.system => null,
    AppLocale.pt => const Locale('pt', 'BR'),
    AppLocale.en => const Locale('en'),
    AppLocale.es => const Locale('es'),
  };
}
