import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataCacheService {
  static const String _transactionsCacheKey = 'transactions_cache_';
  static const String _accountsCacheKey = 'accounts_cache_';
  static const String _budgetsCacheKey = 'budgets_cache_';
  static const String _analyticsCacheKey = 'analytics_cache_';
  static const String _cacheTimestampKey = 'cache_timestamp_';

  final SharedPreferences _prefs;
  static const Duration _cacheDuration = Duration(hours: 1); // 1 hour TTL

  DataCacheService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Cache data with timestamp
  Future<void> cacheData<T>(String key, dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      await _prefs.setString(key, jsonString);
      await _prefs.setInt(
        '$_cacheTimestampKey$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  /// Get cached data if valid
  Future<T?> getCachedData<T>(String key, T Function(dynamic) fromJson) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;

      // Check if cache is expired
      final timestamp = _prefs.getInt('$_cacheTimestampKey$key');
      if (timestamp == null) return null;

      final cacheAge = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - timestamp,
      );

      if (cacheAge > _cacheDuration) {
        // Cache expired
        await clearCache(key);
        return null;
      }

      // Parse and return cached data
      final jsonData = jsonDecode(jsonString);
      return fromJson(jsonData);
    } catch (e) {
      print('Error retrieving cache: $e');
      return null;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    await _prefs.remove(key);
    await _prefs.remove('$_cacheTimestampKey$key');
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    await _prefs.remove(_transactionsCacheKey);
    await _prefs.remove(_accountsCacheKey);
    await _prefs.remove(_budgetsCacheKey);
    await _prefs.remove(_analyticsCacheKey);

    // Remove all timestamps
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheTimestampKey)) {
        await _prefs.remove(key);
      }
    }
  }

  /// Check if cache is valid (not expired)
  bool isCacheValid(String key) {
    final timestamp = _prefs.getInt('$_cacheTimestampKey$key');
    if (timestamp == null) return false;

    final cacheAge = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - timestamp,
    );

    return cacheAge <= _cacheDuration;
  }

  /// Get cache age in seconds
  int? getCacheAgeSeconds(String key) {
    final timestamp = _prefs.getInt('$_cacheTimestampKey$key');
    if (timestamp == null) return null;

    final ageMs = DateTime.now().millisecondsSinceEpoch - timestamp;
    return (ageMs / 1000).toInt();
  }

  /// Clear expired caches
  Future<void> clearExpiredCaches() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith(_cacheTimestampKey)) {
        final isExpired = !isCacheValid(key);
        if (isExpired) {
          await clearCache(key);
        }
      }
    }
  }
}
