import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/labour_model.dart';
import '../data/models/labour_attendance_model.dart';
import '../providers/labour_provider.dart';

/// Daily Attendance Screen - Mark attendance for all workers
class AttendanceScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const AttendanceScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, AttendanceStatus> _attendanceMap = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final labourWithAttendance = ref.watch(
      labourWithAttendanceProvider((
        projectId: widget.projectId,
        date: _selectedDate,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance'),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pick date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: labourWithAttendance.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) {
          if (data.isEmpty) {
            return _buildEmptyState();
          }
          return _buildAttendanceList(data);
        },
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('No active workers'),
          const SizedBox(height: 8),
          const Text('Add workers to mark attendance'),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<Map<String, dynamic>> data) {
    // Re-seed attendance map whenever dataset changes (handles newly added labour)
    if (_attendanceMap.length != data.length) {
      _attendanceMap.clear();
    }
    for (final item in data) {
      final labour = item['labour'] as LabourModel;
      final attendance = item['attendance'] as LabourAttendanceModel?;
      _attendanceMap[labour.id] =
          attendance?.status ??
          _attendanceMap[labour.id] ??
          AttendanceStatus.present;
    }

    return Column(
      children: [
        // Summary bar
        _AttendanceSummaryBar(attendanceMap: _attendanceMap),

        // Worker list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final labour = data[index]['labour'] as LabourModel;
              final currentStatus =
                  _attendanceMap[labour.id] ?? AttendanceStatus.present;

              return _AttendanceCard(
                labour: labour,
                status: currentStatus,
                onStatusChanged: (newStatus) {
                  setState(() {
                    _attendanceMap[labour.id] = newStatus;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Attendance'),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _attendanceMap.clear();
      });
      ref.invalidate(
        labourWithAttendanceProvider((
          projectId: widget.projectId,
          date: _selectedDate,
        )),
      );
    }
  }

  Future<void> _saveAttendance() async {
    if (_attendanceMap.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(labourRepositoryProvider);
      final userId = ref.read(currentUserProvider)?.id;

      final attendances = _attendanceMap.entries.map((entry) {
        return LabourAttendanceModel(
          id: '',
          labourId: entry.key,
          projectId: widget.projectId,
          date: _selectedDate,
          status: entry.value,
          hoursWorked: entry.value == AttendanceStatus.present
              ? 8
              : (entry.value == AttendanceStatus.halfDay ? 4 : 0),
          recordedBy: userId,
          createdAt: DateTime.now(),
        );
      }).toList();

      await repo.bulkMarkAttendance(attendances);

      // Refresh data providers to reflect latest state
      ref.invalidate(
        labourWithAttendanceProvider((
          projectId: widget.projectId,
          date: _selectedDate,
        )),
      );
      ref.invalidate(projectLabourProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

class _AttendanceSummaryBar extends StatelessWidget {
  final Map<String, AttendanceStatus> attendanceMap;

  const _AttendanceSummaryBar({required this.attendanceMap});

  @override
  Widget build(BuildContext context) {
    int present = 0, absent = 0, halfDay = 0;

    for (final status in attendanceMap.values) {
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.halfDay:
          halfDay++;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(label: 'Present', count: present, color: Colors.green),
          _SummaryChip(label: 'Half Day', count: halfDay, color: Colors.orange),
          _SummaryChip(label: 'Absent', count: absent, color: Colors.red),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final LabourModel labour;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _AttendanceCard({
    required this.labour,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
              child: Text(
                labour.name[0].toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and skill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labour.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (labour.skillType != null)
                    Text(
                      labour.skillType!,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),

            // Status buttons
            ToggleButtons(
              isSelected: [
                status == AttendanceStatus.present,
                status == AttendanceStatus.halfDay,
                status == AttendanceStatus.absent,
              ],
              onPressed: (index) {
                switch (index) {
                  case 0:
                    onStatusChanged(AttendanceStatus.present);
                    break;
                  case 1:
                    onStatusChanged(AttendanceStatus.halfDay);
                    break;
                  case 2:
                    onStatusChanged(AttendanceStatus.absent);
                    break;
                }
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
              children: const [
                Icon(Icons.check, color: Colors.green, size: 18),
                Icon(Icons.remove, color: Colors.orange, size: 18),
                Icon(Icons.close, color: Colors.red, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.halfDay:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }
}
