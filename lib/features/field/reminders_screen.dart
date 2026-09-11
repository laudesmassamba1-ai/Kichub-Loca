import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/models/visit.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';
import 'package:kichub_loca/core/widgets/prospect_detail_sheet.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _isLoading = true;
  String? _error;
  final List<Visit> _reminders = [];
  final Map<String, Commerce> _communes = {};

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final visitList = await CommerceService.fetchMyVisits();
      final filtered = visitList.where((v) => v.isReminder).toList();
      filtered.sort(_compareReminders);

      final allBusinesses = await CommerceService.fetchAllBusinesses();
      final byId = {for (final b in allBusinesses) b.id: b};

      if (!mounted) return;
      setState(() {
        _reminders
          ..clear()
          ..addAll(filtered);
        _communes
          ..clear()
          ..addAll(byId);
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

  int _compareReminders(Visit a, Visit b) {
    DateTime? da = a.dateRappel;
    DateTime? db = b.dateRappel;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  Future<void> _openDetail(Visit visit) async {
    final commerce = _communes[visit.commerceId];
    if (commerce == null) return;

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProspectDetailSheet(commerce: commerce),
    );
    if (changed == true) await _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels & relances')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReminders,
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
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.rose,
            ),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadReminders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Aucun rappel pour le moment.\n'
              'Passe un prospect sur « À recontacter » et programme un rappel.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadReminders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _reminders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visit = _reminders[index];
        return _ReminderCard(
          visit: visit,
          onTap: () => _openDetail(visit),
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.visit, required this.onTap});

  final Visit visit;
  final VoidCallback onTap;

  bool get _isOverdue {
    final d = visit.dateRappel;
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }

  bool get _isToday {
    final d = visit.dateRappel;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDate(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        'à $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final name = visit.commerceName ?? 'Commerce';
    final overdue = _isOverdue;
    final today = _isToday;
    final accent = overdue
        ? AppColors.rose
        : today
            ? AppColors.amber
            : AppColors.statusColor(visit.statut);

    return LiquidGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  overdue
                      ? Icons.alarm_on_rounded
                      : Icons.notifications_active_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          AppColors.statusLabel(visit.statut),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (overdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'En retard',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rose,
                              ),
                            ),
                          ),
                        ] else if (today) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Aujourd\'hui',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      visit.dateRappel == null
                          ? 'Programme une date de relance via la fiche.'
                          : 'Relance prévue: ${_formatDate(visit.dateRappel!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}