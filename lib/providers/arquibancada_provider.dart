import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arquibancada_room.dart';
import '../models/player_rating.dart';
import '../models/chat_message.dart';
import '../services/arquibancada_service.dart';

// ─── Service ────────────────────────────────────────────────────────────────

final arquibancadaServiceProvider = Provider<ArquibancadaService>((ref) {
  return ArquibancadaService();
});

// ─── Sala em tempo real ─────────────────────────────────────────────────────

final arquibancadaRoomStreamProvider =
    StreamProvider.family<ArquibancadaRoom, int>((ref, fixtureId) {
  final service = ref.watch(arquibancadaServiceProvider);
  return service.roomStream(fixtureId);
});

// ─── Jogadores em tempo real ────────────────────────────────────────────────

final playersStreamProvider =
    StreamProvider.family<List<PlayerRating>, int>((ref, fixtureId) {
  final service = ref.watch(arquibancadaServiceProvider);
  return service.playersStream(fixtureId);
});

// ─── Chat em tempo real ─────────────────────────────────────────────────────

final chatStreamProvider =
    StreamProvider.family<List<ChatMessage>, int>((ref, fixtureId) {
  final service = ref.watch(arquibancadaServiceProvider);
  return service.messagesStream(fixtureId);
});

// ─── Votos do usuário (carregados uma vez) ──────────────────────────────────

final userVotesProvider =
    FutureProvider.family<Map<String, double>, ({int fixtureId, String userId})>(
        (ref, params) async {
  final service = ref.watch(arquibancadaServiceProvider);
  return service.getUserVotes(params.fixtureId, params.userId);
});

// ─── Estado local: notas que o usuário está dando (antes de salvar) ─────────

class UserRatingsNotifier
    extends StateNotifier<Map<String, double>> {
  UserRatingsNotifier() : super({});

  void setRating(String playerId, double rating) {
    state = {...state, playerId: rating};
  }

  void loadInitialVotes(Map<String, double> votes) {
    state = {...votes};
  }
}

final userRatingsProvider =
    StateNotifierProvider<UserRatingsNotifier, Map<String, double>>(
        (ref) => UserRatingsNotifier());
