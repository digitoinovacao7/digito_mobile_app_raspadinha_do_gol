import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_state.dart';
import '../services/football_service.dart';

final footballServiceProvider = Provider<FootballService>((ref) {
  final service = FootballService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Mantém o estado global da partida atual
final matchStateProvider = StateProvider<MatchState>((ref) {
  return MatchState(fixtureId: 0, homeTeam: '-', awayTeam: '-');
});

// Provider para escutar atualizações ao vivo da API
final matchStreamProvider = StreamProvider<MatchState>((ref) {
  final service = ref.watch(footballServiceProvider);
  
  // Exemplo: inicia polling de uma partida específica
  // No mundo real, a Home Screen passaria o fixtureId que o usuário clicou.
  // Aqui estamos hardcodando o ID 1 para simulação inicial.
  service.startPollingLiveMatch(1);

  service.matchUpdates.listen((updatedMatch) {
    ref.read(matchStateProvider.notifier).state = updatedMatch;
  });

  return service.matchUpdates;
});

// Controla quantas raspadinhas grátis o usuário ainda tem para esta partida.
final freePlaysProvider = StateProvider<int>((ref) => 1);
