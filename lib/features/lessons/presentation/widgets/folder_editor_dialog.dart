import 'package:flutter/material.dart';

/// Ввод названия папки — для создания и переименования. Возвращает введённое
/// название или `null`, если отменили.
class FolderEditorDialog extends StatefulWidget {
  const FolderEditorDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
  });

  /// Заголовок диалога, например «Новая папка».
  final String title;

  /// Подпись кнопки подтверждения, например «Создать».
  final String confirmLabel;

  final String initialValue;

  @override
  State<FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends State<FolderEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(hintText: 'Название папки'),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}
