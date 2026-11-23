import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  SimpleSelectStatement<$AppSettingsTable, AppSetting> _byKey(String key) =>
      select(appSettings)
        ..where((s) => s.key.equals(key) & s.deletedAt.isNull());

  Future<String?> getValue(String key) async =>
      (await _byKey(key).getSingleOrNull())?.value;

  Stream<String?> watchValue(String key) =>
      _byKey(key).watchSingleOrNull().map((s) => s?.value);

  /// Grava o valor da chave (cria, atualiza ou revive a linha da chave).
  Future<void> setValue(String key, String value) => transaction(() async {
    final existing = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (existing == null) {
      await insertSynced(
        appSettings,
        AppSettingsCompanion.insert(key: key, value: value),
      );
    } else {
      await updateSynced(
        appSettings,
        existing.id,
        AppSettingsCompanion(value: Value(value), deletedAt: const Value(null)),
      );
    }
  });
}
