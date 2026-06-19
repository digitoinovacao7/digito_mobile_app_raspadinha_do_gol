class ArquibancadaRoom {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;
  final String status; // 'live' | 'finished'
  final int sentimentScore; // 0-100
  final int applauseCount;
  final int booCount;
  final int participantsCount;

  ArquibancadaRoom({
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
    this.status = 'live',
    this.sentimentScore = 50,
    this.applauseCount = 0,
    this.booCount = 0,
    this.participantsCount = 0,
  });

  factory ArquibancadaRoom.fromMap(Map<String, dynamic> map, int fixtureId) {
    final sentiment = map['sentiment'] as Map<String, dynamic>? ?? {};
    return ArquibancadaRoom(
      fixtureId: fixtureId,
      homeTeam: map['homeTeam'] ?? '',
      awayTeam: map['awayTeam'] ?? '',
      status: map['status'] ?? 'live',
      sentimentScore: (sentiment['score'] as num?)?.toInt() ?? 50,
      applauseCount: (sentiment['applause'] as num?)?.toInt() ?? 0,
      booCount: (sentiment['boo'] as num?)?.toInt() ?? 0,
      participantsCount: (map['participantsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'status': status,
      'sentiment': {
        'score': sentimentScore,
        'applause': applauseCount,
        'boo': booCount,
      },
      'participantsCount': participantsCount,
    };
  }
}
