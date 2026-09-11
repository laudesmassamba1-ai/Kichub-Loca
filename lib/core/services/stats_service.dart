import 'package:kichub_loca/core/models/agent_summary.dart';
import 'package:kichub_loca/core/models/dashboard_stats.dart';
import 'package:kichub_loca/core/models/weekly_point.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';

class StatsService {
  static Future<bool> emailExists(String email) async {
    try {
      final result = await SupabaseService.client
          .rpc('email_exists', params: {'p_email': email.trim()});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AgentSummary>> fetchAgentsSummary() async {
    try {
      final response = await SupabaseService.client.rpc('get_agents_summary');
      if (response is! List) return const [];

      return response
          .map((item) => AgentSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<DashboardStats?> fetchDashboardStats() async {
    try {
      final response = await SupabaseService.client.rpc('get_dashboard_stats');
      if (response is! Map) return null;
      return DashboardStats.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  static Future<List<WeeklyPoint>> fetchWeeklySeries({int weeks = 6}) async {
    try {
      final response = await SupabaseService.client.rpc(
        'get_weekly_series',
        params: {'p_weeks': weeks},
      );
      if (response is! List) return const [];

      return response
          .map((item) => WeeklyPoint.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}