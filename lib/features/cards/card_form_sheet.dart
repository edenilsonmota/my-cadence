import 'package:flutter/material.dart';

typedef CardText = ({String front, String back});

/// Painel para criar um card (frente e verso). Devolve o texto ou `null`.
Future<CardText?> showCardForm(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CardText>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CardForm(),
  );
}

class _CardForm extends StatefulWidget {
  const _CardForm();

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  final _front = TextEditingController();
  final _back = TextEditingController();

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  bool get _valid =>
      _front.text.trim().isNotEmpty && _back.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sobe junto com o teclado.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Novo card', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _front,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Frente'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _back,
            minLines: 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Verso'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _valid
                ? () => Navigator.of(context)
                      .pop((front: _front.text.trim(), back: _back.text.trim()))
                : null,
            child: const Text('Salvar card'),
          ),
        ],
      ),
    );
  }
}
