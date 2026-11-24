/// Textos da lista de books. Puro, sem Flutter.
library;

import '../../core/dates.dart';

/// "editado hoje", "editado ontem", "editado há 3 dias" ou "editado em 2 nov".
String editedLabel(DateTime updated, DateTime today) {
  final days = startOfDay(today).difference(startOfDay(updated)).inHours ~/ 24;
  return switch (days) {
    <= 0 => 'editado hoje',
    1 => 'editado ontem',
    < 7 => 'editado há $days dias',
    _ => 'editado em ${updated.day} ${monthShort[updated.month - 1]}',
  };
}

/// "1 página" / "12 páginas".
String pagesLabel(int count) => '$count ${count == 1 ? 'página' : 'páginas'}';
