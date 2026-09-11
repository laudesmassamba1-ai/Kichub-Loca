import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _cachedPosition;
  static DateTime? _lastCacheTime;

  static Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  static Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPosition != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < const Duration(minutes: 2)) {
      return _cachedPosition;
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      _cachedPosition = position;
      _lastCacheTime = DateTime.now();
      return position;
    } catch (_) {
      return _cachedPosition;
    }
  }

  static void clearCache() {
    _cachedPosition = null;
    _lastCacheTime = null;
  }
}
