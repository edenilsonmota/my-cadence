import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/features/books/book_markdown.dart';

NotePage page(
  String id, {
  required String title,
  String? parent,
  int order = 0,
  String content = '',
}) => NotePage(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dirty: true,
  notebookId: 'book',
  parentPageId: parent,
  title: title,
  content: content,
  sortOrder: order,
);

String contentOf(String markdown) =>
    contentFromDocument(markdownToDocument(markdown));

void main() {
  group('página', () {
    test('conteúdo vazio vira documento com um parágrafo', () {
      final doc = documentFromContent('');
      expect(doc.root.children, hasLength(1));
      expect(doc.root.children.single.type, ParagraphBlockKeys.type);
    });

    test('JSON vai e volta sem perdas', () {
      final content = contentOf('# H\n\nTexto **forte** e *itálico*');
      expect(contentFromDocument(documentFromContent(content)), content);
    });

    test('exporta com título no topo e linha em branco entre blocos', () {
      final md = pageToMarkdown('Resumo', contentOf('P1\n\nP2\n\n- a\n- b'));
      expect(md, '# Resumo\n\nP1\n\nP2\n\n* a\n\n* b\n');
    });

    test('importa: # inicial vira título e sai do corpo', () {
      final p = pageFromMarkdown(
        '# Derivadas\n\nRegra da **cadeia**\n\n- item',
        fallbackTitle: 'arquivo',
      );
      expect(p.title, 'Derivadas');
      final doc = documentFromContent(p.content);
      expect(doc.root.children.map((n) => n.type), [
        ParagraphBlockKeys.type,
        BulletedListBlockKeys.type,
      ]);
    });

    test('sem # inicial usa o nome do arquivo; aceita BOM e CRLF', () {
      final p = pageFromMarkdown(
        '﻿Linha 1\r\n\r\nLinha 2',
        fallbackTitle: 'notas',
      );
      expect(p.title, 'notas');
      expect(documentFromContent(p.content).root.children, hasLength(2));
    });

    test('ida e volta Markdown preserva o essencial', () {
      const original =
          '# Book\n\n## Seção\n\nTexto com **negrito**, *itálico* e `código`.'
          '\n\n- um\n- dois\n\n1. primeiro\n2. segundo\n\n> citação\n\n- [ ] tarefa';
      final first = pageFromMarkdown(original, fallbackTitle: 'x');
      final exported = pageToMarkdown(first.title, first.content);
      final second = pageFromMarkdown(exported, fallbackTitle: 'y');
      expect(second.title, 'Book');
      expect(second.content, first.content);
    });
  });

  group('árvore', () {
    final pages = [
      page('b', title: 'B', order: 2),
      page('a', title: 'A', order: 1),
      page('a2', title: 'A2', parent: 'a', order: 2),
      page('a1', title: 'A1', parent: 'a', order: 1),
      page('a1x', title: 'A1x', parent: 'a1'),
      page('orfa', title: 'Órfã', parent: 'sumiu', order: 3),
    ];

    test('ordem de leitura com profundidade', () {
      expect(
        [for (final (p, d) in flattenPages(pages)) '${p.title}@$d'],
        ['A@0', 'A1@1', 'A1x@2', 'A2@1', 'B@0', 'Órfã@0'],
      );
    });

    test('nomes do zip guardam ordem e hierarquia', () {
      expect(bookFiles(pages).map((f) => f.name), [
        '01 - A.md',
        '01.01 - A1.md',
        '01.01.01 - A1x.md',
        '01.02 - A2.md',
        '02 - B.md',
        '03 - Órfã.md',
      ]);
    });

    test('nome de arquivo seguro', () {
      expect(safeFileName('a/b: c?'), 'a b c');
      expect(safeFileName('   '), 'Sem título');
    });
  });

  group('importar book', () {
    test('zip exportado volta com a mesma árvore e conteúdo', () {
      final pages = [
        page('a', title: 'A', order: 1, content: contentOf('texto A')),
        page('a1', title: 'A1', parent: 'a', content: contentOf('texto A1')),
        page('b', title: 'B', order: 2, content: contentOf('- x\n- y')),
      ];
      final files = markdownFilesFromZip(bookZip(pages));
      final roots = importBookPages(files);

      expect(roots.map((p) => p.title), ['A', 'B']);
      expect(roots.first.children.single.title, 'A1');
      expect(roots.first.content, pages[0].content);
      expect(roots.first.children.single.content, pages[1].content);
      expect(roots.last.content, pages[2].content);
    });

    test(
      'arquivos soltos entram em ordem alfabética, ordem numérica antes',
      () {
        final roots = importBookPages({
          'zeta.md': 'z',
          '10 - Dez.md': '# Dez',
          '2 - Dois.md': '# Dois',
          'alfa.md': '# Alfa de verdade\n\ntexto',
        });
        expect(roots.map((p) => p.title), [
          'Dois',
          'Dez',
          'Alfa de verdade',
          'zeta',
        ]);
      },
    );
  });
}
