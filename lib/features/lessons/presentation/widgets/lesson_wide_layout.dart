import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';


/// Lesson screen on a wide layout: the player left, the segment list right.
class LessonWideLayout extends StatelessWidget {
  const LessonWideLayout({
    super.key,
    required this.header,
    required this.transcript,
    required this.player,
    required this.segments,
  });

  final Widget header;
  final Widget transcript;
  final Widget player;
  final Widget segments;

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
            header,
            const SizedBox(height: AppSpacing.s5),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: transcript),
                              const SizedBox(height: AppSpacing.s4),
                              player,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s5),
                  SizedBox(
                    width: sideWidth,
                    child: segments,
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
