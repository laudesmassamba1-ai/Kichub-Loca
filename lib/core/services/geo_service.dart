import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeoService {
  static const String _kCachePrefix = 'geo_cache_';
  static const Duration _kCacheValidity = Duration(days: 30);
  static const Duration _kMinInterval = Duration(milliseconds: 1100);
  static DateTime? _lastRequestAt;

  /// Retourne une adresse lisible à partir de coordonnées GPS (OpenStreetMap).
  ///
  /// Respecte la politique Nominatim : un vrai User-Agent, un cache local
  /// (résultats réutilisés 30 jours) et une limitation à 1 requête/s max.
  static Future<String?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    // Cache : clé arrondie à ~100 m (3 décimales).
    final key =
        '$_kCachePrefix${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      final address = _decodeCached(cached);
      if (address != null) return address;
      await prefs.remove(key);
    }

    await _throttle();

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': lat.toStringAsFixed(6),
        'lon': lng.toStringAsFixed(6),
        'accept-language': 'fr',
      });

      final res = await http
          .get(
            uri,
            headers: {'User-Agent': 'KichubLoca/1.0 (application terrain)'},
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 429) return null;
      if (res.statusCode != 200) return null;

      final address = _buildAddress(res.body);
      if (address != null) {
        await prefs.setString(key, _encodeCached(address));
      }
      return address;
    } catch (_) {
      return null;
    }
  }

  /// Garantit au maximum 1 appel réseau par seconde.
  static Future<void> _throttle() async {
    final now = DateTime.now();
    final last = _lastRequestAt;
    if (last != null) {
      final wait = _kMinInterval - now.difference(last);
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  static String? _buildAddress(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final display = data['display_name'];
      if (display is String && display.isNotEmpty) return display;

      final address = data['address'];
      if (address is Map) {
        final road = address['road'] ?? address['pedestrian'];
        final town = address['city'] ?? address['town'] ?? address['village'];
        final region = address['state'] ?? address['county'];
        final country = address['country'];
        final parts = [road, town, region, country]
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Encode `horodatage|adresse_codée` — l'expiration est vérifiée à la lecture.
  static String _encodeCached(String address) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = base64Encode(utf8.encode(address));
    return '$now|$payload';
  }

  static String? _decodeCached(String value) {
    try {
      final sep = value.indexOf('|');
      if (sep <= 0) return null;

      final ts = int.tryParse(value.substring(0, sep));
      if (ts == null) return null;

      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > _kCacheValidity) return null;

      return utf8.decode(base64Decode(value.substring(sep + 1)));
    } catch (_) {
      return null;
    }
  }
}