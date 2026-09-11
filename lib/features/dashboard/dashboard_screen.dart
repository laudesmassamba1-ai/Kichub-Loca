import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/agent_summary.dart';
import 'package:kichub_loca/core/models/dashboard_stats.dart';
import 'package:kichub_loca/core/models/weekly_point.dart';
import 'package:kichub_loca/core/services/stats_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  DashboardStats? _stats;
  List<WeeklyPoint> _weekly = const [];
  List<AgentSummary> _agents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        StatsService.fetchDashboardStats(),
        StatsService.fetchWeeklySeries(),
        StatsService.fetchAgentsSummary(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats?;
        _weekly = results[1] as List<WeeklyPoint>;
        _agents = results[2] as List<AgentSummary>;
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
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null)
                      _buildError()
                    else ...[
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildStatCards(),
                      const SizedBox(height: 20),
                      _buildPieCard(),
                      const SizedBox(height: 20),
                      _buildWeeklyCard(),
                      const SizedBox(height: 20),
                      _buildAgentsCard(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.rose),
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

  Widget _buildHeader() {
    final stats = _stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6DFF), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Synthèse terrain de toute l\'équipe',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeaderStat(
                label: 'Prospects',
                value: '${stats?.totalCommerces ?? 0}',
              ),
              _HeaderStat(
                label: 'Visites',
                value: '${stats?.totalVisites ?? 0}',
              ),
              _HeaderStat(label: 'Agents', value: '${stats?.totalAgents ?? 0}'),
              _HeaderStat(
                label: '7 derniers j',
                value: '${stats?.visites7j ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final stats = _stats;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          label: 'Acceptés',
          value: '${stats?.accepte ?? 0}',
          color: AppColors.mint,
        ),
        _StatCard(
          label: 'À recontacter',
          value: '${stats?.aRecontacter ?? 0}',
          color: AppColors.amber,
        ),
        _StatCard(
          label: 'Refusés',
          value: '${stats?.refuse ?? 0}',
          color: AppColors.rose,
        ),
        _StatCard(
          label: 'Nouveaux',
          value: '${stats?.nouveau ?? 0}',
          color: AppColors.sky,
        ),
      ],
    );
  }

  Widget _buildPieCard() {
    final sections = _pieSections();
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Répartition des prospects (par statut)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: sections
                  .map((s) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(s.title, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections() {
    final stats = _stats;
    if (stats == null) return const [];

    final data = [
      (label: 'Nouveaux', value: stats.nouveau, color: AppColors.sky),
      (label: 'Acceptés', value: stats.accepte, color: AppColors.mint),
      (label: 'Refusés', value: stats.refuse, color: AppColors.rose),
      (
        label: 'À recontacter',
        value: stats.aRecontacter,
        color: AppColors.amber,
      ),
    ].where((d) => d.value > 0).toList();

    if (data.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'Aucune visite',
          color: Colors.grey.shade300,
          radius: 90,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ];
    }

    return data
        .map((d) => PieChartSectionData(
              value: d.value.toDouble(),
              title: '${d.value}',
              color: d.color,
              radius: 90,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ))
        .toList();
  }

  Widget _buildWeeklyCard() {
    final points = _weekly;
    final maxTotal = points.fold<int>(
      1,
      (max, p) => p.total > max ? p.total : max,
    );

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patrouilles par semaine',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Historique des visites sur ${points.length} semaines',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Aucune donnée de patrouille.'),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxTotal * 1.2).clamp(1, double.infinity),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                points[index].semaine,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(
                      drawVerticalLine: false,
                      drawHorizontalLine: true,
                    ),
                    barGroups: [
                      for (var i = 0; i < points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: points[i].total.toDouble(),
                              color: i == points.length - 1
                                  ? AppColors.violet
                                  : AppColors.sky,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsCard() {
    final agents = _agents;
    final maxScore =
        agents.fold<int>(0, (max, a) => a.score > max ? a.score : max);
    final top = agents.take(5).toList();

    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top agents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Classement par score', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (top.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Aucun agent pour le moment.'),
              )
            else
              ...List.generate(top.length, (index) {
                final agent = top[index];
                final ratio =
                    maxScore <= 0 ? 0.0 : agent.score / maxScore;
                final color = agent.score >= 60
                    ? AppColors.mint
                    : agent.score >= 25
                        ? AppColors.amber
                        : AppColors.sky;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${agent.nom}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${agent.score} pts · ${agent.visitesSemaine}/sem.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.03, 1.0),
                          minHeight: 8,
                          backgroundColor:
                              Colors.grey.withValues(alpha: 0.2),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}