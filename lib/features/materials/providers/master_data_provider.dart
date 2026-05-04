import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/material_master_repository.dart';

final materialMasterRepositoryProvider = Provider<MaterialMasterRepository>((
  ref,
) {
  return MaterialMasterRepository();
});
