/// Motor de mesclagem de snapshots. Puro, sem Flutter.
///
/// Linha a linha (pela chave de [mergeKey]): só de um lado, fica; dos dois
/// lados, vence o `updated_at` mais recente (a linha inteira); empate com
/// conteúdo diferente vence o JSON canônico maior, para todos os aparelhos
/// convergirem. Excluir também atualiza `updated_at`, então exclusão × edição
/// segue a mesma regra.
library;

import 'snapshot.dart';
import 'upgraders.dart';

/// Quanto tempo uma exclusão (tombstone) é guardada.
const tombstoneRetention = Duration(days: 180);

/// `updated_at` mais longe que isso no futuro vira aviso no log.
const clockSkewWarning = Duration(hours: 24);

/// O aparelho ficou tempo demais sem sincronizar: mesclar poderia ressuscitar
/// coisas já apagadas (os tombstones expiraram). O app deve oferecer
/// substituir os dados locais pelos remotos.
class DeviceInactiveException implements Exception {
  const DeviceInactiveException(this.lastSyncAt);

  final DateTime lastSyncAt;

  @override
  String toString() =>
      'Este aparelho está há mais de 180 dias sem sincronizar. '
      'Substitua os dados deste aparelho pelos da nuvem.';
}

class MergeCounts {
  int inserted = 0;
  int updated = 0;
  int deleted = 0;

  /// Mesmo `updated_at` com conteúdo diferente (resolvido pelo desempate).
  int conflicts = 0;

  /// Tombstones vencidos removidos.
  int purged = 0;

  @override
  String toString() =>
      'inseridas $inserted, atualizadas $updated, excluídas $deleted, '
      'conflitos $conflicts, removidas $purged';
}

class MergeResult {
  MergeResult({
    required this.merged,
    required this.toWrite,
    required this.toPurge,
    required this.remoteChanged,
    required this.counts,
    required this.warnings,
  });

  /// Resultado a enviar para o remoto (e que o local passa a refletir).
  final Snapshot merged;

  /// Linhas vindas do remoto a gravar no banco local, por tabela.
  final Map<String, List<SyncRow>> toWrite;

  /// Ids locais de tombstones vencidos a remover de vez, por tabela.
  final Map<String, List<String>> toPurge;

  /// O remoto difere do resultado (precisa enviar).
  final bool remoteChanged;
  final MergeCounts counts;
  final List<String> warnings;

  bool get localChanged =>
      toWrite.values.any((r) => r.isNotEmpty) ||
      toPurge.values.any((r) => r.isNotEmpty);
}

/// Mescla [local] (gerado agora por este aparelho) com [remote].
///
/// Lança [SnapshotFormatException] para esquema remoto mais novo e
/// [DeviceInactiveException] se este aparelho está inativo há mais de 180
/// dias no remoto.
///
/// [checkInactive] desligado na importação manual de JSON (a pessoa escolheu
/// mesclar aquele arquivo).
MergeResult merge(
  Snapshot local,
  Snapshot remote, {
  required DateTime now,
  bool checkInactive = true,
}) {
  final upgraded = upgradeSnapshot(remote, target: local.schemaVersion);
  final seen = upgraded.devices[local.deviceId]?.lastSyncAt;
  if (checkInactive &&
      seen != null &&
      now.difference(seen) > tombstoneRetention) {
    throw DeviceInactiveException(seen);
  }

  final purgeBefore = now.subtract(tombstoneRetention);
  final skewLimit = now.add(clockSkewWarning);
  final counts = MergeCounts();
  final warnings = <String>[];
  final toWrite = <String, List<SyncRow>>{};
  final toPurge = <String, List<String>>{};
  final mergedTables = <String, List<SyncRow>>{};
  var remoteChanged = false;

  bool expired(SyncRow row) {
    final deleted = parseSyncDate(row['deleted_at']);
    return deleted != null && deleted.isBefore(purgeBefore);
  }

  for (final table in syncTables) {
    bool syncable(SyncRow r) =>
        table != 'app_settings' || !isLocalSetting(r['key']! as String);
    final localRows = {
      for (final r in local.rows(table))
        if (syncable(r)) mergeKey(table, r): r,
    };
    final remoteRows = {
      for (final r in upgraded.rows(table))
        if (syncable(r)) mergeKey(table, r): r,
    };
    final writes = <SyncRow>[];
    final purges = <String>[];
    final result = <SyncRow>[];

    for (final key in {...localRows.keys, ...remoteRows.keys}) {
      final mine = localRows[key];
      final theirs = remoteRows[key];
      final winner = _pick(mine, theirs, counts);

      final updated = parseSyncDate(winner['updated_at']);
      if (updated != null && updated.isAfter(skewLimit)) {
        warnings.add('$table ${winner['id']}: updated_at no futuro ($updated)');
      }

      if (expired(winner)) {
        // Tombstone vencido: sai de todo lugar.
        counts.purged++;
        if (mine != null) purges.add(mine['id']! as String);
        if (theirs != null) remoteChanged = true;
        continue;
      }

      result.add(winner);
      if (!identical(winner, mine) &&
          (mine == null || canonicalJson(mine) != canonicalJson(winner))) {
        writes.add(winner);
        if (mine == null) {
          winner['deleted_at'] == null ? counts.inserted++ : counts.deleted++;
        } else if (mine['deleted_at'] == null && winner['deleted_at'] != null) {
          counts.deleted++;
        } else {
          counts.updated++;
        }
      }
      if (theirs == null || canonicalJson(theirs) != canonicalJson(winner)) {
        remoteChanged = true;
      }
    }

    // Ordem estável (pela chave), para o resultado não depender de quem
    // mesclou.
    result.sort((a, b) => mergeKey(table, a).compareTo(mergeKey(table, b)));
    mergedTables[table] = result;
    if (writes.isNotEmpty) toWrite[table] = writes;
    if (purges.isNotEmpty) toPurge[table] = purges;
  }

  final devices = {
    ...upgraded.devices,
    ...local.devices,
    local.deviceId: DeviceInfo(name: local.deviceName, lastSyncAt: now),
  };

  return MergeResult(
    merged: local.copyWith(
      generatedAt: now,
      devices: devices,
      tables: mergedTables,
    ),
    toWrite: toWrite,
    toPurge: toPurge,
    remoteChanged: remoteChanged,
    counts: counts,
    warnings: warnings,
  );
}

/// A linha vencedora entre a local e a remota (pelo menos uma existe).
SyncRow _pick(SyncRow? mine, SyncRow? theirs, MergeCounts counts) {
  if (mine == null) return theirs!;
  if (theirs == null) return mine;
  final a = parseSyncDate(mine['updated_at'])!;
  final b = parseSyncDate(theirs['updated_at'])!;
  if (a.isAfter(b)) return mine;
  if (b.isAfter(a)) return theirs;
  final ja = canonicalJson(mine), jb = canonicalJson(theirs);
  if (ja == jb) return mine;
  counts.conflicts++;
  return ja.compareTo(jb) > 0 ? mine : theirs;
}
