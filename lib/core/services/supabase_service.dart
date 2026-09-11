import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool _isInitialized = false;

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static bool get isInitialized => _isInitialized;

  static void _requireInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Supabase n\'a pas été initialisé.',
      );
    }
  }

  static SupabaseClient get client {
    _requireInitialized();
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!isConfigured) {
      throw StateError(
        'Supabase n\'est pas configuré.',
      );
    }

    if (_isInitialized) return;

    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        persistSession: true,
      ),
    );
    _isInitialized = true;
  }

  static User? get currentUser =>
      _isInitialized ? client.auth.currentUser : null;

  static Stream<AuthState> get authStateChanges =>
      _isInitialized ? client.auth.onAuthStateChange : const Stream.empty();

  static Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _requireInitialized();
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String nom,
  }) async {
    _requireInitialized();
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nom': nom},
    );
  }

  static Future<void> signOut() async {
    if (!_isInitialized) return;
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    _requireInitialized();
    await client.auth.resetPasswordForEmail(email.trim());
  }
}
