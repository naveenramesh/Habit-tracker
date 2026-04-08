import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final HabitLog? todayLog;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;
  final VoidCallback onSkip;

  const HabitCard({
    super.key,
    required this.habit,
    required this.todayLog,
    required this.streak,
    required this.onTap,
    required this.onCheckIn,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    final isDone = todayLog?.isCompleted ?? false;
    final isSkipped = todayLog?.isSkipped ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color indicator + emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4)
                                      : null,
                                ),
                          ),
                        ),
                        if (streak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Text(
                                  '$streak',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          habit.category,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (!habit.isBinary && !isDone) ...[
                          const Text(' · ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            'Target: ${habit.targetValue.toStringAsFixed(habit.targetValue % 1 == 0 ? 0 : 1)} ${habit.unit}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                        if (isSkipped) ...[
                          const Text(' · ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            'Skipped',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.orange),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action buttons
              if (!isSkipped)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDone)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onSkip();
                        },
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.grey.withOpacity(0.6), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onCheckIn();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              isDone ? color : color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.check,
                          color: isDone ? Colors.white : color,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: onCheckIn,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Undo',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
