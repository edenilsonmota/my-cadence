import 'package:http/http.dart' as http;
import 'package:my_cadence/features/sync/data/google_account.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';
import 'package:my_cadence/features/sync/domain/sync_transport.dart';

/// Conta Google falsa: sem rede, sem plugin.
class FakeAccountApi implements GoogleAccountApi {
  FakeAccountApi({this.configured = false, this.account});

  @override
  final bool configured;

  /// Quem "entra" no login.
  AccountInfo? account;
  int signIns = 0;
  int signOuts = 0;

  @override
  Future<AccountInfo?> restore() async => null;

  @override
  Future<AccountInfo> signIn() async {
    signIns++;
    final a = account;
    if (a == null) {
      throw const AccountAuthException('Login cancelado.', canceled: true);
    }
    return a;
  }

  @override
  Future<void> signOut() async => signOuts++;

  @override
  Future<http.Client> driveClient({bool interactive = false}) =>
      throw UnimplementedError('use FakeSyncTransport');
}

/// "Drive" em memória, com versão que muda a cada gravação.
class FakeSyncTransport implements SyncTransport {
  String? _json;
  int _version = 0;
  int fetches = 0;
  int pushes = 0;
  int versionChecks = 0;

  /// Falha com [SyncOfflineException] nas próximas N chamadas.
  int offlineCalls = 0;

  /// Chamado depois de cada fetch (simula outro aparelho no meio).
  Future<void> Function()? afterFetch;

  /// Chamado no início de cada push (simula edição local durante o envio).
  Future<void> Function()? beforePush;

  Snapshot? get stored => _json == null ? null : Snapshot.decode(_json!);
  String? get currentVersion => _json == null ? null : '$_version';

  void _maybeOffline() {
    if (offlineCalls > 0) {
      offlineCalls--;
      throw const SyncOfflineException();
    }
  }

  /// Grava direto (como se fosse outro aparelho).
  void store(Snapshot snapshot) {
    _json = snapshot.encode();
    _version++;
  }

  @override
  Future<String?> version() async {
    versionChecks++;
    _maybeOffline();
    return currentVersion;
  }

  @override
  Future<({Snapshot? snapshot, String? version})> fetch() async {
    fetches++;
    _maybeOffline();
    final result = (snapshot: stored, version: currentVersion);
    await afterFetch?.call();
    return result;
  }

  @override
  Future<String> push(Snapshot snapshot, {String? expectedVersion}) async {
    await beforePush?.call();
    _maybeOffline();
    if (currentVersion != expectedVersion) throw const VersionConflict();
    pushes++;
    store(snapshot);
    return currentVersion!;
  }
}
