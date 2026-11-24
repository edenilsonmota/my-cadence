import 'dart:async';

/// Agrupa várias mudanças seguidas num só salvamento, [delay] depois da
/// última. `flush()` salva na hora o que estiver pendente (ex.: ao sair da
/// tela).
class DebouncedSaver {
  DebouncedSaver(this._save, {this.delay = const Duration(milliseconds: 800)});

  final Future<void> Function() _save;
  final Duration delay;
  Timer? _timer;
  bool _pending = false;

  bool get hasPending => _pending;

  void schedule() {
    _pending = true;
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (!_pending) return;
    _pending = false;
    await _save();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = false;
  }
}
