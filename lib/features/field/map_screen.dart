import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kichub_loca/core/models/commerce.dart';
import 'package:kichub_loca/core/models/passage.dart';
import 'package:kichub_loca/core/services/commerce_service.dart';
import 'package:kichub_loca/core/services/location_service.dart';
import 'package:kichub_loca/core/services/passage_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Commerce> _businesses = [];
  List<Passage> _passages = [];
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _isSavingPassage = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
    }

    try {
      final businesses = await CommerceService.fetchAllBusinesses();
      final passages = await PassageService.fetchAllPassages();
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _passages = passages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    final passages = await PassageService.fetchAllPassages();
    if (mounted) {
      setState(() => _passages = passages);
    }
  }

  Future<void> _addPassageAt(LatLng point, {String? suggestedNom}) async {
    final saved = await showDialog<({String nom, String? note})>(
      context: context,
      builder: (context) => _PassageDialog(
        suggestedNom: suggestedNom,
        point: point,
      ),
    );

    if (saved == null || !mounted) return;

    setState(() => _isSavingPassage = true);
    final ok = await PassageService.createPassage(
      nom: saved.nom,
      lat: point.latitude,
      lng: point.longitude,
      note: saved.note,
    );
    if (!mounted) return;
    setState(() => _isSavingPassage = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Passage enregistré.'
            : 'Hors ligne : passage mis en file d\'attente.'),
      ),
    );
    await _refresh();
  }

  Future<void> _deletePassage(Passage passage) async {
    final ok = await PassageService.deletePassage(passage.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passage supprimé.')),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation ?? const LatLng(6.3654, 2.4231);
    final userId = SupabaseService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte terrain'),
        actions: [
          if (_currentLocation != null)
            IconButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 16);
              },
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'Ma position',
            ),
          if (_currentLocation != null)
            IconButton(
              onPressed: _isSavingPassage
                  ? null
                  : () => _addPassageAt(_currentLocation!),
              icon: _isSavingPassage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_rounded),
              tooltip: 'Marquer ma position',
            ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    onLongPress: (tap, point) => _addPassageAt(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.kichub.kichub_loca',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        for (final business in _businesses)
                          Marker(
                            point: LatLng(
                              business.latitude,
                              business.longitude,
                            ),
                            width: 36,
                            height: 36,
                            child: Tooltip(
                              message: business.nom,
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.red,
                                size: 36,
                              ),
                            ),
                          ),
                        for (final passage in _passages)
                          Marker(
                            point: LatLng(
                              passage.latitude,
                              passage.longitude,
                            ),
                            width: 32,
                            height: 32,
                            child: Tooltip(
                              message:
                                  '${passage.nom} — ${passage.agentNom ?? 'agent'}',
                              child: GestureDetector(
                                onTap: () {
                                  _mapController.move(
                                    LatLng(
                                      passage.latitude,
                                      passage.longitude,
                                    ),
                                    17,
                                  );
                                },
                                child: Icon(
                                  Icons.flag_circle_rounded,
                                  color: passage.agentId == userId
                                      ? AppColors.violet
                                      : AppColors.amber,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Legend(),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _PassagePanel(
                    passages: _passages,
                    currentUserId: userId,
                    onCenter: (p) => _mapController.move(
                      LatLng(p.latitude, p.longitude),
                      17,
                    ),
                    onDelete: _deletePassage,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row(icon: Icons.person_pin_circle_rounded, color: Colors.blue, label: 'Vous'),
              _Row(icon: Icons.storefront_rounded, color: Colors.red, label: 'Commerces'),
              _Row(icon: Icons.flag_circle_rounded, color: AppColors.violet, label: 'Mes passages'),
              _Row(icon: Icons.flag_circle_rounded, color: AppColors.amber, label: 'Passages équipe'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PassagePanel extends StatelessWidget {
  const _PassagePanel({
    required this.passages,
    required this.currentUserId,
    required this.onCenter,
    required this.onDelete,
  });

  final List<Passage> passages;
  final String? currentUserId;
  final ValueChanged<Passage> onCenter;
  final ValueChanged<Passage> onDelete;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
              child: Row(
                children: [
                  Text(
                    'Passages  (${passages.length})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  const Text(
                    'Appui long sur la carte pour ajouter · Taper un drapeau pour zoomer',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: passages.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aucun passage enregistré.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: passages.length,
                      itemBuilder: (context, index) {
                        final passage = passages[index];
                        final isMine = passage.agentId == currentUserId;
                        final time = passage.datePassage == null
                            ? ''
                            : _formatTime(passage.datePassage!);

                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.flag_rounded,
                            color: isMine ? AppColors.violet : AppColors.amber,
                          ),
                          title: Text(
                            passage.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              passage.agentNom ?? 'agent',
                              time,
                              if (passage.note != null &&
                                  passage.note!.isNotEmpty)
                                passage.note!,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isMine
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () => onDelete(passage),
                                  tooltip: 'Supprimer',
                                )
                              : null,
                          onTap: () => onCenter(passage),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return 'aujourd\'hui $hh:$mm';
  }
}

class _PassageDialog extends StatefulWidget {
  const _PassageDialog({required this.point, this.suggestedNom});

  final LatLng point;
  final String? suggestedNom;

  @override
  State<_PassageDialog> createState() => _PassageDialogState();
}

class _PassageDialogState extends State<_PassageDialog> {
  late final TextEditingController _nomController = TextEditingController(
    text: widget.suggestedNom ?? 'Passage',
  );
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marquer un passage'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lat ${widget.point.latitude.toStringAsFixed(5)}, '
              'Lng ${widget.point.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nomController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom du lieu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final nom = _nomController.text.trim();
            Navigator.pop(
              context,
              (
                nom: nom.isEmpty ? 'Passage' : nom,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}