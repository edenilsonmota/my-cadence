import 'package:flutter/material.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/theme/app_theme.dart';
import '../tags_logic.dart';

typedef TagFormResult = ({String name, String colorKey});

/// Diálogo para criar ou editar uma tag (nome e cor).
///
/// Quando [initialName] é nulo, cria uma nova tag; caso contrário, edita.
Future<TagFormResult?> showTagFormDialog(
  BuildContext context, {
  String? initialName,
  String? initialColorKey,
  Iterable<String> existingNames = const [],
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<TagFormResult>(
    context: context,
    builder: (_) => _TagFormDialog(
      initialName: initialName,
      initialColorKey: initialColorKey,
      existingNames: existingNames,
    ),
  );
}

/// Diálogo rápido para trocar a cor de uma tag em um toque.
Future<String?> showTagColorDialog(
  BuildContext context, {
  required String tagName,
  required String currentColorKey,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final current = PaletteKey.tryParse(currentColorKey) ?? PaletteKey.azul;
  return showDialog<String>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.tagChangeColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tagName,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.space.lg),
            _PaletteSwatches(
              selected: current,
              onPick: (key) => Navigator.of(context).pop(key.name),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
        ],
      );
    },
  );
}

class _TagFormDialog extends StatefulWidget {
  const _TagFormDialog({
    required this.initialName,
    required this.initialColorKey,
    required this.existingNames,
  });

  final String? initialName;
  final String? initialColorKey;
  final Iterable<String> existingNames;

  @override
  State<_TagFormDialog> createState() => _TagFormDialogState();
}

class _TagFormDialogState extends State<_TagFormDialog> {
  late final _name = TextEditingController(text: widget.initialName ?? '');
  late PaletteKey _color =
      PaletteKey.tryParse(widget.initialColorKey) ?? PaletteKey.azul;
  late final Set<String> _taken = {
    for (final name in widget.existingNames) normalizeTagName(name),
  };

  bool get _isEditing => widget.initialName != null;

  bool get _isDuplicate {
    final normalized = normalizeTagName(_name.text);
    return normalized.isNotEmpty && _taken.contains(normalized);
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && !_isDuplicate;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop((name: _name.text.trim(), colorKey: _color.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(_isEditing ? l10n.tagEdit : l10n.tagNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.reviewNameLabel,
              errorText: _isDuplicate ? l10n.tagDuplicateError : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: context.space.lg),
          _PaletteSwatches(
            selected: _color,
            onPick: (key) => setState(() => _color = key),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(_isEditing ? l10n.actionSave : l10n.actionCreate),
        ),
      ],
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  const _PaletteSwatches({required this.selected, required this.onPick});

  final PaletteKey selected;
  final ValueChanged<PaletteKey> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.sm,
      children: [
        for (final key in PaletteKey.values)
          Semantics(
            button: true,
            selected: key == selected,
            label: key.label,
            child: InkResponse(
              onTap: () => onPick(key),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: palette.of(key).strong,
                child: key == selected
                    ? Icon(
                        AppIcons.check,
                        color: context.colors.surface,
                        size: AppIconSize.standard,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
