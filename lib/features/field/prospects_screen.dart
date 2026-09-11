import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';
import 'package:kichub_loca/core/widgets/prospect_detail_sheet.dart';

class ProspectsScreen extends StatefulWidget {
  const ProspectsScreen({super.key});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final rows = await CommerceService.fetchAllBusinessesWithOwner();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(Commerce commerce) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProspectDetailSheet(commerce: commerce),
    );
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prospects & lieux')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.rose),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 52),
            const SizedBox(height: 12),
            const Text('Aucun prospect enregistré.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final commerce = Commerce.fromJson(row);
        final owner = _extractOwner(row);
        final statusColor = AppColors.statusColor(commerce.statut);

        return LiquidGlassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openDetail(commerce),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: commerce.photoUrl != null
                          ? Image.network(
                              commerce.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, _) => const Icon(
                                  Icons.image_not_supported_rounded),
                            )
                          : const Icon(Icons.storefront_rounded, size: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                commerce.nom,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                AppColors.statusLabel(commerce.statut),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                owner,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (commerce.adresse != null &&
                            commerce.adresse!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  commerce.adresse!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (commerce.notes != null &&
                            commerce.notes!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  commerce.notes!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _extractOwner(Map<String, dynamic> row) {
    final creeur = row['creeur'];
    if (creeur is Map) {
      final nom = creeur['nom'];
      if (nom != null && nom.toString().isNotEmpty) return nom.toString();
    }
    return 'Agent inconnu';
  }
}

