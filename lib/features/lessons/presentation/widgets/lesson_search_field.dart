import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/widgets/widgets.dart';

import '../controllers/lessons_filter.dart';

/// Поиск по урокам: пишет строку в [lessonsFilterProvider], крестик очищает.
class LessonSearchField extends ConsumerStatefulWidget {
  const LessonSearchField({super.key});

  @override
  ConsumerState<LessonSearchField> createState() => _LessonSearchFieldState();
}

class _LessonSearchFieldState extends ConsumerState<LessonSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(lessonsFilterProvider.notifier).setQuery(value);
    // Крестик появляется и исчезает вместе с текстом.
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
      hint: 'Поиск по урокам…',
      prefixIcon: AppIcons.search,
      suffixIcon: hasText ? AppIcons.close : null,
      onSuffixPressed: hasText ? _clear : null,
      suffixSemanticLabel: 'Очистить поиск',
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
    );
  }
}
