/// Utilitários de data puros (sem Flutter), com suporte a `pt`, `en` e `es`.
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
const _weekdayShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayShortEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

List<String> weekdaysShortFor(String lang) => switch (lang) {
  'en' => _weekdayShortEn,
  'es' => _weekdayShortEs,
  _ => weekdayShort,
};

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
const _monthShortEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthShortEs = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

List<String> monthsShortFor(String lang) => switch (lang) {
  'en' => _monthShortEn,
  'es' => _monthShortEs,
  _ => monthShort,
};

const _monthNamesPt = [
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
const _monthNamesEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _monthNamesEs = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

List<String> monthNamesFor(String lang) => switch (lang) {
  'en' => _monthNamesEn,
  'es' => _monthNamesEs,
  _ => _monthNamesPt,
};

String two(int n) => n.toString().padLeft(2, '0');

/// "14:05".
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "seg, 24 nov" / "Mon, Nov 24" / "lun, 24 nov" (com o ano só se diferente).
String formatDate(DateTime d, DateTime now, {String lang = 'pt'}) {
  final wd = weekdaysShortFor(lang)[d.weekday - 1];
  final m = monthsShortFor(lang)[d.month - 1];
  final base = lang == 'en' ? '$wd, $m ${d.day}' : '$wd, ${d.day} $m';
  return d.year == now.year ? base : '$base ${d.year}';
}

/// Rótulo relativo: "Hoje", "Amanhã", "Ontem" (ou equivalente em `en`/`es`) ou
/// a data, com a hora se [withTime].
String formatRelative(
  DateTime d,
  DateTime now, {
  bool withTime = false,
  String lang = 'pt',
}) {
  final days = startOfDay(d).difference(startOfDay(now)).inDays;
  final label = switch ((days, lang)) {
    (0, 'en') => 'Today',
    (1, 'en') => 'Tomorrow',
    (-1, 'en') => 'Yesterday',
    (0, 'es') => 'Hoy',
    (1, 'es') => 'Mañana',
    (-1, 'es') => 'Ayer',
    (0, _) => 'Hoje',
    (1, _) => 'Amanhã',
    (-1, _) => 'Ontem',
    _ => formatDate(d, now, lang: lang),
  };
  return withTime ? '$label, ${formatTime(d)}' : label;
}
