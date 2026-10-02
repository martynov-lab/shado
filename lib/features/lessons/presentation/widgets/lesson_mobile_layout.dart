import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Lesson screen on phone; the segment list opens as a modal sheet.
class LessonMobileLayout extends StatelessWidget {
  const LessonMobileLayout({
    super.key,
    required this.header,
    required this.transcript,
    required this.segmentsButton,
    required this.player,
  });

  final Widget header;
  final Widget transcript;
  final Widget segmentsButton;
  final Widget player;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              0,
            ),
            child: header,
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: transcript),
                        const SizedBox(height: AppSpacing.s4),
                        segmentsButton,
                        const SizedBox(height: AppSpacing.s4),
                        player,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
