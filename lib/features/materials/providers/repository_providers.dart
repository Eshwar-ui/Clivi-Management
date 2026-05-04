import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/materials_repository.dart';
import '../data/repositories/receipts_repository.dart';

// Repository Providers
final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(Supabase.instance.client);
});

final receiptsRepositoryProvider = Provider<ReceiptsRepository>((ref) {
  return ReceiptsRepository(Supabase.instance.client);
});
