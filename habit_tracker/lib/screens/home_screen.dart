import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../database/db_helper.dart';
import '../widgets/habit_card.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/add_edit_habit_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;

  // Today tab state
  List<Habit> _todayHabits = [];
  Map<String, HabitLog?> _todayLogs = {};
  Map<String, int> _streaks = {};
  bool _loading = true;

  // All habits tab state
  List<Habit> _allHabits = [];
  bool _showArchived = false;

  final _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;
    final all = await db.getAllHabits(includeArchived: true);
    final todayDay = DateTime.now();
    final today =
        all.where((h) => !h.isArchived && h.isScheduledForDay(todayDay)).toList();

    final logs = <String, HabitLog?>{};
    final streaks = <String, int>{};

    for (final h in today) {
      logs[h.id] = await db.getLogForDate(h.id, _today);
      streaks[h.id] = await db.currentStreak(h.id, h);
    }

    setState(() {
      _todayHabits = today;
      _todayLogs = logs;
      _streaks = streaks;
      _allHabits = all;
      _loading = false;
    });
  }

  Future<void> _checkIn(Habit habit) async {
    final db = DBHelper.instance;
    final existing = _todayLogs[habit.id];

    if (existing != null) {
      // Toggle: if done, remove; if skipped, mark done
      if (existing.isCompleted) {
        await db.deleteLog(existing.id);
        setState(() {
          _todayLogs[habit.id] = null;
        });
      } else if (existing.isSkipped) {
        await db.deleteLog(existing.id);
        final log = HabitLog(
          id: const Uuid().v4(),
          habitId: habit.id,
          date: _today,
          value: habit.isBinary ? 1.0 : habit.targetValue,
          isCompleted: true,
          notes: '',
          isSkipped: false,
          skipReason: '',
          createdAt: DateTime.now().toIso8601String(),
        );
        await db.insertLog(log);
        setState(() => _todayLogs[habit.id] = log);
      }
    } else {
      // First check-in
      if (habit.isBinary) {
        final log = HabitLog(
          id: const Uuid().v4(),
          habitId: habit.id,
          date: _today,
          value: 1.0,
          isCompleted: true,
          notes: '',
          isSkipped: false,
          skipReason: '',
          createdAt: DateTime.now().toIso8601String(),
        );
        await db.insertLog(log);
        setState(() => _todayLogs[habit.id] = log);
      } else {
        // Show quantity dialog
        _showQuantityDialog(habit);
        return;
      }
    }

    // Refresh streak
    final streak = await db.currentStreak(habit.id, habit);
    setState(() => _streaks[habit.id] = streak);
  }

  Future<void> _showQuantityDialog(Habit habit) async {
    final ctrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log ${habit.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                suffixText: habit.unit,
                hintText: habit.targetValue
                    .toStringAsFixed(habit.targetValue % 1 == 0 ? 0 : 1),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration:
                  const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;
    final value = double.tryParse(ctrl.text) ?? habit.targetValue;

    final log = HabitLog(
      id: const Uuid().v4(),
      habitId: habit.id,
      date: _today,
      value: value,
      isCompleted: value >= habit.targetValue,
      notes: notesCtrl.text.trim(),
      isSkipped: false,
      skipReason: '',
      createdAt: DateTime.now().toIso8601String(),
    );
    await DBHelper.instance.insertLog(log);
    final streak = await DBHelper.instance.currentStreak(habit.id, habit);
    setState(() {
      _todayLogs[habit.id] = log;
      _streaks[habit.id] = streak;
    });
  }

  Future<void> _skip(Habit habit) async {
    final db = DBHelper.instance;
    final existing = _todayLogs[habit.id];
    if (existing != null) {
      await db.deleteLog(existing.id);
    }

    String? reason;
    if (mounted) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Skip reason (optional)'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Sick, travel, rest day…'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No reason')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, ctrl.text),
                  child: const Text('Skip')),
            ],
          );
        },
      );
    }

    final log = HabitLog(
      id: const Uuid().v4(),
      habitId: habit.id,
      date: _today,
      value: 0.0,
      isCompleted: false,
      notes: '',
      isSkipped: true,
      skipReason: reason ?? '',
      createdAt: DateTime.now().toIso8601String(),
    );
    await db.insertLog(log);
    setState(() => _todayLogs[habit.id] = log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildTodayTab(),
          _buildAllHabitsTab(),
          SettingsScreen(
            themeMode: _themeMode,
            onThemeChanged: (mode) {
              setState(() => _themeMode = mode);
              widget.onThemeChanged(mode);
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.list_outlined),
              selectedIcon: Icon(Icons.list),
              label: 'Habits'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
      floatingActionButton: _navIndex < 2
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddEditHabitScreen()),
                );
                if (result == true) _loadAll();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTodayTab() {
    final date = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final done =
        _todayLogs.values.where((l) => l?.isCompleted == true).length;
    final total = _todayHabits.length;
    final progress = total == 0 ? 0.0 : done / total;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(date,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAll,
            ),
          ],
        ),
        if (_loading)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
        else if (_todayHabits.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No habits for today',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first habit',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildListDelegate([
              // Progress bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$done / $total completed',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('${(progress * 100).round()}%',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Incomplete habits
              ..._todayHabits
                  .where((h) => _todayLogs[h.id]?.isCompleted != true)
                  .map((h) => HabitCard(
                        habit: h,
                        todayLog: _todayLogs[h.id],
                        streak: _streaks[h.id] ?? 0,
                        onTap: () => _openDetail(h),
                        onCheckIn: () => _checkIn(h),
                        onSkip: () => _skip(h),
                      )),
              // Completed habits
              if (_todayHabits
                  .any((h) => _todayLogs[h.id]?.isCompleted == true)) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'COMPLETED',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                            color: Colors.grey, letterSpacing: 1.2),
                  ),
                ),
                ..._todayHabits
                    .where((h) => _todayLogs[h.id]?.isCompleted == true)
                    .map((h) => HabitCard(
                          habit: h,
                          todayLog: _todayLogs[h.id],
                          streak: _streaks[h.id] ?? 0,
                          onTap: () => _openDetail(h),
                          onCheckIn: () => _checkIn(h),
                          onSkip: () => _skip(h),
                        )),
              ],
              const SizedBox(height: 80),
            ]),
          ),
      ],
    );
  }

  Widget _buildAllHabitsTab() {
    final visible = _allHabits
        .where((h) => _showArchived || !h.isArchived)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('All Habits',
              style: TextStyle(fontWeight: FontWeight.bold)),
          floating: true,
          actions: [
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showArchived = !_showArchived),
              icon: Icon(_showArchived
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              label: Text(_showArchived ? 'Hide archived' : 'Archived'),
            ),
          ],
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No habits yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to create your first habit',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i == visible.length) {
                  return const SizedBox(height: 80);
                }
                final h = visible[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(h.color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(h.emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    h.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: h.isArchived ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    '${h.category} · ${_freqShort(h)}${h.isArchived ? " · Archived" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: h.isArchived ? Colors.grey : null,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDetail(h),
                );
              },
              childCount: visible.length + 1,
            ),
          ),
      ],
    );
  }

  String _freqShort(Habit h) {
    switch (h.frequencyType) {
      case 'daily':
        return 'Daily';
      case 'weekdays':
        return 'Weekdays';
      case 'weekends':
        return 'Weekends';
      case 'custom':
        return '${h.specificDays.length}×/week';
      default:
        return '';
    }
  }

  Future<void> _openDetail(Habit h) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: h)),
    );
    if (result == true) _loadAll();
  }
}
