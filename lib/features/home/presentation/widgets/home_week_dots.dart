import 'package:flutter/material.dart';

import 'home_week_day.dart';

/// Practice week: seven dots with day labels.
class HomeWeekDots extends StatelessWidget {
  const HomeWeekDots({
    super.key,
    required this.days,
    required this.done,
    required this.todayIndex,
  });

  final List<String> days;
  final List<bool> done;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < days.length; i++)
          HomeWeekDay(label: days[i], done: done[i], today: i == todayIndex),
      ],
    );
  }
}
