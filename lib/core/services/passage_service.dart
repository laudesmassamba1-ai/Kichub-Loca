import 'dart:convert';

import 'package:kichub_loca/core/models/passage.dart';
import 'package:kichub_loca/core/services/offline_cache_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassageService {
  static const String _keyCache = 'kichub.cache.passages';

  static Future<List<Passage>> fetchAllPassages() async {
    try {
      final response = await SupabaseService.client
          .from('passages')
          .select('*, agent:profiles(nom)')
          .order('created_at', ascending: false);

      final list = response as List<dynamic>? ?? const [];
      final passages = list
          .map((item) => Passage.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyCache,
        jsonEncode(passages.map((p) => p.toJson()).toList()),
      );

      return passages;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getString(_keyCache));
    }
  }

  static Future<bool> createPassage({
    required String nom,
    required double lat,
    required double lng,
    String? note,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final data = {
      'agent_id': userId,
      'nom': nom,
      'note': note,
      'latitude': lat,
      'longitude': lng,
    };

    try {
      await SupabaseService.client.from('passages').insert(data);
      return true;
    } catch (_) {
      await OfflineCacheService.enqueueWrite(type: 'passage', data: data);
      return false;
    }
  }

  static Future<bool> deletePassage(String passageId) async {
    try {
      await SupabaseService.client
          .from('passages')
          .delete()
          .eq('id', passageId);
      final prefs = await SharedPreferences.getInstance();
      final cached = _decode(prefs.getString(_keyCache))
          .where((p) => p.id != passageId)
          .toList();
      await prefs.setString(
        _keyCache,
        jsonEncode(cached.map((p) => p.toJson()).toList()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<Passage> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => Passage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}