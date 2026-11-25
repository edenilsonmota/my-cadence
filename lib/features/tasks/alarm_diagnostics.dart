/// Diagnóstico de permissões e canais de alarme no aparelho. Puro, sem Flutter.
library;

import '../../data/db/enums.dart';

/// Ações que abrem a tela correspondente nas configurações do sistema.
enum AlarmDiagnosticAction {
  notifications,
  remindersChannel,
  alarmsChannel,
  exactAlarms,
  fullScreenIntent,
  batteryOptimization,
}

/// Estado atual das permissões/configurações que afetam o disparo de lembretes.
class AlarmDiagnostics {
  const AlarmDiagnostics({
    this.notificationsEnabled = true,
    this.remindersChannelMuted = false,
    this.alarmsChannelMuted = false,
    this.exactAlarmsAllowed = true,
    this.fullScreenIntentAllowed = true,
    this.batteryOptimizationIgnored = true,
  });

  factory AlarmDiagnostics.fromMap(Map<Object?, Object?> map) =>
      AlarmDiagnostics(
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
        remindersChannelMuted: map['remindersChannelMuted'] as bool? ?? false,
        alarmsChannelMuted: map['alarmsChannelMuted'] as bool? ?? false,
        exactAlarmsAllowed: map['exactAlarmsAllowed'] as bool? ?? true,
        fullScreenIntentAllowed:
            map['fullScreenIntentAllowed'] as bool? ?? true,
        batteryOptimizationIgnored:
            map['batteryOptimizationIgnored'] as bool? ?? true,
      );

  /// Tudo ok (padrão em plataformas onde o sistema não bloqueia).
  static const allGood = AlarmDiagnostics();

  final bool notificationsEnabled;
  final bool remindersChannelMuted;
  final bool alarmsChannelMuted;
  final bool exactAlarmsAllowed;
  final bool fullScreenIntentAllowed;
  final bool batteryOptimizationIgnored;

  /// `true` se o lembrete nesse [mode] provavelmente não vai tocar ou será
  /// bloqueado pelo sistema.
  bool hasBlockingIssueFor(ReminderMode mode) {
    if (!notificationsEnabled) return true;
    if (!exactAlarmsAllowed) return true;
    if (mode == ReminderMode.notificacao && remindersChannelMuted) return true;
    if (mode == ReminderMode.alarme && alarmsChannelMuted) return true;
    return false;
  }

  /// Quantos itens do diagnóstico precisam de atenção do usuário.
  int get issueCount =>
      (notificationsEnabled ? 0 : 1) +
      (remindersChannelMuted ? 1 : 0) +
      (alarmsChannelMuted ? 1 : 0) +
      (exactAlarmsAllowed ? 0 : 1) +
      (fullScreenIntentAllowed ? 0 : 1) +
      (batteryOptimizationIgnored ? 0 : 1);

  bool get hasAnyIssue => issueCount > 0;

  @override
  bool operator ==(Object other) =>
      other is AlarmDiagnostics &&
      other.notificationsEnabled == notificationsEnabled &&
      other.remindersChannelMuted == remindersChannelMuted &&
      other.alarmsChannelMuted == alarmsChannelMuted &&
      other.exactAlarmsAllowed == exactAlarmsAllowed &&
      other.fullScreenIntentAllowed == fullScreenIntentAllowed &&
      other.batteryOptimizationIgnored == batteryOptimizationIgnored;

  @override
  int get hashCode => Object.hash(
    notificationsEnabled,
    remindersChannelMuted,
    alarmsChannelMuted,
    exactAlarmsAllowed,
    fullScreenIntentAllowed,
    batteryOptimizationIgnored,
  );
}
