import 'dart:async';
import 'package:dio/dio.dart';
import '../models/match_state.dart';
import '../models/league_info.dart';
import 'dart:convert';
import 'db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FootballService {
  final Dio _dio = Dio();
  String? _apiKey;
  String _activeApi = 'api_football'; // 'api_football' or 'football_data'
  Timer? _pollingTimer;

  // Stream para emitir atualizações do jogo em tempo real
  final StreamController<MatchState> _matchStreamController = StreamController<MatchState>.broadcast();
  Stream<MatchState> get matchUpdates => _matchStreamController.stream;

  Future<void> _initApiKey() async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('system_config').doc('general').get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        _activeApi = data['active_football_api']?.toString() ?? 'api_football';
        
        final keys = data['api_keys'] as Map<String, dynamic>? ?? {};
        if (_activeApi == 'football_data') {
          _apiKey = keys['football_data'];
          if (_apiKey != null && _apiKey!.isNotEmpty) {
            _dio.options.headers = {'X-Auth-Token': _apiKey!};
          }
        } else {
          _apiKey = keys['api_football'];
          if (_apiKey != null && _apiKey!.isNotEmpty) {
            _dio.options.headers = {'x-apisports-key': _apiKey!};
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar config da API: $e');
    }
  }

  // Busca as ligas que tem jogos hoje
  Future<List<LeagueInfo>> getActiveLeaguesForToday() async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

    if (_activeApi == 'football_data') {
      return _getActiveLeaguesFootballData();
    } else {
      return _getActiveLeaguesApiFootball();
    }
  }

  Future<List<LeagueInfo>> _getActiveLeaguesApiFootball() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

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
            final leagueId = leagueData['id'];
            if (!uniqueIds.contains(leagueId)) {
              uniqueIds.add(leagueId);
              leagues.add(LeagueInfo(
                id: leagueId,
                name: leagueData['name'],
                logoUrl: leagueData['logo'],
                season: leagueData['season'],
              ));
            }
          }
          return leagues;
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar ligas ativas (API-Football): $e');
      return [];
    }
  }

  Future<List<LeagueInfo>> _getActiveLeaguesFootballData() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('proxyFootballData');
      final response = await callable.call({
        'endpoint': 'matches',
        'queryParams': {'dateFrom': dateStr, 'dateTo': dateStr}
      });

      if (response.data['success'] == true) {
        final data = jsonDecode(response.data['data']);
        if (data['matches'] != null) {
          final Set<int> uniqueIds = {};
          final List<LeagueInfo> leagues = [];
          for (var match in data['matches']) {
            final compData = match['competition'];
            final compId = compData['id'];
            if (!uniqueIds.contains(compId)) {
              uniqueIds.add(compId);
              leagues.add(LeagueInfo(
                id: compId,
                name: compData['name'],
                logoUrl: compData['emblem'],
                season: int.tryParse(match['season']?['startDate']?.toString().substring(0, 4) ?? '') ?? today.year,
              ));
            }
          }
          return leagues;
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar ligas ativas (Football-Data): $e');
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

  Future<List<dynamic>> _getMatchesForLeagueApiFootball(int leagueId, {int? season}) async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    int resolvedSeason = season ?? today.year;
    if (season == null) {
      if ((leagueId == 2 || leagueId == 39 || leagueId == 140) && today.month < 7) {
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
          'timezone': 'America/Sao_Paulo'
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
      print('Erro ao buscar jogos da liga (API-Football): $e');
      return [];
    }
  }

  Future<List<dynamic>> _getMatchesForLeagueFootballData(int leagueId) async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('proxyFootballData');
      final response = await callable.call({
        'endpoint': 'competitions/$leagueId/matches',
        'queryParams': {'dateFrom': dateStr, 'dateTo': dateStr}
      });

      if (response.data['success'] == true) {
        final data = jsonDecode(response.data['data']);
        if (data['matches'] != null) {
          // Adaptador: Mapear o formato do Football-Data para o formato esperado pela tela admin_screen (que espera API-Football nativamente)
          final matches = data['matches'] as List<dynamic>;
          return matches.map((m) {
            return {
              'fixture': {'id': m['id']},
              'teams': {
                'home': {'name': m['homeTeam']['name']},
                'away': {'name': m['awayTeam']['name']}
              }
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar jogos da liga (Football-Data): $e');
      return [];
    }
  }

  // Inicia o polling
  Future<void> startPollingLiveMatch(int fixtureId) async {
    await _initApiKey();
    stopPolling();
    await _fetchFixtureStatus(fixtureId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _fetchFixtureStatus(fixtureId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchFixtureStatus(int fixtureId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
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
          
          final String status = fixtureData['fixture']['status']['short'] ?? 'NS';
          final int elapsed = fixtureData['fixture']['status']['elapsed'] ?? 0;
          final int homeScore = fixtureData['goals']['home'] ?? 0;
          final int awayScore = fixtureData['goals']['away'] ?? 0;
          
          final String homeTeam = fixtureData['teams']['home']['name'];
          final String awayTeam = fixtureData['teams']['away']['name'];

          MatchEventType triggerEvent = MatchEventType.none;
          if (status == 'HT') triggerEvent = MatchEventType.halftime;
          else if (status == 'FT') triggerEvent = MatchEventType.fulltime;

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
          _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
        }
      } else {
        _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
      }
    } catch (e) {
      print('Erro ao buscar dados da api-football: $e');
      _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
    }
  }

  Future<void> _fetchFixtureStatusFootballData(int fixtureId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('proxyFootballData');
      final response = await callable.call({
        'endpoint': 'matches/$fixtureId',
        'queryParams': {}
      });

      if (response.data['success'] == true) {
        final match = jsonDecode(response.data['data']);
        
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

        final int homeScore = match['score']?['fullTime']?['home'] ?? 0;
        final int awayScore = match['score']?['fullTime']?['away'] ?? 0;
        
        final String homeTeam = match['homeTeam']?['name'] ?? 'Home';
        final String awayTeam = match['awayTeam']?['name'] ?? 'Away';

        MatchEventType triggerEvent = MatchEventType.none;
        if (status == 'HT') triggerEvent = MatchEventType.halftime;
        else if (status == 'FT') triggerEvent = MatchEventType.fulltime;

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
        _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
      }
    } catch (e) {
      print('Erro ao buscar dados do football-data.org: $e');
      _matchStreamController.add(MatchState(fixtureId: -1, homeTeam: '', awayTeam: ''));
    }
  }

  void dispose() {
    stopPolling();
    _matchStreamController.close();
  }
}

