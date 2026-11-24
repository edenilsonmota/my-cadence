/// Importação de cards em CSV (`frente;verso`). Puro, sem Flutter.
library;

typedef ImportedCard = ({String front, String back});

class CsvImport {
  const CsvImport(this.cards, this.skippedLines);

  final List<ImportedCard> cards;

  /// Números (a partir de 1) das linhas ignoradas por não terem frente e
  /// verso.
  final List<int> skippedLines;
}

/// Lê um CSV com `;` como separador. Aceita campos entre aspas (com `;`,
/// quebras de linha e `""` para aspas dentro), ignora linhas vazias e um
/// cabeçalho `frente;verso`. Colunas além da segunda são ignoradas.
CsvImport parseCardsCsv(String text) {
  final rows = _parseRows(text.replaceFirst('﻿', ''));
  final cards = <ImportedCard>[];
  final skipped = <int>[];
  for (final (index, row) in rows.indexed) {
    final (line, fields) = row;
    if (fields.every((f) => f.trim().isEmpty)) continue;
    final front = fields.isNotEmpty ? fields[0].trim() : '';
    final back = fields.length > 1 ? fields[1].trim() : '';
    if (index == 0 &&
        front.toLowerCase() == 'frente' &&
        back.toLowerCase() == 'verso') {
      continue;
    }
    if (front.isEmpty || back.isEmpty) {
      skipped.add(line);
    } else {
      cards.add((front: front, back: back));
    }
  }
  return CsvImport(cards, skipped);
}

/// Linhas (com o número da linha onde começam) e seus campos.
List<(int, List<String>)> _parseRows(String text) {
  final rows = <(int, List<String>)>[];
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var line = 1;
  var rowStart = 1;

  void endField() {
    fields.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add((rowStart, fields));
    fields = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        if (c == '\n') line++;
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (c == ';') {
      endField();
    } else if (c == '\r') {
      continue;
    } else if (c == '\n') {
      endRow();
      line++;
      rowStart = line;
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || fields.isNotEmpty) endRow();
  return rows;
}
