import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/usecases/sign_in.dart';
import 'login_form_state.dart';
import 'login_model.dart';
import 'login_page.dart';

LoginWidgetModel loginWidgetModelFactory(BuildContext context) =>
    LoginWidgetModel(
      LoginModel(ProviderScope.containerOf(context, listen: false)),
    );

class LoginWidgetModel extends WidgetModel<LoginPage, LoginModel> {
  LoginWidgetModel(super.model);

  static const Duration _rateLimitCooldown = Duration(minutes: 1);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<LoginFormState> _form = ValueNotifier(
    const LoginFormState(),
  );
  Timer? _cooldownTicker;
  DateTime? _retryAt;

  ValueListenable<LoginFormState> get form => _form;

  bool get canSubmit {
    final form = _form.value;
    if (form.isBusy || form.isRateLimited) return false;
    return !widget.isRegistration || form.termsAccepted;
  }

  String get submitLabel {
    final form = _form.value;
    if (form.isRateLimited) return 'Retry in ${form.retryInSeconds} s';
    return widget.isRegistration ? 'Create account' : 'Sign in';
  }

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    if (model.restoreFailedOffline && !widget.isRegistration) {
      _form.value = _form.value.copyWith(
        errorMessage:
            'No connection to the server — sign in once you are back online',
      );
    }
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_validate() || !canSubmit) return;
    _form.value = _form.value.copyWith(isBusy: true, clearErrorMessage: true);
    final email = emailController.text.trim();
    final password = passwordController.text;
    try {
      if (widget.isRegistration) {
        await model.signUp(
          email: email,
          password: password,
          name: nameController.text,
        );
      } else {
        await model.signIn(email: email, password: password);
      }
      if (isMounted) _form.value = _form.value.copyWith(isBusy: false);
    } on ApiException catch (error) {
      if (!isMounted) return;
      _form.value = _form.value.copyWith(
        isBusy: false,
        errorMessage: _messageFor(error),
      );
      if (error.code == ApiErrorCode.rateLimited) _startCooldown();
    } on Failure catch (failure) {
      if (!isMounted) return;
      _form.value = _form.value.copyWith(
        isBusy: false,
        errorMessage: failure.message,
      );
    }
  }

  void togglePasswordVisibility() => _form.value = _form.value.copyWith(
    obscurePassword: !_form.value.obscurePassword,
  );

  void setTermsAccepted(bool accepted) =>
      _form.value = _form.value.copyWith(termsAccepted: accepted);

  void switchMode() => context.go(
    widget.isRegistration ? LoginPage.routePath : LoginPage.registerRoutePath,
  );

  /// Checks the fields with the same rules as the server before sending.
  bool _validate() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final emailError = switch (email) {
      '' => 'Enter your email',
      _ when !isValidEmail(email) => 'The email looks mistyped',
      _ => null,
    };
    final passwordError = password.length < kMinPasswordLength
        ? 'At least $kMinPasswordLength characters'
        : null;
    _form.value = _form.value.copyWith(
      clearFieldErrors: true,
      emailError: emailError,
      passwordError: passwordError,
    );
    return emailError == null && passwordError == null;
  }

  void _startCooldown() {
    _retryAt = DateTime.now().add(_rateLimitCooldown);
    _cooldownTicker?.cancel();
    _tickCooldown();
    _cooldownTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCooldown(),
    );
  }

  void _tickCooldown() {
    final left = _retryAt?.difference(DateTime.now()) ?? Duration.zero;
    final seconds = left.isNegative ? 0 : left.inSeconds;
    if (seconds == 0) {
      _cooldownTicker?.cancel();
      _cooldownTicker = null;
    }
    _form.value = _form.value.copyWith(retryInSeconds: seconds);
  }

  String _messageFor(ApiException error) => switch (error.code) {
    ApiErrorCode.invalidCredentials => 'Wrong email or password',
    ApiErrorCode.emailTaken =>
      'This email is already registered — try signing in',
    ApiErrorCode.rateLimited => 'Too many attempts. Please wait a minute',
    _ => error.message,
  };
}
