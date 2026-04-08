import 'dart:convert';

class Habit {
  final String id;
  final String name;
  final String emoji;
  final int color;
  final String category;
  final bool isBreakHabit;
  final String frequencyType; // 'daily', 'weekdays', 'weekends', 'custom'
  final List<int> specificDays; // 1=Mon..7=Sun
  final double targetValue;
  final String unit; // empty = binary habit
  final String startDate; // yyyy-MM-dd
  final bool isArchived;
  final String createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.category,
    required this.isBreakHabit,
    required this.frequencyType,
    required this.specificDays,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    required this.isArchived,
    required this.createdAt,
  });

  bool get isBinary => unit.isEmpty;

  bool isScheduledForDay(DateTime day) {
    switch (frequencyType) {
      case 'daily':
        return true;
      case 'weekdays':
        return day.weekday >= 1 && day.weekday <= 5;
      case 'weekends':
        return day.weekday == 6 || day.weekday == 7;
      case 'custom':
        return specificDays.contains(day.weekday);
      default:
        return true;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color,
        'category': category,
        'is_break_habit': isBreakHabit ? 1 : 0,
        'frequency_type': frequencyType,
        'specific_days': jsonEncode(specificDays),
        'target_value': targetValue,
        'unit': unit,
        'start_date': startDate,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt,
      };

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: (m['emoji'] as String?) ?? '✅',
        color: (m['color'] as int?) ?? 0xFF6C63FF,
        category: (m['category'] as String?) ?? 'General',
        isBreakHabit: m['is_break_habit'] == 1,
        frequencyType: (m['frequency_type'] as String?) ?? 'daily',
        specificDays: List<int>.from(jsonDecode((m['specific_days'] as String?) ?? '[]')),
        targetValue: ((m['target_value']) as num?)?.toDouble() ?? 1.0,
        unit: (m['unit'] as String?) ?? '',
        startDate: (m['start_date'] as String?) ?? '',
        isArchived: m['is_archived'] == 1,
        createdAt: (m['created_at'] as String?) ?? '',
      );

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    int? color,
    String? category,
    bool? isBreakHabit,
    String? frequencyType,
    List<int>? specificDays,
    double? targetValue,
    String? unit,
    String? startDate,
    bool? isArchived,
    String? createdAt,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        category: category ?? this.category,
        isBreakHabit: isBreakHabit ?? this.isBreakHabit,
        frequencyType: frequencyType ?? this.frequencyType,
        specificDays: specificDays ?? this.specificDays,
        targetValue: targetValue ?? this.targetValue,
        unit: unit ?? this.unit,
        startDate: startDate ?? this.startDate,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
}
