import 'package:flutter/material.dart';
import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/notification_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/status_chip.dart';

class ProspectDetailSheet extends StatefulWidget {
  const ProspectDetailSheet({super.key, required this.commerce});

  final Commerce commerce;

  @override
  State<ProspectDetailSheet> createState() => _ProspectDetailSheetState();
}

class _ProspectDetailSheetState extends State<ProspectDetailSheet> {
  late String _status;
  late final TextEditingController _notesController;
  DateTime? _rappelDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.commerce.statut;
    _notesController = TextEditingController(text: widget.commerce.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRappelDate() async {
    final now = DateTime.now();
    final initial = _rappelDate ?? now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Choisir la date de relance',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (picked == null) return;

    final time = TimeOfDay(
      hour: _rappelDate?.hour ?? 9,
      minute: _rappelDate?.minute ?? 0,
    );
    setState(() {
      _rappelDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final notes = _notesController.text.trim();
    final isReminderStatus = _status == 'a_recontacter';

    final statusChanged = _status != widget.commerce.statut;
    final notesChanged = notes != (widget.commerce.notes ?? '');

    var ok = true;

    if (statusChanged && isReminderStatus) {
      ok = await CommerceService.createVisit(
        commerceId: widget.commerce.id,
        statut: _status,
        dateVisite: DateTime.now(),
        dateRappel: _rappelDate,
        notes: notes,
      );
      if (ok && _rappelDate != null) {
        await AppNotificationService.showReminderNotification(
          title: 'Relance ${widget.commerce.nom}',
          body:
              '${AppColors.statusLabel(_status)} — pense à recontacter ce prospect.',
          when: _rappelDate!,
        );
      }
    } else if (statusChanged) {
      ok = await CommerceService.updateCommerceStatus(
        commerceId: widget.commerce.id,
        statut: _status,
      );
    }

    if (notesChanged) {
      final notesOk = await CommerceService.updateCommerceNotes(
        commerceId: widget.commerce.id,
        notes: notes.isEmpty ? null : notes,
      );
      ok = ok && notesOk;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Prospect mis à jour.' : 'Erreur lors de la mise à jour.',
        ),
      ),
    );
    Navigator.pop(context, ok);
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
    final commerce = widget.commerce;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commerce.nom,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (commerce.adresse != null && commerce.adresse!.isNotEmpty)
              Text(
                commerce.adresse!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 14),
            if (commerce.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  commerce.photoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 18),
            Text('Statut', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final statut in kStatuts)
                  StatusChip(
                    label: statut,
                    selected: _status == statut,
                    onTap: () => setState(() => _status = statut),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes sur le prospect',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_status == 'a_recontacter') ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickRappelDate,
                icon: const Icon(Icons.alarm_add_rounded),
                label: Text(
                  _rappelDate == null
                      ? 'Programmer une relance (alarme)'
                      : 'Relance prévue le ${_formatDate(_rappelDate!)} — modifier',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (_rappelDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    'Une notification locale sonnera à cette date.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Enregistrer les modifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}