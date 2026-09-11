import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoService {
  /// Retourne une adresse lisible à partir de coordonnées GPS (OpenStreetMap).
  static Future<String?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
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

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final display = data['display_name'];
      if (display is String && display.isNotEmpty) return display;

      final address = data['address'];
      if (address is Map) {
        final road = address['road'] ?? address['pedestrian'];
        final town =
            address['city'] ?? address['town'] ?? address['village'];
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
}