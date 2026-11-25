/// Textos da lista de books. Puro, sem Flutter.
library;

import '../../core/dates.dart';

/// "editado hoje", "edited today", "editado hoy" etc.
String editedLabel(DateTime updated, DateTime today, {String lang = 'pt'}) {
  final days = startOfDay(today).difference(startOfDay(updated)).inHours ~/ 24;
  final m = monthsShortFor(lang)[updated.month - 1];
  return switch (lang) {
    'en' => switch (days) {
      <= 0 => 'edited today',
      1 => 'edited yesterday',
      < 7 => 'edited $days days ago',
      _ => 'edited $m ${updated.day}',
    },
    'es' => switch (days) {
      <= 0 => 'editado hoy',
      1 => 'editado ayer',
      < 7 => 'editado hace $days días',
      _ => 'editado el ${updated.day} $m',
    },
    _ => switch (days) {
      <= 0 => 'editado hoje',
      1 => 'editado ontem',
      < 7 => 'editado há $days dias',
      _ => 'editado em ${updated.day} $m',
    },
  };
}

/// "1 página" / "12 páginas" (e equivalentes em `en`/`es`).
String pagesLabel(int count, {String lang = 'pt'}) => switch (lang) {
  'en' => '$count ${count == 1 ? 'page' : 'pages'}',
  'es' => '$count ${count == 1 ? 'página' : 'páginas'}',
  _ => '$count ${count == 1 ? 'página' : 'páginas'}',
};
