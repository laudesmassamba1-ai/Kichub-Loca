class Agent {
  const Agent({
    required this.id,
    required this.nom,
    required this.email,
    this.role = 'agent',
    this.dateCreation,
  });

  final String id;
  final String nom;
  final String email;
  final String role;
  final DateTime? dateCreation;

  bool get isAdmin => role == 'admin';

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      nom: (json['nom'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'agent').toString(),
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
      'role': role,
      'created_at': dateCreation?.toIso8601String(),
    };
  }
}
