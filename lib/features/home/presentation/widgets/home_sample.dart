/// Демонстрационные данные главного экрана.
///
/// Экран пока показывает статичный макет — реальные метрики (продолжить урок,
/// статистику, цель недели) подключим отдельной задачей. Держим цифры одним
/// местом, чтобы мобильная, планшетная и десктопная раскладки не расходились.
abstract final class HomeSample {
  static const String greetingSubtitle = 'Продолжим тренировку слуха?';
  static const int streakDays = 12;

  // Карточка «Продолжить» — незаконченный урок.
  static const String heroEyebrow = 'Продолжить';
  static const String heroTitle = 'How language shapes thought';
  static const String heroSubtitle = 'Сегмент 4 из 18 · TED';
  static const double heroProgress = 0.38;

  /// Плитки статистики: подпись, число, единица (или `null`), дельта.
  static const List<(String, String, String?, String)> stats = [
    ('Сегодня', '18', 'мин', '+6 к цели'),
    ('Серия', '12', 'дн', 'личный рекорд'),
    ('Повторов', '240', null, '+32 сегодня'),
  ];

  /// Две плитки рядом с «героем» на десктопе.
  static const List<(String, String, String?, String)> statsCompact = [
    ('Сегодня', '18', 'мин', '+6 к цели дня'),
    ('Повторов', '240', null, '+32 сегодня'),
  ];

  /// Превью «Мои уроки»: заголовок, подзаголовок, длительность.
  static const List<(String, String, String)> lessons = [
    ('The power of habit', 'Подкаст · 24 сегмента', '3:20'),
    ('A talk about focus', 'Диалог · 11 сегментов', '2:04'),
    ('Everyday small talk', 'Диалог · 9 сегментов', '1:48'),
  ];
  static const String lessonsAllLabel = 'Все 14';

  static const double weekGoalRatio = 0.70;
  static const String weekGoalValue = '126 / 180 мин';
  static const String weekGoalRemaining = 'осталось 54 минуты';

  static const List<String> weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  /// Дни недели, в которые была тренировка. Индекс совпадает с [weekDays].
  static const List<bool> weekDone = [true, true, true, false, false, false, false];
  static const int todayIndex = 3;

  /// Минуты по дням недели в процентах от максимума — под высоту столбца.
  static const List<int> weekMinutes = [40, 65, 52, 88, 30, 12, 5];
}
