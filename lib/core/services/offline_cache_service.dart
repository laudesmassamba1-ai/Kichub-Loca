import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const String _keyVisits = 'kichub.cache.visits';
  static const String _keyBusinesses = 'kichub.cache.businesses';
  static const String _keyPosition = 'kichub.cache.position';
  static const String _keyPending = 'kichub.cache.pending';
  static const String _keyLastSync = 'kichub.cache.last_sync';

  // ============================================================
  // CACHE DE LECTURE
  // ============================================================

  static Future<void> cacheVisits(List<Map<String, dynamic>> visits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVisits, jsonEncode(visits));
  }

  static Future<List<Map<String, dynamic>>> getCachedVisits() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_keyVisits));
  }

  static Future<void> cacheBusinesses(
    List<Map<String, dynamic>> businesses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBusinesses, jsonEncode(businesses));
  }

  static Future<List<Map<String, dynamic>>> getCachedBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_keyBusinesses));
  }

  static Future<void> cachePosition({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPosition,
      jsonEncode({'lat': latitude, 'lng': longitude}),
    );
  }

  static Future<Map<String, double>?> getCachedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPosition);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map;
      return {
        'lat': (decoded['lat'] as num).toDouble(),
        'lng': (decoded['lng'] as num).toDouble(),
      };
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // FILE D'ATTENTE D'ÉCRITURES (offline → sync)
  // ============================================================

  static Future<void> enqueueWrite({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = List<Map<String, dynamic>>.of(await getPendingWrites());
    pending.add({
      'id': '${DateTime.now().microsecondsSinceEpoch}_${pending.length}',
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_keyPending, jsonEncode(pending));
  }

  static Future<List<Map<String, dynamic>>> getPendingWrites() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_keyPending));
  }

  static Future<int> getPendingCount() async {
    final pending = await getPendingWrites();
    return pending.length;
  }

  static Future<void> removePendingWrite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingWrites();
    pending.removeWhere((op) => op['id'] == id);
    await prefs.setString(_keyPending, jsonEncode(pending));
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPending);
  }

  // ============================================================
  // HORODATAGE DE SYNC
  // ============================================================

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSync);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, time.toIso8601String());
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final sinHalfLat = sin(dLat / 2);
    final sinHalfLng = sin(dLng / 2);
    final a = sinHalfLat * sinHalfLat +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sinHalfLng *
            sinHalfLng;
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * 0.017453292519943295;
}