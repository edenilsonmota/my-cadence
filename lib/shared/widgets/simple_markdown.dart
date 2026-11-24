import 'package:flutter/material.dart';

/// Trecho de texto com estilo, resultado de [parseInlineMarkdown].
class MdSpan {
  const MdSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  @override
  bool operator ==(Object other) =>
      other is MdSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code;

  @override
  int get hashCode => Object.hash(text, bold, italic, code);

  @override
  String toString() =>
      'MdSpan("$text"${bold ? ' b' : ''}${italic ? ' i' : ''}${code ? ' c' : ''})';
}

/// Markdown de linha: `**negrito**`, `*itálico*` (ou `_itálico_`) e
/// `` `código` ``. Marcadores sem par ficam como texto.
List<MdSpan> parseInlineMarkdown(String text) {
  final spans = <MdSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\*(.+?)\*|_(.+?)_');
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) spans.add(MdSpan(text.substring(last, m.start)));
    if (m.group(1) != null) {
      spans.add(MdSpan(m.group(1)!, bold: true));
    } else if (m.group(2) != null) {
      spans.add(MdSpan(m.group(2)!, code: true));
    } else {
      spans.add(MdSpan(m.group(3) ?? m.group(4)!, italic: true));
    }
    last = m.end;
  }
  if (last < text.length) spans.add(MdSpan(text.substring(last)));
  return spans;
}

/// Mostra texto com Markdown simples: os estilos de [parseInlineMarkdown],
/// listas com `- ` ou `* ` e quebras de linha.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.text, {this.style, this.textAlign, super.key});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final codeBg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final lines = text.split('\n');
    final spans = <InlineSpan>[];
    for (final (i, raw) in lines.indexed) {
      var line = raw;
      final bullet = RegExp(r'^\s*[-*]\s+').firstMatch(line);
      if (bullet != null) {
        spans.add(const TextSpan(text: '•  '));
        line = line.substring(bullet.end);
      }
      for (final s in parseInlineMarkdown(line)) {
        spans.add(
          TextSpan(
            text: s.text,
            style: TextStyle(
              fontWeight: s.bold ? FontWeight.bold : null,
              fontStyle: s.italic ? FontStyle.italic : null,
              fontFamily: s.code ? 'monospace' : null,
              backgroundColor: s.code ? codeBg : null,
            ),
          ),
        );
      }
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: textAlign,
    );
  }
}
