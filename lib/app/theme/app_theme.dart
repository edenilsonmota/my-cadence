import 'package:flutter/material.dart';

import 'components.dart';
import 'palette.dart';
import 'tokens.dart';
import 'typography.dart';

export 'app_icons.dart';
export 'icon_catalog.dart';
export 'palette.dart';
export 'theme_settings.dart';
export 'tokens.dart';
export 'typography.dart';

/// Cor de marca (a semente do esquema de cores).
const brandSeed = Color(0xFF00796B);

/// Constrói o tema claro, escuro ou escuro "Lights out" (preto puro OLED com
/// alto contraste).
ThemeData buildTheme(Brightness brightness, {bool lightsOut = false}) {
  final highContrastDark = brightness == Brightness.dark && lightsOut;
  final generated = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: brightness,
    contrastLevel: highContrastDark ? 1.0 : 0.0,
  );
  final scheme = highContrastDark
      ? generated.copyWith(
          surface: const Color(0xFF000000),
          surfaceDim: const Color(0xFF000000),
          surfaceBright: const Color(0xFF1F2322),
          surfaceContainerLowest: const Color(0xFF000000),
          surfaceContainerLow: const Color(0xFF0A0A0A),
          surfaceContainer: const Color(0xFF121212),
          surfaceContainerHigh: const Color(0xFF1A1A1A),
          surfaceContainerHighest: const Color(0xFF242424),
          onSurface: const Color(0xFFFFFFFF),
          onSurfaceVariant: const Color(0xFFD2D8D6),
          outline: const Color(0xFF8C9491),
          outlineVariant: const Color(0xFF343B38),
        )
      : generated;
  final base = ThemeData(colorScheme: scheme, fontFamily: AppFonts.ui);
  final typed = base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.merge(buildTextTheme()),
    extensions: [
      const AppSpacing(),
      const AppRadius(),
      const AppMotion(),
      AppPalette.of(brightness, lightsOut: highContrastDark),
      AppTypography(color: scheme.onSurface, muted: scheme.onSurfaceVariant),
    ],
  );
  return applyComponentThemes(typed);
}

/// Atalhos para os tokens: `context.space.md`, `context.palette.of(...)`.
extension ThemeTokens on BuildContext {
  AppSpacing get space => Theme.of(this).extension<AppSpacing>()!;
  AppRadius get radius => Theme.of(this).extension<AppRadius>()!;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  AppTypography get type => Theme.of(this).extension<AppTypography>()!;

  /// Durações já respeitando "remover animações" do sistema.
  AppMotion get motion =>
      Theme.of(this)
          .extension<AppMotion>()!
          .copyWith(reduced: MediaQuery.disableAnimationsOf(this));

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
