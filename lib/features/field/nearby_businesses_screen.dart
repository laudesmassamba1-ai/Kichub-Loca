import 'package:flutter/material.dart';
import 'package:kichub_loca/app/app.dart';
import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/location_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class NearbyBusinessesScreen extends StatefulWidget {
  const NearbyBusinessesScreen({super.key});

  @override
  State<NearbyBusinessesScreen> createState() => _NearbyBusinessesScreenState();
}

class _NearbyBusinessesScreenState extends State<NearbyBusinessesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Commerce> _businesses = const [];

  @override
  void initState() {
    super.initState();
    _loadNearbyBusiness();
  }

  Future<void> _loadNearbyBusiness() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _error = 'GPS indisponible. Active la géolocalisation.';
          _isLoading = false;
        });
        return;
      }

      final data = await CommerceService.fetchNearbyBusinesses(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: 100,
      );

      if (!mounted) return;
      setState(() {
        _businesses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commerces proches')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNearbyBusiness,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.rose),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadNearbyBusiness,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 52),
            const SizedBox(height: 12),
            const Text('Aucun commerce détecté à proximité.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadNearbyBusiness,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _businesses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final business = _businesses[index];
        final distance = business.distanceMeters ?? 0.0;

        return LiquidGlassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.visitFlow,
                arguments: {
                  'id': business.id,
                  'nom': business.nom,
                  'distance_m': distance,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade200,
                      child: business.photoUrl != null
                          ? Image.network(
                              business.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.storefront_rounded,
                                size: 32,
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.nom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'À ${distance.toStringAsFixed(0)} m',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (business.adresse != null &&
                            business.adresse!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            business.adresse!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
