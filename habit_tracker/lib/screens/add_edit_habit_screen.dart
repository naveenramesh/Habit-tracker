import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit; // null = create mode

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();

  String _emoji = '✅';
  int _color = AppTheme.habitColors[0];
  String _category = AppTheme.categories[0];
  bool _isBreakHabit = false;
  String _frequencyType = 'daily';
  List<int> _specificDays = [];
  bool _isBinary = true;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = widget.habit!;
      _nameCtrl.text = h.name;
      _emoji = h.emoji;
      _color = h.color;
      _category = h.category;
      _isBreakHabit = h.isBreakHabit;
      _frequencyType = h.frequencyType;
      _specificDays = List.from(h.specificDays);
      _isBinary = h.isBinary;
      if (!h.isBinary) {
        _targetCtrl.text = h.targetValue
            .toStringAsFixed(h.targetValue % 1 == 0 ? 0 : 1);
        _unitCtrl.text = h.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequencyType == 'custom' && _specificDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    final habit = Habit(
      id: _isEditing ? widget.habit!.id : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      emoji: _emoji,
      color: _color,
      category: _category,
      isBreakHabit: _isBreakHabit,
      frequencyType: _frequencyType,
      specificDays: _specificDays,
      targetValue: _isBinary ? 1.0 : double.tryParse(_targetCtrl.text) ?? 1.0,
      unit: _isBinary ? '' : _unitCtrl.text.trim(),
      startDate: _isEditing
          ? widget.habit!.startDate
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      isArchived: _isEditing ? widget.habit!.isArchived : false,
      createdAt: _isEditing ? widget.habit!.createdAt : now,
    );

    if (_isEditing) {
      await DBHelper.instance.updateHabit(habit);
    } else {
      await DBHelper.instance.insertHabit(habit);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emoji + Name row
            Row(
              children: [
                GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(_color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(_emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Habit name',
                      labelText: 'Name',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color picker
            _sectionLabel('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppTheme.habitColors.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                              width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Category
            _sectionLabel('Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(),
              items: AppTheme.categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),

            // Type
            _sectionLabel('Habit type'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Build'),
                    icon: Icon(Icons.add_circle_outline)),
                ButtonSegment(
                    value: true,
                    label: Text('Break'),
                    icon: Icon(Icons.remove_circle_outline)),
              ],
              selected: {_isBreakHabit},
              onSelectionChanged: (s) =>
                  setState(() => _isBreakHabit = s.first),
            ),
            const SizedBox(height: 20),

            // Frequency
            _sectionLabel('Frequency'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(
                    value: 'weekdays', label: Text('Weekdays')),
                ButtonSegment(
                    value: 'weekends', label: Text('Weekends')),
                ButtonSegment(value: 'custom', label: Text('Custom')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (s) =>
                  setState(() => _frequencyType = s.first),
            ),
            if (_frequencyType == 'custom') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final day in [
                    (1, 'Mon'),
                    (2, 'Tue'),
                    (3, 'Wed'),
                    (4, 'Thu'),
                    (5, 'Fri'),
                    (6, 'Sat'),
                    (7, 'Sun')
                  ])
                    FilterChip(
                      label: Text(day.$2),
                      selected: _specificDays.contains(day.$1),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _specificDays.add(day.$1);
                        } else {
                          _specificDays.remove(day.$1);
                        }
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Measurement
            _sectionLabel('Measurement'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('Done/Not done'),
                    icon: Icon(Icons.check_circle_outline)),
                ButtonSegment(
                    value: false,
                    label: Text('Quantity'),
                    icon: Icon(Icons.bar_chart)),
              ],
              selected: {_isBinary},
              onSelectionChanged: (s) =>
                  setState(() => _isBinary = s.first),
            ),
            if (!_isBinary) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Target amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (!_isBinary &&
                            (v == null ||
                                double.tryParse(v) == null ||
                                double.parse(v) <= 0)) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                          hintText: 'steps, mins, pages…',
                          labelText: 'Unit'),
                      validator: (v) {
                        if (!_isBinary &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      );

  void _pickEmoji() {
    showModalBottomSheet(
      context: context,
      builder: (_) => GridView.extent(
        maxCrossAxisExtent: 52,
        padding: const EdgeInsets.all(16),
        children: AppTheme.habitEmojis
            .map((e) => GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Text(e,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
