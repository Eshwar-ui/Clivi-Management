import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/bill_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../../../core/config/app_constants.dart';
import '../../../../core/utils/upload_helper.dart';

class BillRepository {
  final SupabaseClient _client;
  static const String _billSelectQuery = '''
    *,
    creator:user_profiles!bills_created_by_fkey(id, full_name, email),
    raiser:user_profiles!bills_raised_by_fkey(id, full_name, email),
    approver:user_profiles!bills_approved_by_fkey(id, full_name, email),
    project:projects!bills_project_id_fkey(id, name)
  ''';

  BillRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Get bills for a specific project (NOT all bills)
  Future<List<BillModel>> getBillsByProject(
    String projectId, {
    String? status,
  }) async {
    try {
      var query = _client
          .from('bills')
          .select(_billSelectQuery)
          .eq('project_id', projectId);

      if (status != null) {
        query = query.eq('status', status);
      }

      // Apply sort order at the end
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to fetch bills: $e');
    }
  }

  /// Get pending bills with pagination
  Future<List<BillModel>> getPendingBills({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await _client
          .from('bills')
          .select(_billSelectQuery)
          .eq('project_id', projectId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to fetch pending bills: $e');
    }
  }

  /// Create a new bill
  Future<BillModel> createBill({
    required String projectId,
    required String title,
    required double amount,
    required String billType,
    String? description,
    String? vendorName,
    String? paymentType,
    String? paymentStatus,
    List<int>? receiptBytes,
    String? receiptName,
    DateTime? billDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      String? receiptUrl;

      // Upload receipt if provided
      if (receiptBytes != null && receiptName != null) {
        try {
          final fileExt = receiptName.contains('.')
              ? receiptName.split('.').last
              : 'pdf';
          final contentType = 'application/$fileExt';
          // bills bucket RLS expects first path segment to be project UUID.
          final relativePath = UploadHelper.generateUniquePath(
            'receipts',
            receiptName,
          );
          final filePath = '$projectId/$relativePath';

          receiptUrl = await UploadHelper.uploadWithRetry(
            bucket: AppConstants.bucketBills,
            path: filePath,
            bytes: Uint8List.fromList(receiptBytes),
            contentType: contentType,
          );
        } catch (e) {
          debugPrint(
            'Receipt upload failed, proceeding without attachment: $e',
          );
          receiptUrl = null;
        }
      }

      final data = {
        'project_id': projectId,
        'title': title,
        'amount': amount,
        'bill_type': billType,
        'description': description,
        'payment_type': paymentType,
        'payment_status': paymentStatus ?? 'need_to_pay',
        'status': 'pending',
        'created_by': userId,
        'uploaded_by': userId,
        'raised_by': userId,
        'image_url': receiptUrl ?? '',
        'image_path': receiptUrl ?? '',
        'bill_date': (billDate ?? DateTime.now())
            .toIso8601String()
            .split('T')
            .first,
      };

      final response = await _client.from('bills').insert(data).select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            raiser:user_profiles!bills_raised_by_fkey(id, full_name, email)
          ''').single();

      final bill = BillModel.fromJson(response);

      // Log operation for admin notifications (activity feed)
      try {
        await _client.rpc(
          'log_operation',
          params: {
            'p_operation_type': 'create',
            'p_entity_type': 'bill',
            'p_entity_id': bill.id,
            'p_title': '[BILL] ${bill.title}',
            'p_description': 'Amount: ₹${bill.amount.toStringAsFixed(2)}',
            'p_project_id': bill.projectId,
          },
        );
      } catch (e) {
        debugPrint('log_operation failed for bill: $e');
      }

      return bill;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      debugPrint('Bill insert failed: $e');
      throw Exception('Failed to create bill: $e');
    }
  }

  /// Fetch bills baseline (non-realtime)
  Future<List<BillModel>> fetchBills(String projectId, {String? status}) async {
    return getBillsByProject(projectId, status: status);
  }

  /// Get role-based bills across accessible projects.
  /// If [onlyAssignedProjects] is true, returns only bills for assigned projects.
  Future<List<BillModel>> getBillsForDashboard({
    String? status,
    bool onlyAssignedProjects = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (onlyAssignedProjects && userId == null) {
        return [];
      }

      String selectQuery = _billSelectQuery;
      
      if (onlyAssignedProjects && userId != null) {
        selectQuery = '''
          *,
          creator:user_profiles!bills_created_by_fkey(id, full_name, email),
          approver:user_profiles!bills_approved_by_fkey(id, full_name, email),
          project:projects!inner(
            id,
            name,
            project_assignments!inner(user_id)
          )
        ''';
      }

      var query = _client.from('bills').select(selectQuery);
      
      if (onlyAssignedProjects && userId != null) {
        query = query.eq('project.project_assignments.user_id', userId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to fetch dashboard bills: $e');
    }
  }

  Future<List<BillModel>> fetchBillsForDashboard({
    String? status,
    bool onlyAssignedProjects = false,
  }) {
    return getBillsForDashboard(
      status: status,
      onlyAssignedProjects: onlyAssignedProjects,
    );
  }

  /// Update a bill (only pending bills can be updated by site managers)
  Future<BillModel> updateBill(
    String billId,
    Map<String, dynamic> updates,
  ) async {
    updates['updated_at'] = DateTime.now().toIso8601String();

    try {
      final response = await _client
          .from('bills')
          .update(updates)
          .eq('id', billId)
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email),
            project:projects!bills_project_id_fkey(id, name)
          ''')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to update bill: $e');
    }
  }

