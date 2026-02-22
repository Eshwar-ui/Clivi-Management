import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/labour_model.dart';
import '../data/models/labour_attendance_model.dart';
import '../data/repositories/labour_repository.dart';
import '../data/models/daily_labour_log.dart';

/// Repository provider
final labourRepositoryProvider = Provider<LabourRepository>((ref) {
  return LabourRepository();
});

/// Labour list for a project
final projectLabourProvider = FutureProvider.family<List<LabourModel>, String>((
  ref,
  projectId,
) async {
  final repo = ref.watch(labourRepositoryProvider);
  return repo.getLabourByProject(projectId);
});

/// Active labour for a project
final activeLabourProvider = FutureProvider.family<List<LabourModel>, String>((
  ref,
  projectId,
) async {
  final repo = ref.watch(labourRepositoryProvider);
  return repo.getActiveLabourByProject(projectId);
});

/// Master labour (project_id null)
final masterLabourProvider = FutureProvider<List<LabourModel>>((ref) async {
  final repo = ref.watch(labourRepositoryProvider);
  return repo.getMasterLabour();
});

/// Attendance for a specific date
final attendanceByDateProvider =
    FutureProvider.family<
      List<LabourAttendanceModel>,
      ({String projectId, DateTime date})
    >((ref, params) async {
      final repo = ref.watch(labourRepositoryProvider);
      return repo.getAttendanceByDate(params.projectId, params.date);
    });

/// Labour with attendance status for marking
final labourWithAttendanceProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String projectId, DateTime date})
    >((ref, params) async {
      final repo = ref.watch(labourRepositoryProvider);
      return repo.getLabourWithAttendance(params.projectId, params.date);
    });

/// Today's attendance summary
final todayAttendanceSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
      final repo = ref.watch(labourRepositoryProvider);
      final today = DateTime.now();
      return repo.getAttendanceSummary(projectId, today, today);
    });

/// Daily Labour Logs (Force Reports) Stream
final dailyLabourLogsProvider =
    StreamProvider.family<List<DailyLabourLog>, String>((ref, projectId) {
      final repo = ref.watch(labourRepositoryProvider);
      return repo.streamDailyLogs(projectId);
    });
