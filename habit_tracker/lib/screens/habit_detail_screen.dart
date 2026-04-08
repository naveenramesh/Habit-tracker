import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../database/db_helper.dart';
import '../widgets/heatmap_widget.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _habit;
  List<HabitLog> _logs = [];
  Map<String, double> _heatmapData = {};
  int _streak = 0;
  int _longestStreak = 0;
  double _rate7 = 0;
  double _rate30 = 0;
  int _totalDone = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;
    final logs = await db.getLogsForHabit(_habit.id);
    final streak = await db.currentStreak(_habit.id, _habit);
    final longest = await db.longestStreak(_habit.id, _habit);
    final r7 = await db.completionRate(_habit.id, _habit, 7);
    final r30 = await db.completionRate(_habit.id, _habit, 30);

    final heatmap = <String, double>{};
    for (final l in logs) {
      if (l.isCompleted) {
        heatmap[l.date] = _habit.isBinary
            ? 1.0
            : (l.value / _habit.targetValue).clamp(0.0, 1.0);
      } else if (l.isSkipped) {
        heatmap[l.date] = 0.0;
      }
    }

    setState(() {
      _logs = logs;
      _heatmapData = heatmap;
      _streak = streak;
      _longestStreak = longest;
      _rate7 = r7;
      _rate30 = r30;
      _totalDone = logs.where((l) => l.isCompleted).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_habit.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditHabitScreen(habit: _habit),
                ),
              );
              if (updated == true) {
                // Reload habit
                final habits =
                    await DBHelper.instance.getAllHabits(includeArchived: true);
                final h = habits.firstWhere((h) => h.id == _habit.id,
                    orElse: () => _habit);
                setState(() => _habit = h);
                _load();
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text(
                    _habit.isArchived ? 'Unarchive' : 'Archive'),
                onTap: () async {
                  await DBHelper.instance
                      .updateHabit(_habit.copyWith(isArchived: !_habit.isArchived));
                  if (mounted) Navigator.pop(context, true);
                },
              ),
              PopupMenuItem(
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete habit?'),
                      content: const Text(
                          'This will delete all logs too. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await DBHelper.instance.deleteHabit(_habit.id);
                    if (mounted) Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(_habit.emoji,
                                style: const TextStyle(fontSize: 30)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_habit.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_habit.category} · ${_habit.isBreakHabit ? "Break habit" : "Build habit"}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: color),
                                ),
                                Text(
                                  _frequencyLabel(_habit),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _statCard(context, '🔥 Streak', '$_streak days', color),
                      const SizedBox(width: 10),
                      _statCard(context, '🏆 Best', '$_longestStreak days',
                          color),
                      const SizedBox(width: 10),
                      _statCard(
                          context, '✅ Total', '$_totalDone done', color),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard(context, '7-day rate',
                          '${(_rate7 * 100).round()}%', color),
                      const SizedBox(width: 10),
                      _statCard(context, '30-day rate',
                          '${(_rate30 * 100).round()}%', color),
                      const SizedBox(width: 10),
                      _statCard(
                          context,
                          'Started',
                          _habit.startDate.isEmpty
                              ? '—'
                              : DateFormat('d MMM')
                                  .format(DateTime.parse(_habit.startDate)),
                          color),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Heatmap
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          HeatmapCalendar(
                            data: _heatmapData,
                            activeColor: color,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Log history
                  Text('History',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_logs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No logs yet — start checking in!',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._logs.take(60).map((log) => _logTile(log, color)),
                ],
              ),
            ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      )),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logTile(HabitLog log, Color color) {
    final date =
        DateFormat('EEE, d MMM').format(DateTime.parse(log.date));
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: log.isCompleted
              ? color.withOpacity(0.15)
              : log.isSkipped
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          log.isCompleted
              ? Icons.check
              : log.isSkipped
                  ? Icons.remove
                  : Icons.close,
          color: log.isCompleted
              ? color
              : log.isSkipped
                  ? Colors.orange
                  : Colors.grey,
          size: 18,
        ),
      ),
      title: Text(date,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: log.notes.isNotEmpty
          ? Text(log.notes,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey))
          : log.isSkipped && log.skipReason.isNotEmpty
              ? Text('Skipped: ${log.skipReason}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.orange))
              : null,
      trailing: log.isCompleted && !_habit.isBinary
          ? Text(
              '${log.value.toStringAsFixed(log.value % 1 == 0 ? 0 : 1)} ${_habit.unit}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            )
          : null,
    );
  }

  String _frequencyLabel(Habit h) {
    switch (h.frequencyType) {
      case 'daily':
        return 'Every day';
      case 'weekdays':
        return 'Weekdays only';
      case 'weekends':
        return 'Weekends only';
      case 'custom':
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return h.specificDays.map((d) => names[d - 1]).join(', ');
      default:
        return '';
    }
  }
}
