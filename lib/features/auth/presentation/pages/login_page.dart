import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/sign_in.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error_banner.dart';

/// Вход и регистрация — одна форма на двух маршрутах: поля те же, отличаются
/// заголовок, кнопка и то, какой запрос уходит.
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /// Тикает, пока форма заперта после `429`, — чтобы таймер на кнопке шёл.
  Timer? _cooldownTicker;

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text;
    final password = _passwordController.text;
    final ok = widget.isRegistration
        ? await controller.signUp(email: email, password: password)
        : await controller.signIn(email: email, password: password);
    if (!ok) _startCooldownTicker();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isRegistration = widget.isRegistration;
    final blocked = state.isBusy || state.isRateLimited;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRegistration ? 'Регистрация' : 'Вход в Shado',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      enabled: !state.isBusy,
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Введите email';
                        if (!isValidEmail(email)) {
                          return 'Похоже, в email опечатка';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword ? 'Показать' : 'Скрыть',
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !state.isBusy,
                      autofillHints: [
                        isRegistration
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => blocked ? null : _submit(),
                      // Ту же проверку делает сервер, но пользователь должен
                      // узнать о коротком пароле от формы, а не от сети.
                      validator: (value) =>
                          (value ?? '').length < kMinPasswordLength
                          ? 'Не короче $kMinPasswordLength символов'
                          : null,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: state.error!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: blocked ? null : _submit,
                      child: state.isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_buttonLabel(state, isRegistration)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: state.isBusy
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .clearError();
                              context.go(
                                isRegistration
                                    ? LoginPage.routePath
                                    : LoginPage.registerRoutePath,
                              );
                            },
                      child: Text(
                        isRegistration
                            ? 'Уже есть аккаунт — войти'
                            : 'Нет аккаунта — зарегистрироваться',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buttonLabel(AuthState state, bool isRegistration) {
    if (state.isRateLimited) {
      return 'Повтор через ${state.retryIn.inSeconds} с';
    }
    return isRegistration ? 'Зарегистрироваться' : 'Войти';
  }
}
