import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/notification_navigation.dart';
import 'app/router.dart';
import 'core/notifications.dart';
import 'core/time_zone.dart';
import 'features/tasks/alarms.dart';
import 'features/tasks/notification_actions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await initTimeZone();

  final container = ProviderContainer();
  // O payload é o id da tarefa, ou `pomodoro` para o fim de um ciclo.
  final navigator = NotificationNavigator(container.read(routerProvider));

  final notifications = NotificationService.instance;
  await notifications.init(
    onTap: navigator.open,
    onBackgroundAction: onNotificationActionInBackground,
  );
  // Reagenda todos os lembretes e passa a acompanhar as mudanças nas tarefas.
  container.read(alarmSyncProvider);

  runApp(
    UncontrolledProviderScope(container: container, child: const CadenceApp()),
  );

  // App aberto por um toque na notificação: vai direto ao hub da tarefa.
  final launchPayload = await notifications.launchPayload();
  if (launchPayload != null) navigator.open(launchPayload);
}

/// Licenças OFL das fontes empacotadas (aparecem em "Licenças" do app).
void _registerFontLicenses() {
  for (final (family, folder) in [
    ('Inter', 'inter'),
    ('Literata', 'literata'),
    ('JetBrains Mono', 'jetbrains_mono'),
  ]) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString('assets/fonts/$folder/OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    });
  }
}
