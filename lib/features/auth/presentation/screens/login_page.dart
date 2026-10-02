import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/auth_form.dart';
import '../widgets/auth_view.dart';
import 'login_wm.dart';

/// Sign-in and sign-up — one form on two routes.
class LoginPage extends ElementaryWidget<LoginWidgetModel> {
  const LoginPage({super.key, this.isRegistration = false})
    : super(loginWidgetModelFactory);

  static const String routePath = '/login';

  /// Route of the same form in sign-up mode.
  static const String registerRoutePath = '/register';

  final bool isRegistration;

  @override
  Widget build(LoginWidgetModel wm) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: wm.form,
          builder: (context, form, _) => AuthView(
            isRegistration: isRegistration,
            form: AuthForm(
              isRegistration: isRegistration,
              // On tablets the heading lives in the card header.
              showHeading: !context.isTablet,
              nameController: wm.nameController,
              emailController: wm.emailController,
              passwordController: wm.passwordController,
              emailError: form.emailError,
              passwordError: form.passwordError,
              errorMessage: form.errorMessage,
              obscurePassword: form.obscurePassword,
              termsAccepted: form.termsAccepted,
              isBusy: form.isBusy,
              canSubmit: wm.canSubmit,
              submitLabel: wm.submitLabel,
              onObscureToggled: wm.togglePasswordVisibility,
              onTermsChanged: wm.setTermsAccepted,
              onSubmitPressed: () => unawaited(wm.submit()),
              onSwitchPressed: form.isBusy ? null : wm.switchMode,
            ),
          ),
        ),
      ),
    );
  }
}
