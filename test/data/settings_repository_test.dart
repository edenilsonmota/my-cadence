import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';

import 'test_db.dart';

void main() {
  late SettingsRepository repo;

  setUp(() => repo = SettingsRepository(openTestDb().settingsDao));

  test('lê nulo, grava, sobrescreve e observa', () async {
    expect(await repo.getString('pomodoro.focoMin'), isNull);

    final values = repo.watchString('pomodoro.focoMin');
    final expectation = expectLater(values, emitsInOrder([null, '25', '50']));

    await pumpEventQueue();
    await repo.setString('pomodoro.focoMin', '25');
    await pumpEventQueue();
    await repo.setString('pomodoro.focoMin', '50');
    await expectation;

    expect(await repo.getString('pomodoro.focoMin'), '50');
  });

  test('uma linha por chave', () async {
    final db = openTestDb();
    final settings = SettingsRepository(db.settingsDao);
    await settings.setString('a', '1');
    await settings.setString('a', '2');
    await settings.setString('b', '3');

    expect(await db.select(db.appSettings).get(), hasLength(2));
  });
}
