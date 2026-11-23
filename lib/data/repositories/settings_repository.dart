import '../db/daos/settings_dao.dart';

/// Ajustes em chave/valor. Os ajustes tipados (durações do pomodoro,
/// retenção etc.) ganham getters próprios nas etapas que os usam.
class SettingsRepository {
  SettingsRepository(this._dao);

  final SettingsDao _dao;

  Future<String?> getString(String key) => _dao.getValue(key);
  Stream<String?> watchString(String key) => _dao.watchValue(key);
  Future<void> setString(String key, String value) => _dao.setValue(key, value);
}
