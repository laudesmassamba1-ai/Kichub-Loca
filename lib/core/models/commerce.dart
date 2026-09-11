class Commerce {
  const Commerce({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.description,
    this.adresse,
    this.notes,
    this.statut = 'nouveau',
    this.photoUrl,
    this.creePar,
    this.dateCreation,
    this.distanceMeters,
  });

  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final String? description;
  final String? adresse;
  final String? notes;
  final String statut;
  final String? photoUrl;
  final String? creePar;
  final DateTime? dateCreation;
  final double? distanceMeters;

  factory Commerce.fromJson(Map<String, dynamic> json) {
    double latitude = 0;
    double longitude = 0;

    if (json['latitude'] != null) {
      latitude = double.tryParse(json['latitude'].toString()) ?? 0;
      longitude = double.tryParse(json['longitude'].toString()) ?? 0;
    }

    final position = json['position'];
    if (position is String && latitude == 0) {
      final cleaned = position
          .replaceAll('POINT(', '')
          .replaceAll(')', '');
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

    return Commerce(
      id: json['id'] as String,
      nom: (json['nom'] ?? '').toString(),
      latitude: latitude,
      longitude: longitude,
      description: json['description'] as String?,
      adresse: json['adresse'] as String?,
      notes: json['notes'] as String?,
      statut: (json['statut'] ?? 'nouveau').toString(),
      photoUrl: json['photo_url'] as String?,
      creePar: json['cree_par'] as String?,
      dateCreation: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      distanceMeters: json['distance_m'] == null
          ? null
          : double.tryParse(json['distance_m'].toString()),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'nom': nom,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'adresse': adresse,
      'notes': notes,
      'statut': statut,
      'photo_url': photoUrl,
      'cree_par': creePar,
    };
  }

  Map<String, dynamic> toJson() {
    final json = toInsertJson();
    json['id'] = id;
    json['distance_m'] = distanceMeters;
    return json;
  }
}
