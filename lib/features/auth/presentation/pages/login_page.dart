import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/usecases/sign_in.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_view.dart';

/// Sign-in and sign-up — one form on two routes.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.isRegistration = false});

  static const String routePath = '/login';

  /// Route of the same form in sign-up mode.
  static const String registerRoutePath = '/register';

  final bool isRegistration;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// Name from the sign-up form — an optional field.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /// Terms consent; unchecked it locks the sign-up button.
  bool _termsAccepted = true;

  String? _emailError;
  String? _passwordError;

  /// Ticks while the form is locked after a `429`.
  Timer? _cooldownTicker;

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ok = widget.isRegistration
        ? await controller.signUp(
            email: email,
            password: password,
            name: _nameController.text,
          )
        : await controller.signIn(email: email, password: password);
    if (!ok) _startCooldownTicker();
  }

  /// Validates input before sending, with the same rules as the server.
  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = _emailErrorFor(email);
      _passwordError = password.length < kMinPasswordLength
          ? 'Не короче $kMinPasswordLength символов'
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  String? _emailErrorFor(String email) {
    if (email.isEmpty) return 'Введите email';
    if (!isValidEmail(email)) return 'Похоже, в email опечатка';
    return null;
  }

  /// Refreshes the countdown on the button once a second.
  void _startCooldownTicker() {
    if (!ref.read(authControllerProvider).isRateLimited) return;
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !ref.read(authControllerProvider).isRateLimited) {
        timer.cancel();
        _cooldownTicker = null;
      }
      if (mounted) setState(() {});
    });
  }

  void _switchMode() {
    ref.read(authControllerProvider.notifier).clearError();
    context.go(
      widget.isRegistration ? LoginPage.routePath : LoginPage.registerRoutePath,
    );
  }

  String _submitLabel(AuthState state) {
    if (state.isRateLimited) return 'Повтор через ${state.retryIn.inSeconds} с';
    return widget.isRegistration ? 'Создать аккаунт' : 'Войти';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isRegistration = widget.isRegistration;
    final blocked = state.isBusy || state.isRateLimited;

    return Scaffold(
      body: SafeArea(
        child: AuthView(
          isRegistration: isRegistration,
          form: AuthForm(
            isRegistration: isRegistration,
            // On tablets the heading lives in the card header.
            showHeading: !context.isTablet,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            emailError: _emailError,
            passwordError: _passwordError,
            errorMessage: state.error,
            obscurePassword: _obscurePassword,
            termsAccepted: _termsAccepted,
            isBusy: state.isBusy,
            canSubmit: !blocked && (!isRegistration || _termsAccepted),
            submitLabel: _submitLabel(state),
            onObscureToggled: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onTermsChanged: (value) => setState(() => _termsAccepted = value),
            onSubmitPressed: _submit,
            onSwitchPressed: state.isBusy ? null : _switchMode,
          ),
        ),
      ),
    );
  }
}
