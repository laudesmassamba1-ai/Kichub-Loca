import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/geo_service.dart';
import 'package:kichub_loca/core/services/location_service.dart';
import 'package:kichub_loca/core/services/storage_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';
import 'package:kichub_loca/core/widgets/status_chip.dart';

class NewBusinessScreen extends StatefulWidget {
  const NewBusinessScreen({super.key});

  @override
  State<NewBusinessScreen> createState() => _NewBusinessScreenState();
}

class _NewBusinessScreenState extends State<NewBusinessScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  Position? _currentPosition;
  String _status = 'nouveau';
  bool _isLoading = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    final position = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  Future<void> _useCurrentPosition() async {
    if (_isGeocoding) return;
    setState(() => _isGeocoding = true);

    var position = _currentPosition;
    position ??= await LocationService.getCurrentPosition();
    if (position == null || !mounted) {
      if (mounted) {
        setState(() => _isGeocoding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS indisponible.')),
        );
      }
      return;
    }

    setState(() => _currentPosition = position);

    final address = await GeoService.reverseGeocode(
      lat: position.latitude,
      lng: position.longitude,
    );

    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      if (address != null && address.isNotEmpty) {
        _addressController.text = address;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          address == null
              ? 'Position GPS utilisée (adresse introuvable).'
              : 'Adresse récupérée depuis la position GPS.',
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

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du commerce est requis.')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS requis. Attente de la position...'),
        ),
      );
      await _loadPosition();
      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer la position GPS.'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await StorageService.uploadCommercePhoto(
          file: _pickedImage!,
        );
      }

      final notes = _notesController.text.trim();
      final createdId = await CommerceService.createCommerce(
        name: _nameController.text.trim(),
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        adresse: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        statut: _status,
        photoUrl: photoUrl,
      );

      if (createdId != null && _status != 'nouveau') {
        await CommerceService.createVisit(
          commerceId: createdId,
          statut: _status,
          dateVisite: DateTime.now(),
          notes: notes.isEmpty ? null : notes,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdId != null
                ? 'Prospect créé avec statut « ${AppColors.statusLabel(_status)} ».'
                : 'Hors ligne : prospect enregistré localement, sync automatique au retour du réseau.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau prospect')),
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
                      Text(
                        'Informations du prospect',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: const Icon(Icons.place_outlined),
                          suffixIcon: IconButton(
                            onPressed: _useCurrentPosition,
                            icon: _isGeocoding
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            tooltip: 'Utiliser la position GPS actuelle',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isGeocoding ? null : _useCurrentPosition,
                        icon: const Icon(Icons.location_on_rounded, size: 18),
                        label: Text(
                          _isGeocoding
                              ? 'Récupération...'
                              : 'Récupérer la localisation actuelle (GPS)',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes sur le prospect',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Statut direct',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final statut in kStatuts)
                            StatusChip(
                              label: statut,
                              selected: _status == statut,
                              onTap: () =>
                                  setState(() => _status = statut),
                            ),
                        ],
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
                        'Photo du prospect',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      if (_pickedImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _pickedImageBytes!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 40),
                          ),
                        ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(
                          kIsWeb
                              ? 'Choisir une photo'
                              : 'Capturer une photo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isLoading ? 'Création...' : 'Enregistrer le prospect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}