import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/app_theme.dart';

/// Razão de contraste da WCAG entre duas cores opacas.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('paleta no tema ${brightness.name}', () {
      final theme = buildTheme(brightness);
      final palette = theme.extension<AppPalette>()!;
      final surface = theme.colorScheme.surface;

      for (final key in PaletteKey.values) {
        test(key.name, () {
          final t = palette.of(key);
          expect(
            contrast(t.onTint, t.tint),
            greaterThanOrEqualTo(4.5),
            reason: 'texto sobre o fundo suave',
          );
          expect(
            contrast(t.strong, surface),
            greaterThanOrEqualTo(3),
            reason: 'elemento gráfico sobre a superfície',
          );
          expect(
            contrast(t.strong, t.tint),
            greaterThanOrEqualTo(2),
            reason: 'barra lateral sobre o fundo do bloco',
          );
        });
      }

      test('as 12 cores são distintas', () {
        final strong = {
          for (final k in PaletteKey.values) palette.of(k).strong,
        };
        expect(strong, hasLength(12));
      });
    });
  }

  test('tema Lights out usa preto puro e alto contraste (WCAG AAA)', () {
    final theme = buildTheme(Brightness.dark, lightsOut: true);
    final scheme = theme.colorScheme;
    final palette = theme.extension<AppPalette>()!;

    expect(scheme.surface, const Color(0xFF000000));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(
      contrast(scheme.onSurface, scheme.surface),
      greaterThanOrEqualTo(15),
    );
    expect(
      contrast(scheme.onSurfaceVariant, scheme.surface),
      greaterThanOrEqualTo(7),
    );

    for (final key in PaletteKey.values) {
      final t = palette.of(key);
      expect(
        contrast(t.onTint, t.tint),
        greaterThanOrEqualTo(7),
        reason: 'AAA em ${key.name}',
      );
      expect(
        contrast(t.strong, scheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'alto contraste sobre preto em ${key.name}',
      );
    }
  });

  test('chave desconhecida cai no padrão', () {
    final palette = AppPalette.of(Brightness.light);
    expect(PaletteKey.tryParse('verde'), PaletteKey.verde);
    expect(PaletteKey.tryParse('magenta'), isNull);
    expect(palette.byName('magenta'), same(palette.of(PaletteKey.ardosia)));
    expect(
      palette.byName(null, fallback: PaletteKey.azul).strong,
      palette.of(PaletteKey.azul).strong,
    );
  });
}
