/// Conteúdo de um modelo de tarefa (JSON guardado em `TaskTemplates`).
/// Puro, sem Flutter. Datas e repetição ficam de fora: o modelo serve para
/// qualquer dia, e o formulário abre logo depois para escolher.
library;

import 'dart:convert';

import '../../data/db/database.dart';
import '../../data/db/enums.dart';

class TaskTemplateData {
  const TaskTemplateData({
    required this.title,
    this.notes,
    this.priority = 0,
    this.colorKey,
    this.iconKey,
    this.estimatedMinutes,
    this.reminderOffsets,
    this.reminderMode = ReminderMode.notificacao,
    this.nagIntervalMinutes,
    this.hasTime = false,
    this.tagIds = const [],
    this.notebookIds = const [],
    this.deckIds = const [],
    this.subtasks = const [],
  });

  /// Copia de [task] o que vale repetir, com os vínculos e os títulos das
  /// subtarefas (só o primeiro nível).
  factory TaskTemplateData.fromTask(
    Task task, {
    Iterable<String> tagIds = const [],
    Iterable<String> notebookIds = const [],
    Iterable<String> deckIds = const [],
    Iterable<String> subtasks = const [],
  }) => TaskTemplateData(
    title: task.title,
    notes: task.notes,
    priority: task.priority,
    colorKey: task.colorKey,
    iconKey: task.iconKey,
    estimatedMinutes: task.estimatedMinutes,
    reminderOffsets: task.reminderOffsets,
    reminderMode: task.reminderMode,
    nagIntervalMinutes: task.nagIntervalMinutes,
    hasTime: task.hasTime,
    tagIds: tagIds.toList(),
    notebookIds: notebookIds.toList(),
    deckIds: deckIds.toList(),
    subtasks: subtasks.toList(),
  );

  /// Lê o JSON salvo; campo ausente ou estranho cai no padrão (modelos de
  /// versões futuras continuam abrindo).
  factory TaskTemplateData.decode(String payload, {String fallbackTitle = ''}) {
    Map<String, Object?> json;
    try {
      json = (jsonDecode(payload) as Map).cast<String, Object?>();
    } on Object {
      json = const {};
    }
    List<String> strings(String key) => [
      for (final v in (json[key] as List?) ?? const []) '$v',
    ];
    int? intOf(String key) => json[key] is int ? json[key]! as int : null;
    String? stringOf(String key) =>
        json[key] is String ? json[key]! as String : null;
    return TaskTemplateData(
      title: stringOf('title') ?? fallbackTitle,
      notes: stringOf('notes'),
      priority: (intOf('priority') ?? 0).clamp(0, 3),
      colorKey: stringOf('colorKey'),
      iconKey: stringOf('iconKey'),
      estimatedMinutes: intOf('estimatedMinutes'),
      reminderOffsets: stringOf('reminderOffsets'),
      reminderMode:
          ReminderMode.values.asNameMap()[stringOf('reminderMode')] ??
          ReminderMode.notificacao,
      nagIntervalMinutes: intOf('nagIntervalMinutes'),
      hasTime: json['hasTime'] == true,
      tagIds: strings('tagIds'),
      notebookIds: strings('notebookIds'),
      deckIds: strings('deckIds'),
      subtasks: strings('subtasks'),
    );
  }

  final String title;
  final String? notes;
  final int priority;
  final String? colorKey;
  final String? iconKey;
  final int? estimatedMinutes;
  final String? reminderOffsets;
  final ReminderMode reminderMode;
  final int? nagIntervalMinutes;
  final bool hasTime;
  final List<String> tagIds;
  final List<String> notebookIds;
  final List<String> deckIds;

  /// Títulos das subtarefas, na ordem.
  final List<String> subtasks;

  String encode() => jsonEncode({
    'title': title,
    'notes': ?notes,
    'priority': priority,
    'colorKey': ?colorKey,
    'iconKey': ?iconKey,
    'estimatedMinutes': ?estimatedMinutes,
    'reminderOffsets': ?reminderOffsets,
    'reminderMode': reminderMode.name,
    'nagIntervalMinutes': ?nagIntervalMinutes,
    'hasTime': hasTime,
    'tagIds': tagIds,
    'notebookIds': notebookIds,
    'deckIds': deckIds,
    'subtasks': subtasks,
  });
}
