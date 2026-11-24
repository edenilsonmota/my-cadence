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
  // O payload é o id da tarefa, ou `pomodoro` para o fim de um ciclo.
  void openTask(String payload) => container
      .read(routerProvider)
      .push(
        payload == pomodoroPayload ? Routes.pomodoro() : Routes.task(payload),
      );

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
