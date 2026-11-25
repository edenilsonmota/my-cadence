import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/skeleton.dart';
import '../tasks/alarm_diagnostics.dart';
import '../tasks/alarms.dart';

/// Ajustes → Diagnóstico de alarmes: verifica notificações, canais, alarmes
/// exatos, tela cheia (Android 14+) e otimização de bateria, abrindo a tela do
/// sistema para cada item que precisa de ajuste.
class AlarmDiagnosticsPage extends ConsumerStatefulWidget {
  const AlarmDiagnosticsPage({super.key});

  @override
  ConsumerState<AlarmDiagnosticsPage> createState() =>
      _AlarmDiagnosticsPageState();
}

class _AlarmDiagnosticsPageState extends ConsumerState<AlarmDiagnosticsPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(alarmDiagnosticsProvider);

  Future<void> _open(AlarmDiagnosticAction action) async {
    await ref.read(alarmSchedulerProvider).openDiagnosticSettings(action);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final diagnostics = ref.watch(alarmDiagnosticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAlarmDiagnostics),
        actions: [
          IconButton(
            tooltip: l10n.diagnosticsRefresh,
            icon: const Icon(AppIcons.sync),
            onPressed: _refresh,
          ),
        ],
      ),
      body: diagnostics.when(
        loading: () => const SkeletonList(),
        error: (_, _) => Center(
          child: TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(AppIcons.sync),
            label: Text(l10n.diagnosticsRefresh),
          ),
        ),
        data: (d) => _DiagnosticsBody(diagnostics: d, onOpen: _open),
      ),
    );
  }
}

class _DiagnosticsBody extends StatelessWidget {
  const _DiagnosticsBody({required this.diagnostics, required this.onOpen});

  final AlarmDiagnostics diagnostics;
  final Future<void> Function(AlarmDiagnosticAction action) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.space;
    final palette = context.palette;
    final summaryTone = diagnostics.hasAnyIssue
        ? palette.warning
        : palette.success;

    return ListView(
      padding: EdgeInsets.fromLTRB(space.page, space.sm, space.page, space.xxl),
      children: [
        Container(
          padding: EdgeInsets.all(space.lg),
          decoration: BoxDecoration(
            color: summaryTone.tint,
            borderRadius: context.radius.lgAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                diagnostics.hasAnyIssue ? AppIcons.diagnostics : AppIcons.done,
                color: summaryTone.onTint,
              ),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnostics.hasAnyIssue
                          ? l10n.settingsAlarmDiagnosticsIssues(
                              diagnostics.issueCount,
                            )
                          : l10n.settingsAlarmDiagnosticsOk,
                      style: context.text.titleSmall!.copyWith(
                        color: summaryTone.onTint,
                      ),
                    ),
                    SizedBox(height: space.xxs),
                    Text(
                      diagnostics.hasAnyIssue
                          ? l10n.diagnosticsSummaryIssues
                          : l10n.diagnosticsSummaryOk,
                      style: context.text.bodySmall!.copyWith(
                        color: summaryTone.onTint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space.lg),
        _DiagnosticTile(
          title: l10n.diagNotificationsTitle,
          ok: diagnostics.notificationsEnabled,
          subtitle: diagnostics.notificationsEnabled
              ? l10n.diagNotificationsOk
              : l10n.diagNotificationsOff,
          onOpen: () => onOpen(AlarmDiagnosticAction.notifications),
        ),
        _DiagnosticTile(
          title: l10n.diagRemindersChannelTitle,
          ok: !diagnostics.remindersChannelMuted,
          subtitle: diagnostics.remindersChannelMuted
              ? l10n.diagRemindersChannelMuted
              : l10n.diagRemindersChannelOk,
          onOpen: () => onOpen(AlarmDiagnosticAction.remindersChannel),
        ),
        _DiagnosticTile(
          title: l10n.diagAlarmsChannelTitle,
          ok: !diagnostics.alarmsChannelMuted,
          subtitle: diagnostics.alarmsChannelMuted
              ? l10n.diagAlarmsChannelMuted
              : l10n.diagAlarmsChannelOk,
          onOpen: () => onOpen(AlarmDiagnosticAction.alarmsChannel),
        ),
        _DiagnosticTile(
          title: l10n.diagExactAlarmsTitle,
          ok: diagnostics.exactAlarmsAllowed,
          subtitle: diagnostics.exactAlarmsAllowed
              ? l10n.diagExactAlarmsOk
              : l10n.diagExactAlarmsDenied,
          onOpen: () => onOpen(AlarmDiagnosticAction.exactAlarms),
        ),
        _DiagnosticTile(
          title: l10n.diagFullScreenTitle,
          ok: diagnostics.fullScreenIntentAllowed,
          subtitle: diagnostics.fullScreenIntentAllowed
              ? l10n.diagFullScreenOk
              : l10n.diagFullScreenDenied,
          onOpen: () => onOpen(AlarmDiagnosticAction.fullScreenIntent),
        ),
        _DiagnosticTile(
          title: l10n.diagBatteryTitle,
          ok: diagnostics.batteryOptimizationIgnored,
          subtitle: diagnostics.batteryOptimizationIgnored
              ? l10n.diagBatteryOk
              : l10n.diagBatteryRestricted,
          onOpen: () => onOpen(AlarmDiagnosticAction.batteryOptimization),
        ),
      ],
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.title,
    required this.ok,
    required this.subtitle,
    required this.onOpen,
  });

  final String title;
  final bool ok;
  final String subtitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final space = context.space;
    final tone = ok ? palette.success : palette.warning;

    return Card.outlined(
      margin: EdgeInsets.only(bottom: space.md),
      child: Padding(
        padding: EdgeInsets.all(space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ok ? AppIcons.done : AppIcons.error,
                  size: AppIconSize.standard,
                  color: tone.strong,
                ),
                SizedBox(width: space.sm),
                Expanded(child: Text(title, style: context.text.titleSmall)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: space.sm,
                    vertical: space.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: tone.tint,
                    borderRadius: context.radius.smAll,
                  ),
                  child: Text(
                    ok ? l10n.diagnosticsStatusOk : l10n.diagnosticsStatusIssue,
                    style: context.text.labelSmall!.copyWith(
                      color: tone.onTint,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: space.xs),
            Text(
              subtitle,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (!ok) ...[
              SizedBox(height: space.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onOpen,
                  child: Text(l10n.diagnosticsOpenSettings),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
