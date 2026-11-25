import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/features/tasks/alarm_diagnostics.dart';

/// Agenda em memória no lugar do plugin de notificações.
class FakeScheduler implements AlarmScheduler {
  FakeScheduler({
    this.fullScreenIntentGranted = true,
    this.grantFullScreenOnRequest = true,
    this.diagnostics,
  });

  final Map<int, AlarmSpec> pending = {};
  final List<String> log = [];
  final List<AlarmDiagnosticAction> openedDiagnostics = [];
  int permissionRequests = 0;
  int fullScreenPermissionRequests = 0;
  bool fullScreenIntentGranted;
  final bool grantFullScreenOnRequest;
  AlarmDiagnostics? diagnostics;

  @override
  Future<void> schedule(AlarmSpec alarm) async {
    pending[alarm.id] = alarm;
    log.add('schedule ${alarm.title} ${alarm.time}');
  }

  @override
  Future<void> cancel(int id) async {
    pending.remove(id);
    log.add('cancel $id');
  }

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<bool> canUseFullScreenIntent() async =>
      diagnostics?.fullScreenIntentAllowed ?? fullScreenIntentGranted;

  @override
  Future<bool> requestFullScreenIntentPermission() async {
    fullScreenPermissionRequests++;
    if (grantFullScreenOnRequest) {
      fullScreenIntentGranted = true;
      if (diagnostics case final d?) {
        diagnostics = AlarmDiagnostics(
          notificationsEnabled: d.notificationsEnabled,
          remindersChannelMuted: d.remindersChannelMuted,
          alarmsChannelMuted: d.alarmsChannelMuted,
          exactAlarmsAllowed: d.exactAlarmsAllowed,
          fullScreenIntentAllowed: true,
          batteryOptimizationIgnored: d.batteryOptimizationIgnored,
        );
      }
    }
    return canUseFullScreenIntent();
  }

  @override
  Future<AlarmDiagnostics> getDiagnostics() async =>
      diagnostics ??
      AlarmDiagnostics(fullScreenIntentAllowed: fullScreenIntentGranted);

  @override
  Future<void> openDiagnosticSettings(AlarmDiagnosticAction action) async {
    openedDiagnostics.add(action);
    if (action == AlarmDiagnosticAction.fullScreenIntent) {
      await requestFullScreenIntentPermission();
    }
  }
}
