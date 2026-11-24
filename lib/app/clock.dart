import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Relógio do app ("vencidos agora", sessões em andamento, revisão). Os testes
/// trocam por um horário controlado.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Batida de um segundo para redesenhar relógios e filas (só a tela; os
/// tempos vêm sempre do banco). Os testes trocam por um stream parado.
final tickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => clock());
});
