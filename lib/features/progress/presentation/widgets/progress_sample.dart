import 'package:shado/widgets/widgets.dart';

/// Демонстрационные данные экрана прогресса.
///
/// Экран пока показывает статичный макет — реальные метрики подключим отдельной
/// задачей. Держим цифры одним местом, чтобы мобильная, планшетная и десктопная
/// раскладки не расходились.
abstract final class ProgressSample {
  static const int streakDays = 12;
  static const String streakHint = 'Лучшая серия — 21 день. Не пропускай сегодня!';
  static const String streakHintShort = 'Лучшая серия — 21 день';

  /// Минуты по дням недели в процентах от максимума — под высоту столбца.
  static const List<int> weekMinutes = [40, 65, 52, 88, 30, 58, 72];
  static const List<String> weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const int todayIndex = 6;

  static const String levelFrom = 'B1';
  static const String levelTo = 'B2';
  static const double levelRatio = 0.64;
  static const String levelHint = 'Осталось ~40 уроков до следующего уровня';
  static const String levelHintShort = '~40 уроков до B2';

  static const double weekGoalRatio = 0.70;
  static const String weekGoalValue = '126 / 180 мин';
  static const String weekGoalRemaining = 'осталось 54 мин';

  /// Наборы статистики: три плитки в узких раскладках и четыре — на десктопе.
  /// Кортеж: подпись, число, единица (или `null`), дельта.
  static const List<(String, String, String?, String)> weekStats = [
    ('За неделю', '126', 'мин', '+18%'),
    ('Повторов', '240', null, '+32'),
    ('Уроков', '14', null, '4 активных'),
  ];

  static const List<(String, String, String?, String)> weekStatsWide = [
    ('За неделю', '126', 'мин', '+18% к прошлой'),
    ('Повторов', '240', null, '+32 сегодня'),
    ('Уроков', '14', null, '4 активных'),
    ('Ср. в день', '18', 'мин', 'цель 15'),
  ];

  /// Достижения: иконка, подпись, закрыто ли. Закрытым иконку рисует замок.
  static const List<(AppIcons, String, bool)> achievements = [
    (AppIcons.flame, 'Серия 7', false),
    (AppIcons.check, '100 повторов', false),
    (AppIcons.lock, 'Серия 30', true),
    (AppIcons.lock, '10 уроков', true),
  ];

  /// Активность за 10 недель: 70 ячеек (7 строк × 10 недель), минуты за день.
  /// Нули — дни без занятий. Значения детерминированы, чтобы макет не «дышал».
  static final List<int> activity = List<int>.generate(70, (i) {
    final value = (i * 17 + 5) % 41;
    return (i * 3) % 7 == 0 ? 0 : value;
  });
}
