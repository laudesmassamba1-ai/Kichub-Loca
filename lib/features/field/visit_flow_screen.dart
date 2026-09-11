import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/storage_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';
import 'package:kichub_loca/core/widgets/status_chip.dart';

class VisitFlowScreen extends StatefulWidget {
  const VisitFlowScreen({super.key, required this.nearbyBusiness});

  final Map<String, dynamic> nearbyBusiness;

  @override
  State<VisitFlowScreen> createState() => _VisitFlowScreenState();
}

class _VisitFlowScreenState extends State<VisitFlowScreen> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String _status = 'nouveau';
  DateTime? _rappelDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.nearbyBusiness;
    final name = business['nom'] ?? 'Commerce';
    final distance = business['distance_m'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Qualifier la visite')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'À ${distance.toStringAsFixed(0)} m',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
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
                      if (_status == 'a_recontacter')
                        InkWell(
                          onTap: _pickReminderDate,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _rappelDate == null
                                        ? 'Choisir une date de rappel'
                                        : 'Rappel: ${_rappelDate!.day}/${_rappelDate!.month}/${_rappelDate!.year}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Notes / observations',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LiquidGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo de la boutique',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_pickedImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _pickedImageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 42),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Prendre une photo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitVisit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Enregistrement...'
                        : 'Enregistrer la visite',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source =
        kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() => _rappelDate = date);
    }
  }

  Future<void> _submitVisit() async {
    if (_status == 'a_recontacter' && _rappelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une date de rappel est obligatoire pour "À recontacter".',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await StorageService.uploadCommercePhoto(
          file: _pickedImage!,
        );
      }

      final businessId = widget.nearbyBusiness['id'] as String;
      final ordered = await CommerceService.createVisit(
        commerceId: businessId,
        statut: _status,
        dateVisite: DateTime.now(),
        dateRappel: _rappelDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (photoUrl != null) {
        await CommerceService.updateCommercePhoto(
          commerceId: businessId,
          photoUrl: photoUrl,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ordered
                ? 'Visite enregistrée avec succès.'
                : 'Hors ligne : visite enregistrée localement, sync automatique au retour du réseau.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
