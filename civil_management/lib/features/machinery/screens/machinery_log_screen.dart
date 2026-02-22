import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/machinery_provider.dart';
import '../data/models/machinery_model.dart';

class MachineryLogScreen extends ConsumerStatefulWidget {
  final String projectId;

  const MachineryLogScreen({super.key, required this.projectId});

  @override
  ConsumerState<MachineryLogScreen> createState() => _MachineryLogScreenState();
}

class _MachineryLogScreenState extends ConsumerState<MachineryLogScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _selectedMachineryId;
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double get _totalHours {
    if (_startTime == null || _endTime == null) return 0.0;

    final start = _startTime!.hour + _startTime!.minute / 60.0;
    final end = _endTime!.hour + _endTime!.minute / 60.0;

    if (end <= start) return 0.0;

    return double.parse((end - start).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final machineryListAsync = ref.watch(machineryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Machinery Usage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Log Date
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                tileColor: Colors.grey.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Machinery Dropdown
              machineryListAsync.when(
                data: (list) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Machinery',
                  ),
                  value: _selectedMachineryId,
                  items: list
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.name} (${m.type ?? ''})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedMachineryId = val),
                  validator: (v) =>
                      v == null ? 'Please select machinery' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading machinery: $e'),
              ),
              const SizedBox(height: 16),

              // 3. Work Activity
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(
                  labelText: 'Work Activity',
                  hintText: 'e.g. Digging foundation',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // 4. Time Pickers
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Start Time',
                      time: _startTime,
                      onPick: (t) => setState(() => _startTime = t),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      label: 'End Time',
                      time: _endTime,
                      onPick: (t) => setState(() => _endTime = t),
                    ),
                  ),
                ],
              ),
              if (_startTime != null && _endTime != null && _totalHours <= 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'End time must be after Start time',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),

              // 5. Total Hours Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Hours:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_totalHours.toStringAsFixed(2)} hrs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SAVE LOG'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required Function(TimeOfDay) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (t != null) onPick(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          time?.format(context) ?? 'Select',
          style: time == null ? const TextStyle(color: Colors.grey) : null,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select times')));
      return;
    }

    if (_totalHours <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid duration')));
      return;
    }

    final success = await ref
        .read(machineryControllerProvider.notifier)
        .logTimeBased(
          projectId: widget.projectId,
          machineryId: _selectedMachineryId!,
          workActivity: _activityController.text.trim(),
          logDate: _selectedDate,
          startTime:
              '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          endTime:
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
          totalHours: _totalHours,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (success && mounted) {
      context.pop();
      ref.invalidate(machineryLogsProvider(widget.projectId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log Saved')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log usage! Check console logs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
