import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import 'scratch_game_screen.dart';
import 'arquibancada_screen.dart';
import '../models/match_state.dart';

class ActiveMatchScreen extends ConsumerStatefulWidget {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;

  const ActiveMatchScreen({
    super.key,
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  ConsumerState<ActiveMatchScreen> createState() => _ActiveMatchScreenState();
}

class _ActiveMatchScreenState extends ConsumerState<ActiveMatchScreen> {
  bool _isMarkingWatching = false;
  bool _isOpeningScratch = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _markWatchingMatch(String homeTeam, String awayTeam) async {
    final auth = ref.read(authServiceProvider);
    final firebaseUser = auth.currentUser;
    final currentUser = ref.read(currentUserProvider);

    if (firebaseUser == null) return;

    setState(() {
      _isMarkingWatching = true;
    });

    try {
      await DbService().markWatchingMatch(
        uid: firebaseUser.uid,
        fixtureId: widget.fixtureId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
      );

      if (currentUser != null) {
        ref.read(currentUserProvider.notifier).state = currentUser.copyWith(
          watchingFixtureId: widget.fixtureId,
          watchingHomeTeam: homeTeam,
          watchingAwayTeam: awayTeam,
        );
      }
      ref.invalidate(appUserFutureProvider(firebaseUser.uid));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jogo marcado. As chances agora valem para esta partida.',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível marcar o jogo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingWatching = false;
        });
      }
    }
  }

  Future<void> _openScratchGame(int raspadinhasDisponiveis) async {
    if (_isOpeningScratch) return;

    // Registra otimisticamente a jogada localmente e no banco (usando o count de quizzes como "raspadas")
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    final appUser = ref.read(currentUserProvider);
    if (appUser?.watchingFixtureId != widget.fixtureId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Marque este jogo como o que você está assistindo antes de raspar.',
          ),
        ),
      );
      return;
    }

    if (raspadinhasDisponiveis <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda não há raspadinha disponível para este jogo.'),
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para usar a raspadinha.')),
      );
      return;
    }

    setState(() {
      _isOpeningScratch = true;
    });

    try {
      final dbService = DbService();
      await dbService.incrementQuizCount(user.uid, widget.fixtureId.toString());
      if (appUser != null) {
        final updatedCounts = Map<String, int>.from(
          appUser.answeredQuizzesCount,
        );
        final key = widget.fixtureId.toString();
        updatedCounts[key] = (updatedCounts[key] ?? 0) + 1;
        ref.read(currentUserProvider.notifier).state = appUser.copyWith(
          answeredQuizzesCount: updatedCounts,
        );
      }
      ref.invalidate(appUserFutureProvider(user.uid));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOpeningScratch = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível consumir a chance: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScratchGameScreen()),
    );
    if (user != null) {
      ref.invalidate(appUserFutureProvider(user.uid));
    }
    if (mounted) {
      setState(() {
        _isOpeningScratch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for score or status changes to play sounds
    ref.listen<AsyncValue<MatchState>>(matchStreamProvider(widget.fixtureId), (previous, next) {
      if (next.value != null && previous?.value != null) {
        final prevMatch = previous!.value!;
        final nextMatch = next.value!;
        
        if (nextMatch.homeScore > prevMatch.homeScore || nextMatch.awayScore > prevMatch.awayScore) {
          _audioPlayer.play(AssetSource('sounds/goal.wav'));
        }
        if (prevMatch.status != 'HT' && nextMatch.status == 'HT') {
          _audioPlayer.play(AssetSource('sounds/whistle.wav'));
        }
      }
    });

    // Escuta o stream do provider passando o fixtureId
    final matchState = ref.watch(matchStreamProvider(widget.fixtureId));
    final authService = ref.watch(authServiceProvider);
    final firebaseUser = authService.currentUser;
    final appUserAsync = firebaseUser != null
        ? ref.watch(appUserFutureProvider(firebaseUser.uid))
        : null;
    final appUser = ref.watch(currentUserProvider) ?? appUserAsync?.value;
    final bool isWatchingThisMatch =
        appUser?.watchingFixtureId == widget.fixtureId;
    final bool isWatchingAnotherMatch =
        appUser?.watchingFixtureId != null && !isWatchingThisMatch;

    // Só eventos reais geram chances: gols, intervalo e fim de jogo.
    int totalEventos =
        (matchState.value?.homeScore ?? 0) + (matchState.value?.awayScore ?? 0);
    final status = matchState.value?.status ?? '';
    final elapsed = matchState.value?.elapsed ?? 0;

    if (elapsed >= 45 || ['HT', '2H', 'FT', 'AET', 'PEN'].contains(status)) {
      totalEventos += 1;
    }
    if (elapsed >= 90 || ['FT', 'AET', 'PEN'].contains(status)) {
      totalEventos += 1;
    }

    final int raspadinhasConsumidas =
        appUser?.answeredQuizzesCount[widget.fixtureId.toString()] ??
        appUserAsync?.value?.answeredQuizzesCount[widget.fixtureId
            .toString()] ??
        0;
    final int rawRaspadinhasDisponiveis = isWatchingThisMatch
        ? totalEventos - raspadinhasConsumidas
        : 0;
    final int raspadinhasDisponiveis = rawRaspadinhasDisponiveis < 0
        ? 0
        : rawRaspadinhasDisponiveis;
    final bool temRaspadinhaDisponivel = raspadinhasDisponiveis > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala da Partida'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      floatingActionButton: _ArquibancadaFab(
        onTap: () {
          final match = matchState.value;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArquibancadaScreen(
                fixtureId: widget.fixtureId,
                homeTeam: match?.homeTeam.isNotEmpty == true
                    ? match!.homeTeam
                    : widget.homeTeam,
                awayTeam: match?.awayTeam.isNotEmpty == true
                    ? match!.awayTeam
                    : widget.awayTeam,
                homeScore: match?.homeScore ?? 0,
                awayScore: match?.awayScore ?? 0,
                elapsed: match?.elapsed.toString() ?? '0',
                status: match?.status ?? 'NS',
              ),
            ),
          );
        },
      ),
      body: matchState.when(
        data: (match) {
          if (match.fixtureId == -1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: Colors.orange.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'API de futebol não configurada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure a chave em settings/general no Firestore (campo api_keys.api_football ou api_keys.football_data).',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'O botão 🏟️ ARQUIBANCADA abaixo ainda funciona!',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            match.homeTeam.isNotEmpty
                                ? match.homeTeam
                                : widget.homeTeam,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                Colors.green.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '${match.homeScore} - ${match.awayScore}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            match.awayTeam.isNotEmpty
                                ? match.awayTeam
                                : widget.awayTeam,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${match.elapsed}\' - ${match.status}',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (isWatchingThisMatch)
                    _buildScratchChancePanel(
                      temRaspadinhaDisponivel: temRaspadinhaDisponivel,
                      raspadinhasDisponiveis: raspadinhasDisponiveis,
                    )
                  else
                    _buildWatchingGateCard(
                      homeTeam: match.homeTeam.isNotEmpty
                          ? match.homeTeam
                          : widget.homeTeam,
                      awayTeam: match.awayTeam.isNotEmpty
                          ? match.awayTeam
                          : widget.awayTeam,
                      isWatchingAnotherMatch: isWatchingAnotherMatch,
                      currentWatchingHomeTeam: appUser?.watchingHomeTeam,
                      currentWatchingAwayTeam: appUser?.watchingAwayTeam,
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => _buildFastLoadingRoom(),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildWatchingGateCard({
    required String homeTeam,
    required String awayTeam,
    required bool isWatchingAnotherMatch,
    String? currentWatchingHomeTeam,
    String? currentWatchingAwayTeam,
  }) {
    final currentMatchLabel =
        '${currentWatchingHomeTeam ?? 'Outro jogo'} x ${currentWatchingAwayTeam ?? ''}'
            .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isWatchingAnotherMatch
                ? 'Você marcou outro jogo'
                : 'Marque o jogo que está assistindo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWatchingAnotherMatch
                ? 'Agora suas chances estão valendo para $currentMatchLabel. Você pode trocar para este jogo se ele é o que está assistindo.'
                : 'Só o jogo marcado libera raspadinhas. Assim cada pessoa acompanha uma partida por vez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMarkingWatching
                  ? null
                  : () => _markWatchingMatch(homeTeam, awayTeam),
              icon: _isMarkingWatching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                isWatchingAnotherMatch
                    ? 'Trocar para este jogo'
                    : 'Estou assistindo este jogo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchChancePanel({
    required bool temRaspadinhaDisponivel,
    required int raspadinhasDisponiveis,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'Jogo marcado',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (temRaspadinhaDisponivel)
            _AnimatedScratchButton(
              onPressed: () => _openScratchGame(raspadinhasDisponiveis),
              badgeCount: raspadinhasDisponiveis,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'CHANCES ZERADAS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            temRaspadinhaDisponivel
                ? 'Você tem $raspadinhasDisponiveis chance(s) pendente(s) neste jogo.'
                : 'Aguarde o próximo gol, intervalo ou fim de jogo para ganhar mais chances.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFastLoadingRoom() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.homeTeam,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '0 - 0',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.awayTeam,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentGold),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sincronizando placar...',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'A sala já está aberta. As chances aparecem assim que o placar oficial responder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedScratchButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int badgeCount;
  const _AnimatedScratchButton({required this.onPressed, this.badgeCount = 1});

  @override
  State<_AnimatedScratchButton> createState() => _AnimatedScratchButtonState();
}

class _AnimatedScratchButtonState extends State<_AnimatedScratchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(
                          alpha: 0.16 * _scaleAnimation.value,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_outlined,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Raspadinha disponível',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 88,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: CustomPaint(
                          painter: const _ScratchCoatingPainter(),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: Colors.black54),
                                SizedBox(height: 4),
                                Text(
                                  'TOQUE PARA RASPAR',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    widget.badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScratchCoatingPainter extends CustomPainter {
  const _ScratchCoatingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;

    for (double x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }

    final dotPaint = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (double y = 10; y < size.height; y += 18) {
      for (double x = 8; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── FAB: Arquibancada Digital ────────────────────────────────────────────────

class _ArquibancadaFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ArquibancadaFab({required this.onTap});

  @override
  State<_ArquibancadaFab> createState() => _ArquibancadaFabState();
}

class _ArquibancadaFabState extends State<_ArquibancadaFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003300), Color(0xFF006400)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(
                  0xFF39FF14,
                ).withValues(alpha: _glowAnim.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF39FF14,
                  ).withValues(alpha: _glowAnim.value * 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏟️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'ARQUIBANCADA',
                  style: TextStyle(
                    color: Color(0xFF39FF14),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
