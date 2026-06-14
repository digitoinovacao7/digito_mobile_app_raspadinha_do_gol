import 'dart:async';
import 'package:dio/dio.dart';
import '../models/match_state.dart';
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
    if (_apiKey == null || _apiKey!.isEmpty) return;

    try {
      final response = await _dio.get(
        'https://v3.football.api-sports.io/fixtures',
        queryParameters: {'id': fixtureId},
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

          // Simples lógica de gatilho baseada no status ou mudança de gols.
          // Em um app real, precisaríamos manter o estado anterior para comparar e saber se foi um "NOVO" gol.
          // Aqui, estamos simplificando para o escopo do projeto.
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
        }
      }
    } catch (e) {
      print('Erro ao buscar dados da api-football: $e');
    }
  }

  void dispose() {
    stopPolling();
    _matchStreamController.close();
  }
}
