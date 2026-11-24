import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Garante que a dependência do editor (fork fixado) compila e monta neste
// Flutter, e que o Markdown faz ida e volta no essencial.
void main() {
  testWidgets('AppFlowyEditor monta e converte Markdown', (tester) async {
    final state = EditorState(
      document: markdownToDocument('# Título\n\nTexto **forte**\n\n- item'),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppFlowyEditorLocalizations.delegate],
        home: Scaffold(body: AppFlowyEditor(editorState: state)),
      ),
    );
    final md = documentToMarkdown(state.document);
    expect(md, contains('# Título'));
    expect(md, contains('**forte**'));
    expect(md, contains('* item'));
  });

  test('sem linha em branco entre blocos, parágrafos se fundem', () {
    final doc = markdownToDocument('P1\n\nP2');
    final semQuebra = markdownToDocument(documentToMarkdown(doc));
    final comQuebra = markdownToDocument(
      documentToMarkdown(doc, lineBreak: '\n'),
    );
    // Por isso a exportação usa lineBreak: '\n'.
    expect(semQuebra.root.children, hasLength(1));
    expect(comQuebra.root.children, hasLength(2));
  });
}
