import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/lesson.dart';
import 'lesson_labels.dart';

/// Lesson picker for a folder; returns their ids or `null`.
class AddLessonsToFolderSheet extends StatefulWidget {
  const AddLessonsToFolderSheet({super.key, required this.candidates});

  final List<Lesson> candidates;

  @override
  State<AddLessonsToFolderSheet> createState() =>
      _AddLessonsToFolderSheetState();
}

class _AddLessonsToFolderSheetState extends State<AddLessonsToFolderSheet> {
  final _selected = <String>{};

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Добавить уроки',
              style: AppText.h2.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            if (widget.candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
                child: Text(
                  'Все ваши уроки уже в этой папке.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: colors.text2),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.candidates.length,
                  itemBuilder: (context, index) {
                    final lesson = widget.candidates[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s2,
                      ),
                      child: AppCheckbox(
                        value: _selected.contains(lesson.id),
                        onChanged: (_) => _toggle(lesson.id),
                        label: lesson.title,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(
              label: _selected.isEmpty
                  ? 'Добавить'
                  : 'Добавить · ${lessonsLabel(_selected.length)}',
              expand: true,
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
            ),
          ],
        ),
      ),
    );
  }
}
