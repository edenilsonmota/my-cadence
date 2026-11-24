import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/clock.dart';
import '../../data/providers.dart';
import '../sync/domain/snapshot.dart' show formatSyncDate, parseSyncDate;
import 'update_check.dart';

/// Última verificação automática (ajuste do aparelho: não sincroniza).
const updateLastCheckKey = 'device.updateLastCheck';

/// Busca a última release (`null` se ainda não há nenhuma).
typedef ReleaseFetcher = Future<ReleaseInfo?> Function();

Future<ReleaseInfo?> fetchLatestRelease() async {
  final response = await http
      .get(
        latestReleaseUri,
        headers: const {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 15));
  if (response.statusCode == 404) return null;
  if (response.statusCode != 200) {
    throw http.ClientException('GitHub respondeu ${response.statusCode}');
  }
  final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
  return ReleaseInfo.fromGitHub(json);
}

/// Os testes trocam por um falso (sem rede).
final releaseFetcherProvider = Provider<ReleaseFetcher>(
  (ref) => fetchLatestRelease,
);

/// Versão instalada ("1.2.0").
final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

/// Abre um link fora do app (navegador ou download).
final urlOpenerProvider = Provider<Future<bool> Function(String url)>(
  (ref) =>
      (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
);

enum UpdatePhase { idle, checking, upToDate, available, error }

class UpdateState {
  const UpdateState({this.phase = UpdatePhase.idle, this.release});

  final UpdatePhase phase;

  /// A release mais nova, quando [phase] é [UpdatePhase.available].
  final ReleaseInfo? release;
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(
  UpdateController.new,
);

class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  /// Verifica a última release. Automática ([auto]): no máximo uma vez por
  /// dia e sem mostrar erro (offline segue quieto).
  Future<void> check({bool auto = false}) async {
    if (state.phase == UpdatePhase.checking) return;
    final settings = ref.read(settingsRepositoryProvider);
    final now = ref.read(clockProvider)();
    if (auto) {
      final last = parseSyncDate(await settings.getString(updateLastCheckKey));
      if (!updateCheckDue(last?.toLocal(), now)) return;
    }
    if (!ref.mounted) return;
    final previous = state;
    state = const UpdateState(phase: UpdatePhase.checking);
    try {
      final current = await ref.read(appVersionProvider.future);
      final release = await ref.read(releaseFetcherProvider)();
      await settings.setString(updateLastCheckKey, formatSyncDate(now));
      if (!ref.mounted) return;
      state = release != null && isNewerVersion(release.version, current)
          ? UpdateState(phase: UpdatePhase.available, release: release)
          : const UpdateState(phase: UpdatePhase.upToDate);
    } on Object {
      if (!ref.mounted) return;
      state = auto ? previous : const UpdateState(phase: UpdatePhase.error);
    }
  }
}
