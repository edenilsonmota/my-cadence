/// Estado observável da sincronização (o avatar e a folha da conta mostram).
library;

enum SyncPhase {
  /// Sem conta Google conectada.
  disconnected,

  /// Em dia.
  idle,
  syncing,

  /// Há alterações locais ainda não enviadas.
  pending,

  /// Sem internet: tenta de novo depois, sem alarde.
  offline,
  error,
}

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.lastSyncAt,
    this.message,
    this.needsSignIn = false,
    this.needsReplace = false,
    this.autoSync = true,
  });

  final SyncPhase phase;
  final DateTime? lastSyncAt;

  /// Mensagem do erro (em português), quando houver.
  final String? message;

  /// Token expirado ou acesso revogado: ação "Entrar novamente".
  final bool needsSignIn;

  /// Aparelho inativo há mais de 180 dias: oferecer usar os dados da nuvem.
  final bool needsReplace;

  /// Sincronização automática ligada.
  final bool autoSync;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    String? message,
    bool clearMessage = false,
    bool? needsSignIn,
    bool? needsReplace,
    bool? autoSync,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    message: clearMessage ? null : message ?? this.message,
    needsSignIn: needsSignIn ?? this.needsSignIn,
    needsReplace: needsReplace ?? this.needsReplace,
    autoSync: autoSync ?? this.autoSync,
  );
}

/// "agora há pouco", "há 3 min", "há 2 h", "há 4 dias".
String syncedAgo(DateTime last, DateTime now) {
  final d = now.difference(last);
  if (d.inMinutes < 1) return 'agora há pouco';
  if (d.inHours < 1) return 'há ${d.inMinutes} min';
  if (d.inDays < 1) return 'há ${d.inHours} h';
  return 'há ${d.inDays} ${d.inDays == 1 ? 'dia' : 'dias'}';
}
