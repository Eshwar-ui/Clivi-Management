import '../config/supabase_client.dart';

/// Generic in-memory cache with Stale-While-Revalidate (SWR) pattern
/// Returns stale data immediately while refreshing in background
class CachedRepository<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration staleDuration;
  final Duration maxDuration;
  final int maxSize;
  final void Function(String key, T value)? onBackgroundRefresh;

  CachedRepository({
    this.staleDuration = const Duration(minutes: 2),
    this.maxDuration = const Duration(minutes: 10),
    this.maxSize = 100,
    this.onBackgroundRefresh,
  });

  /// SWR: Return cached data immediately, refresh in background if stale
  Future<T> getOrFetch(String key, Future<T> Function() fetcher) async {
    final cached = _cache[key];

    if (cached != null) {
      // Check if data is still usable (not hard expired)
      if (!cached.isHardExpired(maxDuration)) {
        // Move to end (LRU refresh)
        _cache.remove(key);
        _cache[key] = cached;

        // If stale, trigger background refresh
        if (cached.isStale(staleDuration)) {
          _refreshInBackground(key, fetcher);
        }

        return cached.value;
      }
    }

    // No cache or hard expired - fetch fresh
    final value = await fetcher();
    _put(key, value);
    return value;
  }

  /// Refresh data in background without blocking
  void _refreshInBackground(String key, Future<T> Function() fetcher) async {
    try {
      final fresh = await fetcher();
      _put(key, fresh);
      logger.i('Background refresh completed for key: $key');
      onBackgroundRefresh?.call(key, fresh);
    } catch (e) {
      logger.w('Background refresh failed for key $key: $e');
    }
  }

  /// Add value to cache with LRU eviction
  void _put(String key, T value) {
    // Evict oldest entries if at capacity
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = CacheEntry(value, DateTime.now());
  }

  /// Get cached value without fetching
  T? get(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isHardExpired(maxDuration)) {
      return cached.value;
    }
    return null;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final cached = _cache[key];
    return cached != null && !cached.isHardExpired(maxDuration);
  }

  void invalidate(String key) => _cache.remove(key);
  void invalidateAll() => _cache.clear();
  int get size => _cache.length;
}

class CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  CacheEntry(this.value, this.timestamp);

  bool isStale(Duration staleDuration) =>
      DateTime.now().difference(timestamp) > staleDuration;

  bool isHardExpired(Duration maxDuration) =>
      DateTime.now().difference(timestamp) > maxDuration;

  Duration get age => DateTime.now().difference(timestamp);
}
