import 'package:flutter/material.dart';

import 'tokens.dart';

/// Temas dos componentes: plano, com cantos e espaços dos tokens, sem o
/// "jeito" padrão do Material.
ThemeData applyComponentThemes(ThemeData base) {
  final c = base.colorScheme;
  final t = base.textTheme;
  const r = AppRadius();
  const s = AppSpacing();
  final md = RoundedRectangleBorder(borderRadius: r.mdAll);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  const buttonSize = Size(64, 44);

  return base.copyWith(
    scaffoldBackgroundColor: c.surface,
    iconTheme: IconThemeData(color: c.onSurfaceVariant, size: 20),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarThemeData(
      elevation: 0,
      // Ao rolar: só uma leve mudança de superfície, sem sombra.
      scrolledUnderElevation: 2,
      shadowColor: Colors.transparent,
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      centerTitle: false,
      titleSpacing: s.lg,
      titleTextStyle: t.titleLarge!.copyWith(color: c.onSurface),
      iconTheme: IconThemeData(color: c.onSurface, size: 22),
      actionsIconTheme: IconThemeData(color: c.onSurfaceVariant, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: c.surfaceContainerLow,
      indicatorColor: c.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: r.pillAll),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? c.onSecondaryContainer
              : c.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => t.labelSmall!.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? c.onSurface
              : c.onSurfaceVariant,
        ),
      ),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: c.surfaceContainerLow,
      indicatorColor: c.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: r.pillAll),
      labelTextStyle: WidgetStatePropertyAll(t.labelLarge),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surfaceContainerHighest.withValues(alpha: 0.6),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.md),
      border: OutlineInputBorder(
        borderRadius: r.mdAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: r.mdAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r.mdAll,
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: r.mdAll,
        borderSide: BorderSide(color: c.error),
      ),
      hintStyle: t.bodyLarge!.copyWith(color: c.onSurfaceVariant),
      labelStyle: t.labelLarge!.copyWith(color: c.onSurfaceVariant),
      floatingLabelStyle: t.labelLarge!.copyWith(color: c.primary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: md,
        padding: buttonPadding,
        minimumSize: buttonSize,
        textStyle: t.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: md,
        padding: buttonPadding,
        minimumSize: buttonSize,
        side: BorderSide(color: c.outlineVariant),
        textStyle: t.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: md,
        padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
        textStyle: t.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: md,
        side: BorderSide(color: c.outlineVariant),
        selectedBackgroundColor: c.secondaryContainer,
        selectedForegroundColor: c.onSecondaryContainer,
        textStyle: t.labelLarge,
        // Quatro opções cabem em 360 dp sem quebrar ("Nenhuma").
        padding: EdgeInsets.symmetric(horizontal: s.xs),
        visualDensity: VisualDensity.compact,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 1,
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: r.lgAll),
      iconSize: 24,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: r.smAll),
      side: BorderSide(color: c.outlineVariant.withValues(alpha: 0.7)),
      labelStyle: t.labelMedium,
      padding: EdgeInsets.symmetric(horizontal: s.xs, vertical: s.xxs),
      iconTheme: IconThemeData(size: 16, color: c.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: c.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: r.lgAll),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.onSurfaceVariant,
      contentPadding: EdgeInsets.symmetric(horizontal: s.lg),
      minVerticalPadding: s.sm,
      titleTextStyle: t.bodyLarge!.copyWith(color: c.onSurface),
      subtitleTextStyle: t.bodySmall!.copyWith(color: c.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: r.mdAll),
    ),
    dividerTheme: DividerThemeData(
      color: c.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: c.inverseSurface,
      contentTextStyle: t.bodyMedium!.copyWith(color: c.onInverseSurface),
      actionTextColor: c.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: r.mdAll),
      insetPadding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.md),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: c.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: r.xlAll),
      titleTextStyle: t.titleLarge!.copyWith(color: c.onSurface),
      contentTextStyle: t.bodyMedium!.copyWith(color: c.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      modalElevation: 0,
      backgroundColor: c.surfaceContainerLow,
      modalBackgroundColor: c.surfaceContainerLow,
      showDragHandle: true,
      dragHandleColor: c.outlineVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.xl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 2,
      color: c.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: r.mdAll),
      textStyle: t.bodyMedium!.copyWith(color: c.onSurface),
      labelTextStyle: WidgetStatePropertyAll(
        t.bodyMedium!.copyWith(color: c.onSurface),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.inverseSurface, borderRadius: r.smAll),
      textStyle: t.labelSmall!.copyWith(color: c.onInverseSurface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.surfaceContainerHighest,
      borderRadius: r.pillAll,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: r.xsAll),
      side: BorderSide(color: c.outline, width: 1.5),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: c.primary,
      textColor: c.onPrimary,
      textStyle: t.labelSmall,
    ),
    datePickerTheme: DatePickerThemeData(
      elevation: 0,
      backgroundColor: c.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: r.xlAll),
    ),
    timePickerTheme: TimePickerThemeData(
      elevation: 0,
      backgroundColor: c.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: r.xlAll),
    ),
  );
}

/// Transição de página: fade com leve deslocamento para cima. Com "remover
/// animações" do sistema, só o fade.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Easing.emphasizedDecelerate,
      reverseCurve: Easing.emphasizedAccelerate,
    );
    final faded = FadeTransition(opacity: enter, child: child);
    if (MediaQuery.disableAnimationsOf(context)) return faded;
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(enter),
      child: faded,
    );
  }
}
