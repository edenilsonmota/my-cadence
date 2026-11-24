import '../data/snapshot_repository.dart';
import '../domain/merge.dart';
import '../domain/snapshot.dart';
import '../domain/sync_transport.dart';
import '../domain/upgraders.dart';

/// Resultado de uma execução (para o status e o log).
class SyncRun {
  const SyncRun({
    required this.skipped,
    this.counts,
    this.pushed = false,
    this.warnings = const [],
  });

  /// Nada mudou dos dois lados: nem baixou nem enviou.
  final bool skipped;
  final MergeCounts? counts;
  final bool pushed;
  final List<String> warnings;
}

/// Um ciclo de sincronização:
/// 1. lê a versão remota; sem alterações locais e com a mesma versão já
///    conhecida, não faz nada;
/// 2. baixa, mescla com o local e aplica no banco;
/// 3. envia o resultado só se a versão remota ainda for a lida (senão
///    repete, até 3 vezes);
/// 4. limpa `dirty` do que foi enviado e guarda a nova versão.
class SyncEngine {
  SyncEngine({
    required this.repo,
    required this.transport,
    required this.loadVersion,
    required this.saveVersion,
    required this.clock,
  });

  static const maxAttempts = 3;

  final SnapshotRepository repo;
  final SyncTransport transport;

  /// Última versão remota conhecida (guardada localmente).
  final Future<String?> Function() loadVersion;
  final Future<void> Function(String version) saveVersion;
  final DateTime Function() clock;

  Future<SyncRun> run() async {
    final known = await loadVersion();
    if (known != null && known.isNotEmpty && !await repo.hasDirty()) {
      if (await transport.version() == known) {
        return const SyncRun(skipped: true);
      }
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final now = clock();
      final remote = await transport.fetch();
      final local = await repo.readLocal(now: now);

      final Snapshot toSend;
      final bool changed;
      MergeCounts? counts;
      var warnings = const <String>[];
      final remoteSnapshot = remote.snapshot;
      if (remoteSnapshot == null) {
        toSend = local.copyWith(
          devices: {
            local.deviceId: DeviceInfo(name: local.deviceName, lastSyncAt: now),
          },
        );
        changed = true;
      } else {
        final result = merge(local, remoteSnapshot, now: now);
        await repo.apply(result);
        toSend = result.merged;
        changed = result.remoteChanged;
        counts = result.counts;
        warnings = result.warnings;
      }

      var version = remote.version;
      if (changed) {
        try {
          version = await transport.push(
            toSend,
            expectedVersion: remote.version,
          );
        } on VersionConflict {
          if (attempt == maxAttempts) rethrow;
          continue; // outro aparelho gravou no meio: refaz com o novo
        }
      }
      // Só o que não mudou depois de lido sai de "pendente".
      await repo.markClean(toSend);
      await saveVersion(version!);
      return SyncRun(
        skipped: false,
        counts: counts,
        pushed: changed,
        warnings: warnings,
      );
    }
    throw const VersionConflict();
  }

  /// Troca os dados locais pelos da nuvem (aparelho inativo há muito tempo,
  /// ou "usar só os da nuvem" ao conectar). Quem chama faz o backup antes.
  Future<void> replaceWithRemote() async {
    final remote = await transport.fetch();
    final snapshot = remote.snapshot;
    if (snapshot == null) return;
    final upgraded = upgradeSnapshot(snapshot);
    await repo.replaceAll(upgraded, markDirty: false);
    // Registra este aparelho como em dia (senão continuaria "inativo").
    final now = clock();
    final id = await repo.deviceId();
    final version = await transport.push(
      upgraded.copyWith(
        generatedAt: now,
        devices: {
          ...upgraded.devices,
          id: DeviceInfo(name: await repo.deviceName(), lastSyncAt: now),
        },
      ),
      expectedVersion: remote.version,
    );
    await saveVersion(version);
  }

  /// Existe snapshot na nuvem? (primeira conexão)
  Future<bool> remoteExists() async => await transport.version() != null;
}
