class Passage {
  const Passage({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.agentId,
    this.agentNom,
    this.note,
    this.datePassage,
  });

  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final String? agentId;
  final String? agentNom;
  final String? note;
  final DateTime? datePassage;

  factory Passage.fromJson(Map<String, dynamic> json) {
    double latitude = 0;
    double longitude = 0;

    if (json['latitude'] != null) {
      latitude = double.tryParse(json['latitude'].toString()) ?? 0;
      longitude = double.tryParse(json['longitude'].toString()) ?? 0;
    }

    final position = json['position'];
    if (position is String && latitude == 0) {
      final cleaned = position.replaceAll('POINT(', '').replaceAll(')', '');
      final parts = cleaned.split(' ');
      if (parts.length >= 2) {
        longitude = double.tryParse(parts[0]) ?? 0;
        latitude = double.tryParse(parts[1]) ?? 0;
      }
    } else if (position is Map && latitude == 0) {
      latitude =
          double.tryParse((position['lat'] ?? position['y'] ?? 0).toString()) ??
              0;
      longitude =
          double.tryParse((position['lng'] ?? position['x'] ?? 0).toString()) ??
              0;
    }

    final agent = json['agent'];
    String? agentNom;
    if (agent is Map) {
      agentNom = (agent['nom'] ?? '').toString();
      if (agentNom.isEmpty) agentNom = null;
    }

    return Passage(
      id: json['id'] as String,
      nom: (json['nom'] ?? 'Passage').toString(),
      latitude: latitude,
      longitude: longitude,
      agentId: json['agent_id'] as String?,
      agentNom: agentNom,
      note: json['note'] as String?,
      datePassage: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'nom': nom,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': datePassage?.toIso8601String(),
    };
  }
}