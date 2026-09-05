import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'lesson_header.dart';
import 'lesson_player_panel.dart';
import 'lesson_segments_panel.dart';
import 'lesson_transcript_panel.dart';

/// Lesson screen on a wide layout: the player left, the segment list right.
class LessonWideLayout extends StatelessWidget {
  const LessonWideLayout({
    super.key,
    required this.lessonId,
    required this.onBack,
    required this.onEdit,
  });

  final String lessonId;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final padding = context.responsive(
      mobile: AppSpacing.s6,
      desktop: AppSpacing.s8,
    );
    final sideWidth = context.responsive(mobile: 270.0, desktop: 300.0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonHeader(lessonId: lessonId, onBack: onBack, onEdit: onEdit),
            const SizedBox(height: AppSpacing.s5),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LessonTranscriptPanel(lessonId: lessonId),
                          const SizedBox(height: AppSpacing.s4),
                          LessonPlayerPanel(lessonId: lessonId),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s5),
                  SizedBox(
                    width: sideWidth,
                    child: LessonSegmentsPanel(lessonId: lessonId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
