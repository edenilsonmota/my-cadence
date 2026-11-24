import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Valores visuais soltos fora de `lib/app/theme/`: cores, ícones do
/// Material, `fontSize` e durações em milissegundos. Tudo isso deve vir do
/// tema (tokens, `AppIcons`, paleta).
final _loose = RegExp(
  r'\bColors\.|\bColor\(0x|\bIcons\.|fontSize:|Duration\(milliseconds: \d'
  r'|\b0x[fF]{2}[0-9a-fA-F]{6}\b',
);

/// Dívida visual permitida por arquivo (catraca): pode diminuir, nunca
/// aumentar, e arquivo novo começa em zero. Ao migrar um arquivo para os
/// tokens, baixe (ou remova) o número dele aqui.
const _allowed = <String, int>{
  'app/shell.dart': 10,
  'features/books/book_actions.dart': 1,
  'features/books/book_page.dart': 6,
  'features/books/books_page.dart': 6,
  'features/books/page_editor_page.dart': 6,
  'features/calendar/agenda_page.dart': 10,
  'features/calendar/calendar_providers.dart': 6,
  'features/calendar/month_view.dart': 1,
  'features/calendar/timeline_view.dart': 5,
  'features/cards/card_form_sheet.dart': 1,
  'features/cards/cards_list_page.dart': 4,
  'features/cards/review_page.dart': 7,
  'features/cards/review_session_page.dart': 4,
  'features/pomodoro/pomodoro_mini_player.dart': 6,
  'features/pomodoro/pomodoro_page.dart': 5,
  'features/stats/stats_page.dart': 3,
  'features/tasks/hub/hub_tools.dart': 15,
  'features/tasks/task_form_page.dart': 7,
  'features/tasks/task_labels.dart': 12,
  'features/tasks/task_page.dart': 18,
  'features/tasks/tasks_page.dart': 9,
  'features/tasks/today_page.dart': 4,
  'features/tasks/widgets/task_picker.dart': 2,
  'features/tasks/widgets/task_tile.dart': 9,
  'shared/widgets/app_drawer.dart': 3,
  'shared/widgets/number_stepper.dart': 2,
};

/// Exceções permanentes (o valor precisa ser literal ali).
const _permanent = <String, int>{
  // Android exige a cor da notificação em ARGB; core/ não importa o tema.
  'core/notifications.dart': 1,
  // Máscara de 32 bits do hash FNV-1a, não é cor.
  'core/notification_id.dart': 1,
  // Espera do salvamento automático (comportamento, não animação).
  'shared/debounced_saver.dart': 1,
};

void main() {
  test('sem valores visuais soltos fora do tema (catraca)', () {
    final over = <String>[];
    final below = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      final path = file.path.replaceAll(r'\', '/');
      if (file is! File ||
          !path.endsWith('.dart') ||
          path.endsWith('.g.dart') ||
          path.startsWith('lib/app/theme/')) {
        continue;
      }
      final rel = path.substring(4);
      final count = _loose.allMatches(file.readAsStringSync()).length;
      final limit = (_allowed[rel] ?? 0) + (_permanent[rel] ?? 0);
      if (count > limit) over.add('$rel: $count (máx. $limit)');
      if (count < (_allowed[rel] ?? 0) + (_permanent[rel] ?? 0)) {
        below.add('$rel: $count');
      }
    }
    expect(over, isEmpty, reason: 'use os tokens do tema');
    // Lembrete para baixar a catraca quando um arquivo melhora.
    if (below.isNotEmpty) {
      // ignore: avoid_print
      print('Baixe a catraca em visual_debt_test.dart: ${below.join(', ')}');
    }
  });
}
