import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/agent_summary.dart';
import 'package:kichub_loca/core/services/stats_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class AgentDirectoryScreen extends StatefulWidget {
  const AgentDirectoryScreen({super.key});

  @override
  State<AgentDirectoryScreen> createState() => _AgentDirectoryScreenState();
}

class _AgentDirectoryScreenState extends State<AgentDirectoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<AgentSummary> _agents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final agents = await StatsService.fetchAgentsSummary();
      if (!mounted) return;
      setState(() {
        _agents = agents;
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
      appBar: AppBar(title: const Text('Équipe terrain')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Classement des agents',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scores basés sur les visites qualifiées, patrouilles et commerciaux. ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      _ErrorState(message: _error!, onRetry: _load)
                    else if (_agents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aucun agent enregistré.'),
                        ),
                      )
                    else
                      ...List.generate(
                        _agents.length,
                        (index) => _AgentCard(
                          agent: _agents[index],
                          rank: index + 1,
                          maxScore: _agents.first.score,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.rank,
    required this.maxScore,
  });

  final AgentSummary agent;
  final int rank;
  final int maxScore;

  Color get _scoreColor {
    if (agent.score >= 60) return AppColors.mint;
    if (agent.score >= 25) return AppColors.amber;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore <= 0 ? 0.0 : agent.score / maxScore;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LiquidGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _scoreColor.withValues(alpha: 0.18),
                    child: Text(
                      agent.nom.isEmpty
                          ? '?'
                          : agent.nom[0].toUpperCase(),
                      style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.nom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          agent.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.03, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: _scoreColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(
                    icon: Icons.emoji_events_rounded,
                    value: '${agent.score}',
                    label: 'Score',
                    color: _scoreColor,
                  ),
                  _MiniStat(
                    icon: Icons.storefront_rounded,
                    value: '${agent.totalCommerces}',
                    label: 'Prospects',
                    color: AppColors.sky,
                  ),
                  _MiniStat(
                    icon: Icons.assignment_turned_in_rounded,
                    value: '${agent.totalVisites}',
                    label: 'Visites',
                    color: AppColors.violet,
                  ),
                  _MiniStat(
                    icon: Icons.speed_rounded,
                    value: '${agent.visitesSemaine}',
                    label: 'Cette sem.',
                    color: AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '✓ ${agent.acceptes} acceptés · ✗ ${agent.refuses} refusés · ⏳ ${agent.aRecontacter} à recontacter',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 52, color: AppColors.rose),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}