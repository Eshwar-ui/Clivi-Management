import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/machinery_provider.dart';
import '../data/models/machinery_model.dart';
import '../data/models/machinery_log_model.dart';
import '../../common/widgets/searchable_dropdown_with_create.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/screens/project_operations_screen.dart';

class MachineryTabScreen extends ConsumerWidget {
  final String projectId;

  const MachineryTabScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(machineryLogsProvider(projectId));
    final dateRange = ref.watch(projectDateRangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogMachinerySheet(context, projectId),
        backgroundColor: const Color(0xFF1E293B), // Dark Navy from design
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Machinery History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final dateRange = ref.watch(projectDateRangeProvider);
                    final isFiltered = dateRange != null;
                    return OutlinedButton.icon(
                      onPressed: () async {
                        if (isFiltered) {
                          ref.read(projectDateRangeProvider.notifier).state =
                              null;
                        } else {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDateRange: dateRange,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: const Color(
                                      0xFF1E293B,
                                    ), // Match dark theme tone
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref.read(projectDateRangeProvider.notifier).state =
                                picked;
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(
                          color: isFiltered
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        backgroundColor: isFiltered
                            ? const Color(0xFF1E293B).withValues(alpha: 0.05)
                            : Colors.transparent,
                      ),
                      icon: Icon(
                        isFiltered ? Icons.clear : Icons.date_range,
                        size: 16,
                        color: isFiltered
                            ? const Color(0xFF1E293B)
                            : Colors.black,
                      ),
                      label: Text(
                        isFiltered ? 'Clear Filter' : 'Select Date',
                        style: TextStyle(
                          color: isFiltered
                              ? const Color(0xFF1E293B)
                              : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                var displayLogs = logs;
                if (dateRange != null) {
                  displayLogs = logs.where((log) {
                    final lDate = log.logDate ?? log.loggedAt;
                    final logDate = DateTime(
                      lDate.year,
                      lDate.month,
                      lDate.day,
                    );
                    final start = DateTime(
                      dateRange.start.year,
                      dateRange.start.month,
                      dateRange.start.day,
                    );
                    final end = DateTime(
                      dateRange.end.year,
                      dateRange.end.month,
                      dateRange.end.day,
                    );
                    return (logDate.isAtSameMomentAs(start) ||
                            logDate.isAfter(start)) &&
                        (logDate.isAtSameMomentAs(end) ||
                            logDate.isBefore(end));
                  }).toList();
                }

                if (displayLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No usage logged yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    80,
                  ), // Bottom padding for FAB
                  itemCount: displayLogs.length,
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final requireNote =
                        ref.read(userRoleProvider) == UserRole.siteManager;
                    return _MachineryCard(
                      log: log,
                      color: _getColor(index),
                      requireNote: requireNote,
                      onDeleted: () {
                        ref.invalidate(machineryLogsProvider(projectId));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogMachinerySheet(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogMachinerySheet(projectId: projectId),
    );
  }

  Color _getColor(int index) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}

class _MachineryCard extends ConsumerWidget {
  final MachineryLog log;
  final Color color;
  final VoidCallback onDeleted;
  final bool requireNote;

  const _MachineryCard({
    required this.log,
    required this.color,
    required this.onDeleted,
    required this.requireNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = log.logDate != null
        ? DateFormat('MMM dd, yyyy').format(log.logDate!)
        : DateFormat('MMM dd, yyyy').format(log.loggedAt);

    final isTimeBased =
        log.logType == 'time' && log.startTime != null && log.endTime != null;
    final timeRange = isTimeBased ? '${log.startTime} - ${log.endTime}' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Machine Name & Reg
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.machineryName ?? 'Unknown Machine',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.registrationNo ?? 'No Registration',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final noteController = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete machinery log'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('This will remove the log entry.'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText:
                                  'Note ${requireNote ? "*" : "(optional)"}',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (requireNote &&
                                noteController.text.trim().isEmpty) {
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(machineryRepositoryProvider)
                        .deleteMachineryLog(
                          logId: log.id,
                          projectId: log.projectId,
                          note: noteController.text.trim().isEmpty
                              ? null
                              : noteController.text.trim(),
                        );
                    onDeleted();
                  }
                },
              ),

              // Hours Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${log.duration.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Details Grid
          Row(
            children: [
              // Date Column
              Expanded(
                child: _DetailItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateStr,
                ),
              ),

              // Time or Reading Column
              Expanded(
                child: isTimeBased
                    ? _DetailItem(
                        icon: Icons.schedule,
                        label: 'Time',
                        value: timeRange!,
                      )
                    : _DetailItem(
                        icon: Icons.speed,
                        label: 'Reading',
                        value:
                            log.startReading != null && log.endReading != null
                            ? '${log.startReading!.toStringAsFixed(0)} → ${log.endReading!.toStringAsFixed(0)}'
                            : '-',
                      ),
              ),
            ],
          ),

          // Work Activity
          if (log.workActivity.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailItem(
              icon: Icons.construction,
              label: 'Activity',
              value: log.workActivity,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogMachinerySheet extends ConsumerStatefulWidget {
  final String projectId;

  const _LogMachinerySheet({required this.projectId});

  @override
  ConsumerState<_LogMachinerySheet> createState() => _LogMachinerySheetState();
}

class _LogMachinerySheetState extends ConsumerState<_LogMachinerySheet> {
  final _formKey = GlobalKey<FormState>();

  // Selection
  MachineryModel? _selectedMachine;
  final _activityController = TextEditingController();

  // Logic Toggle
  bool _isTimeBased = true; // Default to Time

  // Time Inputs
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Reading Inputs
  final _startReadingController = TextEditingController();
  final _endReadingController = TextEditingController();

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  double get _calculatedDuration {
    if (_isTimeBased) {
      if (_startTime == null || _endTime == null) return 0.0;
      final start = _startTime!.hour + _startTime!.minute / 60.0;
      var end = _endTime!.hour + _endTime!.minute / 60.0;
      if (end < start) end += 24; // Handle overnight
      return end - start;
    } else {
      final start = double.tryParse(_startReadingController.text) ?? 0.0;
      final end = double.tryParse(_endReadingController.text) ?? 0.0;
      return (end - start).clamp(0.0, 9999.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show content if we have sufficient height, otherwise scroll
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Wrap to avoid overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Machinery',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add data to the site ledger',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleOption(
                      'By Time',
                      _isTimeBased,
                      () => setState(() => _isTimeBased = true),
                    ),
                    _buildToggleOption(
                      'By Reading',
                      !_isTimeBased,
                      () => setState(() => _isTimeBased = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Machine Selection
              const Text(
                'MACHINE SELECTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final machineryAsync = ref.watch(machineryListProvider);
                  return machineryAsync.when(
                    data: (machines) => SearchableDropdownWithCreate<MachineryModel>(
                      label: 'Equipment',
                      items: machines,
                      itemLabelBuilder: (m) =>
                          '${m.name} (${m.registrationNo ?? "-"})',
                      value: _selectedMachine,
                      onChanged: (val) =>
                          setState(() => _selectedMachine = val),
                      hint: 'Choose equipment',
                      onAdd: (name) async {
                        final result = await _showQuickCreateDialog(
                          context,
                          name,
                        );
                        if (result == true) {
                          ref.invalidate(machineryListProvider);
                          // Return a temporary model to satisfy non-nullable requirement
                          // In a real app, we should return the created object from backend
                          return MachineryModel(
                            id: 'temp_id',
                            name: name,
                            currentReading: 0,
                            totalHours: 0,
                            status: 'active',
                          );
                        }
                        throw 'Creation cancelled';
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading machines: $e'),
                  );
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'LOG DATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1E293B),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Work Activity
              const Text(
                'WORK ACTIVITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _activityController,
                decoration: InputDecoration(
                  hintText: 'e.g. Excavation Phase 1',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // Inputs (Time or Reading)
              if (_isTimeBased) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        'START TIME',
                        _startTime,
                        (t) => setState(() => _startTime = t),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        'END TIME',
                        _endTime,
                        (t) => setState(() => _endTime = t),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'START READING',
                        _startReadingController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'END READING',
                        _endReadingController,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Calculated Result
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isTimeBased ? 'Execution Hours' : 'Difference',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      _isTimeBased
                          ? '${_calculatedDuration.toStringAsFixed(1)} hrs'
                          : '${_calculatedDuration.toStringAsFixed(1)} units',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirm & Save Log',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time?.format(context) ?? '--:--',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (_) => setState(() {}), // trigger rebuild for calc
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachine == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a machine')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(machineryControllerProvider.notifier);
      bool success = false;

      if (_isTimeBased) {
        if (_startTime == null || _endTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select Start and End time')),
          );
          setState(() => _isLoading = false);
          return;
        }

        debugPrint('[MACHINERY LOG] Logging time-based...');
        debugPrint('[MACHINERY LOG] Machine: ${_selectedMachine!.name}');
        debugPrint(
          '[MACHINERY LOG] Start: ${_startTime!.format(context)}, End: ${_endTime!.format(context)}',
        );
        debugPrint('[MACHINERY LOG] Duration: $_calculatedDuration hrs');

        success = await controller.logTimeBased(
          projectId: widget.projectId,
          machineryId: _selectedMachine!.id,
          workActivity: _activityController.text,
          logDate: _selectedDate,
          startTime: _startTime!.format(context),
          endTime: _endTime!.format(context),
          totalHours: _calculatedDuration,
        );
      } else {
        final start = double.tryParse(_startReadingController.text);
        final end = double.tryParse(_endReadingController.text);

        if (start == null || end == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid readings')));
          setState(() => _isLoading = false);
          return;
        }

        debugPrint('[MACHINERY LOG] Logging reading-based...');
        debugPrint('[MACHINERY LOG] Machine: ${_selectedMachine!.name}');
        debugPrint('[MACHINERY LOG] Start: $start, End: $end');

        success = await controller.logUsage(
          projectId: widget.projectId,
          machineryId: _selectedMachine!.id,
          workActivity: _activityController.text,
          logDate: _selectedDate,
          startReading: start,
          endReading: end,
        );
      }

      debugPrint('[MACHINERY LOG] Success: $success');

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ref.invalidate(machineryLogsProvider(widget.projectId));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save log'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[MACHINERY LOG ERROR] $e');
      debugPrint('[MACHINERY LOG STACK] $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool?> _showQuickCreateDialog(
    BuildContext context,
    String name,
  ) async {
    // Placeholder for quick create - can be expanded effectively
    // For now returning null doesn't block "create" if user really wants,
    // but without backend "create" logic here we just return null.
    // However, existing backend supports `createMachinery`.
    // Let's implement a super simple Alert Dialog.
    final typeController = TextEditingController();
    final regController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add "$name"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type (e.g. Excavator)',
              ),
            ),
            TextField(
              controller: regController,
              decoration: const InputDecoration(labelText: 'Registration No'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (typeController.text.isEmpty) return;
              final success = await ref
                  .read(machineryControllerProvider.notifier)
                  .createMachinery(
                    name: name,
                    type: typeController.text,
                    registrationNo: regController.text,
                    ownershipType: 'Own', // Default
                  );
              if (context.mounted) Navigator.pop(context, success);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
