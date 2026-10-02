/// What the sign-in form shows besides the text fields.
class LoginFormState {
  const LoginFormState({
    this.obscurePassword = true,
    this.termsAccepted = true,
    this.emailError,
    this.passwordError,
    this.errorMessage,
    this.isBusy = false,
    this.retryInSeconds = 0,
  });

  final bool obscurePassword;

  /// Sign-up stays locked until the terms are accepted.
  final bool termsAccepted;

  final String? emailError;
  final String? passwordError;

  /// The server's answer that applies to the whole form.
  final String? errorMessage;

  final bool isBusy;

  /// Seconds left before the next attempt after a `429`; `0` when allowed.
  final int retryInSeconds;

  bool get isRateLimited => retryInSeconds > 0;

  LoginFormState copyWith({
    bool? obscurePassword,
    bool? termsAccepted,
    String? emailError,
    String? passwordError,
    bool clearFieldErrors = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isBusy,
    int? retryInSeconds,
  }) {
    return LoginFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      emailError: clearFieldErrors ? emailError : emailError ?? this.emailError,
      passwordError: clearFieldErrors
          ? passwordError
          : passwordError ?? this.passwordError,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      isBusy: isBusy ?? this.isBusy,
      retryInSeconds: retryInSeconds ?? this.retryInSeconds,
    );
  }
}
