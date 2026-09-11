import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/visit.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/export_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Visit> _visits = const [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final visits = await CommerceService.fetchMyVisits();
      if (!mounted) return;
      setState(() {
        _visits = visits;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des visites'),
        actions: [
          if (_visits.isNotEmpty)
            IconButton(
              onPressed: _exportCsv,
              icon: const Icon(Icons.file_download_rounded),
              tooltip: 'Exporter CSV',
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVisits,
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
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadVisits,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 52),
            const SizedBox(height: 12),
            const Text('Aucune visite enregistrée.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadVisits,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _visits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visit = _visits[index];
        final name = visit.commerceName ?? 'Commerce';

        return LiquidGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusColor(visit.statut)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppColors.statusLabel(visit.statut),
                        style: TextStyle(
                          color: AppColors.statusColor(visit.statut),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Le ${_formatDate(visit.dateVisite)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (visit.dateRappel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rappel: ${_formatDate(visit.dateRappel!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (visit.notes != null && visit.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    visit.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _exportCsv() async {
    if (_visits.isEmpty) return;
    try {
      await ExportService.exportVisitsAsCsv(_visits);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible: $e')),
      );
    }
  }
}
