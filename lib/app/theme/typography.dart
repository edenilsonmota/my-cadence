import 'package:flutter/material.dart';

/// Famílias empacotadas em `assets/fonts` (ver `pubspec.yaml`).
abstract final class AppFonts {
  /// Interface.
  static const ui = 'Inter';

  /// Leitura dos books e verso dos flashcards.
  static const reading = 'Literata';

  /// Código.
  static const code = 'JetBrains Mono';
}

/// Poucos tamanhos; a hierarquia vem do peso. Títulos fortes, apoio discreto.
TextTheme buildTextTheme() {
  const tight = -0.2;
  return const TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.8,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      height: 1.15,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: tight,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: tight,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: tight,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: tight,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.3,
    ),
  );
}

/// Estilos que não cabem no `TextTheme`. Use `context.type`.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({required this.color, required this.muted});

  final Color color;
  final Color muted;

  /// Rótulo de seção: pequeno, caixa alta, espaçado ("HOJE").
  TextStyle get section => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    height: 1.3,
    color: muted,
  );

  /// Corpo de leitura (books, verso dos cards).
  TextStyle get reading => TextStyle(
    fontFamily: AppFonts.reading,
    fontSize: 17,
    height: 1.6,
    color: color,
  );

  /// Código.
  TextStyle get code => TextStyle(
    fontFamily: AppFonts.code,
    fontSize: 14,
    height: 1.5,
    color: color,
  );

  /// Número grande de indicador (métricas).
  TextStyle get metric => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.15,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Tempo do pomodoro.
  TextStyle get timer => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 64,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  AppTypography copyWith({Color? color, Color? muted}) =>
      AppTypography(color: color ?? this.color, muted: muted ?? this.muted);

  @override
  AppTypography lerp(AppTypography? other, double t) => other == null
      ? this
      : AppTypography(
          color: Color.lerp(color, other.color, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
        );
}

/// Algarismos tabulares, para números que mudam sem "dançar".
extension TabularFigures on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
