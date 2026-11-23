/// Utilitários de data puros (sem Flutter), em português.
library;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Soma dias no calendário local preservando a hora do relógio.
DateTime addDays(DateTime d, int days) => DateTime(
  d.year,
  d.month,
  d.day + days,
  d.hour,
  d.minute,
  d.second,
  d.millisecond,
);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const weekdayShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
const monthShort = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

String two(int n) => n.toString().padLeft(2, '0');

/// "14:05".
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "seg, 24 nov" (com o ano só se for diferente do de [now]).
String formatDate(DateTime d, DateTime now) {
  final base =
      '${weekdayShort[d.weekday - 1]}, ${d.day} ${monthShort[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

/// Rótulo relativo: "Hoje", "Amanhã", "Ontem" ou a data, com a hora se
/// [withTime].
String formatRelative(DateTime d, DateTime now, {bool withTime = false}) {
  final days = startOfDay(d).difference(startOfDay(now)).inDays;
  final label = switch (days) {
    0 => 'Hoje',
    1 => 'Amanhã',
    -1 => 'Ontem',
    _ => formatDate(d, now),
  };
  return withTime ? '$label, ${formatTime(d)}' : label;
}
