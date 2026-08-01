import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';

/// Строка списка уроков: моноширинный индекс, обложка, заголовок с
/// подзаголовком и длительность справа.
///
/// Индекс и время набраны моноширинным [AppText.monoTime] — цифры стоят в
/// колонку и не пляшут при прокрутке.
class AppListRow extends StatefulWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.index,
    this.cover,
    this.subtitle,
    this.trailingTime,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
  });

  final String title;

  /// Порядковый номер. Показывается с ведущим нулём: `01`, `02`, …
  final int? index;

  /// Обложка 48×48. Если не задана, рисуется заглушка с иконкой.
  final Widget? cover;

  final String? subtitle;

  /// Длительность справа, например `04:12`.
  final String? trailingTime;

  /// Произвольный элемент справа вместо [trailingTime] — кнопка, бейдж.
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Строка играет сейчас: подсветка primarySoft и заголовок primary.
  final bool selected;

  final String? semanticLabel;

  @override
  State<AppListRow> createState() => _AppListRowState();
}

class _AppListRowState extends State<AppListRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;

    final background = selected
        ? colors.primarySoft
        : (_hovered ? colors.surface2 : Colors.transparent);

    final content = AnimatedContainer(
      duration: context.motion(AppDurations.fast),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.rLg),
      child: Row(
        children: [
          if (widget.index != null) ...[
            SizedBox(
              width: AppSpacing.s6,
              child: Text(
                widget.index!.toString().padLeft(2, '0'),
                style: AppText.monoTime.copyWith(
                  color: selected ? colors.primary : colors.text3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
          ],
          ClipRRect(
            borderRadius: AppRadii.rMd,
            child: SizedBox.square(
              dimension: AppSizes.cover,
              child:
                  widget.cover ??
                  ColoredBox(
                    color: colors.surface2,
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: AppSizes.iconMd,
                      color: colors.text3,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppText.title.copyWith(
                    color: selected ? colors.primary : colors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    widget.subtitle!,
                    style: AppText.caption.copyWith(color: colors.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.s3),
            widget.trailing!,
          ] else if (widget.trailingTime != null) ...[
            const SizedBox(width: AppSpacing.s3),
            Text(
              widget.trailingTime!,
              style: AppText.monoTime.copyWith(color: colors.text2),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null) {
      return Semantics(
        label: widget.semanticLabel,
        container: true,
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: widget.semanticLabel,
      child: AppFocusRing(
        visible: _focused,
        borderRadius: AppRadii.rLg,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(
              () => _focused = value && AppFocusRing.isKeyboardFocus,
            ),
            borderRadius: AppRadii.rLg,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: content,
          ),
        ),
      ),
    );
  }
}
