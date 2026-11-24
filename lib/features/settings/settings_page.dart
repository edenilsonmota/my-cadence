import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../shared/widgets/number_stepper.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../pomodoro/pomodoro_logic.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s =
        ref.watch(pomodoroSettingsProvider).value ?? const PomodoroSettings();
    final repo = ref.read(settingsRepositoryProvider);
    void setInt(String key, int v) => repo.setString(key, '$v');
    void setBool(String key, bool v) => repo.setString(key, '$v');

    Widget minutes(String label, String key, int value) => ListTile(
      title: Text(label),
      trailing: NumberStepper(
        value: value,
        min: 1,
        max: 180,
        semanticLabel: label,
        onChanged: (v) => setInt(key, v),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Header('Pomodoro'),
          minutes('Foco (min)', PomodoroSettings.keyFocus, s.focusMinutes),
          minutes(
            'Pausa curta (min)',
            PomodoroSettings.keyShortBreak,
            s.shortBreakMinutes,
          ),
          minutes(
            'Pausa longa (min)',
            PomodoroSettings.keyLongBreak,
            s.longBreakMinutes,
          ),
          ListTile(
            title: const Text('Pausa longa a cada'),
            subtitle: Text('${s.longBreakEvery} focos'),
            trailing: NumberStepper(
              value: s.longBreakEvery,
              min: 1,
              max: 12,
              semanticLabel: 'Focos até a pausa longa',
              onChanged: (v) => setInt(PomodoroSettings.keyLongEvery, v),
            ),
          ),
          SwitchListTile(
            title: const Text('Iniciar pausas sozinho'),
            subtitle: const Text(
              'Ao fim do foco, a pausa começa automaticamente',
            ),
            value: s.autoStartBreaks,
            onChanged: (v) => setBool(PomodoroSettings.keyAutoBreaks, v),
          ),
          SwitchListTile(
            title: const Text('Som ao terminar'),
            value: s.sound,
            onChanged: (v) => setBool(PomodoroSettings.keySound, v),
          ),
          SwitchListTile(
            title: const Text('Vibrar ao terminar'),
            value: s.vibrate,
            onChanged: (v) => setBool(PomodoroSettings.keyVibrate, v),
          ),
          SwitchListTile(
            title: const Text('Manter a tela ligada'),
            subtitle: const Text('Enquanto a tela do pomodoro estiver aberta'),
            value: s.keepScreenOn,
            onChanged: (v) => setBool(PomodoroSettings.keyScreenOn, v),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall!
            .copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
