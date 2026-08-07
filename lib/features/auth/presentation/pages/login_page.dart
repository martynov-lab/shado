import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';

import '../../domain/usecases/sign_in.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_view.dart';

/// Вход и регистрация — одна форма на двух маршрутах: поля почти те же,
/// отличаются заголовок, кнопка и то, какой запрос уходит.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.isRegistration = false});

  static const String routePath = '/login';

  /// Та же форма, но с регистрацией: свой путь, чтобы ссылка «нет аккаунта»
  /// была обычным переходом, а не состоянием экрана.
  static const String registerRoutePath = '/register';

  final bool isRegistration;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// Имя из формы регистрации: уходит в `/v1/auth/register` необязательным
  /// полем (язык и цель задаются позже в настройках).
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /// Согласие с условиями. В макете флажок уже отмечен, снятый — запирает
  /// кнопку регистрации.
  bool _termsAccepted = true;

  String? _emailError;
  String? _passwordError;

  /// Тикает, пока форма заперта после `429`, — чтобы таймер на кнопке шёл.
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

  /// Те же проверки, что делает сервер: про опечатку в адресе и короткий
  /// пароль пользователь должен узнать от формы, а не от сети.
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

  /// Кнопка показывает, сколько осталось ждать, поэтому раз в секунду
  /// перерисовываем её, пока запрет не снимется.
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
            // На планшете заголовок стоит в шапке карточки, а не в форме.
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
