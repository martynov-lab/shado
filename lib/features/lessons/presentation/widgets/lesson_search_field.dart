import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';


/// Lesson search field with a clear button.
class LessonSearchField extends StatefulWidget {
  const LessonSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<LessonSearchField> createState() => _LessonSearchFieldState();
}

class _LessonSearchFieldState extends State<LessonSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    // The clear button appears and disappears with the text.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return AppTextField(
      controller: _controller,
      hint: 'Search lessons…',
      prefixIcon: AppIcons.search,
      suffixIcon: hasText ? AppIcons.close : null,
      onSuffixPressed: hasText ? _clear : null,
      suffixSemanticLabel: 'Clear search',
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
    );
  }
}
