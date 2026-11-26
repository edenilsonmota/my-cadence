/// Importação de cards em CSV (`frente;verso`). Puro, sem Flutter.
library;

typedef ImportedCard = ({String front, String back});

typedef DuplicateFilterResult = ({
  List<ImportedCard> unique,
  int duplicateCount,
});

class CsvImport {
  const CsvImport(this.cards, this.skippedLines);

  final List<ImportedCard> cards;

  /// Números (a partir de 1) das linhas ignoradas por não terem frente e
  /// verso.
  final List<int> skippedLines;
}

const _headerPairs = {
  ('frente', 'verso'),
  ('front', 'back'),
  ('frente', 'reverso'),
};

/// Normaliza a frente de um card para detecção de duplicados (ignora
/// maiúsculas e espaços extras).
String normalizeCardFront(String front) =>
    front.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Remove cards cuja frente já existe em [existingFronts] ou se repete no
/// próprio lote, mantendo a primeira ocorrência.
DuplicateFilterResult filterDuplicateCards(
  List<ImportedCard> cards, {
  Iterable<String> existingFronts = const [],
}) {
  final seen = <String>{for (final f in existingFronts) normalizeCardFront(f)};
  final unique = <ImportedCard>[];
  var duplicates = 0;
  for (final card in cards) {
    if (seen.add(normalizeCardFront(card.front))) {
      unique.add(card);
    } else {
      duplicates++;
    }
  }
  return (unique: unique, duplicateCount: duplicates);
}

/// Lê um CSV com `;` como separador. Aceita campos entre aspas (com `;`,
/// quebras de linha e `""` para aspas dentro), ignora linhas vazias e um
/// cabeçalho `frente;verso` (ou `front;back` / `frente;reverso`). Colunas
/// além da segunda são ignoradas.
CsvImport parseCardsCsv(String text) {
  final rows = _parseRows(text.replaceFirst('\uFEFF', ''));
  final cards = <ImportedCard>[];
  final skipped = <int>[];
  var sawNonEmpty = false;
  for (final row in rows) {
    final (line, fields) = row;
    if (fields.every((f) => f.trim().isEmpty)) continue;
    final front = fields.isNotEmpty ? fields[0].trim() : '';
    final back = fields.length > 1 ? fields[1].trim() : '';
    final isFirst = !sawNonEmpty;
    sawNonEmpty = true;
    if (isFirst &&
        _headerPairs.contains((front.toLowerCase(), back.toLowerCase()))) {
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

/// Gera texto CSV (`frente;verso`) pronto para copiar ou salvar em arquivo.
/// Envolve em aspas campos que contenham `;`, `"`, ou quebra de linha.
String exportCardsCsv(Iterable<ImportedCard> cards) {
  String escape(String value) {
    final needsQuotes =
        value.contains(';') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  final buf = StringBuffer();
  for (final card in cards) {
    buf
      ..write(escape(card.front))
      ..write(';')
      ..writeln(escape(card.back));
  }
  return buf.toString();
}
