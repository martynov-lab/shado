import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../../widgets/lesson_kind_option.dart';
import 'add_lesson_kind_wm.dart';

/// The first step of the add section: which kind of lesson to create.
class AddLessonKindPage extends ElementaryWidget<AddLessonKindWidgetModel> {
  const AddLessonKindPage({super.key}) : super(addLessonKindWidgetModelFactory);

  static const String routePath = '/add';

  @override
  Widget build(AddLessonKindWidgetModel wm) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.colors.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.tablet,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.s5),
                children: [
                  Text(
                    'New lesson',
                    style: AppText.h2.copyWith(color: context.colors.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  LessonKindOption(
                    icon: Icons.article_outlined,
                    title: 'Story',
                    description: 'Audio with a full text, cut into segments',
                    onTap: wm.createStory,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  LessonKindOption(
                    icon: Icons.format_quote_rounded,
                    title: 'Phrases',
                    description:
                        'Separate phrases with translations to drill as cards',
                    onTap: wm.createPhraseSet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
