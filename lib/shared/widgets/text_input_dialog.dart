import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';

/// Diálogo com um campo de texto. Devolve o texto (sem espaços nas pontas)
/// ou `null` se cancelado ou vazio.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? confirmLabel,
  String initialValue = '',
}) {
  // Sem isso, ao fechar o diálogo o foco volta a um campo da tela de trás.
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<String>(
    context: context,
    builder: (ctx) => _TextInputDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel ?? ctx.l10n.actionCreate,
      initialValue: initialValue,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
