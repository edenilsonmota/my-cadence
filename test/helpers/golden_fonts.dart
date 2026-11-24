import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Carrega as fontes reais (Inter, Literata, JetBrains Mono e Lucide) para os
/// goldens; sem isso o teste desenha tudo com a fonte de blocos "Ahem".
Future<void> loadGoldenFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.view(File(f).readAsBytesSync().buffer)),
      );
    }
    await loader.load();
  }

  await load('Inter', [
    for (final w in [400, 500, 600, 700]) 'assets/fonts/inter/Inter-$w.ttf',
  ]);
  await load('Literata', ['assets/fonts/literata/Literata-400.ttf']);
  await load('JetBrains Mono', [
    'assets/fonts/jetbrains_mono/JetBrainsMono-400.ttf',
  ]);

  final lucide = _packageRoot('lucide_icons_flutter');
  for (final w in [300, 500]) {
    await load('packages/lucide_icons_flutter/Lucide$w', [
      '$lucide/assets/build_font/LucideVariable-w$w.ttf',
    ]);
  }
}

String _packageRoot(String name) {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final packages = (config['packages'] as List).cast<Map<String, dynamic>>();
  final uri =
      packages.firstWhere((p) => p['name'] == name)['rootUri'] as String;
  return Uri.parse(uri).toFilePath();
}
