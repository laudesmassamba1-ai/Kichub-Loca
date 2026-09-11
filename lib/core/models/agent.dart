class Agent {
  const Agent({
    required this.id,
    required this.nom,
    required this.email,
    this.dateCreation,
  });

  final String id;
  final String nom;
  final String email;
  final DateTime? dateCreation;

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      nom: (json['nom'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      dateCreation: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'created_at': dateCreation?.toIso8601String(),
    };
  }
}