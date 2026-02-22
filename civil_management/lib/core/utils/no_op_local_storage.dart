import 'package:supabase_flutter/supabase_flutter.dart';

/// A LocalStorage implementation that does nothing.
/// Used for creating a SupabaseClient that doesn't persist sessions,
/// allowing us to create users without overwriting the current admin session.
class NoOpLocalStorage extends LocalStorage {
  const NoOpLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}
