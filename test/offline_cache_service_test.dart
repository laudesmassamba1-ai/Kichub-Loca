import 'package:flutter_test/flutter_test.dart';
import 'package:kichub_loca/core/services/offline_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineCacheService', () {
    test('cache et relit les visites', () async {
      await OfflineCacheService.cacheVisits([
        {'id': 'v1', 'commerce_id': 'c1', 'statut': 'accepte'},
      ]);

      final visits = await OfflineCacheService.getCachedVisits();
      expect(visits, hasLength(1));
      expect(visits.first['id'], 'v1');
    });

    test('cache et relit les commerces', () async {
      await OfflineCacheService.cacheBusinesses([
        {'id': 'c1', 'nom': 'Boutique A'},
      ]);

      final businesses = await OfflineCacheService.getCachedBusinesses();
      expect(businesses, hasLength(1));
      expect(businesses.first['nom'], 'Boutique A');
    });

    test('file d\'attente : enqueue, compte, remove', () async {
      await OfflineCacheService.enqueueWrite(
        type: 'visit',
        data: {'commerce_id': 'c1'},
      );
      await OfflineCacheService.enqueueWrite(
        type: 'commerce',
        data: {'nom': 'B'},
      );

      expect(await OfflineCacheService.getPendingCount(), 2);

      final pending = await OfflineCacheService.getPendingWrites();
      await OfflineCacheService.removePendingWrite(pending.first['id']);

      expect(await OfflineCacheService.getPendingCount(), 1);
    });

    test('cache position', () async {
      await OfflineCacheService.cachePosition(
        latitude: 6.3654,
        longitude: 2.4231,
      );

      final pos = await OfflineCacheService.getCachedPosition();
      expect(pos, isNotNull);
      expect(pos!['lat'], 6.3654);
      expect(pos['lng'], 2.4231);
    });

    test('calcul de distance correct', () {
      final distance = OfflineCacheService.distanceMeters(
        lat1: 6.3654,
        lng1: 2.4231,
        lat2: 6.3664,
        lng2: 2.4241,
      );

      expect(distance, greaterThan(100));
      expect(distance, lessThan(200));
    });

    test('dernière synchronisation', () async {
      expect(await OfflineCacheService.getLastSync(), isNull);

      final now = DateTime.now();
      await OfflineCacheService.setLastSync(now);

      final lastSync = await OfflineCacheService.getLastSync();
      expect(lastSync, isNotNull);
    });
  });
}