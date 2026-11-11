import 'dart:developer';
import 'dart:async';
import 'package:dio/dio.dart';
import '../models/match_state.dart';
import '../models/league_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FootballService {
  final Dio _dio = Dio();
  String? _apiKey;
  Timer? _pollingTimer;

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

  Future<void> _initApiKey() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();
      if (!docSnap.exists) {
        log('[FootballService] ⚠️ Documento settings/general NÃO EXISTE no Firestore!');
        return;
      }
      final data = docSnap.data()!;
      final keys = data['api_keys'] as Map<String, dynamic>? ?? {};

      _apiKey = keys['api_football']?.toString() ??
          data['api_football_key']?.toString() ??
          data['api_football']?.toString();

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        _dio.options.headers = {'x-apisports-key': _apiKey!};
        log('[FootballService] ✅ API-Football key carregada (${_apiKey!.length} chars)');
      } else {
        log('[FootballService] ❌ Key api_football ausente ou vazia no Firestore!');
      }
    } catch (e) {
      log('[FootballService] 💥 Erro ao carregar config da API: $e');
    }
  }

  Future<List<LeagueInfo>> getPopularLeagues() async {
    await _initApiKey();
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

  // Busca as ligas que tem jogos hoje via API-Football
  Future<List<LeagueInfo>> getActiveLeaguesForToday() async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) {
      log('[FootballService] ⚠️ getActiveLeaguesForToday: sem API key.');
      return [];
    }

    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {'date': dateStr, 'timezone': 'America/Sao_Paulo'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response'] != null) {
          final Set<int> uniqueIds = {};
          final List<LeagueInfo> leagues = [];
          for (var match in data['response']) {
            final leagueData = match['league'];
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
      }
      return [];
    } catch (e) {
      log('Erro ao buscar ligas ativas (API-Football): $e');
      return [];
    }
  }

  // Busca os jogos de hoje para uma liga específica
  Future<List<dynamic>> getMatchesForLeague(int leagueId, {int? season}) async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

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

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {
          'league': leagueId,
          'season': resolvedSeason,
          'date': dateStr,
          'timezone': 'America/Sao_Paulo',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response'] != null) {
          return data['response'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      log('Erro ao buscar jogos da liga (API-Football): $e');
      return [];
    }
  }

  // --- FEATURED MATCHES ---
  Future<List<dynamic>> getFeaturedMatchesForToday() async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {'date': dateStr, 'timezone': 'America/Sao_Paulo'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response'] != null) {
          final popular = await getPopularLeagues();
          final popularIds = popular.map((l) => l.id).toSet();

          final matches = data['response'] as List<dynamic>;
          final mainMatches = matches
              .where((m) => popularIds.contains(_toInt(m['league']?['id'])))
              .toList();

          // Priority: Live matches first
          mainMatches.sort((a, b) {
            final sA = a['fixture']['status']['short'];
            final sB = b['fixture']['status']['short'];
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
      }
      return [];
    } catch (e) {
      log('Erro ao buscar destaques (API-Football): $e');
      return [];
    }
  }

  // Polling para partida ao vivo
  Future<void> startPollingLiveMatch(int fixtureId) async {
    stopPolling();
    await _initApiKey();

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
    if (_apiKey == null || _apiKey!.isEmpty) {
      log('[FootballService] ⚠️ _fetchFixtureStatus: sem API key.');
      _matchStreamController.add(
        MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''),
      );
      return;
    }

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {'id': fixtureId, 'timezone': 'America/Sao_Paulo'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response'] != null && data['response'].isNotEmpty) {
          final fixtureData = data['response'][0];

          final String status =
              fixtureData['fixture']['status']['short'] ?? 'NS';
          final int elapsed = fixtureData['fixture']['status']['elapsed'] ?? 0;
          final int homeScore = fixtureData['goals']['home'] ?? 0;
          final int awayScore = fixtureData['goals']['away'] ?? 0;

          final String homeTeam = fixtureData['teams']['home']['name'];
          final String awayTeam = fixtureData['teams']['away']['name'];

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
