/// IDs do cliente OAuth do Google (não são segredos). Vêm de
/// `--dart-define-from-file=config/google.json` (ver `docs/google-cloud.md`);
/// sem eles, o login com Google fica indisponível e o resto do app funciona.
abstract final class GoogleConfig {
  /// ID do cliente **Web** (no Android, o `serverClientId`).
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// ID do cliente iOS.
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get configured => serverClientId.isNotEmpty;
}
