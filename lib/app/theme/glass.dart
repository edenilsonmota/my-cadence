import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Tokens do efeito de vidro fosco das superfícies flutuantes (barra de
/// navegação, mini player, folhas e diálogos). No Lights out o vidro vira
/// preto sólido: o modo existe para o preto puro e o alto contraste.
class AppGlass extends ThemeExtension<AppGlass> {
  const AppGlass({
    required this.tint,
    required this.border,
    required this.highlight,
    required this.blur,
    required this.accent,
    required this.card,
  });

  factory AppGlass.of(
    ColorScheme c, {
    required bool lightsOut,
    required Color accentEnd,
  }) {
    // Degradê do destaque (botões, FAB) e fundo sutil dos cartões.
    final accent = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.primary, accentEnd],
    );
    final card = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          c.primary.withValues(alpha: lightsOut ? 0.10 : 0.14),
          c.surfaceContainerLow,
        ),
        c.surfaceContainerLow,
      ],
      stops: const [0, 0.7],
    );
    final dark = c.brightness == Brightness.dark;
    if (lightsOut) {
      return AppGlass(
        tint: c.surfaceContainerLow,
        border: c.outlineVariant,
        highlight: c.surfaceContainerLow,
        blur: 0,
        accent: accent,
        card: card,
      );
    }
    return AppGlass(
      tint: dark
          ? c.surfaceContainerHigh.withValues(alpha: 0.62)
          : c.surfaceContainerLowest.withValues(alpha: 0.72),
      border: dark
          ? c.onSurface.withValues(alpha: 0.10)
          : c.onSurface.withValues(alpha: 0.08),
      highlight: dark
          ? c.onSurface.withValues(alpha: 0.06)
          : c.surfaceContainerLowest.withValues(alpha: 0.5),
      blur: 22,
      accent: accent,
      card: card,
    );
  }

  /// Degradê da cor de destaque (botões principais e FAB).
  final LinearGradient accent;

  /// Fundo dos cartões de destaque (métricas): reflexo da cor no canto.
  final LinearGradient card;

  /// Cor sobre o conteúdo desfocado.
  final Color tint;

  /// Contorno fino (a "aresta" do vidro).
  final Color border;

  /// Reflexo suave no topo da superfície.
  final Color highlight;

  /// Intensidade do desfoque (0 = sólido).
  final double blur;

  @override
  AppGlass copyWith({
    Color? tint,
    Color? border,
    Color? highlight,
    double? blur,
    LinearGradient? accent,
    LinearGradient? card,
  }) => AppGlass(
    tint: tint ?? this.tint,
    border: border ?? this.border,
    highlight: highlight ?? this.highlight,
    blur: blur ?? this.blur,
    accent: accent ?? this.accent,
    card: card ?? this.card,
  );

  @override
  AppGlass lerp(AppGlass? other, double t) {
    if (other == null) return this;
    return AppGlass(
      tint: Color.lerp(tint, other.tint, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      blur: lerpDouble(blur, other.blur, t)!,
      accent: LinearGradient.lerp(accent, other.accent, t)!,
      card: LinearGradient.lerp(card, other.card, t)!,
    );
  }
}
