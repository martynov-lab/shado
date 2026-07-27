/// Базовая ошибка приложения. Домен и presentation работают только с ней,
/// не зная, какая инфраструктура её породила.
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Ошибка локального хранилища (БД, файлы).
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Ошибка работы с аудиофайлом: копирование, чтение длительности, разбор волны.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.cause});
}

/// Некорректный пользовательский ввод или нарушение инварианта домена.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// Запрошенной сущности нет.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}
