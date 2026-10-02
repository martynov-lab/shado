import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Collapsible filter section; collapsed by default.
class LessonsFilterGroupSection extends StatefulWidget {
  const LessonsFilterGroupSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  State<LessonsFilterGroupSection> createState() =>
      _LessonsFilterGroupSectionState();
}

class _LessonsFilterGroupSectionState extends State<LessonsFilterGroupSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: widget.title,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.rSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.label.copyWith(color: colors.text),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: context.motion(AppDurations.fast),
                      child: AppIcon(
                        AppIcons.chevronDown,
                        size: AppSizes.iconSm,
                        color: colors.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: widget.child,
          ),
      ],
    );
  }
}
