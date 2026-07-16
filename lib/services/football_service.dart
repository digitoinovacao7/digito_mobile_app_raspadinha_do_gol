import 'dart:developer';
import 'dart:async';
import 'package:dio/dio.dart';
import '../models/match_state.dart';
import '../models/league_info.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FootballService {
  final Dio _dio = Dio();
  String? _apiKey;
  String _activeApi = 'api_football'; // 'api_football' or 'football_data'
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

  Future<void> _initApiKey() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();
      if (!docSnap.exists) {
        log(
          '[FootballService] ⚠️ Documento settings/general NAO EXISTE no Firestore!',
        );
        return;
      }
      final data = docSnap.data()!;
      _activeApi = data['active_football_api']?.toString() ?? 'api_football';
      log('[FootballService] 🔧 API ativa: $_activeApi');

      final keys = data['api_keys'] as Map<String, dynamic>? ?? {};
      log('[FootballService] 🔑 Keys disponíveis: ${keys.keys.toList()}');

      if (_activeApi == 'football_data') {
        _apiKey = keys['football_data']?.toString();
        if (_apiKey != null && _apiKey!.isNotEmpty) {
          _dio.options.headers = {'X-Auth-Token': _apiKey!};
          log(
            '[FootballService] ✅ football_data key carregada (${_apiKey!.length} chars)',
          );
        } else {
          log('[FootballService] ❌ Key football_data ausente ou vazia!');
        }
      } else {
        _apiKey = keys['api_football']?.toString();
        if (_apiKey != null && _apiKey!.isNotEmpty) {
          _dio.options.headers = {'x-apisports-key': _apiKey!};
          log(
            '[FootballService] ✅ api_football key carregada (${_apiKey!.length} chars)',
          );
        } else {
          log('[FootballService] ❌ Key api_football ausente ou vazia!');
        }
      }
    } catch (e) {
      log('[FootballService] 💥 Erro ao carregar config da API: $e');
    }
  }

  Future<List<LeagueInfo>> getPopularLeagues() async {
    await _initApiKey();
    final today = DateTime.now();
    int season = today.year;

    if (_activeApi == 'football_data') {
      return [
        LeagueInfo(
          id: 2013,
          name: 'Brasileirão Série A',
          season: season,
          logoUrl: 'https://crests.football-data.org/764.svg',
        ),
        LeagueInfo(
          id: 2152,
          name: 'Copa Libertadores',
          season: season,
          logoUrl: 'https://crests.football-data.org/libertadores.png',
        ),
        LeagueInfo(
          id: 2000,
          name: 'Copa do Mundo',
          season: season,
          logoUrl: 'https://crests.football-data.org/wc.png',
        ),
        LeagueInfo(
          id: 2001,
          name: 'Champions League',
          season: season,
          logoUrl: 'https://crests.football-data.org/CL.png',
        ),
        LeagueInfo(
          id: 2021,
          name: 'Premier League',
          season: season,
          logoUrl: 'https://crests.football-data.org/PL.png',
        ),
        LeagueInfo(
          id: 2014,
          name: 'La Liga',
          season: season,
          logoUrl: 'https://crests.football-data.org/PD.png',
        ),
        LeagueInfo(
          id: 2019,
          name: 'Serie A Italiana',
          season: season,
          logoUrl: 'https://crests.football-data.org/SA.png',
        ),
        LeagueInfo(
          id: 2002,
          name: 'Bundesliga',
          season: season,
          logoUrl: 'https://crests.football-data.org/BL1.png',
        ),
      ];
    } else {
      return [
        LeagueInfo(
          id: 71,
          name: 'Brasileirão Série A',
          season: season,
          logoUrl: 'https://media.api-sports.io/football/leagues/71.png',
        ),
        LeagueInfo(
          id: 13,
          name: 'Copa Libertadores',
          season: season,
          logoUrl: 'https://media.api-sports.io/football/leagues/13.png',
        ),
        LeagueInfo(
          id: 73,
          name: 'Copa do Brasil',
          season: season,
          logoUrl: 'https://media.api-sports.io/football/leagues/73.png',
        ),
        LeagueInfo(
          id: 11,
          name: 'Copa Sul-Americana',
          season: season,
          logoUrl: 'https://media.api-sports.io/football/leagues/11.png',
        ),
        LeagueInfo(
          id: 1,
          name: 'Copa do Mundo',
          season: season,
          logoUrl: 'https://media.api-sports.io/football/leagues/1.png',
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
  }

  Future<List<LeagueInfo>> getCombinedLeagues() async {
    // Mantém a vitrine previsível e relevante. A resposta diária da API inclui
    // muitas ligas regionais e amistosos, cuja ordem varia a cada atualização.
    return getPopularLeagues();
  }

  // Busca as ligas que tem jogos hoje
  Future<List<LeagueInfo>> getActiveLeaguesForToday() async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) {
      log(
        '[FootballService] ⚠️ getActiveLeaguesForToday: sem API key. Retornando lista vazia.',
      );
      return [];
    }
    log('[FootballService] 🔍 Buscando ligas ativas (api=$_activeApi)...');

    if (_activeApi == 'football_data') {
      return _getActiveLeaguesFootballData();
    } else {
      return _getActiveLeaguesApiFootball();
    }
  }

  Future<List<LeagueInfo>> _getActiveLeaguesApiFootball() async {
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
                  name: leagueData['name']?.toString() ?? '',
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

  Future<List<LeagueInfo>> _getActiveLeaguesFootballData() async {
    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'proxyFootballData',
      );
      final response = await callable.call({
        'endpoint': 'matches',
        'queryParams': {'dateFrom': dateStr, 'dateTo': dateStr},
      });

      if (response.data['success'] == true) {
        dynamic rawData = response.data['data'];
        final data = rawData is String ? jsonDecode(rawData) : rawData;
        if (data['matches'] != null) {
          final Set<int> uniqueIds = {};
          final List<LeagueInfo> leagues = [];
          for (var match in data['matches']) {
            final compData = match['competition'];
            final compId = _toInt(compData['id']);
            if (!uniqueIds.contains(compId)) {
              uniqueIds.add(compId);
              leagues.add(
                LeagueInfo(
                  id: compId,
                  name: compData['name']?.toString() ?? '',
                  logoUrl: compData['emblem']?.toString(),
                  season:
                      int.tryParse(
                        match['season']?['startDate']?.toString().substring(
                              0,
                              4,
                            ) ??
                            '',
                      ) ??
                      today.year,
                ),
              );
            }
          }
          return leagues;
        }
      }
      return [];
    } catch (e) {
      log('Erro ao buscar ligas ativas (Football-Data): $e');
      return [];
    }
  }

  // Busca os jogos de hoje para uma liga específica
  Future<List<dynamic>> getMatchesForLeague(int leagueId, {int? season}) async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

    if (_activeApi == 'football_data') {
      return _getMatchesForLeagueFootballData(leagueId);
    } else {
      return _getMatchesForLeagueApiFootball(leagueId, season: season);
    }
  }

  Future<List<dynamic>> _getMatchesForLeagueApiFootball(
    int leagueId, {
    int? season,
  }) async {
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

  Future<List<dynamic>> _getMatchesForLeagueFootballData(int leagueId) async {
    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'proxyFootballData',
      );
      final response = await callable.call({
        'endpoint': 'competitions/$leagueId/matches',
        'queryParams': {'dateFrom': dateStr, 'dateTo': dateStr},
      });

      if (response.data['success'] == true) {
        dynamic rawData = response.data['data'];
        final data = rawData is String ? jsonDecode(rawData) : rawData;
        if (data['matches'] != null) {
          // Adaptador: mapeia Football-Data → formato API-Football esperado pelo MatchesScreen
          final matches = data['matches'] as List<dynamic>;
          return matches.map((m) {
            // Converte status do Football-Data para short code do API-Football
            final rawStatus = m['status'] ?? 'SCHEDULED';
            String shortStatus;
            switch (rawStatus) {
              case 'IN_PLAY':
                shortStatus = '1H'; // aproximação
                break;
              case 'PAUSED':
                shortStatus = 'HT';
                break;
              case 'FINISHED':
                shortStatus = 'FT';
                break;
              case 'POSTPONED':
                shortStatus = 'PST';
                break;
              case 'CANCELLED':
                shortStatus = 'CANC';
                break;
              default:
                shortStatus = 'NS'; // Not Started
            }

            final homeScore = _toInt(m['score']?['fullTime']?['home']);
            final awayScore = _toInt(m['score']?['fullTime']?['away']);

            return {
              'fixture': {
                'id': _toInt(m['id']),
                'date':
                    m['utcDate']?.toString() ??
                    DateTime.now().toIso8601String(),
                'status': {'short': shortStatus, 'elapsed': null},
              },
              'teams': {
                'home': {
                  'name':
                      m['homeTeam']?['shortName']?.toString() ??
                      m['homeTeam']?['name']?.toString() ??
                      'Casa',
                },
                'away': {
                  'name':
                      m['awayTeam']?['shortName']?.toString() ??
                      m['awayTeam']?['name']?.toString() ??
                      'Visitante',
                },
              },
              'goals': {'home': homeScore, 'away': awayScore},
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      log('Erro ao buscar jogos da liga (Football-Data): $e');
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

    if (_activeApi == 'football_data') {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'proxyFootballData',
        );
        final response = await callable.call({
          'endpoint': 'matches',
          'queryParams': {'dateFrom': dateStr, 'dateTo': dateStr},
        });

        if (response.data['success'] == true) {
          dynamic rawData = response.data['data'];
          final data = rawData is String ? jsonDecode(rawData) : rawData;
          if (data['matches'] != null) {
            final popular = await getPopularLeagues();
            final popularIds = popular.map((l) => l.id).toSet();

            final matches = data['matches'] as List<dynamic>;
            final mainMatches = matches
                .where(
                  (m) => popularIds.contains(_toInt(m['competition']?['id'])),
                )
                .toList();

            // Priority: IN_PLAY first, then others
            mainMatches.sort((a, b) {
              final statusA = a['status'];
              final statusB = b['status'];
              if (statusA == 'IN_PLAY' && statusB != 'IN_PLAY') return -1;
              if (statusB == 'IN_PLAY' && statusA != 'IN_PLAY') return 1;
              return 0;
            });
            final top5 = mainMatches.take(5).toList();

            return top5.map((m) {
              final rawStatus = m['status'] ?? 'SCHEDULED';
              String shortStatus;
              switch (rawStatus) {
                case 'IN_PLAY':
                  shortStatus = '1H';
                  break;
                case 'PAUSED':
                  shortStatus = 'HT';
                  break;
                case 'FINISHED':
                  shortStatus = 'FT';
                  break;
                default:
                  shortStatus = 'NS';
              }
              final homeScore = _toInt(m['score']?['fullTime']?['home']);
              final awayScore = _toInt(m['score']?['fullTime']?['away']);
              return {
                'fixture': {
                  'id': _toInt(m['id']),
                  'date':
                      m['utcDate']?.toString() ??
                      DateTime.now().toIso8601String(),
                  'status': {'short': shortStatus},
                },
                'teams': {
                  'home': {
                    'name':
                        m['homeTeam']?['shortName']?.toString() ??
                        m['homeTeam']?['name']?.toString() ??
                        'Casa',
                    'logo': m['homeTeam']?['crest'],
                  },
                  'away': {
                    'name':
                        m['awayTeam']?['shortName']?.toString() ??
                        m['awayTeam']?['name']?.toString() ??
                        'Visitante',
                    'logo': m['awayTeam']?['crest'],
                  },
                },
                'goals': {'home': homeScore, 'away': awayScore},
              };
            }).toList();
          }
        }
        return [];
      } catch (e) {
        log('Erro ao buscar destaques (Football-Data): $e');
        return [];
      }
    } else {
      // API Football
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

            // Priority: Live matches
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
            return mainMatches.take(5).toList();
          }
        }
        return [];
      } catch (e) {
        log('Erro ao buscar destaques (API-Football): $e');
        return [];
      }
    }
  }

  // Inicia o polling
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
      log(
        '[FootballService] ⚠️ _fetchFixtureStatus: sem API key. Emitindo estado de erro.',
      );
      _matchStreamController.add(
        MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''),
      );
      return;
    }

    if (_activeApi == 'football_data') {
      await _fetchFixtureStatusFootballData(fixtureId);
    } else {
      await _fetchFixtureStatusApiFootball(fixtureId);
    }
  }

  Future<void> _fetchFixtureStatusApiFootball(int fixtureId) async {
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
      log('Erro ao buscar dados da api-football: $e');
      _matchStreamController.add(
        MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''),
      );
    }
  }

  Future<void> _fetchFixtureStatusFootballData(int fixtureId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'proxyFootballData',
      );
      final response = await callable.call({
        'endpoint': 'matches/$fixtureId',
        'queryParams': {},
      });

      if (response.data['success'] == true) {
        dynamic rawData = response.data['data'];
        final match = rawData is String ? jsonDecode(rawData) : rawData;

        final String rawStatus = match['status'] ?? 'SCHEDULED';
        int elapsed = 0;
        if (match['minute'] != null) {
          elapsed = int.tryParse(match['minute'].toString()) ?? 0;
        }

        // Mapeamento de status para o padrão API-Football
        String status = 'NS';
        if (rawStatus == 'IN_PLAY') {
          status = elapsed > 45 ? '2H' : '1H';
        } else if (rawStatus == 'PAUSED') {
          status = 'HT';
        } else if (rawStatus == 'FINISHED') {
          status = 'FT';
        } else if (rawStatus == 'POSTPONED') {
          status = 'PST';
        } else if (rawStatus == 'SUSPENDED') {
          status = 'SUSP';
        }

        final int homeScore = _toInt(match['score']?['fullTime']?['home']);
        final int awayScore = _toInt(match['score']?['fullTime']?['away']);

        final String homeTeam =
            match['homeTeam']?['name']?.toString() ?? 'Home';
        final String awayTeam =
            match['awayTeam']?['name']?.toString() ?? 'Away';

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
      log('Erro ao buscar dados do football-data.org: $e');
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
