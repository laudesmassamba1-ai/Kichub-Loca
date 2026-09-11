class Visit {
  const Visit({
    required this.id,
    required this.commerceId,
    required this.agentId,
    required this.statut,
    required this.dateVisite,
    this.commerceName,
    this.dateRappel,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String commerceId;
  final String agentId;
  final String statut;
  final DateTime dateVisite;
  final String? commerceName;
  final DateTime? dateRappel;
  final String? notes;
  final DateTime? createdAt;

  bool get isReminder => statut == 'a_recontacter' || dateRappel != null;

  factory Visit.fromJson(Map<String, dynamic> json) {
    String? commerceName;
    if (json['commerce_name'] != null) {
      commerceName = json['commerce_name'].toString();
    } else {
      final commerce = json['commerces'];
      if (commerce is Map) {
        commerceName = commerce['nom']?.toString();
      }
    }

    return Visit(
      id: json['id'] as String,
      commerceId: json['commerce_id'] as String,
      agentId: json['agent_id'] as String,
      statut: (json['statut'] ?? 'nouveau').toString(),
      commerceName: commerceName,
      dateVisite:
          DateTime.tryParse(json['date_visite'].toString()) ?? DateTime.now(),
      dateRappel: json['date_rappel'] == null
          ? null
          : DateTime.tryParse(json['date_rappel'].toString()),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'commerce_id': commerceId,
      'agent_id': agentId,
      'statut': statut,
      'date_visite': dateVisite.toUtc().toIso8601String(),
      'date_rappel': dateRappel?.toUtc().toIso8601String(),
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    final json = toInsertJson();
    json['id'] = id;
    json['commerce_name'] = commerceName;
    return json;
  }
}
