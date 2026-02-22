import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_balance_model.dart';

class MaterialsRepository {
  final SupabaseClient _client;

  MaterialsRepository(this._client);

  Future<List<StockBalanceModel>> getProjectStockBalance(
    String projectId,
  ) async {
    // Placeholder implementation
    // Ideally this would call an RPC or query a view
    // For now returning empty list to satisfy compilation
    return [];
  }
}
