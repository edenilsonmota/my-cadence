import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/update/update_check.dart';

import '../../helpers/pump_app.dart';

const _release = ReleaseInfo(
  version: '1.1.0',
  pageUrl: 'https://github.com/x/y/releases/tag/v1.1.0',
  apkUrl: 'https://github.com/x/y/releases/download/v1.1.0/cadence-1.1.0.apk',
  notes: 'Modo alarme',
);

void main() {
  testWidgets('ao abrir, versão nova vira aviso com "Baixar"', (tester) async {
    final opened = <String>[];
    await pumpApp(
      tester,
      releaseFetcher: () async => _release,
      openedUrls: opened,
    );
    await settle(tester);
    expect(find.text('Versão 1.1.0 disponível'), findsOneWidget);
    await tester.tap(find.text('Baixar'));
    await settle(tester);
    expect(opened, [_release.apkUrl]);
  });

  testWidgets('Ajustes mostra a versão e verifica pelo toque', (tester) async {
    var calls = 0;
    await pumpApp(
      tester,
      releaseFetcher: () async {
        calls++;
        return calls == 1 ? null : _release;
      },
    );
    await settle(tester);
    expect(calls, 1); // verificação automática ao abrir, sem novidade
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byTooltip('Abrir menu de navegação').first);
    await settle(tester);
    await tester.tap(find.text('Ajustes'));
    await settle(tester);
    final tile = find.text('Versão 1.0.0');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    expect(find.text('Você está na versão mais recente'), findsOneWidget);

    await tester.tap(tile);
    await settle(tester);
    expect(calls, 2);
    expect(find.text('Versão 1.1.0 disponível'), findsWidgets);
    expect(find.text('Modo alarme'), findsOneWidget);
  });
}
