import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/pomodoro/pomodoro_controller.dart';
import '../features/tasks/alarms.dart';
import 'router.dart';
import 'theme.dart';

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
    return MaterialApp.router(
      title: 'My Cadence',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        AppFlowyEditorLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
