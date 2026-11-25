import 'dart:ui' show DartPluginRegistrant, PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/l10n/locale_settings.dart';
import '../../core/notifications.dart';
import '../../core/time_zone.dart';
import '../../data/db/database.dart';
import '../../data/repositories/tasks_repository.dart';
import 'alarms.dart';

/// Ações "Concluir" e "Adiar" tocadas na notificação. Roda num isolate de
/// segundo plano (inclusive com o app fechado), então abre o próprio banco.
@pragma('vm:entry-point')
Future<void> onNotificationActionInBackground(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  await initTimeZone();
  final db = AppDatabase.open();
  try {
    await handleAlarmAction(
      actionId: response.actionId,
      taskId: response.payload,
      repo: TasksRepository(db.tasksDao, db.tagsDao),
      scheduler: NotificationService.instance,
      now: DateTime.now(),
      allDayHour: parseAllDayHour(
        await db.settingsDao.getValue(allDayReminderHourKey),
      ),
      lang: resolveLangCode(
        parseAppLocale(await db.settingsDao.getValue(appLocaleSettingKey)),
        systemCode: PlatformDispatcher.instance.locale.languageCode,
      ),
    );
  } finally {
    await db.close();
  }
}
