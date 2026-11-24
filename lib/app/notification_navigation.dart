import 'package:go_router/go_router.dart';

import '../core/notifications.dart';
import 'router.dart';

/// Abre a tela de uma notificação tocada (hub da tarefa ou pomodoro).
///
/// Dois cuidados, achados no aparelho:
/// - Com o app aberto pela notificação, o toque chega antes de o roteador
///   terminar a navegação inicial; um `push` nessa hora vira a base da pilha
///   (a tela fica sem as abas e sem "voltar"). Então espera o roteador ter a
///   rota inicial antes de empilhar.
/// - O mesmo toque pode chegar por dois caminhos (abertura do app e callback
///   do plugin); repetições do mesmo payload em poucos segundos são ignoradas.
class NotificationNavigator {
  NotificationNavigator(this._router, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final GoRouter _router;
  final DateTime Function() _clock;
  String? _lastPayload;
  DateTime? _lastAt;

  static const _dedupeWindow = Duration(seconds: 3);

  static String routeFor(String payload) =>
      payload == pomodoroPayload ? Routes.pomodoro() : Routes.task(payload);

  void open(String payload) {
    final now = _clock();
    if (payload == _lastPayload &&
        _lastAt != null &&
        now.difference(_lastAt!) < _dedupeWindow) {
      return;
    }
    _lastPayload = payload;
    _lastAt = now;

    final target = routeFor(payload);
    final delegate = _router.routerDelegate;
    if (delegate.currentConfiguration.isNotEmpty) {
      _router.push(target);
      return;
    }
    void whenReady() {
      if (delegate.currentConfiguration.isEmpty) return;
      delegate.removeListener(whenReady);
      _router.push(target);
    }

    delegate.addListener(whenReady);
  }
}
