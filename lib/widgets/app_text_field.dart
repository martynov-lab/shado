import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Однострочное или многострочное поле ввода.
///
/// Рамка и фон рисуются вручную, а внутри стоит «раздетый» [TextField]
/// (`InputDecoration.collapsed`) — так поле не тянет за собой стоковый
/// Material-декор и полностью подчиняется токенам.
///
/// В фокусе вокруг поля появляется мягкое кольцо primarySoft; при [errorText]
/// рамка и подпись краснеют.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.suffixSemanticLabel,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
  });

  final TextEditingController? controller;

  /// Подпись над полем.
  final String? label;
  final String? hint;

  /// Пояснение под полем. Скрывается, когда есть [errorText].
  final String? helperText;

  /// Непустой текст переводит поле в состояние ошибки.
  final String? errorText;

  final IconData? prefixIcon;
  final IconData? suffixIcon;

  /// Делает [suffixIcon] нажимаемой (показать пароль, очистить поле).
  final VoidCallback? onSuffixPressed;
  final String? suffixSemanticLabel;

  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  bool get hasError => errorText != null && errorText!.isNotEmpty;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = widget.hasError;

    final borderColor = switch ((hasError, _focused)) {
      (true, _) => c.danger,
      (false, true) => c.primary,
      (false, false) => c.border,
    };

    final field = AnimatedContainer(
      duration: context.motion(AppDurations.fast),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: widget.enabled ? c.surface2 : c.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: borderColor,
          width: _focused || hasError
              ? AppSizes.borderThick
              : AppSizes.borderThin,
        ),
        // Мягкое кольцо вместо жёсткой обводки: фокус видно, но поле не
        // «прыгает» — тень не занимает места в раскладке.
        boxShadow: _focused && !hasError
            ? [BoxShadow(color: c.primarySoft, spreadRadius: AppSizes.focusRing)]
            : const [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.prefixIcon != null) ...[
            Icon(widget.prefixIcon, size: AppSizes.iconMd, color: c.text3),
            const SizedBox(width: AppSpacing.s3),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: c.primary,
              style: AppText.body.copyWith(color: c.text),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: AppText.body.copyWith(color: c.text3),
              ),
            ),
          ),
          if (widget.suffixIcon != null) ...[
            const SizedBox(width: AppSpacing.s3),
            if (widget.onSuffixPressed != null)
              _SuffixButton(
                icon: widget.suffixIcon!,
                semanticLabel: widget.suffixSemanticLabel,
                onPressed: widget.enabled ? widget.onSuffixPressed : null,
              )
            else
              Icon(widget.suffixIcon, size: AppSizes.iconMd, color: c.text3),
          ],
        ],
      ),
    );

    final caption = hasError ? widget.errorText : widget.helperText;

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppText.label.copyWith(color: c.text2),
            ),
            const SizedBox(height: AppSpacing.s2),
          ],
          Opacity(
            opacity: widget.enabled ? 1 : AppOpacities.disabled,
            child: field,
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              caption,
              style: AppText.caption.copyWith(
                color: hasError ? c.danger : c.text3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Нажимаемая иконка справа внутри поля.
class _SuffixButton extends StatelessWidget {
  const _SuffixButton({
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.iconLg,
        child: Icon(icon, size: AppSizes.iconMd, color: c.text2),
      ),
    );
  }
}
