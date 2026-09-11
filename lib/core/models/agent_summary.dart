class AgentSummary {
  const AgentSummary({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.totalCommerces,
    required this.totalVisites,
    required this.acceptes,
    required this.refuses,
    required this.aRecontacter,
    required this.visitesSemaine,
    required this.score,
  });

  final String id;
  final String nom;
  final String email;
  final String role;
  final int totalCommerces;
  final int totalVisites;
  final int acceptes;
  final int refuses;
  final int aRecontacter;
  final int visitesSemaine;
  final int score;

  factory AgentSummary.fromJson(Map<String, dynamic> json) {
    return AgentSummary(
      id: json['id'] as String,
      nom: (json['nom'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'agent').toString(),
      totalCommerces: (json['total_commerces'] ?? 0).toInt(),
      totalVisites: (json['total_visites'] ?? 0).toInt(),
      acceptes: (json['acceptes'] ?? 0).toInt(),
      refuses: (json['refuses'] ?? 0).toInt(),
      aRecontacter: (json['a_recontacter'] ?? 0).toInt(),
      visitesSemaine: (json['visites_semaine'] ?? 0).toInt(),
      score: (json['score'] ?? 0).toInt(),
    );
  }
}