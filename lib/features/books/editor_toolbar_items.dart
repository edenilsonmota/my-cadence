import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../shared/widgets/text_input_dialog.dart';

/// Insere [node] depois do bloco do cursor (ou no lugar dele, se vazio),
/// como o divisor do pacote faz.
void _insertBlock(EditorState editorState, Node node) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) return;
  final path = selection.end.path;
  final current = editorState.getNodeAtPath(path);
  final delta = current?.delta;
  if (current == null || delta == null) return;
  final at = delta.isEmpty ? path : path.next;
  final transaction = editorState.transaction
    ..insertNode(at, node)
    ..insertNode(at.next, paragraphNode())
    ..afterSelection = Selection.collapsed(Position(path: at.next));
  editorState.apply(transaction);
}

Widget _icon(BuildContext context, IconData icon) =>
    Icon(icon, color: MobileToolbarTheme.of(context).iconColor);

/// Tabela 3 × 3 vazia.
final tableMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (context, _, _) => _icon(context, AppIcons.table),
  actionHandler: (_, editorState) => _insertBlock(
    editorState,
    TableNode.fromList([
      ['', '', ''],
      ['', '', ''],
      ['', '', ''],
    ]).node,
  ),
);

/// Imagem por link (URL).
final imageMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (context, _, _) => _icon(context, AppIcons.image),
  actionHandler: (context, editorState) async {
    final selection = editorState.selection;
    final url = await showTextInputDialog(
      context,
      title: 'Imagem por link',
      label: 'Endereço da imagem (https://…)',
      confirmLabel: 'Inserir',
    );
    final link = url?.trim() ?? '';
    if (!link.startsWith('http')) return;
    editorState.selection = selection;
    _insertBlock(editorState, imageNode(url: link));
  },
);
