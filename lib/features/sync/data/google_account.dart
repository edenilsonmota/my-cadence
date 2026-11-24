import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../app/config/google_config.dart';

/// Só a pasta privada do app no Drive (escopo não sensível). Nada de
/// `drive` nem `drive.file`.
const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Conta conectada (o que a tela mostra, também offline).
class AccountInfo {
  const AccountInfo({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  /// "Edenilson Mota" → "EM"; sem nome, a 1ª letra do e-mail.
  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  String toJson() => jsonEncode({
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
  });

  static AccountInfo? fromJson(String? text) {
    if (text == null || text.isEmpty) return null;
    final map = (jsonDecode(text) as Map).cast<String, Object?>();
    return AccountInfo(
      id: map['id']! as String,
      email: map['email']! as String,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}

/// Login negado, cancelado ou acesso revogado (mensagem para a tela).
class AccountAuthException implements Exception {
  const AccountAuthException(this.message, {this.canceled = false});

  final String message;
  final bool canceled;

  @override
  String toString() => message;
}

/// Login e autorização do Google. Os testes trocam por um falso.
abstract interface class GoogleAccountApi {
  /// O app tem os IDs do cliente OAuth neste build.
  bool get configured;

  /// Restaura uma sessão anterior sem interação (ou `null`).
  Future<AccountInfo?> restore();

  /// Login interativo e autorização do Drive (pede o consentimento).
  Future<AccountInfo> signIn();

  /// Sai (o acesso concedido continua valendo para entrar de novo).
  Future<void> signOut();

  /// Cliente HTTP autorizado para o Drive. Sem [interactive], não mostra
  /// nada; lança [AccountAuthException] se precisar de interação.
  Future<http.Client> driveClient({bool interactive = false});
}

/// Implementação com o `google_sign_in` 7 (autenticação e autorização
/// separadas).
class GoogleSignInAccountApi implements GoogleAccountApi {
  GoogleSignIn get _signIn => GoogleSignIn.instance;
  Future<void>? _initialized;
  GoogleSignInAccount? _current;

  @override
  bool get configured => GoogleConfig.configured;

  Future<void> _init() => _initialized ??= _signIn.initialize(
    serverClientId: GoogleConfig.serverClientId,
    clientId: GoogleConfig.iosClientId.isEmpty
        ? null
        : GoogleConfig.iosClientId,
  );

  static AccountInfo _info(GoogleSignInAccount a) => AccountInfo(
    id: a.id,
    email: a.email,
    name: a.displayName,
    photoUrl: a.photoUrl,
  );

  @override
  Future<AccountInfo?> restore() async {
    if (!configured) return null;
    await _init();
    try {
      final account = await _signIn.attemptLightweightAuthentication();
      _current = account;
      return account == null ? null : _info(account);
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<AccountInfo> signIn() async {
    if (!configured) {
      throw const AccountAuthException(
        'Login com Google ainda não configurado neste app.',
      );
    }
    await _init();
    try {
      final account = await _signIn.authenticate(
        scopeHint: const [driveAppDataScope],
      );
      // Pede o acesso ao Drive já no login (a pessoa está interagindo).
      await account.authorizationClient.authorizeScopes(const [
        driveAppDataScope,
      ]);
      _current = account;
      return _info(account);
    } on GoogleSignInException catch (e) {
      throw AccountAuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Login cancelado.'
            : 'Não foi possível entrar com o Google (${e.code.name}).',
        canceled: e.code == GoogleSignInExceptionCode.canceled,
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!configured) return;
    await _init();
    _current = null;
    await _signIn.signOut();
  }

  @override
  Future<http.Client> driveClient({bool interactive = false}) async {
    await _init();
    final account =
        _current ?? await _signIn.attemptLightweightAuthentication();
    if (account == null) {
      throw const AccountAuthException('Entre novamente com o Google.');
    }
    _current = account;
    const scopes = [driveAppDataScope];
    final client = account.authorizationClient;
    final authorization =
        await client.authorizationForScopes(scopes) ??
        (interactive ? await client.authorizeScopes(scopes) : null);
    if (authorization == null) {
      throw const AccountAuthException(
        'Autorize o acesso ao Google Drive para sincronizar.',
      );
    }
    return authorization.authClient(scopes: scopes);
  }
}
