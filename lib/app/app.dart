import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/pomodoro/pomodoro_controller.dart';
import '../features/tasks/alarms.dart';
import '../features/tasks/daily_reminders_providers.dart';
import '../features/tasks/routine_rollover.dart';
import '../features/widgets/home_widget_sync.dart';
import 'l10n/l10n.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_providers.dart';

class CadenceApp extends ConsumerStatefulWidget {
  const CadenceApp({super.key});

  @override
  ConsumerState<CadenceApp> createState() => _CadenceAppState();
}

class _CadenceAppState extends ConsumerState<CadenceApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  /// Ao voltar para o app: uma ação de notificação pode ter gravado no banco
  /// por outra conexão (outra engine). Força as consultas a reler e
  /// reconcilia os lembretes com o que está agendado no sistema.
  void _onResume() {
    ref.read(alarmSyncProvider).reset();
    ref.read(dailyReminderSyncProvider).reset();
    ref.read(homeWidgetSyncProvider).reset();
    ref.read(routineRolloverProvider).run();
    ref.invalidate(alarmDiagnosticsProvider);
    // O ciclo pode ter acabado com o app em segundo plano.
    ref.read(pomodoroControllerProvider.notifier).checkDue();
    final db = ref.read(databaseProvider);
    db.markTablesUpdated(db.allTables);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final appLocale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'My Cadence',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accent: themeSettings.accent),
      darkTheme: buildTheme(
        Brightness.dark,
        accent: themeSettings.accent,
        lightsOut: themeSettings.lightsOut,
      ),
      themeMode: themeSettings.mode.material,
      locale: appLocale.materialLocale,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        AppFlowyEditorLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
