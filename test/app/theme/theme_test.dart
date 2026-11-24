import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('tema ${brightness.name} traz fontes e tokens', () {
      final theme = buildTheme(brightness);
      expect(theme.colorScheme.brightness, brightness);
      expect(theme.textTheme.bodyMedium!.fontFamily, AppFonts.ui);
      expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w600);
      for (final type in [
        AppSpacing,
        AppRadius,
        AppMotion,
        AppPalette,
        AppTypography,
      ]) {
        expect(
          theme.extensions.keys,
          contains(type),
          reason: '$type registrado',
        );
      }
      final type = theme.extension<AppTypography>()!;
      expect(type.reading.fontFamily, AppFonts.reading);
      expect(type.code.fontFamily, AppFonts.code);
      expect(type.metric.fontFeatures, isNotEmpty); // algarismos tabulares
    });
  }

  testWidgets('"remover animações" zera as durações', (tester) async {
    late AppMotion normal, reduced;
    Widget probe(bool disable, void Function(AppMotion) out) => MediaQuery(
      data: MediaQueryData(disableAnimations: disable),
      child: Theme(
        data: buildTheme(Brightness.light),
        child: Builder(
          builder: (context) {
            out(context.motion);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(probe(false, (m) => normal = m));
    await tester.pumpWidget(probe(true, (m) => reduced = m));
    expect(normal.base, greaterThan(Duration.zero));
    expect(normal.slow.inMilliseconds, lessThanOrEqualTo(400));
    expect(reduced.base, Duration.zero);
  });
}
