import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/l10n/locale_providers.dart';
import 'app/l10n/locale_settings.dart';
import 'app/nav_tabs.dart';
import 'app/nav_tabs_providers.dart';
import 'app/notification_navigation.dart';
import 'app/router.dart';
import 'app/theme/theme_providers.dart';
import 'app/theme/theme_settings.dart';
import 'app/widget_navigation.dart';
import 'core/notifications.dart';
import 'core/time_zone.dart';
import 'data/db/database.dart';
import 'data/providers.dart';
import 'data/repositories/settings_repository.dart';
import 'features/calendar/calendar_providers.dart';
import 'features/sync/sync_providers.dart';
import 'features/tasks/alarms.dart';
import 'features/tasks/daily_reminders_providers.dart';
import 'features/tasks/notification_actions.dart';
import 'features/widgets/home_widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await initTimeZone();

  final db = AppDatabase.open();
  final settings = SettingsRepository(db.settingsDao);
  final initialTabs = parseNavTabs(await settings.getString(navTabsSettingKey));
  final initialTheme = ThemeSettings(
    mode: ThemeSettings.parseThemeMode(
      await settings.getString(themeModeSettingKey),
    ),
    accent: ThemeSettings.parseAccentColor(
      await settings.getString(accentColorSettingKey),
    ),
    lightsOut: ThemeSettings.parseLightsOut(
      await settings.getString(lightsOutSettingKey),
    ),
  );

  final initialLocale = parseAppLocale(
    await settings.getString(appLocaleSettingKey),
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
      initialNavTabsProvider.overrideWithValue(initialTabs),
      initialThemeSettingsProvider.overrideWithValue(initialTheme),
      initialLocaleProvider.overrideWithValue(initialLocale),
    ],
  );
  // O payload é o id da tarefa, ou `pomodoro` para o fim de um ciclo.
  final navigator = NotificationNavigator(
    container.read(routerProvider),
    readNavTabs: () => container.read(navTabsProvider),
  );

  final notifications = NotificationService.instance;
  await notifications.init(
    onTap: navigator.open,
    onBackgroundAction: onNotificationActionInBackground,
  );
  // Reagenda todos os lembretes e passa a acompanhar as mudanças nas tarefas,
  // nos avisos diários opcionais e nos widgets da tela inicial.
  container.read(alarmSyncProvider);
  container.read(dailyReminderSyncProvider);
  container.read(homeWidgetSyncProvider);

  final widgetNavigator = WidgetNavigator(
    container.read(routerProvider),
    readNavTabs: () => container.read(navTabsProvider),
    onSelectAgendaDay: (day) =>
        container.read(calendarDayProvider.notifier).show(day),
    onCompleteTask: (id) =>
        container.read(tasksRepositoryProvider).completeTask(id),
  );
  final widgetBridge = container.read(homeWidgetBridgeProvider);
  widgetBridge.setUriListener(widgetNavigator.open);

  runApp(
    UncontrolledProviderScope(container: container, child: const CadenceApp()),
  );

  // Cópia local automática (uma por dia), sem atrasar a abertura.
  unawaited(
    container
        .read(manualBackupProvider)
        .autoBackupIfDue()
        .catchError((_) => null),
  );

  // App aberto por um toque na notificação ou num widget da tela inicial.
  final launchPayload = await notifications.launchPayload();
  if (launchPayload != null) navigator.open(launchPayload);
  final launchWidgetUri = await widgetBridge.consumeLaunchUri();
  if (launchWidgetUri != null) widgetNavigator.open(launchWidgetUri);
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
