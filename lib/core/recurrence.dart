/// Recorrência de tarefas num subconjunto de RRULE (RFC 5545):
/// `FREQ=DAILY|WEEKLY`, `INTERVAL`, `BYDAY` (só semanal) e `UNTIL`.
///
/// Guardar em RRULE permite que o backend leia com `rrule-go` depois.
/// Semanas começam na segunda-feira (WKST=MO, o padrão da RFC).
library;

import 'dates.dart';

enum Frequency { daily, weekly }

class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    Set<int> weekdays = const {},
    DateTime? until,
  }) : weekdays = Set.unmodifiable(weekdays),
       until = until == null ? null : startOfDay(until) {
    if (interval < 1) {
      throw ArgumentError.value(interval, 'interval', 'deve ser >= 1');
    }
    if (weekdays.any((d) => d < DateTime.monday || d > DateTime.sunday)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'use 1 (seg) a 7 (dom)');
    }
    if (frequency == Frequency.daily && weekdays.isNotEmpty) {
      throw ArgumentError.value(weekdays, 'weekdays', 'só vale para semanal');
    }
  }

  /// Lê uma RRULE do subconjunto suportado. Aceita o prefixo `RRULE:`.
  ///
  /// Lança [FormatException] para regras fora do subconjunto.
  factory RecurrenceRule.parse(String rule) {
    var text = rule.trim();
    if (text.toUpperCase().startsWith('RRULE:')) text = text.substring(6);

    Frequency? frequency;
    var interval = 1;
    var weekdays = <int>{};
    DateTime? until;

    for (final part in text.split(';')) {
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq <= 0) throw FormatException('Parte inválida na RRULE', rule);
      final key = part.substring(0, eq).toUpperCase();
      final value = part.substring(eq + 1).toUpperCase();
      switch (key) {
        case 'FREQ':
          frequency = switch (value) {
            'DAILY' => Frequency.daily,
            'WEEKLY' => Frequency.weekly,
            _ => throw FormatException('FREQ não suportada: $value', rule),
          };
        case 'INTERVAL':
          final n = int.tryParse(value);
          if (n == null || n < 1) {
            throw FormatException('INTERVAL inválido: $value', rule);
          }
          interval = n;
        case 'BYDAY':
          weekdays = {
            for (final code in value.split(',')) _parseDay(code, rule),
          };
        case 'UNTIL':
          until = _parseUntil(value, rule);
        case 'WKST' when value == 'MO':
          break;
        default:
          throw FormatException('Parte não suportada: $key', rule);
      }
    }

    if (frequency == null) throw FormatException('FREQ ausente', rule);
    if (frequency == Frequency.daily && weekdays.isNotEmpty) {
      throw FormatException('BYDAY só é suportado com FREQ=WEEKLY', rule);
    }
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      weekdays: weekdays,
      until: until,
    );
  }

  /// Como [RecurrenceRule.parse], mas devolve `null` para regra inválida.
  static RecurrenceRule? tryParse(String rule) {
    try {
      return RecurrenceRule.parse(rule);
    } on FormatException {
      return null;
    }
  }

  final Frequency frequency;

  /// A cada quantos dias ou semanas.
  final int interval;

  /// Dias da semana ([DateTime.monday] a [DateTime.sunday]). Vazio em regra
  /// semanal = mesmo dia da semana da ocorrência atual.
  final Set<int> weekdays;

  /// Último dia (inclusive) com ocorrência. Só a data conta, sem hora.
  final DateTime? until;

  /// Texto RRULE, ex.: `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;UNTIL=20261231`.
  String toRule() {
    final parts = [
      'FREQ=${frequency == Frequency.daily ? 'DAILY' : 'WEEKLY'}',
      if (interval != 1) 'INTERVAL=$interval',
      if (weekdays.isNotEmpty)
        'BYDAY=${[for (final d in _sortedDays) _dayCodes[d - 1]].join(',')}',
      if (until case final u?)
        'UNTIL=${u.year.toString().padLeft(4, '0')}'
            '${_two(u.month)}${_two(u.day)}',
    ];
    return parts.join(';');
  }

  /// Próxima ocorrência depois de [from], que deve ser uma ocorrência da
  /// série (normalmente o `dueAt` atual). Mantém a hora do dia de [from].
  ///
  /// Retorna `null` se a próxima passaria de [until].
  DateTime? next(DateTime from) {
    final DateTime candidate;
    if (frequency == Frequency.daily) {
      candidate = addDays(from, interval);
    } else {
      final days = weekdays.isEmpty ? [from.weekday] : _sortedDays;
      final laterThisWeek = days.where((d) => d > from.weekday);
      if (laterThisWeek.isNotEmpty) {
        candidate = addDays(from, laterThisWeek.first - from.weekday);
      } else {
        final mondayOffset = -(from.weekday - DateTime.monday);
        candidate = addDays(
          from,
          mondayOffset + 7 * interval + (days.first - DateTime.monday),
        );
      }
    }
    final u = until;
    if (u != null && startOfDay(candidate).isAfter(u)) return null;
    return candidate;
  }

  /// Primeira ocorrência estritamente depois de [after], partindo da
  /// ocorrência [from] e pulando as que ficaram no passado.
  DateTime? nextAfter(DateTime from, DateTime after) {
    DateTime? current = from;
    do {
      current = next(current!);
    } while (current != null && !current.isAfter(after));
    return current;
  }

  /// Descrição curta no idioma [lang] (`pt`, `en` ou `es`), ex.:
  /// "A cada 2 semanas: seg e qua".
  String describe({String lang = 'pt'}) {
    final buffer = StringBuffer();
    if (frequency == Frequency.daily) {
      buffer.write(switch (lang) {
        'en' => interval == 1 ? 'Every day' : 'Every $interval days',
        'es' => interval == 1 ? 'Todos los días' : 'Cada $interval días',
        _ => interval == 1 ? 'Todo dia' : 'A cada $interval dias',
      });
    } else {
      buffer.write(switch (lang) {
        'en' => interval == 1 ? 'Every week' : 'Every $interval weeks',
        'es' => interval == 1 ? 'Cada semana' : 'Cada $interval semanas',
        _ => interval == 1 ? 'Toda semana' : 'A cada $interval semanas',
      });
      if (weekdays.isNotEmpty) {
        final names = weekdaysShortFor(lang);
        buffer.write(': ');
        buffer.write(
          _joinList([for (final d in _sortedDays) names[d - 1]], lang),
        );
      }
    }
    if (until case final u?) {
      final date = lang == 'en'
          ? '${u.year}-${_two(u.month)}-${_two(u.day)}'
          : '${_two(u.day)}/${_two(u.month)}/${u.year}';
      buffer.write(switch (lang) {
        'en' => ', until $date',
        'es' => ', hasta $date',
        _ => ', até $date',
      });
    }
    return buffer.toString();
  }

  List<int> get _sortedDays => weekdays.toList()..sort();

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.until == until &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode => Object.hash(
    frequency,
    interval,
    until,
    Object.hashAllUnordered(weekdays),
  );

  @override
  String toString() => 'RecurrenceRule(${toRule()})';
}

const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

int _parseDay(String code, String rule) {
  final index = _dayCodes.indexOf(code.trim());
  if (index < 0) throw FormatException('Dia inválido em BYDAY: $code', rule);
  return index + 1;
}

/// Aceita `AAAAMMDD` ou `AAAAMMDDTHHMMSS[Z]`. Com `Z`, converte para o fuso
/// local antes de pegar a data.
DateTime _parseUntil(String value, String rule) {
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$',
  ).firstMatch(value);
  if (match == null) throw FormatException('UNTIL inválido: $value', rule);
  int g(int i) => int.parse(match.group(i) ?? '0');
  if (match.group(7) != null) {
    return DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6)).toLocal();
  }
  return DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
}

String _two(int n) => n.toString().padLeft(2, '0');

String _joinList(List<String> items, String lang) {
  if (items.length <= 1) return items.join();
  final conj = switch (lang) {
    'en' => 'and',
    'es' => 'y',
    _ => 'e',
  };
  return '${items.sublist(0, items.length - 1).join(', ')} $conj ${items.last}';
}
