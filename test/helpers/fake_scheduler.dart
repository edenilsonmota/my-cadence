import 'package:my_cadence/core/notifications.dart';

/// Agenda em memória no lugar do plugin de notificações.
class FakeScheduler implements AlarmScheduler {
  FakeScheduler({
    this.fullScreenIntentGranted = true,
    this.grantFullScreenOnRequest = true,
  });

  final Map<int, AlarmSpec> pending = {};
  final List<String> log = [];
  int permissionRequests = 0;
  int fullScreenPermissionRequests = 0;
  bool fullScreenIntentGranted;
  final bool grantFullScreenOnRequest;

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
  Future<bool> canUseFullScreenIntent() async => fullScreenIntentGranted;

  @override
  Future<bool> requestFullScreenIntentPermission() async {
    fullScreenPermissionRequests++;
    if (grantFullScreenOnRequest) fullScreenIntentGranted = true;
    return fullScreenIntentGranted;
  }
}
