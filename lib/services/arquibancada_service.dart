import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/arquibancada_room.dart';
import '../models/player_rating.dart';
import '../models/chat_message.dart';

class ArquibancadaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Referências ───────────────────────────────────────────────────────────

  DocumentReference _roomRef(int fixtureId) =>
      _db.collection('arquibancada_rooms').doc(fixtureId.toString());

  CollectionReference _playersRef(int fixtureId) =>
      _roomRef(fixtureId).collection('players');

  CollectionReference _messagesRef(int fixtureId) =>
      _roomRef(fixtureId).collection('messages');

  // ─── Sala ──────────────────────────────────────────────────────────────────

  /// Cria ou garante que a sala existe para esta partida.
  Future<void> ensureRoomExists(
      int fixtureId, String homeTeam, String awayTeam) async {
    final doc = await _roomRef(fixtureId).get();
    if (!doc.exists) {
      await _roomRef(fixtureId).set({
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'status': 'live',
        'sentiment': {'score': 50, 'applause': 0, 'boo': 0},
        'participantsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream da sala para atualizações em tempo real.
  Stream<ArquibancadaRoom> roomStream(int fixtureId) {
    return _roomRef(fixtureId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return ArquibancadaRoom(
          fixtureId: fixtureId,
          homeTeam: '',
          awayTeam: '',
        );
      }
      return ArquibancadaRoom.fromMap(
          snap.data()! as Map<String, dynamic>, fixtureId);
    });
  }

  // ─── Sentimento ────────────────────────────────────────────────────────────

  /// Registra um aplauso — incrementa score e contador.
  Future<void> sendApplause(int fixtureId) async {
    await _roomRef(fixtureId).update({
      'sentiment.applause': FieldValue.increment(1),
      'sentiment.score': FieldValue.increment(1),
    });
  }

  /// Registra uma vaia — decrementa score e incrementa boo.
  Future<void> sendBoo(int fixtureId) async {
    await _roomRef(fixtureId).update({
      'sentiment.boo': FieldValue.increment(1),
      'sentiment.score': FieldValue.increment(-1),
    });
  }

  // ─── Jogadores ─────────────────────────────────────────────────────────────

  /// Stream de todos os jogadores com avaliações em tempo real.
  Stream<List<PlayerRating>> playersStream(int fixtureId) {
    return _playersRef(fixtureId)
        .orderBy('shirtNumber')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlayerRating.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Inicializa a escalação de jogadores na sala (chamado pelo admin/sistema).
  Future<void> initializePlayers(
      int fixtureId, List<PlayerRating> players) async {
    final batch = _db.batch();
    for (final player in players) {
      final ref = _playersRef(fixtureId).doc(player.id);
      batch.set(ref, player.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Submete a nota de um usuário para um jogador.
  /// Usa uma sub-coleção de votos para garantir 1 voto/usuário e calcular média.
  Future<void> ratePlayer(
      int fixtureId, String playerId, String userId, double rating) async {
    final voteRef = _playersRef(fixtureId)
        .doc(playerId)
        .collection('votes')
        .doc(userId);

    final playerRef = _playersRef(fixtureId).doc(playerId);

    await _db.runTransaction((transaction) async {
      final voteSnap = await transaction.get(voteRef);
      final playerSnap = await transaction.get(playerRef);

      if (!playerSnap.exists) return;

      if (voteSnap.exists) {
        // Atualizar voto existente: remove o voto antigo, adiciona o novo
        final oldRating = (voteSnap.data()!['rating'] as num).toDouble();
        transaction.update(playerRef, {
          'ratingSum': FieldValue.increment(rating - oldRating),
        });
        transaction.update(voteRef, {'rating': rating});
      } else {
        // Novo voto
        transaction.update(playerRef, {
          'ratingSum': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
        });
        transaction.set(voteRef, {
          'rating': rating,
          'votedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Retorna a nota já dada pelo usuário em cada jogador (mapa playerId → nota).
  Future<Map<String, double>> getUserVotes(
      int fixtureId, String userId) async {
    final Map<String, double> votes = {};
    final playersSnap = await _playersRef(fixtureId).get();

    for (final playerDoc in playersSnap.docs) {
      final voteSnap = await playerDoc.reference
          .collection('votes')
          .doc(userId)
          .get();
      if (voteSnap.exists) {
        votes[playerDoc.id] =
            (voteSnap.data()!['rating'] as num).toDouble();
      }
    }
    return votes;
  }

  // ─── Chat ──────────────────────────────────────────────────────────────────

  /// Stream das últimas 50 mensagens do chat.
  Stream<List<ChatMessage>> messagesStream(int fixtureId) {
    return _messagesRef(fixtureId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Envia uma mensagem de texto.
  Future<void> sendMessage(
      int fixtureId, String userId, String userName, String text) async {
    if (text.trim().isEmpty) return;
    await _messagesRef(fixtureId).add({
      'userId': userId,
      'userName': userName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Envia uma reação rápida (emoji).
  Future<void> sendReaction(
      int fixtureId, String userId, String userName, String reaction) async {
    await _messagesRef(fixtureId).add({
      'userId': userId,
      'userName': userName,
      'reaction': reaction,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Presença ──────────────────────────────────────────────────────────────

  /// Incrementa o contador de participantes ao entrar.
  Future<void> joinRoom(int fixtureId) async {
    await _roomRef(fixtureId).update({
      'participantsCount': FieldValue.increment(1),
    });
  }

  /// Decrementa o contador de participantes ao sair.
  Future<void> leaveRoom(int fixtureId) async {
    await _roomRef(fixtureId).update({
      'participantsCount': FieldValue.increment(-1),
    });
  }
}
