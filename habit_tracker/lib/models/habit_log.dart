class HabitLog {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final double value;
  final bool isCompleted;
  final String notes;
  final bool isSkipped;
  final String skipReason;
  final String createdAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.value,
    required this.isCompleted,
    required this.notes,
    required this.isSkipped,
    required this.skipReason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date,
        'value': value,
        'is_completed': isCompleted ? 1 : 0,
        'notes': notes,
        'is_skipped': isSkipped ? 1 : 0,
        'skip_reason': skipReason,
        'created_at': createdAt,
      };

  factory HabitLog.fromMap(Map<String, dynamic> m) => HabitLog(
        id: m['id'] as String,
        habitId: m['habit_id'] as String,
        date: m['date'] as String,
        value: ((m['value']) as num?)?.toDouble() ?? 0.0,
        isCompleted: m['is_completed'] == 1,
        notes: (m['notes'] as String?) ?? '',
        isSkipped: m['is_skipped'] == 1,
        skipReason: (m['skip_reason'] as String?) ?? '',
        createdAt: (m['created_at'] as String?) ?? '',
      );
}
