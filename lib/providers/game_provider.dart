import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_state.dart';
import '../services/football_service.dart';

final footballServiceProvider = Provider<FootballService>((ref) {
  final service = FootballService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Mantém o estado global da partida atual
final matchStateProvider = StateProvider<MatchState>((ref) {
  return MatchState(fixtureId: -1, homeTeam: '-', awayTeam: '-');
});

// Provider para escutar atualizações ao vivo da API, agora passando o ID do jogo escolhido
final matchStreamProvider = StreamProvider.family<MatchState, int>((ref, fixtureId) async* {
  final service = ref.watch(footballServiceProvider);
  
  // Inicia o polling com o ID escolhido pelo usuário
  service.startPollingLiveMatch(fixtureId);

  service.matchUpdates.listen((updatedMatch) {
    ref.read(matchStateProvider.notifier).state = updatedMatch;
  });

  await for (final update in service.matchUpdates) {
    yield update;
  }
});

// Controla quantas raspadinhas grátis o usuário ainda tem para esta partida.
final freePlaysProvider = StateProvider<int>((ref) => 1);

