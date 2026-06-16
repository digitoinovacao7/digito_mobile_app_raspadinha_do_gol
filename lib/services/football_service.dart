import 'dart:async';
import 'package:dio/dio.dart';
import '../models/match_state.dart';
import '../models/league_info.dart';
import 'db_service.dart';

class FootballService {
  final Dio _dio = Dio();
  final DbService _dbService = DbService();
  String? _apiKey;
  Timer? _pollingTimer;

  // Stream para emitir atualizações do jogo em tempo real
  final StreamController<MatchState> _matchStreamController = StreamController<MatchState>.broadcast();
  Stream<MatchState> get matchUpdates => _matchStreamController.stream;

  Future<void> _initApiKey() async {
    if (_apiKey == null) {
      final keys = await _dbService.getApiKeys();
      _apiKey = keys['api_football'];
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        _dio.options.headers['x-apisports-key'] = _apiKey;
      }
    }
  }

  // Busca as ligas que tem jogos hoje
  Future<List<LeagueInfo>> getActiveLeaguesForToday() async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {
          'date': dateStr,
          'timezone': 'America/Sao_Paulo'
        },
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
      print('Erro ao buscar ligas ativas: $e');
      return [];
    }
  }

  // Busca os jogos de hoje para uma liga específica
  Future<List<dynamic>> getMatchesForLeague(int leagueId, {int? season}) async {
    await _initApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) return [];

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    // Simplificação para a temporada caso não seja passada
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
      print('Erro ao buscar jogos da liga $leagueId: $e');
      return [];
    }
  }

  // Inicia o polling (ex: a cada 1 minuto) para uma partida em andamento
  Future<void> startPollingLiveMatch(int fixtureId) async {
    await _initApiKey();
    
    // Cancela o polling anterior se houver
    stopPolling();

    // Primeira chamada imediata
    await _fetchFixtureStatus(fixtureId);

    // Configura o timer para buscar atualizações a cada 60 segundos
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
      _matchStreamController.add(MatchState(
        fixtureId: -1, // ID -1 indica que não há jogo configurado ou api key faltando
        homeTeam: '',
        awayTeam: '',
      ));
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
          
          final String status = fixtureData['fixture']['status']['short'] ?? 'NS';
          final int elapsed = fixtureData['fixture']['status']['elapsed'] ?? 0;
          final int homeScore = fixtureData['goals']['home'] ?? 0;
          final int awayScore = fixtureData['goals']['away'] ?? 0;
          
          final String homeTeam = fixtureData['teams']['home']['name'];
          final String awayTeam = fixtureData['teams']['away']['name'];

          MatchEventType triggerEvent = MatchEventType.none;

          // Eventos de gatilho para ganhar tokens (simplificado para gols e finalizações de tempo)
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

  void dispose() {
    stopPolling();
    _matchStreamController.close();
  }
}
