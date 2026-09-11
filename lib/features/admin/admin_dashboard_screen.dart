import 'package:flutter/material.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalBusinesses = 0;
  Map<String, int> _visitStats = {};
  List<Map<String, dynamic>> _recentVisits = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final businesses = await CommerceService.fetchAllBusinesses();
      final stats = await CommerceService.getVisitStats();
      final visits = await CommerceService.fetchMyVisits();

      if (!mounted) return;
      setState(() {
        _totalBusinesses = businesses.length;
        _visitStats = stats;
        _recentVisits = visits
            .take(5)
            .map((v) => {
                  'name': v.commerceName ?? 'Commerce',
                  'statut': v.statut,
                  'date': v.dateVisite,
                  'notes': v.notes,
                })
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard admin')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suivi des prospections',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        children: [
                          _StatCard(
                            label: 'Commerces',
                            value: '$_totalBusinesses',
                            color: AppColors.sky,
                          ),
                          _StatCard(
                            label: 'À recontacter',
                            value: '${_visitStats['a_recontacter'] ?? 0}',
                            color: AppColors.amber,
                          ),
                          _StatCard(
                            label: 'Acceptés',
                            value: '${_visitStats['accepte'] ?? 0}',
                            color: AppColors.mint,
                          ),
                          _StatCard(
                            label: 'Refusés',
                            value: '${_visitStats['refuse'] ?? 0}',
                            color: AppColors.rose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activités récentes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 16),
                              if (_recentVisits.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Aucune activité récente.'),
                                )
                              else
                                ...List.generate(
                                  _recentVisits.length,
                                  (index) {
                                    final visit = _recentVisits[index];
                                    final statut =
                                        (visit['statut'] ?? 'nouveau')
                                            .toString();
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: AppColors.statusColor(
                                                statut,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${visit['name']} – ${AppColors.statusLabel(statut)}',
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                if (visit['notes'] != null &&
                                                    (visit['notes'] as String)
                                                        .isNotEmpty)
                                                  Text(
                                                    visit['notes'],
                                                    style: const TextStyle(
                                                      color: Color(
                                                        0xFF475569,
                                                      ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatDate(visit['date']),
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
    }
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}
