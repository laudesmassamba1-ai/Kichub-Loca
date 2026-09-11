class DashboardStats {
  const DashboardStats({
    required this.totalCommerces,
    required this.totalVisites,
    required this.totalAgents,
    required this.nouveau,
    required this.accepte,
    required this.refuse,
    required this.aRecontacter,
    required this.visites7j,
  });

  final int totalCommerces;
  final int totalVisites;
  final int totalAgents;
  final int nouveau;
  final int accepte;
  final int refuse;
  final int aRecontacter;
  final int visites7j;

  int get totalGender =>
      accepte + refuse + aRecontacter;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCommerces: (json['total_commerces'] ?? 0).toInt(),
      totalVisites: (json['total_visites'] ?? 0).toInt(),
      totalAgents: (json['total_agents'] ?? 0).toInt(),
      nouveau: (json['nouveau'] ?? 0).toInt(),
      accepte: (json['accepte'] ?? 0).toInt(),
      refuse: (json['refuse'] ?? 0).toInt(),
      aRecontacter: (json['a_recontacter'] ?? 0).toInt(),
      visites7j: (json['visites_7j'] ?? 0).toInt(),
    );
  }
}