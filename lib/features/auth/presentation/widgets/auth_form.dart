import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'auth_divider.dart';
import 'auth_error_banner.dart';
import 'auth_link.dart';
import 'auth_social_button.dart';
import 'auth_switch_line.dart';
import 'auth_terms_checkbox.dart';

/// Sign-in and sign-up form: fields, the main action and links below it.
class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.isRegistration,
    required this.showHeading,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.errorMessage,
    required this.obscurePassword,
    required this.termsAccepted,
    required this.isBusy,
    required this.canSubmit,
    required this.submitLabel,
    required this.onObscureToggled,
    required this.onTermsChanged,
    required this.onSubmitPressed,
    required this.onSwitchPressed,
  });

  final bool isRegistration;
  final bool showHeading;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// Field errors: a non-empty string puts the field into an error state.
  final String? emailError;
  final String? passwordError;

  /// Server error that applies to the whole form.
  final String? errorMessage;

  final bool obscurePassword;
  final bool termsAccepted;
  final bool isBusy;
  final bool canSubmit;
  final String submitLabel;

  final VoidCallback onObscureToggled;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onSubmitPressed;
  final VoidCallback? onSwitchPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            isRegistration ? 'Создать аккаунт' : 'С возвращением',
            style: AppText.h1.copyWith(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            isRegistration
                ? 'Начните учиться уже сегодня'
                : 'Войдите, чтобы продолжить тренировку',
            style: AppText.caption.copyWith(color: colors.text3),
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
        if (isRegistration) ...[
          AppTextField(
            controller: nameController,
            label: 'Имя',
            hint: 'Андрей',
            prefixIcon: AppIcons.user,
            textInputAction: TextInputAction.next,
            enabled: !isBusy,
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        AppTextField(
          controller: emailController,
          label: 'Email',
          hint: 'andrew@example.com',
          prefixIcon: AppIcons.mail,
          errorText: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isBusy,
        ),
        const SizedBox(height: AppSpacing.s4),
        AppTextField(
          controller: passwordController,
          label: 'Пароль',
          hint: isRegistration ? 'Минимум 8 символов' : '••••••••',
          prefixIcon: AppIcons.lock,
          suffixIcon: obscurePassword ? AppIcons.eye : AppIcons.eyeOff,
          suffixSemanticLabel: obscurePassword ? 'Показать' : 'Скрыть',
          onSuffixPressed: onObscureToggled,
          obscureText: obscurePassword,
          errorText: passwordError,
          textInputAction: TextInputAction.done,
          onSubmitted: canSubmit ? (_) => onSubmitPressed() : null,
          enabled: !isBusy,
        ),
        if (isRegistration) ...[
          const SizedBox(height: AppSpacing.s4),
          AuthTermsCheckbox(
            value: termsAccepted,
            onChanged: isBusy ? null : onTermsChanged,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.s3),
          // Password recovery does not exist yet — the link has no action.
          const Align(
            alignment: Alignment.centerRight,
            child: AuthLink(label: 'Забыли пароль?'),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s4),
          AuthErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: AppSpacing.s6),
        AppButton(
          label: submitLabel,
          size: AppButtonSize.lg,
          expand: true,
          loading: isBusy,
          onPressed: canSubmit ? onSubmitPressed : null,
        ),
        const SizedBox(height: AppSpacing.s5),
        const AuthDivider(label: 'или'),
        const SizedBox(height: AppSpacing.s5),
        // Social sign-in is not wired yet — buttons have no handlers.
        const Row(
          children: [
            Expanded(
              child: AuthSocialButton(
                icon: AppIcons.brandGoogle,
                label: 'Google',
              ),
            ),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: AuthSocialButton(
                icon: AppIcons.brandApple,
                label: 'Apple',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        AuthSwitchLine(
          isRegistration: isRegistration,
          onPressed: onSwitchPressed,
        ),
      ],
    );
  }
}
