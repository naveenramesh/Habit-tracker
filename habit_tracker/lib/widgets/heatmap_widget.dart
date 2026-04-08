import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<String, double> data; // 'yyyy-MM-dd' -> completion value 0.0–1.0
  final Color activeColor;
  final int weeks;

  const HeatmapCalendar({
    super.key,
    required this.data,
    required this.activeColor,
    this.weeks = 16,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDay = today.subtract(Duration(days: weeks * 7 - 1));

    // Align start to Monday of that week
    final adjustedStart =
        startDay.subtract(Duration(days: startDay.weekday - 1));

    final List<DateTime> days = [];
    for (int i = 0; i < weeks * 7; i++) {
      days.add(adjustedStart.add(Duration(days: i)));
    }

    final monthLabels = _buildMonthLabels(days, weeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        SizedBox(
          height: 16,
          child: Row(
            children: monthLabels.map((label) {
              return SizedBox(
                width: label.$2 * 13.0,
                child: Text(
                  label.$1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              children: const ['M', '', 'W', '', 'F', '', 'S']
                  .map((d) => SizedBox(
                        height: 13,
                        child: Text(
                          d,
                          style: const TextStyle(
                              fontSize: 8, color: Colors.grey),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 4),
            // Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeks, (col) {
                    return Column(
                      children: List.generate(7, (row) {
                        final day = days[col * 7 + row];
                        final key = DateFormat('yyyy-MM-dd').format(day);
                        final value = data[key] ?? -1.0;
                        final isToday = key ==
                            DateFormat('yyyy-MM-dd').format(today);
                        final isFuture = day.isAfter(today);

                        return Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: isToday
                                ? Border.all(
                                    color: activeColor, width: 1.5)
                                : null,
                            color: isFuture
                                ? Colors.transparent
                                : value < 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.08)
                                    : value == 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.1)
                                        : Color(activeColor.value).withOpacity(
                                            0.2 + (value * 0.8)),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i == 0
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.08)
                      : Color(activeColor.value)
                          .withOpacity(0.2 + (i / 4) * 0.8),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text('More',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  List<(String, int)> _buildMonthLabels(List<DateTime> days, int weeks) {
    final labels = <(String, int)>[];
    String? currentMonth;
    int count = 0;

    for (int col = 0; col < weeks; col++) {
      final month = DateFormat('MMM').format(days[col * 7]);
      if (month != currentMonth) {
        if (currentMonth != null) labels.add((currentMonth, count));
        currentMonth = month;
        count = 1;
      } else {
        count++;
      }
    }
    if (currentMonth != null) labels.add((currentMonth, count));
    return labels;
  }
}
