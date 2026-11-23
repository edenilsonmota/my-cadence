import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/notifications.dart';
import 'core/time_zone.dart';
import 'features/tasks/alarms.dart';
import 'features/tasks/notification_actions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTimeZone();

  final container = ProviderContainer();
  void openTask(String taskId) =>
      container.read(routerProvider).push(Routes.task(taskId));

  final notifications = NotificationService.instance;
  await notifications.init(
    onTap: openTask,
    onBackgroundAction: onNotificationActionInBackground,
  );
  // Reagenda todos os lembretes e passa a acompanhar as mudanças nas tarefas.
  container.read(alarmSyncProvider);

  runApp(
    UncontrolledProviderScope(container: container, child: const CadenceApp()),
  );

  // App aberto por um toque na notificação: vai direto ao hub da tarefa.
  final launchTask = await notifications.launchPayload();
  if (launchTask != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => openTask(launchTask));
  }
}
