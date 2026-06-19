import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/arquibancada_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sentiment_thermometer.dart';
import '../widgets/player_rating_card.dart';
import '../widgets/live_chat_widget.dart';
import '../models/player_rating.dart';
import '../models/arquibancada_room.dart';
import '../models/chat_message.dart';

class ArquibancadaScreen extends ConsumerStatefulWidget {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String elapsed;
  final String status;

  const ArquibancadaScreen({
    super.key,
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.elapsed,
    required this.status,
  });

  @override
  ConsumerState<ArquibancadaScreen> createState() =>
      _ArquibancadaScreenState();
}

class _ArquibancadaScreenState extends ConsumerState<ArquibancadaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controle de debounce para avaliações
  final Map<String, DateTime> _lastRatingTime = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ensureRoomAndJoin();
  }

  Future<void> _ensureRoomAndJoin() async {
    final service = ref.read(arquibancadaServiceProvider);
    await service.ensureRoomExists(
        widget.fixtureId, widget.homeTeam, widget.awayTeam);
    await service.joinRoom(widget.fixtureId);

    // Carrega os votos iniciais do usuário
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final votes =
          await service.getUserVotes(widget.fixtureId, user.uid);
      ref.read(userRatingsProvider.notifier).loadInitialVotes(votes);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Decrementa presença ao sair
    ref
        .read(arquibancadaServiceProvider)
        .leaveRoom(widget.fixtureId)
        .ignore();
    super.dispose();
  }

  Future<void> _handleRate(String playerId, double rating) async {
    final now = DateTime.now();
    final last = _lastRatingTime[playerId];
    if (last != null && now.difference(last).inMilliseconds < 800) return;
    _lastRatingTime[playerId] = now;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    ref.read(userRatingsProvider.notifier).setRating(playerId, rating);
    await ref
        .read(arquibancadaServiceProvider)
        .ratePlayer(widget.fixtureId, playerId, user.uid, rating);
  }

  // ─── Inicializa jogadores mock se não houver nenhum ──────────────────────
  // Em produção, isso viria da API de futebol via Cloud Function
  Future<void> _initMockPlayers() async {
    final service = ref.read(arquibancadaServiceProvider);
    final mockPlayers = [
      PlayerRating(id: 'p1', name: 'Goleiro', position: 'Goalkeeper', shirtNumber: 1),
      PlayerRating(id: 'p3', name: 'Zagueiro Esq.', position: 'Defender', shirtNumber: 3),
      PlayerRating(id: 'p4', name: 'Zagueiro Dir.', position: 'Defender', shirtNumber: 4),
      PlayerRating(id: 'p2', name: 'Lateral Dir.', position: 'Defender', shirtNumber: 2),
      PlayerRating(id: 'p5', name: 'Lateral Esq.', position: 'Defender', shirtNumber: 5),
      PlayerRating(id: 'p8', name: 'Volante', position: 'Midfielder', shirtNumber: 8),
      PlayerRating(id: 'p6', name: 'Meia Central', position: 'Midfielder', shirtNumber: 6),
      PlayerRating(id: 'p10', name: 'Meia Atacante', position: 'Midfielder', shirtNumber: 10),
      PlayerRating(id: 'p7', name: 'Ponta Dir.', position: 'Attacker', shirtNumber: 7),
      PlayerRating(id: 'p11', name: 'Ponta Esq.', position: 'Attacker', shirtNumber: 11),
      PlayerRating(id: 'p9', name: 'Centroavante', position: 'Attacker', shirtNumber: 9),
    ];
    await service.initializePlayers(widget.fixtureId, mockPlayers);
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'HT':
        return 'INTERVALO';
      case 'FT':
        return 'FIM DE JOGO';
      case '1H':
        return '1º TEMPO';
      case '2H':
        return '2º TEMPO';
      default:
        return widget.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final roomAsync =
        ref.watch(arquibancadaRoomStreamProvider(widget.fixtureId));
    final playersAsync = ref.watch(playersStreamProvider(widget.fixtureId));
    final chatAsync = ref.watch(chatStreamProvider(widget.fixtureId));
    final userRatings = ref.watch(userRatingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Column(
        children: [
          // ── AppBar customizado com placar ──────────────────────────────
          _buildScoreboard(roomAsync.value),

          // ── TabBar ────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0D0D1A),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF39FF14),
              indicatorWeight: 3,
              labelColor: const Color(0xFF39FF14),
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.thermostat, size: 18), text: 'HUMOR'),
                Tab(icon: Icon(Icons.star, size: 18), text: 'NOTAS'),
                Tab(icon: Icon(Icons.chat_bubble, size: 18), text: 'CHAT'),
              ],
            ),
          ),

          // ── Conteúdo das tabs ─────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Termômetro de Humor
                _buildHumorTab(roomAsync),

                // Tab 2: Avaliação de Jogadores
                _buildPlayersTab(playersAsync, userRatings, user?.uid),

                // Tab 3: Chat ao Vivo
                _buildChatTab(chatAsync, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Placar no topo ──────────────────────────────────────────────────────

  Widget _buildScoreboard(ArquibancadaRoom? room) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E1A), Color(0xFF0D0D1A)],
        ),
      ),
      child: Row(
        children: [
          // Botão voltar
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          // Time casa
          Expanded(
            child: Text(
              widget.homeTeam,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Placar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.homeScore} - ${widget.awayScore}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      widget.status == 'HT' || widget.status == 'FT'
                          ? _statusLabel
                          : "${widget.elapsed}'",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time visitante
          Expanded(
            child: Text(
              widget.awayTeam,
              textAlign: TextAlign.left,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Contador de participantes
          if (room != null && room.participantsCount > 0)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt,
                    color: Color(0xFF39FF14), size: 16),
                Text(
                  '${room.participantsCount}',
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Tab Humor ───────────────────────────────────────────────────────────

  Widget _buildHumorTab(AsyncValue<ArquibancadaRoom> roomAsync) {
    return roomAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      ),
      error: (e, _) => Center(
        child: Text('Erro: $e',
            style: const TextStyle(color: Colors.white54)),
      ),
      data: (room) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SentimentThermometer(
              score: room.sentimentScore,
              applauseCount: room.applauseCount,
              booCount: room.booCount,
              onApplause: () => ref
                  .read(arquibancadaServiceProvider)
                  .sendApplause(widget.fixtureId),
              onBoo: () => ref
                  .read(arquibancadaServiceProvider)
                  .sendBoo(widget.fixtureId),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🏟️ COMO FUNCIONA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HowToRow(
                        icon: '👏',
                        text:
                            'Toque em APLAUDIR quando a torcida está animada'),
                    _HowToRow(
                        icon: '😤',
                        text:
                            'Toque em VAIAR quando a situação está frustrante'),
                    _HowToRow(
                        icon: '🌡️',
                        text:
                            'O termômetro reflete o humor coletivo de todos os torcedores'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Jogadores ───────────────────────────────────────────────────────

  Widget _buildPlayersTab(
      AsyncValue<List<PlayerRating>> playersAsync, Map<String, double> userRatings, String? userId) {
    return playersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      ),
      error: (e, _) => Center(
        child: Text('Erro: $e',
            style: const TextStyle(color: Colors.white54)),
      ),
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer,
                    color: Colors.white24, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Escalação ainda não disponível',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 24),
                // Botão para inicializar jogadores mock (modo dev)
                TextButton(
                  onPressed: _initMockPlayers,
                  child: const Text(
                    'Inicializar Jogadores (Dev)',
                    style: TextStyle(color: Color(0xFF39FF14)),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: players.length,
          itemBuilder: (context, i) {
            final player = players[i];
            return PlayerRatingCard(
              player: player,
              userRating: userRatings[player.id],
              onRate: userId != null
                  ? (rating) => _handleRate(player.id, rating)
                  : (_) {},
            );
          },
        );
      },
    );
  }

  // ─── Tab Chat ─────────────────────────────────────────────────────────────

  Widget _buildChatTab(AsyncValue<List<ChatMessage>> chatAsync, dynamic user) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;
    final displayName =
        currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Torcedor';

    return chatAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      ),
      error: (e, _) => Center(
        child: Text('Erro: $e',
            style: const TextStyle(color: Colors.white54)),
      ),
      data: (messages) => LiveChatWidget(
        messages: messages,
        currentUserId: currentUser?.uid ?? '',
        currentUserName: displayName,
        onSendMessage: currentUser == null
            ? (_) {}
            : (text) => ref
                .read(arquibancadaServiceProvider)
                .sendMessage(
                    widget.fixtureId, currentUser.uid, displayName, text),
        onSendReaction: currentUser == null
            ? (_) {}
            : (reaction) => ref
                .read(arquibancadaServiceProvider)
                .sendReaction(
                    widget.fixtureId, currentUser.uid, displayName, reaction),
      ),
    );
  }
}

// ─── Widget auxiliar ─────────────────────────────────────────────────────────

class _HowToRow extends StatelessWidget {
  final String icon;
  final String text;

  const _HowToRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
