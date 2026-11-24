/// Geometria do calendário, sem Flutter: colunas de blocos sobrepostos,
/// arredondamento de horários e as grades de semana e mês.
library;

import 'dates.dart';

typedef Span = ({DateTime start, DateTime end});

/// Posição horizontal de um bloco: coluna [column] de [columns] no grupo de
/// blocos que se sobrepõem.
typedef SlotLayout = ({int column, int columns});

/// Distribui blocos sobrepostos lado a lado (como no Google Agenda).
///
/// Blocos que se tocam em cadeia formam um grupo; cada bloco vai para a
/// primeira coluna livre do grupo, e todos do grupo dividem a largura pelo
/// número de colunas usadas. Blocos mais curtos que [minDuration] contam como
/// tendo essa duração (é a altura mínima que ocupam na tela).
///
/// O resultado segue a ordem de [spans].
List<SlotLayout> layoutOverlaps(
  List<Span> spans, {
  Duration minDuration = const Duration(minutes: 15),
}) {
  DateTime endOf(Span s) {
    final min = s.start.add(minDuration);
    return s.end.isBefore(min) ? min : s.end;
  }

  final order = List.generate(spans.length, (i) => i)
    ..sort((a, b) {
      final byStart = spans[a].start.compareTo(spans[b].start);
      if (byStart != 0) return byStart;
      final byEnd = endOf(spans[b]).compareTo(endOf(spans[a])); // longo antes
      return byEnd != 0 ? byEnd : a.compareTo(b);
    });

  final columnOf = List.filled(spans.length, 0);
  final result = List<SlotLayout>.filled(spans.length, (column: 0, columns: 1));
  var group = <int>[];
  var columnEnds = <DateTime>[];
  DateTime? groupEnd;

  void closeGroup() {
    for (final i in group) {
      result[i] = (column: columnOf[i], columns: columnEnds.length);
    }
    group = [];
    columnEnds = [];
    groupEnd = null;
  }

  for (final i in order) {
    final start = spans[i].start, end = endOf(spans[i]);
    if (groupEnd != null && !start.isBefore(groupEnd!)) closeGroup();
    var column = columnEnds.indexWhere((e) => !e.isAfter(start));
    if (column < 0) {
      column = columnEnds.length;
      columnEnds.add(end);
    } else {
      columnEnds[column] = end;
    }
    columnOf[i] = column;
    group.add(i);
    if (groupEnd == null || end.isAfter(groupEnd!)) groupEnd = end;
  }
  closeGroup();
  return result;
}

/// Arredonda [minutes] para baixo no passo [step] (15 min por padrão).
int floorToStep(int minutes, {int step = 15}) => (minutes ~/ step) * step;

/// Arredonda [minutes] para o passo [step] mais próximo.
int roundToStep(num minutes, {int step = 15}) =>
    (minutes / step).round() * step;

/// Segunda-feira da semana de [day] (meia-noite).
DateTime weekStart(DateTime day) =>
    addDays(startOfDay(day), -(day.weekday - DateTime.monday));

/// Dias da grade do mês de [month]: de segunda a domingo, cobrindo o mês
/// inteiro (4 a 6 semanas).
List<DateTime> monthGridDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  final start = weekStart(first);
  final end = addDays(weekStart(last), 7);
  return [for (var d = start; d.isBefore(end); d = addDays(d, 1)) d];
}

/// Minutos desde a meia-noite de [day] até [time] (pode passar de 1440).
int minutesFrom(DateTime day, DateTime time) =>
    time.difference(startOfDay(day)).inMinutes;

const monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];
