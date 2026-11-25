import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/l10n/locale_settings.dart';
import 'package:my_cadence/core/dates.dart';
import 'package:my_cadence/core/recurrence.dart';
import 'package:my_cadence/features/books/books_format.dart';
import 'package:my_cadence/features/cards/fsrs_bridge.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';

void main() {
  group('AppLocale e device.locale', () {
    test('parseAppLocale interpreta valores válidos e cai em system', () {
      expect(parseAppLocale(null), AppLocale.system);
      expect(parseAppLocale(''), AppLocale.system);
      expect(parseAppLocale('invalido'), AppLocale.system);
      expect(parseAppLocale('system'), AppLocale.system);
      expect(parseAppLocale('pt'), AppLocale.pt);
      expect(parseAppLocale('en'), AppLocale.en);
      expect(parseAppLocale('es'), AppLocale.es);
      expect(parseAppLocale(' en '), AppLocale.en);
    });

    test('device.locale é configuração local (não sincroniza no Drive)', () {
      expect(isLocalSetting(appLocaleSettingKey), isTrue);
    });
  });

  group('formatadores puros em pt, en e es', () {
    final today = DateTime(2026, 11, 23);

    test('formatRelative e formatDate respeitam o idioma', () {
      expect(formatRelative(today, today, lang: 'pt'), 'Hoje');
      expect(formatRelative(today, today, lang: 'en'), 'Today');
      expect(formatRelative(today, today, lang: 'es'), 'Hoy');

      final tomorrow = DateTime(2026, 11, 24, 9, 30);
      expect(
        formatRelative(tomorrow, today, withTime: true, lang: 'en'),
        'Tomorrow, 09:30',
      );
      expect(
        formatRelative(tomorrow, today, withTime: true, lang: 'es'),
        'Mañana, 09:30',
      );

      final other = DateTime(2026, 5, 10);
      expect(formatDate(other, today, lang: 'pt'), 'dom, 10 mai');
      expect(formatDate(other, today, lang: 'en'), 'Sun, May 10');
      expect(formatDate(other, today, lang: 'es'), 'dom, 10 may');
    });

    test('RecurrenceRule.describe descreve em pt, en e es', () {
      final daily = RecurrenceRule(frequency: Frequency.daily);
      expect(daily.describe(lang: 'pt'), 'Todo dia');
      expect(daily.describe(lang: 'en'), 'Every day');
      expect(daily.describe(lang: 'es'), 'Todos los días');

      final weekly = RecurrenceRule(
        frequency: Frequency.weekly,
        weekdays: const {DateTime.monday, DateTime.friday},
      );
      expect(weekly.describe(lang: 'pt'), 'Toda semana: seg e sex');
      expect(weekly.describe(lang: 'en'), 'Every week: Mon and Fri');
      expect(weekly.describe(lang: 'es'), 'Cada semana: lun y vie');
    });

    test('books_format (pagesLabel e editedLabel) respeitam o idioma', () {
      expect(pagesLabel(0, lang: 'en'), '0 pages');
      expect(pagesLabel(1, lang: 'en'), '1 page');
      expect(pagesLabel(3, lang: 'en'), '3 pages');
      expect(pagesLabel(0, lang: 'es'), '0 páginas');
      expect(pagesLabel(1, lang: 'es'), '1 página');
      expect(pagesLabel(3, lang: 'es'), '3 páginas');

      expect(editedLabel(today, today, lang: 'en'), 'edited today');
      expect(editedLabel(today, today, lang: 'es'), 'editado hoy');
    });

    test('formatInterval formata meses e anos em pt, en e es', () {
      expect(formatInterval(const Duration(days: 60), lang: 'pt'), '2 meses');
      expect(formatInterval(const Duration(days: 60), lang: 'en'), '2 mo');
      expect(formatInterval(const Duration(days: 60), lang: 'es'), '2 meses');

      expect(formatInterval(const Duration(days: 365), lang: 'pt'), '1 ano');
      expect(formatInterval(const Duration(days: 365), lang: 'en'), '1 yr');
      expect(formatInterval(const Duration(days: 365), lang: 'es'), '1 año');
    });
  });
}
