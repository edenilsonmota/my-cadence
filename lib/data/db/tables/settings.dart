import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Ajustes em chave/valor (durações do pomodoro, retenção desejada etc.).
class AppSettings extends Table with SyncColumns {
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}
