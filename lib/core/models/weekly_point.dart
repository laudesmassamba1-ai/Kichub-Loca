class WeeklyPoint {
  const WeeklyPoint({required this.semaine, required this.total});

  final String semaine;
  final int total;

  factory WeeklyPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyPoint(
      semaine: (json['semaine'] ?? '').toString(),
      total: (json['total'] ?? 0).toInt(),
    );
  }
}