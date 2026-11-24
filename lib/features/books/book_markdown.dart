/// Conversões dos books: JSON do editor (fonte da verdade) ↔ Markdown
/// (importar/exportar), árvore de páginas e zip do book.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:archive/archive.dart';

import '../../data/db/database.dart';

// ─── Conteúdo da página ──────────────────────────────────────────────────────

/// Documento do editor a partir da coluna `content` (JSON). Vazio = página
/// nova, com um parágrafo para digitar.
Document documentFromContent(String content) {
  if (content.trim().isEmpty) return Document.blank(withInitialText: true);
  return Document.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

String contentFromDocument(Document document) => jsonEncode(document.toJson());

/// Markdown de uma página: o título vira `# Título` no topo. Blocos separados
/// por linha em branco (sem ela, dois parágrafos voltam como um só).
String pageToMarkdown(String title, String content) {
  final body = documentToMarkdown(
    documentFromContent(content),
    lineBreak: '\n',
  ).trimRight();
  return body.isEmpty ? '# $title\n' : '# $title\n\n$body\n';
}

typedef ImportedPageContent = ({String title, String content});

/// Página a partir de um Markdown. Um `# Título` no início vira o título (e
/// sai do corpo); sem ele, usa [fallbackTitle] (ex.: nome do arquivo).
ImportedPageContent pageFromMarkdown(
  String markdown, {
  required String fallbackTitle,
}) {
  final document = markdownToDocument(
    markdown.replaceFirst('﻿', '').replaceAll('\r\n', '\n'),
  );
  var title = fallbackTitle;
  final first = document.root.children.firstOrNull;
  if (first != null &&
      first.type == HeadingBlockKeys.type &&
      first.attributes[HeadingBlockKeys.level] == 1) {
    final text = first.delta?.toPlainText().trim() ?? '';
    if (text.isNotEmpty) {
      title = text;
      document.delete([0]);
    }
  }
  if (document.root.children.isEmpty) {
    return (title: title, content: '');
  }
  return (title: title, content: contentFromDocument(document));
}

// ─── Árvore de páginas ───────────────────────────────────────────────────────

/// Páginas em ordem de leitura (pai, depois as subpáginas, por `sortOrder`),
/// com a profundidade de cada uma. Subpágina com pai ausente vira raiz.
List<(NotePage, int)> flattenPages(Iterable<NotePage> pages) {
  final ids = {for (final p in pages) p.id};
  final childrenOf = <String?, List<NotePage>>{};
  for (final page in pages) {
    final parent = ids.contains(page.parentPageId) ? page.parentPageId : null;
    (childrenOf[parent] ??= []).add(page);
  }
  for (final list in childrenOf.values) {
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  }
  final out = <(NotePage, int)>[];
  void visit(String? parent, int depth) {
    for (final page in childrenOf[parent] ?? const <NotePage>[]) {
      out.add((page, depth));
      visit(page.id, depth + 1);
    }
  }

  visit(null, 0);
  return out;
}

/// Irmãs da página (mesmo pai), em ordem.
List<NotePage> siblingsOf(NotePage page, Iterable<NotePage> pages) =>
    pages.where((p) => p.parentPageId == page.parentPageId).toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });

// ─── Book em zip ─────────────────────────────────────────────────────────────

/// Nome seguro para arquivo (sem / \ : * ? " < > |).
String safeFileName(String title) {
  final cleaned = title
      .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final name = cleaned.isEmpty ? 'Sem título' : cleaned;
  return name.length > 80 ? name.substring(0, 80).trim() : name;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Arquivos do book: um `.md` por página, com a posição na árvore no nome
/// (`01 - A.md`, `01.01 - A1.md`, `02 - B.md`) para manter ordem e hierarquia.
List<({String name, String markdown})> bookFiles(Iterable<NotePage> pages) {
  final files = <({String name, String markdown})>[];
  final counters = <int>[];
  for (final (page, depth) in flattenPages(pages)) {
    if (counters.length > depth + 1) {
      counters.removeRange(depth + 1, counters.length);
    }
    if (counters.length == depth + 1) {
      counters[depth]++;
    } else {
      counters.add(1);
    }
    final number = counters.map(_two).join('.');
    files.add((
      name: '$number - ${safeFileName(page.title)}.md',
      markdown: pageToMarkdown(page.title, page.content),
    ));
  }
  return files;
}

Uint8List bookZip(Iterable<NotePage> pages) {
  final archive = Archive();
  for (final file in bookFiles(pages)) {
    archive.addFile(ArchiveFile.bytes(file.name, utf8.encode(file.markdown)));
  }
  return ZipEncoder().encodeBytes(archive);
}

// ─── Importar ────────────────────────────────────────────────────────────────

class ImportedPage {
  ImportedPage(this.title, this.content);

  final String title;
  final String content;
  final List<ImportedPage> children = [];
}

final _numbered = RegExp(r'^(\d+(?:\.\d+)*) - (.+)$');

String _baseName(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  return name.toLowerCase().endsWith('.md')
      ? name.substring(0, name.length - 3)
      : name;
}

/// Monta as páginas de um book a partir de arquivos Markdown (nome → texto).
/// Nomes no formato da exportação (`01.02 - Título`) refazem a hierarquia;
/// os demais entram como páginas de primeiro nível, em ordem alfabética.
List<ImportedPage> importBookPages(Map<String, String> files) {
  final entries = files.entries.toList()
    ..sort((a, b) => _sortKey(a.key).compareTo(_sortKey(b.key)));
  final roots = <ImportedPage>[];
  final byNumber = <String, ImportedPage>{};
  for (final MapEntry(key: path, value: text) in entries) {
    final base = _baseName(path);
    final match = _numbered.firstMatch(base);
    final page = pageFromMarkdown(text, fallbackTitle: match?.group(2) ?? base);
    final imported = ImportedPage(page.title, page.content);
    if (match == null) {
      roots.add(imported);
      continue;
    }
    final number = match.group(1)!;
    byNumber[number] = imported;
    final dot = number.lastIndexOf('.');
    final parent = dot < 0 ? null : byNumber[number.substring(0, dot)];
    (parent?.children ?? roots).add(imported);
  }
  return roots;
}

/// Ordena "01.02" numericamente por partes e o resto alfabeticamente.
String _sortKey(String path) {
  final base = _baseName(path);
  final match = _numbered.firstMatch(base);
  if (match == null) return '1${base.toLowerCase()}';
  final parts = match.group(1)!.split('.').map((p) => p.padLeft(6, '0'));
  return '0${parts.join('.')}';
}

/// Arquivos `.md` de dentro de um zip (nome → texto).
Map<String, String> markdownFilesFromZip(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  return {
    for (final file in archive.files)
      if (file.isFile && file.name.toLowerCase().endsWith('.md'))
        file.name: utf8.decode(file.content, allowMalformed: true),
  };
}
