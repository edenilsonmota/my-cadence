import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../data/db/enums.dart';
import '../../features/tasks/task_appearance.dart';

/// As 12 cores que tags, tarefas e books podem usar. Guardadas no banco pela
/// chave (`name`), nunca por ARGB. A ordem é também a das séries nos
/// gráficos.
enum PaletteKey {
  azul(0xFF2563EB),
  indigo(0xFF4F46E5),
  violeta(0xFF7C3AED),
  rosa(0xFFDB2777),
  vermelho(0xFFDC2626),
  laranja(0xFFEA580C),
  ambar(0xFFD97706),
  lima(0xFF65A30D),
  verde(0xFF16A34A),
  teal(0xFF0D9488),
  ciano(0xFF0891B2),
  ardosia(0xFF475569);

  const PaletteKey(this.seed);

  /// Cor de origem (só o matiz e a croma são usados).
  final int seed;

  /// Chave desconhecida (ou nula) vira `null`.
  static PaletteKey? tryParse(String? key) =>
      key == null ? null : PaletteKey.values.asNameMap()[key];

  /// Nome para a interface.
  String get label => switch (this) {
    azul => 'Azul',
    indigo => 'Índigo',
    violeta => 'Violeta',
    rosa => 'Rosa',
    vermelho => 'Vermelho',
    laranja => 'Laranja',
    ambar => 'Âmbar',
    lima => 'Lima',
    verde => 'Verde',
    teal => 'Verde-azulado',
    ciano => 'Ciano',
    ardosia => 'Ardósia',
  };
}

/// Tons de uma cor da paleta num tema.
@immutable
class Tones {
  const Tones({required this.tint, required this.strong, required this.onTint});

  /// Fundo suave: blocos da agenda, quadrado do ícone, chips.
  final Color tint;

  /// Barra lateral, ponto da tag, anel do pomodoro, linha do gráfico.
  final Color strong;

  /// Texto e ícone sobre o [tint].
  final Color onTint;

  /// Tons a partir de uma cor qualquer, pelo HCT (mesma luminosidade
  /// percebida para todos os matizes, logo o mesmo contraste).
  factory Tones.fromSeed(
    int argb,
    Brightness brightness, {
    bool lightsOut = false,
  }) {
    final hct = Hct.fromInt(argb);
    final hue = hct.hue, chroma = hct.chroma;
    Color tone(double t, double maxChroma) =>
        Color(Hct.from(hue, math.min(chroma, maxChroma), t).toInt());
    if (brightness == Brightness.light) {
      return Tones(
        tint: tone(92, 18),
        strong: tone(45, 80),
        onTint: tone(24, 48),
      );
    }
    if (lightsOut) {
      return Tones(
        tint: tone(16, 28),
        strong: tone(82, 68),
        onTint: tone(96, 16),
      );
    }
    return Tones(
      tint: tone(24, 24),
      strong: tone(76, 60),
      onTint: tone(90, 20),
    );
  }
}

/// Cores do app além do `ColorScheme`: a paleta, as semânticas e as das notas
/// do flashcard. Use `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette._(this.brightness, this._tones);

  factory AppPalette.of(Brightness brightness, {bool lightsOut = false}) =>
      AppPalette._(brightness, {
        for (final key in PaletteKey.values)
          key: Tones.fromSeed(key.seed, brightness, lightsOut: lightsOut),
      });

  final Brightness brightness;
  final Map<PaletteKey, Tones> _tones;

  Tones of(PaletteKey key) => _tones[key]!;

  /// Pela chave guardada no banco; desconhecida cai em [fallback].
  Tones byName(String? key, {PaletteKey fallback = PaletteKey.ardosia}) =>
      of(PaletteKey.tryParse(key) ?? fallback);

  // Semânticas.
  Tones get success => of(PaletteKey.verde);
  Tones get warning => of(PaletteKey.ambar);
  Tones get danger => of(PaletteKey.vermelho);
  Tones get info => of(PaletteKey.azul);

  /// Cor padrão de cada tipo de tarefa.
  static PaletteKey kindKey(TaskKind kind) =>
      PaletteKey.tryParse(kindColorKey(kind))!;

  /// Nota do flashcard (1 Errei, 2 Difícil, 3 Bom, 4 Fácil).
  Tones grade(int rating) => of(switch (rating) {
    1 => PaletteKey.vermelho,
    2 => PaletteKey.ambar,
    3 => PaletteKey.verde,
    _ => PaletteKey.azul,
  });

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
