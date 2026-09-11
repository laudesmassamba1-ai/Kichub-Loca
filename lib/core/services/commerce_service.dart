import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/models/visit.dart';
import 'package:kichub_loca/core/services/offline_cache_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';

class CommerceService {
  // ============================================================
  // LECTURES
  // ============================================================

  static Future<List<Commerce>> fetchNearbyBusinesses({
    required double lat,
    required double lng,
    int radiusMeters = 100,
  }) async {
    try {
      final data = await SupabaseService.client.rpc(
        'commerces_proches',
        params: {'lat': lat, 'lng': lng, 'rayon_m': radiusMeters},
      );

      if (data is! List) return const [];

      final businesses = data
          .map((item) => Commerce.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      await OfflineCacheService.cacheBusinesses(
        businesses.map((b) => b.toJson()).toList(),
      );
      await OfflineCacheService.cachePosition(
        latitude: lat,
        longitude: lng,
      );

      return businesses;
    } catch (_) {
      return _fetchNearbyFromCache(lat: lat, lng: lng, radiusMeters: radiusMeters);
    }
  }

  static Future<List<Commerce>> fetchAllBusinesses() async {
    try {
      final response = await SupabaseService.client
          .from('commerces')
          .select()
          .order('created_at', ascending: false);

      final list = response as List<dynamic>? ?? const [];
      final businesses = list
          .map((item) => Commerce.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      await OfflineCacheService.cacheBusinesses(
        businesses.map((b) => b.toJson()).toList(),
      );

      return businesses;
    } catch (_) {
      final cached = await OfflineCacheService.getCachedBusinesses();
      return cached
          .map((item) => Commerce.fromJson(item))
          .toList();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllBusinessesWithOwner() async {
    try {
      final response = await SupabaseService.client
          .from('commerces')
          .select('*, creeur:profiles(nom)')
          .order('created_at', ascending: false);

      return (response as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      final cached = await OfflineCacheService.getCachedBusinesses();
      return cached;
    }
  }

  static Future<Map<String, String>> fetchLatestStatuses() async {
    try {
      final response = await SupabaseService.client
          .from('visites')
          .select('commerce_id, statut')
          .order('date_visite', ascending: false);

      final list = response as List<dynamic>? ?? const [];
      final statusByCommerce = <String, String>{};
      for (final item in list) {
        final map = Map<String, dynamic>.from(item);
        final cid = map['commerce_id'].toString();
        statusByCommerce[cid] ??= (map['statut'] ?? 'nouveau').toString();
      }
      return statusByCommerce;
    } catch (_) {
      return const {};
    }
  }

  static Future<List<Visit>> fetchMyVisits() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const [];

    try {
      final response = await SupabaseService.client
          .from('visites')
          .select('*, commerces(nom)')
          .eq('agent_id', userId)
          .order('date_visite', ascending: false);

      final list = response as List<dynamic>? ?? const [];
      final visits = list
          .map((item) => Visit.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      await OfflineCacheService.cacheVisits(
        visits.map((v) => v.toJson()).toList(),
      );

      return visits;
    } catch (_) {
      final cached = await OfflineCacheService.getCachedVisits();
      return cached.map((item) => Visit.fromJson(item)).toList();
    }
  }

  static Future<List<Visit>> fetchVisitsForCommerce(String commerceId) async {
    try {
      final response = await SupabaseService.client
          .from('visites')
          .select()
          .eq('commerce_id', commerceId)
          .order('date_visite', ascending: false);

      final list = response as List<dynamic>? ?? const [];
      return list
          .map((item) => Visit.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      final cached = await OfflineCacheService.getCachedVisits();
      return cached
          .where((v) => v['commerce_id'] == commerceId)
          .map((item) => Visit.fromJson(item))
          .toList();
    }
  }

  // ============================================================
  // ÉCRITURES (avec queue offline)
  // ============================================================

  static Future<String?> createCommerce({
    required String name,
    required double lat,
    required double lng,
    String? description,
    String? adresse,
    String? notes,
    String statut = 'nouveau',
    String? photoUrl,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final data = {
      'nom': name,
      'latitude': lat,
      'longitude': lng,
      'description': description,
      'adresse': adresse,
      'notes': notes,
      'statut': statut,
      'photo_url': photoUrl,
      'cree_par': userId,
    };

    try {
      final res = await SupabaseService.client
          .from('commerces')
          .insert(data)
          .select('id')
          .single();
      return res['id'] as String?;
    } catch (_) {
      await OfflineCacheService.enqueueWrite(type: 'commerce', data: data);
      return null;
    }
  }

  static Future<bool> updateCommerceStatus({
    required String commerceId,
    required String statut,
  }) async {
    try {
      await SupabaseService.client
          .from('commerces')
          .update({'statut': statut}).eq('id', commerceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateCommerceNotes({
    required String commerceId,
    required String? notes,
  }) async {
    try {
      await SupabaseService.client
          .from('commerces')
          .update({'notes': notes}).eq('id', commerceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> createVisit({
    required String commerceId,
    required String statut,
    required DateTime dateVisite,
    DateTime? dateRappel,
    String? notes,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final data = {
      'commerce_id': commerceId,
      'agent_id': userId,
      'statut': statut,
      'date_visite': dateVisite.toUtc().toIso8601String(),
      'date_rappel': dateRappel?.toUtc().toIso8601String(),
      'notes': notes,
    };

    try {
      await SupabaseService.client.from('visites').insert(data);
      await SupabaseService.client
          .from('commerces')
          .update({'statut': statut}).eq('id', commerceId);
      return true;
    } catch (_) {
      await OfflineCacheService.enqueueWrite(type: 'visit', data: data);
      return false;
    }
  }

  static Future<bool> updateCommercePhoto({
    required String commerceId,
    required String photoUrl,
  }) async {
    try {
      await SupabaseService.client
          .from('commerces')
          .update({'photo_url': photoUrl}).eq('id', commerceId);
      return true;
    } catch (_) {
      await OfflineCacheService.enqueueWrite(
        type: 'commerce_photo',
        data: {'commerce_id': commerceId, 'photo_url': photoUrl},
      );
      return false;
    }
  }

  // ============================================================
  // SYNC OFFLINE → CLOUD
  // ============================================================

  /// Retourne le nombre d'opérations synchronisées.
  static Future<int> syncPendingWrites() async {
    final pending = await OfflineCacheService.getPendingWrites();
    if (pending.isEmpty) return 0;

    int synced = 0;

    for (final op in pending) {
      try {
        final type = (op['type'] ?? '').toString();
        final data = Map<String, dynamic>.from(op['data'] ?? {});

        switch (type) {
          case 'visit':
            await SupabaseService.client.from('visites').insert(data);
            final cid = data['commerce_id'];
            final statut = data['statut'];
            if (cid != null && statut != null) {
              await SupabaseService.client
                  .from('commerces')
                  .update({'statut': statut}).eq('id', cid);
            }
          case 'commerce':
            await SupabaseService.client.from('commerces').insert(data);
          case 'commerce_photo':
            await SupabaseService.client
                .from('commerces')
                .update({'photo_url': data['photo_url']})
                .eq('id', data['commerce_id']);
          case 'passage':
            await SupabaseService.client.from('passages').insert(data);
        }

        await OfflineCacheService.removePendingWrite(op['id']);
        synced++;
      } catch (_) {
        break;
      }
    }

    if (synced > 0) {
      await OfflineCacheService.setLastSync(DateTime.now());
    }

    return synced;
  }

  // ============================================================
  // STATS (offline-friendly)
  // ============================================================

  static Future<int> countBusinesses() async {
    try {
      final response = await SupabaseService.client
          .from('commerces')
          .select('id')
          .count();
      return response.count;
    } catch (_) {
      final cached = await OfflineCacheService.getCachedBusinesses();
      return cached.length;
    }
  }

  static Future<Map<String, int>> getVisitStats() async {
    List<Map<String, dynamic>> rows;
    try {
      final response = await SupabaseService.client.from('visites').select('statut');
      rows = (response as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      rows = await OfflineCacheService.getCachedVisits();
    }

    final stats = <String, int>{
      'total': rows.length,
      'nouveau': 0,
      'accepte': 0,
      'refuse': 0,
      'a_recontacter': 0,
    };

    for (final item in rows) {
      final statut = (item['statut'] ?? 'nouveau').toString();
      stats[statut] = (stats[statut] ?? 0) + 1;
    }

    return stats;
  }

  // ============================================================
  // PRIVÉ
  // ============================================================

  static Future<List<Commerce>> _fetchNearbyFromCache({
    required double lat,
    required double lng,
    required int radiusMeters,
  }) async {
    final cached = await OfflineCacheService.getCachedBusinesses();
    if (cached.isEmpty) return const [];

    return cached.map((item) => Commerce.fromJson(item)).where((b) {
      final distance = OfflineCacheService.distanceMeters(
        lat1: lat,
        lng1: lng,
        lat2: b.latitude,
        lng2: b.longitude,
      );
      return distance <= radiusMeters.toDouble();
    }).map((b) {
      final distance = OfflineCacheService.distanceMeters(
        lat1: lat,
        lng1: lng,
        lat2: b.latitude,
        lng2: b.longitude,
      );
      return Commerce(
        id: b.id,
        nom: b.nom,
        latitude: b.latitude,
        longitude: b.longitude,
        description: b.description,
        adresse: b.adresse,
        notes: b.notes,
        statut: b.statut,
        photoUrl: b.photoUrl,
        creePar: b.creePar,
        dateCreation: b.dateCreation,
        distanceMeters: distance,
      );
    }).toList();
  }
}