  /// Admin approval workflow update:
  /// - payment status: pending / will pay / paid
  /// - mark completed toggles bill completion
  Future<BillModel> updateBillApproval({
    required String billId,
    required PaymentStatus paymentStatus,
    required bool markCompleted,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final now = DateTime.now().toIso8601String();

    try {
      final response = await _client
          .from('bills')
          .update({
            'payment_status': paymentStatus.value,
            'status': markCompleted ? 'paid' : 'pending',
            'approved_by': userId,
            'approved_at': now,
            'updated_at': now,
          })
          .eq('id', billId)
          .select(_billSelectQuery)
          .single();

      final bill = BillModel.fromJson(response);

      try {
        await _client.rpc(
          'log_operation',
          params: {
            'p_operation_type': 'update',
            'p_entity_type': 'bill',
            'p_entity_id': bill.id,
            'p_title': '[BILL] ${bill.title} updated',
            'p_description':
                'Payment: ${bill.paymentStatus.label}, Completion: ${markCompleted ? 'Completed' : 'Pending'}',
            'p_project_id': bill.projectId,
          },
        );
      } catch (e) {
        debugPrint('log_operation failed for bill update: $e');
      }

      return bill;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to update bill approval: $e');
    }
  }

  /// Approve a bill (Admin only)
  Future<BillModel> approveBill(String billId) async {
    final userId = _client.auth.currentUser?.id;

    try {
      final response = await _client
          .from('bills')
          .update({
            'status': 'approved',
            'approved_by': userId,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId)
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email)
          ''')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to approve bill: $e');
    }
  }

  /// Reject a bill (Admin only)
  Future<BillModel> rejectBill(String billId, {String? reason}) async {
    final userId = _client.auth.currentUser?.id;

    try {
      final response = await _client
          .from('bills')
          .update({
            'status': 'rejected',
            'approved_by': userId,
            'approved_at': DateTime.now().toIso8601String(),
            'description':
                reason, // Store rejection reason if description field is used for it, or check if 'rejection_reason' column exists? Guide mapped it to 'description'.
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId)
          .select()
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to reject bill: $e');
    }
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      await _client.from('bills').delete().eq('id', billId);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to delete bill: $e');
    }
  }

  /// Stream bills for real-time updates
  Stream<List<BillModel>> streamBillsByProject(String projectId) {
    return _client
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => BillModel.fromJson(json)).toList());
  }

  Stream<List<BillModel>> streamBillsForDashboard({
    bool onlyAssignedProjects = false,
  }) async* {
    final userId = _client.auth.currentUser?.id;
    if (onlyAssignedProjects && userId == null) {
      yield [];
      return;
    }

    Set<String> assignedProjectIds = {};
    if (onlyAssignedProjects && userId != null) {
      try {
        final assignments = await _client
            .from('project_assignments')
            .select('project_id')
            .eq('user_id', userId);
        assignedProjectIds = (assignments as List).map((a) => a['project_id'] as String).toSet();
      } catch (e) {
        debugPrint('Failed to fetch project assignments for stream: $e');
      }
    }

    yield* _client
        .from('bills')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => BillModel.fromJson(json)).toList())
        .map((items) {
          if (!onlyAssignedProjects || userId == null) {
            return items;
          }
          return items
              .where((bill) => assignedProjectIds.contains(bill.projectId))
              .toList();
        });
  }
}
