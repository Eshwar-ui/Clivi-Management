import 'package:hive_flutter/hive_flutter.dart';
import '../config/supabase_client.dart';
import '../utils/retry_helper.dart';

/// Offline queue for storing operations when network is unavailable
/// Syncs automatically when connection is restored
class OfflineQueueService {
  static const String _queueBoxName = 'offline_queue';
  static OfflineQueueService? _instance;
  static OfflineQueueService get instance => _instance!;

  late Box<Map> _queueBox;
  bool _isSyncing = false;

  OfflineQueueService._();

  /// Initialize the offline queue
  static Future<void> init() async {
    _instance = OfflineQueueService._();
    await _instance!._openBox();
  }

  Future<void> _openBox() async {
    _queueBox = await Hive.openBox<Map>(_queueBoxName);
    logger.i(
      'Offline queue initialized with ${_queueBox.length} pending items',
    );
  }

  /// Enqueue a write operation for later sync
  Future<void> enqueue({
    required String table,
    required String operation, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ??
        '${table}_${operation}_${DateTime.now().millisecondsSinceEpoch}';

    await _queueBox.put(key, {
      'table': table,
      'operation': operation,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });

    logger.i('Enqueued offline operation: $key');
  }

  /// Process all pending operations
  Future<void> processQueue() async {
    if (_isSyncing || _queueBox.isEmpty) return;

    _isSyncing = true;
    logger.i('Processing offline queue: ${_queueBox.length} items');

    final keys = _queueBox.keys.toList();
    int successCount = 0;
    int failCount = 0;

    for (final key in keys) {
      final op = _queueBox.get(key);
      if (op == null) continue;

      try {
        await _executeOperation(Map<String, dynamic>.from(op));
        await _queueBox.delete(key);
        successCount++;
      } catch (e) {
        // Increment attempt counter
        final attempts = (op['attempts'] as int? ?? 0) + 1;
        if (attempts >= 5) {
          // Max retries reached, move to dead letter queue
          logger.e('Max retries reached for $key, removing from queue');
          await _queueBox.delete(key);
          failCount++;
        } else {
          op['attempts'] = attempts;
          await _queueBox.put(key, op);
          logger.w('Failed to process $key (attempt $attempts): $e');
        }
      }
    }

    _isSyncing = false;
    logger.i('Queue processed: $successCount success, $failCount failed');
  }

  Future<void> _executeOperation(Map<String, dynamic> op) async {
    final table = op['table'] as String;
    final operation = op['operation'] as String;
    final data = Map<String, dynamic>.from(op['data'] as Map);

    await RetryHelper.withRetry(() async {
      switch (operation) {
        case 'insert':
          await supabase.from(table).insert(data);
          break;
        case 'update':
          final id = data.remove('id');
          await supabase.from(table).update(data).eq('id', id);
          break;
        case 'delete':
          await supabase.from(table).delete().eq('id', data['id']);
          break;
        default:
          throw Exception('Unknown operation: $operation');
      }
    }, maxAttempts: 2);
  }

  /// Get count of pending operations
  int get pendingCount => _queueBox.length;

  /// Check if there are pending operations
  bool get hasPending => _queueBox.isNotEmpty;

  /// Clear all pending operations
  Future<void> clear() async {
    await _queueBox.clear();
    logger.i('Offline queue cleared');
  }
}
