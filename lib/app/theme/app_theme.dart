import 'package:flutter/material.dart';

import 'palette.dart';
import 'tokens.dart';
import 'typography.dart';

export 'palette.dart';
export 'tokens.dart';
export 'typography.dart';

/// Cor de marca (a semente do esquema de cores).
const brandSeed = Color(0xFF00796B);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: AppFonts.ui);
  return base.copyWith(
    textTheme: base.textTheme.merge(buildTextTheme()),
    extensions: [
      const AppSpacing(),
      const AppRadius(),
      const AppMotion(),
      AppPalette.of(brightness),
      AppTypography(color: scheme.onSurface, muted: scheme.onSurfaceVariant),
    ],
  );
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
