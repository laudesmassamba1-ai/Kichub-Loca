import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kichub_loca/app/app.dart';
import 'package:kichub_loca/core/services/auth_prefs_service.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/connectivity_service.dart';
import 'package:kichub_loca/core/services/location_service.dart';
import 'package:kichub_loca/core/services/offline_cache_service.dart';
import 'package:kichub_loca/core/services/profile_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';
import 'package:geolocator/geolocator.dart';

class FieldHomeScreen extends StatefulWidget {
  const FieldHomeScreen({super.key});

  @override
  State<FieldHomeScreen> createState() => _FieldHomeScreenState();
}

class _FieldHomeScreenState extends State<FieldHomeScreen> {
  bool _isLoadingNearby = false;
  String _statusMessage = 'Prêt pour la prospection';
  String _agentName = 'Agent';
  Position? _currentPosition;
  int _pendingCount = 0;
  int _reminderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPosition();
    _refreshPendingCount();
    _refreshReminderCount();
    ConnectivityService.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (ConnectivityService.isOnline.value) {
      _syncPending();
    }
  }

  Future<void> _refreshPendingCount() async {
    final count = await OfflineCacheService.getPendingCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _refreshReminderCount() async {
    try {
      final visits = await CommerceService.fetchMyVisits();
      final count = visits.where((v) => v.isReminder).length;
      if (mounted) setState(() => _reminderCount = count);
    } catch (_) {
      // Silencieux : le compteur restera à 0.
    }
  }

  Future<void> _syncPending() async {
    final synced = await CommerceService.syncPendingWrites();
    if (synced > 0 && mounted) {
      _refreshPendingCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$synced action(s) synchronisée(s) avec le serveur.'),
        ),
      );
    }
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.fetchCurrentProfile();
    if (mounted && profile != null) {
      setState(() {
        _agentName = (profile['nom'] ?? 'Agent').toString();
      });
    } else if (mounted) {
      final user = SupabaseService.currentUser;
      final metaName = user?.userMetadata?['nom'];
      if (metaName != null) {
        setState(() => _agentName = metaName.toString());
      }
    }
  }

  Future<void> _loadPosition() async {
    final position = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  Future<void> _checkNearbyBusinesses() async {
    setState(() {
      _isLoadingNearby = true;
      _statusMessage = 'Récupération de la position...';
    });

    final position = await LocationService.getCurrentPosition(forceRefresh: true);
    if (position == null) {
      setState(() {
        _statusMessage = 'GPS indisponible. Active la géolocalisation.';
        _isLoadingNearby = false;
      });
      return;
    }

    setState(() {
      _currentPosition = position;
      _statusMessage = 'Recherche de commerces à proximité...';
    });

    try {
      final data = await CommerceService.fetchNearbyBusinesses(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: 100,
      );

      setState(() {
        _statusMessage = data.isEmpty
            ? 'Aucun commerce détecté dans un rayon de 100m.'
            : '${data.length} commerce(s) trouvé(s) à proximité.';
      });

      if (data.isNotEmpty && mounted) {
        Navigator.pushNamed(context, AppRoutes.nearby);
      }
    } catch (error) {
      setState(() {
        _statusMessage = 'Erreur: $error';
      });
    } finally {
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prospection terrain'),
        actions: [
          IconButton(
            tooltip: 'Mon profil',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_rounded),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await SupabaseService.signOut();
              await AuthPrefsService.clear();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ConnectivityService.isOnline,
          builder: (context, _) {
            final offline = !ConnectivityService.isOnline.value;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(
                    kIsWeb ? 16 : 20,
                  ),
                  child: ListView(
                children: [
                  if (offline) ...[
                    _OfflineBanner(
                      onSync: _syncPending,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_pendingCount > 0 && !offline) ...[
                    _PendingBanner(count: _pendingCount),
                    const SizedBox(height: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, $_agentName',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vérifie les points proches, crée des fiches et qualifie les visites.',
                        style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Détection de doublons',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null)
                        Text(
                          'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          '${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          key: ValueKey(_statusMessage),
                          _statusMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _isLoadingNearby ? null : _checkNearbyBusinesses,
                        icon: _isLoadingNearby
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(
                          _isLoadingNearby ? 'Recherche...' : 'Vérifier proximité',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  _ActionTile(
                    title: 'Prospects',
                    subtitle: 'Lieux de l\'équipe',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.prospects,
                    ),
                  ),
                  _ActionTile(
                    title: 'Agents',
                    subtitle: 'Classement',
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.agents,
                    ),
                  ),
                  _ActionTile(
                    title: 'Statistiques',
                    subtitle: 'Graphiques',
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.dashboard,
                    ),
                  ),
                  _ActionTile(
                    title: 'Historique',
                    subtitle: 'Voir les visites',
                    icon: Icons.history_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.history,
                    ),
                  ),
                  _ActionTile(
                    title: 'À recontacter',
                    subtitle:
                        _reminderCount == 0 ? 'Rappels' : '$_reminderCount rappel(s)',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFF59E0B),
                    badgeCount: _reminderCount,
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.reminders);
                      _refreshReminderCount();
                    },
                  ),
                  _ActionTile(
                    title: 'Carte',
                    subtitle: 'Suivi terrain',
                    icon: Icons.map_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.map,
                    ),
                  ),
                  _ActionTile(
                    title: 'Nouveau commerce',
                    subtitle: 'Créer une fiche',
                    icon: Icons.add_business_rounded,
                    color: const Color(0xFF14B8A6),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.newBusiness,
                    ),
                  ),
                ],
              ),
              ],
              ),
            ),
          ),
        );
              },
            ),
          ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onSync});

  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.amber),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mode hors ligne — les données enregistrées seront synchronisées au retour du réseau.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onSync,
            icon: const Icon(Icons.sync_rounded, color: AppColors.amber),
            tooltip: 'Synchroniser maintenant',
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: AppColors.sky, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count action(s) en attente de synchronisation',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.14),
        highlightColor: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
