import 'dart:developer';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/match_state.dart';
import '../models/league_info.dart';

class FootballService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');
  Timer? _pollingTimer;

  // Cache em memória de curta duração para evitar chamadas repetidas na mesma sessão/tela
  final Map<String, _CachedFixtures> _memoryCache = {};
  final Map<String, Future<List<dynamic>>> _inFlight = {};

  // Stream para emitir atualizações do jogo em tempo real
  final StreamController<MatchState> _matchStreamController =
      StreamController<MatchState>.broadcast();
  Stream<MatchState> get matchUpdates => _matchStreamController.stream;

  /// Converte qualquer valor numérico (Int64, num, String) para int Dart.
  /// Necessário no Flutter Web (dart2js) onde Int64 não é suportado diretamente.
  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  /// Nomes mais claros para o público brasileiro.
  static String _friendlyLeagueName(int id, String fallback) {
    const namesById = <int, String>{
      71: 'Brasileirão Série A',
      72: 'Brasileirão Série B',
      73: 'Copa do Brasil',
      13: 'Copa Libertadores',
      11: 'Copa Sul-Americana',
      2: 'Champions League',
      39: 'Premier League',
      140: 'La Liga',
      135: 'Serie A Italiana',
      78: 'Bundesliga',
    };
    return namesById[id] ?? fallback;
  }

  Future<List<dynamic>> _callFixturesProxy(
    Map<String, dynamic> payload, {
    Duration ttl = const Duration(seconds: 60),
  }) async {
    final sortedKeys = payload.keys.toList()..sort();
    final cacheKey = sortedKeys.map((k) => '$k=${payload[k]}').join('&');

    final cached = _memoryCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < ttl) {
      return cached.data;
    }

    final existing = _inFlight[cacheKey];
    if (existing != null) {
      return existing;
    }

    final future = () async {
      try {
        final callable = _functions.httpsCallable('getFootballFixtures');
        final result = await callable.call(payload);
        final data = result.data;
        if (data is Map && data['success'] == true && data['response'] is List) {
          final list = List<dynamic>.from(data['response'] as List);
          _memoryCache[cacheKey] = _CachedFixtures(list, DateTime.now());
          return list;
        }
        return <dynamic>[];
      } catch (e) {
        log('[FootballService] Erro ao consultar getFootballFixtures: $e');
        return <dynamic>[];
      } finally {
        _inFlight.remove(cacheKey);
      }
    }();

    _inFlight[cacheKey] = future;
    return future;
  }

  Future<List<LeagueInfo>> getPopularLeagues() async {
    final today = DateTime.now();
    int season = today.year;

    return [
      LeagueInfo(
        id: 71,
        name: 'Brasileirão Série A',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/71.png',
      ),
      LeagueInfo(
        id: 73,
        name: 'Copa do Brasil',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/73.png',
      ),
      LeagueInfo(
        id: 13,
        name: 'Copa Libertadores',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/13.png',
      ),
      LeagueInfo(
        id: 11,
        name: 'Copa Sul-Americana',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/11.png',
      ),
      LeagueInfo(
        id: 72,
        name: 'Brasileirão Série B',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/72.png',
      ),
      LeagueInfo(
        id: 2,
        name: 'Champions League',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/2.png',
      ),
      LeagueInfo(
        id: 39,
        name: 'Premier League',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/39.png',
      ),
      LeagueInfo(
        id: 140,
        name: 'La Liga',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/140.png',
      ),
      LeagueInfo(
        id: 135,
        name: 'Serie A Italiana',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/135.png',
      ),
      LeagueInfo(
        id: 78,
        name: 'Bundesliga',
        season: season,
        logoUrl: 'https://media.api-sports.io/football/leagues/78.png',
      ),
    ];
  }

  Future<List<LeagueInfo>> getCombinedLeagues() async {
    return getPopularLeagues();
  }

  Future<List<LeagueInfo>> getMainActiveLeaguesForToday() async {
    final popularLeagues = await getPopularLeagues();
    final activeLeagues = await getActiveLeaguesForToday();

    if (activeLeagues.isEmpty) return popularLeagues;

    final activeById = {for (final league in activeLeagues) league.id: league};
    return popularLeagues
        .where((league) => activeById.containsKey(league.id))
        .map((league) => activeById[league.id]!)
        .toList();
  }

  // Busca as ligas que tem jogos hoje via proxy seguro com cache
  Future<List<LeagueInfo>> getActiveLeaguesForToday() async {
    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final matches = await _callFixturesProxy({'date': dateStr});
    if (matches.isEmpty) return [];

    final Set<int> uniqueIds = {};
    final List<LeagueInfo> leagues = [];
    for (var match in matches) {
      final leagueData = match['league'];
      if (leagueData is! Map) continue;
      final leagueId = _toInt(leagueData['id']);
      if (!uniqueIds.contains(leagueId)) {
        uniqueIds.add(leagueId);
        leagues.add(
          LeagueInfo(
            id: leagueId,
            name: _friendlyLeagueName(
              leagueId,
              leagueData['name']?.toString() ?? '',
            ),
            logoUrl: leagueData['logo']?.toString(),
            season: _toInt(
              leagueData['season'],
              fallback: DateTime.now().year,
            ),
          ),
        );
      }
    }
    return leagues;
  }

  // Busca os jogos de hoje para uma liga específica
  Future<List<dynamic>> getMatchesForLeague(int leagueId, {int? season}) async {
    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    int resolvedSeason = season ?? today.year;
    if (season == null) {
      if ((leagueId == 2 || leagueId == 39 || leagueId == 140) &&
          today.month < 7) {
        resolvedSeason = today.year - 1;
      }
    }

    return _callFixturesProxy({
      'leagueId': leagueId,
      'season': resolvedSeason,
      'date': dateStr,
    });
  }

  // --- FEATURED MATCHES ---
  Future<List<dynamic>> getFeaturedMatchesForToday() async {
    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final matches = await _callFixturesProxy({'date': dateStr});
    if (matches.isEmpty) return [];

    final popular = await getPopularLeagues();
    final popularIds = popular.map((l) => l.id).toSet();

    final mainMatches = matches
        .where((m) => popularIds.contains(_toInt(m['league']?['id'])))
        .toList();

    // Priority: Live matches first
    mainMatches.sort((a, b) {
      final sA = a['fixture']?['status']?['short'];
      final sB = b['fixture']?['status']?['short'];
      final liveStatuses = ['1H', '2H', 'HT', 'ET', 'P'];
      if (liveStatuses.contains(sA) && !liveStatuses.contains(sB)) {
        return -1;
      }
      if (liveStatuses.contains(sB) && !liveStatuses.contains(sA)) {
        return 1;
      }
      return 0;
    });

    final featured = mainMatches.take(5).toList();
    for (final match in featured) {
      final league = match['league'];
      if (league is Map) {
        final leagueId = _toInt(league['id']);
        league['name'] = _friendlyLeagueName(
          leagueId,
          league['name']?.toString() ?? '',
        );
      }
    }
    return featured;
  }

  // Polling para partida ao vivo
  Future<void> startPollingLiveMatch(int fixtureId) async {
    stopPolling();

    Future<void>.delayed(Duration.zero, () async {
      await _fetchFixtureStatus(fixtureId);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _fetchFixtureStatus(fixtureId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchFixtureStatus(int fixtureId) async {
    try {
      final response = await _callFixturesProxy(
        {'fixtureId': fixtureId},
        ttl: const Duration(seconds: 20),
      );

      if (response.isNotEmpty) {
        final fixtureData = response[0];

        final String status =
            fixtureData['fixture']?['status']?['short']?.toString() ?? 'NS';
        final int elapsed = _toInt(fixtureData['fixture']?['status']?['elapsed']);
        final int homeScore = _toInt(fixtureData['goals']?['home']);
        final int awayScore = _toInt(fixtureData['goals']?['away']);

        final String homeTeam =
            fixtureData['teams']?['home']?['name']?.toString() ?? '';
        final String awayTeam =
            fixtureData['teams']?['away']?['name']?.toString() ?? '';

        MatchEventType triggerEvent = MatchEventType.none;
        if (status == 'HT') {
          triggerEvent = MatchEventType.halftime;
        } else if (status == 'FT') {
          triggerEvent = MatchEventType.fulltime;
        }

        final matchState = MatchState(
          fixtureId: fixtureId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          homeScore: homeScore,
          awayScore: awayScore,
          status: status,
          elapsed: elapsed,
          lastTriggeredEvent: triggerEvent,
          isScratchUnlocked: triggerEvent != MatchEventType.none,
        );

        _matchStreamController.add(matchState);
      } else {
        _matchStreamController.add(
          MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''),
        );
      }
    } catch (e) {
      log('Erro ao buscar status do jogo (API-Football): $e');
      _matchStreamController.add(
        MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''),
      );
    }
  }

  void dispose() {
    stopPolling();
    _matchStreamController.close();
  }
}

class _CachedFixtures {
  final List<dynamic> data;
  final DateTime fetchedAt;
  _CachedFixtures(this.data, this.fetchedAt);
}
