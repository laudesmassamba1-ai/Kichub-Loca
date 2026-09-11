import 'package:flutter/material.dart';
import 'package:kichub_loca/core/services/profile_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final summary = await ProfileService.fetchProfileSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'agent@kichub.local';
    final name = _summary?['nom'] ??
        user?.userMetadata?['nom'] ??
        'Agent Kichub';
    final role = (_summary?['role'] ?? 'agent').toString();
    final totalCommerces = _summary?['total_commerces'] ?? 0;
    final totalVisits = _summary?['total_visites'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    LiquidGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.sky.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 42,
                                color: AppColors.sky,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name.toString(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LiquidGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistiques',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  value: totalCommerces.toString(),
                                  label: 'Commerces',
                                  color: AppColors.sky,
                                ),
                                _StatItem(
                                  value: totalVisits.toString(),
                                  label: 'Visites',
                                  color: AppColors.mint,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LiquidGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations du compte',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              label: 'Rôle',
                              value: role == 'admin' ? 'Administrateur' : 'Agent terrain',
                            ),
                            _InfoRow(label: 'Statut', value: 'Actif'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await SupabaseService.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Se déconnecter'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.rose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
