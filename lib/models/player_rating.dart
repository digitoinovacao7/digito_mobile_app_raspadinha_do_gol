class PlayerRating {
  final String id; // Firestore doc ID (ex: "player_9")
  final String name;
  final String position;
  final int shirtNumber;
  final double ratingSum;
  final int ratingCount;

  PlayerRating({
    required this.id,
    required this.name,
    required this.position,
    required this.shirtNumber,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get avgRating =>
      ratingCount == 0 ? 0.0 : (ratingSum / ratingCount).clamp(1.0, 10.0);

  factory PlayerRating.fromMap(Map<String, dynamic> map, String id) {
    return PlayerRating(
      id: id,
      name: map['name'] ?? 'Jogador',
      position: map['position'] ?? '?',
      shirtNumber: (map['shirtNumber'] as num?)?.toInt() ?? 0,
      ratingSum: (map['ratingSum'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'shirtNumber': shirtNumber,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
    };
  }
}
