import 'package:kichub_loca/core/services/supabase_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchProfileSummary() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await SupabaseService.client
          .rpc('get_profile_summary');

      if (response is List) {
        for (final row in response) {
          final map = Map<String, dynamic>.from(row);
          if (map['id'] == userId) return map;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    try {
      final response = await SupabaseService.client
          .rpc('get_profile_summary');

      if (response is List) {
        return response
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
