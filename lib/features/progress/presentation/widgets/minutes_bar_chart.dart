import 'package:flutter/material.dart';

import 'minutes_bar.dart';

/// Daily minutes bar chart: heights from [values], labels from [labels].
class MinutesBarChart extends StatelessWidget {
  const MinutesBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.todayIndex,
  });

  final List<int> values;
  final List<String> labels;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: MinutesBar(
              heightPercent: values[i],
              label: labels[i],
              isToday: i == todayIndex,
            ),
          ),
      ],
    );
  }
}
