enum MatchEventType { none, goal, halftime, fulltime }

class MatchState {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String status; // e.g. "1H", "HT", "2H", "FT"
  final int elapsed; // minutes played
  final MatchEventType lastTriggeredEvent;
  final bool isScratchUnlocked;

  MatchState({
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.status = "NS",
    this.elapsed = 0,
    this.lastTriggeredEvent = MatchEventType.none,
    this.isScratchUnlocked = false,
  });

  MatchState copyWith({
    int? fixtureId,
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
    String? status,
    int? elapsed,
    MatchEventType? lastTriggeredEvent,
    bool? isScratchUnlocked,
  }) {
    return MatchState(
      fixtureId: fixtureId ?? this.fixtureId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      lastTriggeredEvent: lastTriggeredEvent ?? this.lastTriggeredEvent,
      isScratchUnlocked: isScratchUnlocked ?? this.isScratchUnlocked,
    );
  }
}
