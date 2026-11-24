import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
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

  /// Login interativo e autorização do Drive (pede o consentimento).
  Future<AccountInfo> signIn();

  /// Sai (o acesso concedido continua valendo para entrar de novo).
  Future<void> signOut();

  /// Cliente HTTP autorizado para o Drive da [account], sem mostrar nada;
  /// lança [AccountAuthException] se precisar de interação.
  Future<http.Client> driveClient(AccountInfo account);

  /// O Drive recusou o último token (401): descarta-o do cache do aparelho
  /// para o próximo [driveClient] pedir outro.
  Future<void> invalidateDriveToken();
}

/// Implementação com o `google_sign_in` 7 (autenticação e autorização
/// separadas).
class GoogleSignInAccountApi implements GoogleAccountApi {
  GoogleSignIn get _signIn => GoogleSignIn.instance;
  Future<void>? _initialized;
  String? _token;

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
    _token = null;
    await _signIn.signOut();
  }

  /// Só a autorização, pelo e-mail guardado: no Android ela não depende
  /// de uma sessão de login (a "restauração" silenciosa do plugin abre o
  /// seletor de contas quando não consegue entrar sozinha).
  @override
  Future<http.Client> driveClient(AccountInfo account) async {
    await _init();
    const scopes = [driveAppDataScope];
    final ClientAuthorizationTokenData? tokens;
    try {
      tokens = await GoogleSignInPlatform.instance
          .clientAuthorizationTokensForScopes(
            ClientAuthorizationTokensForScopesParameters(
              request: AuthorizationRequestDetails(
                scopes: scopes,
                userId: account.id,
                email: account.email,
                promptIfUnauthorized: false,
              ),
            ),
          );
    } on GoogleSignInException catch (e) {
      throw AccountAuthException(
        'Não foi possível autorizar o Google Drive (${e.code.name}).',
      );
    }
    if (tokens == null) {
      throw const AccountAuthException(
        'Autorize o acesso ao Google Drive para sincronizar.',
      );
    }
    _token = tokens.accessToken;
    return GoogleSignInClientAuthorization(accessToken: tokens.accessToken)
        .authClient(scopes: scopes);
  }

  @override
  Future<void> invalidateDriveToken() async {
    final token = _token;
    _token = null;
    if (token == null) return;
    await _signIn.authorizationClient.clearAuthorizationToken(
      accessToken: token,
    );
  }
}
