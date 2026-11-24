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

  /// Todos os ajustes cujas chaves começam com [prefix], como mapa.
  Stream<Map<String, String>> watchPrefix(String prefix) =>
      (select(appSettings)
            ..where((s) => s.key.like('$prefix%') & s.deletedAt.isNull()))
          .watch()
          .map((rows) => {for (final r in rows) r.key: r.value});

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
