import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/clock.dart';
import '../../../data/providers.dart';
import '../data/drive_transport.dart';
import '../data/google_account.dart';
import '../domain/merge.dart';
import '../domain/snapshot.dart';
import '../domain/sync_transport.dart';
import '../sync_providers.dart';
import 'account_controller.dart';
import 'sync_engine.dart';
import 'sync_status.dart';

/// Transporte (os testes trocam por um falso).
final syncTransportProvider = Provider<SyncTransport>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return DriveTransport(
    client: () => ref.read(googleAccountApiProvider).driveClient(),
    loadFileId: () => settings.getString(SyncKeys.fileId),
    saveFileId: (id) => settings.setString(SyncKeys.fileId, id ?? ''),
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return SyncEngine(
    repo: ref.watch(snapshotRepositoryProvider),
    transport: ref.watch(syncTransportProvider),
    loadVersion: () => settings.getString(SyncKeys.remoteVersion),
    saveVersion: (v) => settings.setString(SyncKeys.remoteVersion, v),
    clock: ref.watch(clockProvider),
  );
});

/// Enquanto a pessoa escolhe "Juntar / Usar só os da nuvem" na primeira
/// conexão, o sync automático espera.
final awaitingFirstChoiceProvider = NotifierProvider<_FlagNotifier, bool>(
  _FlagNotifier.new,
);

class _FlagNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

/// Uma execução registrada no log de sync.
class SyncLogEntry {
  const SyncLogEntry({
    required this.at,
    required this.millis,
    required this.result,
    this.detail,
  });

  final DateTime at;
  final int millis;

  /// "ok", "sem alterações", "offline" ou "erro".
  final String result;
  final String? detail;

  Map<String, Object?> toJson() => {
    'at': formatSyncDate(at),
    'ms': millis,
    'result': result,
    'detail': detail,
  };

  static SyncLogEntry fromJson(Map<String, Object?> j) => SyncLogEntry(
    at: parseSyncDate(j['at'])!.toLocal(),
    millis: j['ms']! as int,
    result: j['result']! as String,
    detail: j['detail'] as String?,
  );
}

/// Log das últimas execuções (mais recente primeiro).
final syncLogProvider = StreamProvider.autoDispose<List<SyncLogEntry>>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchString(SyncKeys.log)
      .map(decodeSyncLog),
);

List<SyncLogEntry> decodeSyncLog(String? text) {
  if (text == null || text.isEmpty) return const [];
  return [
    for (final e in jsonDecode(text) as List)
      SyncLogEntry.fromJson((e as Map).cast<String, Object?>()),
  ];
}

final syncServiceProvider = NotifierProvider<SyncService, SyncStatus>(
  SyncService.new,
);

/// Orquestra quando sincronizar, um de cada vez, com novas tentativas.
class SyncService extends Notifier<SyncStatus> {
  static const debounce = Duration(seconds: 30);
  static const resumeAfter = Duration(minutes: 2);
  static const logSize = 50;

