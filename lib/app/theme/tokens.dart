import 'package:flutter/material.dart';

/// Escala de espaçamento (múltiplos de 4). Use `context.space.md`.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing();

  final double xxs = 2;
  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 24;
  final double xxl = 32;
  final double xxxl = 48;

  /// Margem lateral padrão das telas.
  double get page => lg;

  @override
  AppSpacing copyWith() => this;

  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}

/// Raios de canto. Use `context.radius.md`.
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius();

  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 24;
  final double pill = 999;

  BorderRadius get xsAll => BorderRadius.circular(xs);
  BorderRadius get smAll => BorderRadius.circular(sm);
  BorderRadius get mdAll => BorderRadius.circular(md);
  BorderRadius get lgAll => BorderRadius.circular(lg);
  BorderRadius get xlAll => BorderRadius.circular(xl);
  BorderRadius get pillAll => BorderRadius.circular(pill);

  @override
  AppRadius copyWith() => this;

  @override
  AppRadius lerp(AppRadius? other, double t) => this;
}

/// Durações e curvas. Nada passa de 400 ms. Use `context.motion.base`.
///
/// Com "remover animações" do sistema (`MediaQuery.disableAnimations`), as
/// durações viram zero.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({this.reduced = false});

  final bool reduced;

  Duration get fast =>
      reduced ? Duration.zero : const Duration(milliseconds: 150);
  Duration get base =>
      reduced ? Duration.zero : const Duration(milliseconds: 200);
  Duration get slow =>
      reduced ? Duration.zero : const Duration(milliseconds: 300);

  /// Intervalo da entrada em cascata de listas.
  Duration get stagger =>
      reduced ? Duration.zero : const Duration(milliseconds: 40);

  /// Espera do salvamento automático (não é animação; fica aqui para não
  /// haver duração solta fora do tema).
  static const autosave = Duration(milliseconds: 800);

  Curve get enter => Easing.emphasizedDecelerate;
  Curve get exit => Easing.emphasizedAccelerate;
  Curve get standard => Easing.standard;

  /// Escala ao pressionar.
  double get pressedScale => 0.98;

  @override
  AppMotion copyWith({bool? reduced}) =>
      AppMotion(reduced: reduced ?? this.reduced);

  @override
  AppMotion lerp(AppMotion? other, double t) => other ?? this;
}
