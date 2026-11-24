import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_cadence/features/sync/data/drive_transport.dart';
import 'package:my_cadence/features/sync/data/google_account.dart';
import 'package:my_cadence/features/sync/domain/sync_transport.dart';

/// Drive falso no nível HTTP: responde a versão do arquivo `abc`.
class _Drive {
  final statuses = <int>[]; // próximas respostas (vazio = 200)
  int clients = 0;
  int invalidations = 0;
  bool hang = false;

  Future<http.Client> client() async {
    clients++;
    return MockClient((request) async {
      if (hang) await Completer<void>().future;
      final status = statuses.isEmpty ? 200 : statuses.removeAt(0);
      if (status != 200) {
        return http.Response(
          jsonEncode({
            'error': {'code': status, 'message': 'x'},
          }),
          status,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'version': '7'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  DriveTransport transport({Duration? timeout}) => DriveTransport(
    client: client,
    loadFileId: () async => 'abc',
    saveFileId: (_) async {},
    onUnauthorized: () async => invalidations++,
    requestTimeout: timeout ?? const Duration(seconds: 30),
  );
}

void main() {
  test(
    'cada operação pede um cliente novo (o token pode ter mudado)',
    () async {
      final d = _Drive();
      final t = d.transport();
      expect(await t.version(), '7');
      expect(await t.version(), '7');
      expect(d.clients, 2);
    },
  );

  test('token recusado (401): descarta, pede outro e tenta de novo', () async {
    final d = _Drive()..statuses.add(401);
    expect(await d.transport().version(), '7');
    expect(d.invalidations, 1);
    expect(d.clients, 2);
  });

  test('401 de novo depois de renovar: pede para entrar outra vez', () async {
    final d = _Drive()..statuses.addAll([401, 401]);
    await expectLater(
      d.transport().version(),
      throwsA(isA<AccountAuthException>()),
    );
    expect(d.invalidations, 1);
  });

  test('requisição pendurada vira offline (não trava o sync)', () async {
    final d = _Drive()..hang = true;
    await expectLater(
      d.transport(timeout: const Duration(milliseconds: 50)).version(),
      throwsA(isA<SyncOfflineException>()),
    );
  });
}
