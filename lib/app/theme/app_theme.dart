import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import 'components.dart';
import 'palette.dart';
import 'theme_settings.dart';
import 'tokens.dart';
import 'typography.dart';

export 'app_icons.dart';
export 'icon_catalog.dart';
export 'palette.dart';
export 'theme_settings.dart';
export 'tokens.dart';
export 'typography.dart';

/// Cor de marca (usada como padrão de referência).
const brandSeed = Color(0xFF1D9BF0);

/// Cor visual da bolinha no seletor de cor de destaque e do check sobre ela.
extension AppAccentSwatch on AppAccentColor {
  Color get swatch => Color(argb);

  Color get onSwatch => this == AppAccentColor.amarelo
      ? const Color(0xFF141418)
      : const Color(0xFFFFFFFF);
}

/// Constrói o tema claro, escuro neutro ou escuro "Lights out" (preto puro OLED
/// com alto contraste), aplicando [accent] apenas nos destaques e controles —
/// sem tingir os fundos neutros.
ThemeData buildTheme(
  Brightness brightness, {
  AppAccentColor accent = AppAccentColor.azul,
  bool lightsOut = false,
}) {
  final isDark = brightness == Brightness.dark;
  final highContrastDark = isDark && lightsOut;
  final hct = Hct.fromInt(accent.argb);
  Color hctTone(double chroma, double tone) =>
      Color(Hct.from(hct.hue, chroma, tone).toInt());

  final generated = ColorScheme.fromSeed(
    seedColor: accent.swatch,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    contrastLevel: highContrastDark ? 1.0 : 0.0,
  );

  final ColorScheme scheme;
  if (!isDark) {
    final primary = hctTone(math.max(hct.chroma, 48), 42);
    final container = hctTone(math.min(hct.chroma, 30), 90);
    final onContainer = hctTone(math.min(hct.chroma, 48), 22);
    scheme = generated.copyWith(
      primary: primary,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: container,
      onPrimaryContainer: onContainer,
      secondary: primary,
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: container,
      onSecondaryContainer: onContainer,
      surface: const Color(0xFFFAFAFC),
      surfaceDim: const Color(0xFFECECF0),
      surfaceBright: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF3F3F6),
      surfaceContainer: const Color(0xFFECECF0),
      surfaceContainerHigh: const Color(0xFFE5E5EB),
      surfaceContainerHighest: const Color(0xFFDDDDE4),
      onSurface: const Color(0xFF141418),
      onSurfaceVariant: const Color(0xFF555562),
      outline: const Color(0xFF7A7A88),
      outlineVariant: const Color(0xFFD6D6DF),
      inverseSurface: const Color(0xFF1E1E24),
      onInverseSurface: const Color(0xFFF5F5F8),
      inversePrimary: hctTone(math.max(hct.chroma, 52), 72),
    );
  } else if (highContrastDark) {
    final primary = hctTone(math.max(hct.chroma, 56), 74);
    final onPrimary = hctTone(math.min(hct.chroma, 36), 10);
    final container = hctTone(math.min(hct.chroma, 42), 20);
    final onContainer = hctTone(math.min(hct.chroma, 18), 96);
    scheme = generated.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: container,
      onPrimaryContainer: onContainer,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: container,
      onSecondaryContainer: onContainer,
      surface: const Color(0xFF000000),
      surfaceDim: const Color(0xFF000000),
      surfaceBright: const Color(0xFF222226),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0A0A0C),
      surfaceContainer: const Color(0xFF121215),
      surfaceContainerHigh: const Color(0xFF1A1A1E),
      surfaceContainerHighest: const Color(0xFF242429),
      onSurface: const Color(0xFFFFFFFF),
      onSurfaceVariant: const Color(0xFFD4D4DC),
      outline: const Color(0xFF8E8E98),
      outlineVariant: const Color(0xFF34343C),
      inverseSurface: const Color(0xFFF5F5F8),
      onInverseSurface: const Color(0xFF121215),
      inversePrimary: hctTone(math.max(hct.chroma, 48), 40),
    );
  } else {
    final primary = hctTone(math.max(hct.chroma, 52), 70);
    final onPrimary = hctTone(math.min(hct.chroma, 36), 12);
    final container = hctTone(math.min(hct.chroma, 38), 24);
    final onContainer = hctTone(math.min(hct.chroma, 22), 92);
    scheme = generated.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: container,
      onPrimaryContainer: onContainer,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: container,
      onSecondaryContainer: onContainer,
      surface: const Color(0xFF121214),
      surfaceDim: const Color(0xFF0E0E10),
      surfaceBright: const Color(0xFF2C2C30),
      surfaceContainerLowest: const Color(0xFF0B0B0D),
      surfaceContainerLow: const Color(0xFF17171A),
      surfaceContainer: const Color(0xFF1D1D21),
      surfaceContainerHigh: const Color(0xFF242429),
      surfaceContainerHighest: const Color(0xFF2E2E34),
      onSurface: const Color(0xFFF2F2F5),
      onSurfaceVariant: const Color(0xFFA8A8B3),
      outline: const Color(0xFF6E6E78),
      outlineVariant: const Color(0xFF303038),
      inverseSurface: const Color(0xFFF2F2F5),
      onInverseSurface: const Color(0xFF17171A),
      inversePrimary: hctTone(math.max(hct.chroma, 48), 42),
    );
  }

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
