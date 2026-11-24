import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/update/update_check.dart';

void main() {
  test('compara versões por número, não por texto', () {
    expect(isNewerVersion('1.10.0', '1.9.3'), isTrue);
    expect(isNewerVersion('v1.2.0', '1.1.9+7'), isTrue);
    expect(isNewerVersion('1.2', '1.2.0'), isFalse);
    expect(isNewerVersion('1.2.0', '1.2.0'), isFalse);
    expect(isNewerVersion('1.0.0', '1.0.1'), isFalse);
    expect(isNewerVersion('lixo', '1.0.0'), isFalse);
  });

  test('lê a release do GitHub e escolhe o APK principal', () {
    final r = ReleaseInfo.fromGitHub({
      'tag_name': 'v1.3.0',
      'html_url': 'https://github.com/x/y/releases/tag/v1.3.0',
      'body': '  Novidades  ',
      'assets': [
        {
          'name': 'cadence-1.3.0-aparelhos-antigos.apk',
          'browser_download_url': 'https://a/antigo.apk',
        },
        {
          'name': 'cadence-1.3.0.apk',
          'browser_download_url': 'https://a/principal.apk',
        },
      ],
    })!;
    expect(r.version, '1.3.0');
    expect(r.apkUrl, 'https://a/principal.apk');
    expect(r.notes, 'Novidades');
    expect(ReleaseInfo.fromGitHub({'message': 'Not Found'}), isNull);
  });

  test('verificação automática no máximo uma vez por dia', () {
    final now = DateTime(2026, 11, 24, 10);
    expect(updateCheckDue(null, now), isTrue);
    expect(
      updateCheckDue(now.subtract(const Duration(hours: 5)), now),
      isFalse,
    );
    expect(updateCheckDue(now.subtract(const Duration(days: 1)), now), isTrue);
  });
}