  /// Espera entre tentativas depois de falhas seguidas.
  static const backoff = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 30),
  ];

  /// Falhas seguidas antes de mostrar erro (antes disso: "pendente").
  static const failuresBeforeError = 3;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  StreamSubscription<Object?>? _changes;
  AppLifecycleListener? _lifecycle;
  bool _running = false;
  bool _again = false;
  int _failures = 0;

  DateTime Function() get _clock => ref.read(clockProvider);

  @override
  SyncStatus build() {
    final account = ref.watch(accountProvider).value;
    ref.onDispose(_stop);
    if (account == null || !account.connected) {
      return const SyncStatus(phase: SyncPhase.disconnected);
    }
    _start();
    return const SyncStatus(phase: SyncPhase.idle);
  }

  void _start() {
    // Alteração local: sincroniza 30 s depois da última (debounce).
    _changes = ref.read(databaseProvider).tableUpdates().listen((_) {
      if (_running || !state.autoSync) return;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounce, () async {
        // Só alterações que sobem (o próprio log e os ajustes do aparelho
        // também mexem no banco e não devem disparar outro sync).
        if (await ref.read(snapshotRepositoryProvider).hasDirty()) {
          await sync();
        }
      });
    });
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final last = state.lastSyncAt;
        if (state.autoSync &&
            (last == null || _clock().difference(last) > resumeAfter)) {
          sync();
        }
      },
      // Melhor esforço ao sair: envia o que estiver pendente.
      onHide: () {
        if (state.autoSync) sync();
      },
    );
    scheduleMicrotask(_init);
  }

  void _stop() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _changes?.cancel();
    _lifecycle?.dispose();
  }

  Future<void> _init() async {
    final settings = ref.read(settingsRepositoryProvider);
    final auto = await settings.getString(SyncKeys.auto) != 'false';
    final last = parseSyncDate(await settings.getString(SyncKeys.lastSyncAt));
    if (!ref.mounted) return;
    state = state.copyWith(autoSync: auto, lastSyncAt: last?.toLocal());
    // Ao abrir o app (a não ser durante a escolha da primeira conexão).
    if (auto && !ref.read(awaitingFirstChoiceProvider)) await sync();
  }

  /// Liga ou desliga a sincronização automática.
  Future<void> setAutoSync(bool on) async {
    await ref.read(settingsRepositoryProvider).setString(SyncKeys.auto, '$on');
    state = state.copyWith(autoSync: on);
    if (on) await sync();
  }

  /// Sincroniza agora (botão ou gatilho). Com um sync em andamento, marca
  /// para rodar de novo ao terminar.
  Future<void> sync() async {
    if (state.phase == SyncPhase.disconnected || !ref.mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing);
    final started = _clock();
    final watch = Stopwatch()..start();
    try {
      final run = await ref.read(syncEngineProvider).run();
      _failures = 0;
      final now = _clock();
      await ref
          .read(settingsRepositoryProvider)
          .setString(SyncKeys.lastSyncAt, formatSyncDate(now));
      final pending = await ref.read(snapshotRepositoryProvider).hasDirty();
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: pending ? SyncPhase.pending : SyncPhase.idle,
        lastSyncAt: now,
        clearMessage: true,
        needsSignIn: false,
        needsReplace: false,
      );
      await _log(
        started,
        watch,
        run.skipped ? 'sem alterações' : 'ok',
        run.skipped
            ? null
            : [
                if (run.counts != null) '${run.counts}',
                if (run.pushed) 'enviado',
                ...run.warnings,
              ].join(' · '),
      );
    } on SyncOfflineException {
      if (!ref.mounted) return;
      state = state.copyWith(phase: SyncPhase.offline, clearMessage: true);
      await _log(started, watch, 'offline', null);
      _scheduleRetry();
    } on AccountAuthException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: SyncPhase.error,
        message: e.message,
        needsSignIn: true,
      );
      await _log(started, watch, 'erro', e.message);
    } on DeviceInactiveException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: SyncPhase.error,
        message: e.toString(),
        needsReplace: true,
      );
      await _log(started, watch, 'erro', e.toString());
    } on SnapshotFormatException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: SyncPhase.error, message: e.message);
      await _log(started, watch, 'erro', e.message);
    } on Object catch (e) {
      _failures++;
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: _failures >= failuresBeforeError
            ? SyncPhase.error
            : SyncPhase.pending,
        message: 'Não foi possível sincronizar. Tentando de novo.',
      );
      await _log(started, watch, 'erro', '$e');
      _scheduleRetry();
    } finally {
      _running = false;
      if (_again && ref.mounted) {
        _again = false;
        unawaited(sync());
      }
    }
  }

  void _scheduleRetry() {
    final step = backoff[(_failures - 1).clamp(0, backoff.length - 1)];
    _retryTimer?.cancel();
    _retryTimer = Timer(step, () => sync());
  }

  Future<void> _log(
    DateTime at,
    Stopwatch watch,
    String result,
    String? detail,
  ) async {
    final settings = ref.read(settingsRepositoryProvider);
    final entries = [
      SyncLogEntry(
        at: at,
        millis: watch.elapsedMilliseconds,
        result: result,
        detail: detail == null || detail.isEmpty ? null : detail,
      ),
      ...decodeSyncLog(await settings.getString(SyncKeys.log)),
    ].take(logSize);
    await settings.setString(
      SyncKeys.log,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }

  /// Substitui os dados locais pelos da nuvem, guardando antes uma cópia
  /// local (aparelho inativo ou "usar só os da nuvem").
  Future<void> replaceWithRemote() async {
    final repo = ref.read(snapshotRepositoryProvider);
    final now = _clock();
    await (await ref.read(backupStoreProvider))
        .save(await repo.readLocal(now: now), now);
    await ref.read(syncEngineProvider).replaceWithRemote();
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: SyncPhase.idle,
      lastSyncAt: _clock(),
      clearMessage: true,
      needsReplace: false,
    );
  }
}
