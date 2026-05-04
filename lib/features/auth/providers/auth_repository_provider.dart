import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

/// Provider for AuthRepository
/// Use this to inject the repository into other providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
