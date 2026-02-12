import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../data/models/report_models.dart';
import '../data/repositories/report_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// ============================================================
// STATE
// ============================================================

class ReportState {
  final FinancialStats stats;
  final TimePeriod selectedPeriod;
  final bool isLoading;
  final String? error;
  final String? selectedVendorId;
  final List<MaterialVendorReportRow> materialVendors;
  final List<MachineryProjectReportRow> machineryProjects;
  final List<LabourProjectReportRow> labourProjects;

  const ReportState({
    this.stats = FinancialStats.empty,
    this.selectedPeriod = TimePeriod.monthly,
    this.isLoading = false,
    this.error,
    this.selectedVendorId,
    this.materialVendors = const [],
    this.machineryProjects = const [],
    this.labourProjects = const [],
  });

  ReportState copyWith({
    FinancialStats? stats,
    TimePeriod? selectedPeriod,
    bool? isLoading,
    String? error,
    String? selectedVendorId,
    List<MaterialVendorReportRow>? materialVendors,
    List<MachineryProjectReportRow>? machineryProjects,
    List<LabourProjectReportRow>? labourProjects,
    bool clearError = false,
  }) {
    return ReportState(
      stats: stats ?? this.stats,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedVendorId: selectedVendorId ?? this.selectedVendorId,
      materialVendors: materialVendors ?? this.materialVendors,
      machineryProjects: machineryProjects ?? this.machineryProjects,
      labourProjects: labourProjects ?? this.labourProjects,
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;

  ReportNotifier(this._repository) : super(const ReportState()) {
    loadReports();
  }

  /// Load reports based on current filter
  Future<void> loadReports({String? projectId, String? vendorId}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final results = await Future.wait([
        _repository.getFinancialMetrics(
          period: state.selectedPeriod,
          projectId: projectId,
        ),
        _repository.getMaterialVendorReport(
          projectId: projectId,
          vendorId: vendorId,
        ),
        _repository.getMachineryProjectReport(projectId: projectId),
        _repository.getLabourProjectReport(projectId: projectId),
      ]);

      state = state.copyWith(
        stats: results[0] as FinancialStats,
        materialVendors: results[1] as List<MaterialVendorReportRow>,
        machineryProjects: results[2] as List<MachineryProjectReportRow>,
        labourProjects: results[3] as List<LabourProjectReportRow>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Change time period filter
  void setPeriod(TimePeriod period, {String? projectId}) {
    if (state.selectedPeriod == period) return;
    
    state = state.copyWith(selectedPeriod: period);
    loadReports(projectId: projectId, vendorId: state.selectedVendorId);
  }
  
  /// Change vendor filter
  void setVendor(String? vendorId, {String? projectId}) {
    if (state.selectedVendorId == vendorId) return;
    state = state.copyWith(selectedVendorId: vendorId);
    loadReports(projectId: projectId, vendorId: vendorId);
  }
  
  /// Refresh data
  Future<void> refresh({String? projectId}) async {
    await loadReports(projectId: projectId, vendorId: state.selectedVendorId);
  }
}

// ============================================================
// PROVIDER
// ============================================================

/// Reports provider (optionally qualified by project ID)
/// Since reports screen is global for now, we don't need family yet, 
/// but keeping structure flexible.
final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(repository);
});
