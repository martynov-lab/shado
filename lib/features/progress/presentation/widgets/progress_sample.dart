import 'package:shado/widgets/widgets.dart';

/// Demo data for the progress screen.
abstract final class ProgressSample {
  static const int streakDays = 12;
  static const String streakHint = 'Best streak — 21 days. Do not skip today!';
  static const String streakHintShort = 'Best streak — 21 days';

  /// Daily minutes as a percentage of the maximum.
  static const List<int> weekMinutes = [40, 65, 52, 88, 30, 58, 72];
  static const List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const int todayIndex = 6;

  static const String levelFrom = 'B1';
  static const String levelTo = 'B2';
  static const double levelRatio = 0.64;
  static const String levelHint = '~40 lessons left to the next level';
  static const String levelHintShort = '~40 lessons to B2';

  static const double weekGoalRatio = 0.70;
  static const String weekGoalValue = '126 / 180 min';
  static const String weekGoalRemaining = '54 min left';

  /// Stat tile sets.
  static const List<(String, String, String?, String)> weekStats = [
    ('This week', '126', 'min', '+18%'),
    ('Repeats', '240', null, '+32'),
    ('Lessons', '14', null, '4 active'),
  ];

  static const List<(String, String, String?, String)> weekStatsWide = [
    ('This week', '126', 'min', '+18% vs last'),
    ('Repeats', '240', null, '+32 today'),
    ('Lessons', '14', null, '4 active'),
    ('Daily avg', '18', 'min', 'goal 15'),
  ];

  /// Achievements: icon, label and a locked flag.
  static const List<(AppIcons, String, bool)> achievements = [
    (AppIcons.flame, 'Streak 7', false),
    (AppIcons.check, '100 repeats', false),
    (AppIcons.lock, 'Streak 30', true),
    (AppIcons.lock, '10 lessons', true),
  ];

  /// Ten weeks of activity: 70 cells with minutes per day.
  static final List<int> activity = List<int>.generate(70, (i) {
    final value = (i * 17 + 5) % 41;
    return (i * 3) % 7 == 0 ? 0 : value;
  });
}
