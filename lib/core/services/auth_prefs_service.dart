import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefsService {
  static const String _keyEmail = 'kichub.auth.email';
  static const String _keyPassword = 'kichub.auth.password';

  static Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email.trim());
    await prefs.setString(_keyPassword, password);
  }

  static Future<({String email, String password})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);
    if (email == null || email.isEmpty || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
  }

  static Future<bool> exists() async => await load() != null;
}