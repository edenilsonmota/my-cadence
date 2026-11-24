import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../data/providers.dart';
import '../data/google_account.dart';

/// Chaves locais (prefixo `sync.`: não sincronizam).
abstract final class SyncKeys {
  static const account = 'sync.account';
  static const auto = 'sync.auto';
  static const fileId = 'sync.fileId';
  static const remoteVersion = 'sync.remoteVersion';
  static const lastSyncAt = 'sync.lastSyncAt';
  static const log = 'sync.log';
}

final googleAccountApiProvider = Provider<GoogleAccountApi>(
  (ref) => GoogleSignInAccountApi(),
);

/// Baixa a foto de perfil (os testes trocam por um falso).
final photoDownloaderProvider = Provider<Future<Uint8List?> Function(String)>(
  (ref) => (url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } on Object {
      return null; // offline: tenta na próxima vez
    }
  },
);

/// Onde a foto fica guardada, para aparecer offline.
final photoFileProvider = Provider<Future<File>>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/account_photo');
});

class AccountState {
  const AccountState({
    required this.configured,
    this.account,
    this.photo,
    this.busy = false,
  });

  final bool configured;
  final AccountInfo? account;

  /// Foto em cache (ou `null`: mostra as iniciais).
  final Uint8List? photo;
  final bool busy;

  bool get connected => account != null;

  AccountState copyWith({
    AccountInfo? account,
    bool clearAccount = false,
    Uint8List? photo,
    bool clearPhoto = false,
    bool? busy,
  }) => AccountState(
    configured: configured,
    account: clearAccount ? null : account ?? this.account,
    photo: clearPhoto ? null : photo ?? this.photo,
    busy: busy ?? this.busy,
  );
}

final accountProvider = AsyncNotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

class AccountController extends AsyncNotifier<AccountState> {
  GoogleAccountApi get _api => ref.read(googleAccountApiProvider);

  @override
  Future<AccountState> build() async {
    final settings = ref.read(settingsRepositoryProvider);
    final stored = AccountInfo.fromJson(
      await settings.getString(SyncKeys.account),
    );
    final photo = await _readPhoto();
    final state = AccountState(
      configured: _api.configured,
      account: stored,
      photo: photo,
    );
    // Sem "restaurar sessão" ao abrir: o sync só precisa da autorização do
    // Drive, pedida pelo e-mail guardado (ver `GoogleAccountApi`).
    return state;
  }

  /// Login interativo. Devolve a conta ou lança [AccountAuthException].
  Future<AccountInfo> connect() async {
    final current = await future;
    state = AsyncData(current.copyWith(busy: true));
    try {
      final account = await _api.signIn();
      await _remember(account);
      return account;
    } finally {
      final s = state.value;
      if (s != null) state = AsyncData(s.copyWith(busy: false));
    }
  }

  /// Sai da conta atual e entra noutra.
  Future<AccountInfo> switchAccount() async {
    await _api.signOut();
    return connect();
  }

  /// Para de sincronizar: os dados ficam no aparelho; esquece a conta, o
  /// arquivo remoto e a versão conhecida.
  Future<void> disconnect() async {
    await _api.signOut();
    final settings = ref.read(settingsRepositoryProvider);
    for (final key in [
      SyncKeys.account,
      SyncKeys.fileId,
      SyncKeys.remoteVersion,
      SyncKeys.lastSyncAt,
    ]) {
      await settings.setString(key, '');
    }
    try {
      await (await ref.read(photoFileProvider)).delete();
    } on FileSystemException {
      // não havia foto
    }
    final s = await future;
    state = AsyncData(s.copyWith(clearAccount: true, clearPhoto: true));
  }

  Future<void> _remember(AccountInfo account) async {
    await ref
        .read(settingsRepositoryProvider)
        .setString(SyncKeys.account, account.toJson());
    Uint8List? photo;
    if (account.photoUrl case final url?) {
      photo = await ref.read(photoDownloaderProvider)(url);
      if (photo != null) {
        await (await ref.read(photoFileProvider)).writeAsBytes(photo);
      }
    }
    final s = state.value ?? AccountState(configured: _api.configured);
    state = AsyncData(s.copyWith(account: account, photo: photo ?? s.photo));
  }

  Future<Uint8List?> _readPhoto() async {
    try {
      final file = await ref.read(photoFileProvider);
      return await file.exists() ? await file.readAsBytes() : null;
    } on Object {
      return null;
    }
  }
}
