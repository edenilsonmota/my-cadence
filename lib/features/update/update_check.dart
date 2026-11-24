/// Verificação de versão nova pelas Releases do GitHub (puro, sem Flutter).
library;

/// Repositório de onde saem os APKs (GitHub Actions, `docs/RELEASE.md`).
const releasesRepo = 'edenilsonmota/my-cadence';

/// API da última release publicada (404 enquanto não houver nenhuma).
final latestReleaseUri = Uri.parse(
  'https://api.github.com/repos/$releasesRepo/releases/latest',
);

/// Uma release publicada.
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.pageUrl,
    this.apkUrl,
    this.notes,
  });

  /// "1.2.0" (sem o "v" da tag).
  final String version;

  /// Página da release no GitHub.
  final String pageUrl;

  /// APK principal (arm64), se a release tiver.
  final String? apkUrl;
  final String? notes;

  /// Lê a resposta da API do GitHub. O APK principal é o `.apk` que não é
  /// o de aparelhos antigos.
  static ReleaseInfo? fromGitHub(Map<String, Object?> json) {
    final tag = json['tag_name'];
    final page = json['html_url'];
    if (tag is! String || page is! String) return null;
    String? apk;
    for (final asset in (json['assets'] as List?) ?? const []) {
      if (asset is! Map) continue;
      final name = asset['name'], url = asset['browser_download_url'];
      if (name is String &&
          url is String &&
          name.endsWith('.apk') &&
          !name.contains('antigos')) {
        apk = url;
        break;
      }
    }
    final body = json['body'];
    return ReleaseInfo(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      pageUrl: page,
      apkUrl: apk,
      notes: body is String && body.trim().isNotEmpty ? body.trim() : null,
    );
  }
}

/// "1.10.2" → [1, 10, 2]; ignora o "+build" e sufixos ("-beta"). Inválido
/// vira lista vazia.
List<int> parseVersion(String text) {
  final core = text.trim().split('+').first.split('-').first;
  final parts = core.startsWith('v') ? core.substring(1) : core;
  final numbers = <int>[];
  for (final p in parts.split('.')) {
    final n = int.tryParse(p);
    if (n == null) return const [];
    numbers.add(n);
  }
  return numbers;
}

/// [candidate] é mais nova que [current]? Versões inválidas nunca são.
bool isNewerVersion(String candidate, String current) {
  final a = parseVersion(candidate), b = parseVersion(current);
  if (a.isEmpty || b.isEmpty) return false;
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Verificação automática: no máximo uma por dia.
bool updateCheckDue(DateTime? lastCheck, DateTime now) =>
    lastCheck == null || now.difference(lastCheck) >= const Duration(days: 1);
