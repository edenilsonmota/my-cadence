import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repositories/tasks_repository.dart';
import 'task_providers.dart';

/// Dá baixa automática nas ocorrências passadas de rotinas não acumulativas
/// na abertura do app, ao voltar do segundo plano e na virada da meia-noite.
class RoutineRolloverService {
  RoutineRolloverService(this._tasks, this._readToday);

  final TasksRepository _tasks;
  final DateTime Function() _readToday;
  Future<int>? _running;

  Future<int> run() => _running ??= _tasks
      .rolloverMissedRoutines(_readToday())
      .whenComplete(() => _running = null);
}

final routineRolloverProvider = Provider<RoutineRolloverService>((ref) {
  final service = RoutineRolloverService(
    ref.watch(tasksRepositoryProvider),
    () => ref.read(todayProvider),
  );
  ref.listen<DateTime>(todayProvider, (_, _) {
    unawaited(service.run());
  });
  unawaited(service.run());
  return service;
});
