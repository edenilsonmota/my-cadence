import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/shared/widgets/simple_markdown.dart';

void main() {
  test('negrito, itálico e código', () {
    expect(parseInlineMarkdown('a **b** *c* _d_ `e` f'), const [
      MdSpan('a '),
      MdSpan('b', bold: true),
      MdSpan(' '),
      MdSpan('c', italic: true),
      MdSpan(' '),
      MdSpan('d', italic: true),
      MdSpan(' '),
      MdSpan('e', code: true),
      MdSpan(' f'),
    ]);
  });

  test('marcador sem par fica como texto', () {
    expect(parseInlineMarkdown('2 * 3 = 6'), const [MdSpan('2 * 3 = 6')]);
  });

  testWidgets('lista vira marcador', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SimpleMarkdown('Itens:\n- um\n- **dois**')),
    );
    final text = tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText();
    expect(text, 'Itens:\n•  um\n•  dois');
  });
}
