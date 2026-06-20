import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_quiz_service.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import 'scratch_game_screen.dart';
import 'checkout_screen.dart';
import 'arquibancada_screen.dart';

class ActiveMatchScreen extends ConsumerStatefulWidget {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;

  const ActiveMatchScreen({
    Key? key,
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
  }) : super(key: key);

  @override
  ConsumerState<ActiveMatchScreen> createState() => _ActiveMatchScreenState();
}

class _ActiveMatchScreenState extends ConsumerState<ActiveMatchScreen> {
  Future<void> _openQuizModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return _QuizWidget(homeTeam: widget.homeTeam, awayTeam: widget.awayTeam, fixtureId: widget.fixtureId);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o stream do provider passando o fixtureId
    final matchState = ref.watch(matchStreamProvider(widget.fixtureId));
    final freePlays = ref.watch(freePlaysProvider);
    
    final authService = ref.watch(authServiceProvider);
    final firebaseUser = authService.currentUser;
    final appUserAsync = firebaseUser != null ? ref.watch(appUserFutureProvider(firebaseUser.uid)) : null;
    
    // Calcula o total de eventos/chances na partida: 1 entrada + gols + intervalo + fim
    int totalEventos = 1 + (matchState.value?.homeScore ?? 0) + (matchState.value?.awayScore ?? 0);
    final status = matchState.value?.status ?? '';
    final elapsed = matchState.value?.elapsed ?? 0;
    
    if (elapsed >= 45 || ['HT', '2H', 'FT', 'AET', 'PEN'].contains(status)) totalEventos += 1;
    if (elapsed >= 90 || ['FT', 'AET', 'PEN'].contains(status)) totalEventos += 1;

    final int quizzesRespondidos = appUserAsync?.value?.answeredQuizzesCount[widget.fixtureId.toString()] ?? 0;
    final int quizzesDisponiveis = totalEventos - quizzesRespondidos;
    final bool temQuizDisponivel = quizzesDisponiveis > 0;

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
                    Icon(Icons.wifi_off_rounded, size: 64, color: Colors.orange.shade300),
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
                      'Configure a chave em system_config/general no Firestore (campo api_keys.api_football ou api_keys.football_data).',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'O botão 🏟️ ARQUIBANCADA abaixo ainda funciona!',
                      style: TextStyle(color: Colors.green.shade600, fontSize: 13, fontWeight: FontWeight.w600),
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
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Text(match.homeTeam.isNotEmpty ? match.homeTeam : widget.homeTeam, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.primaryGreen, Colors.green.shade700]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Text('${match.homeScore} - ${match.awayScore}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(match.awayTeam.isNotEmpty ? match.awayTeam : widget.awayTeam, textAlign: TextAlign.left, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          '${match.elapsed}\' - ${match.status}',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      children: [
                        if (temQuizDisponivel)
                          _AnimatedQuizButton(
                            onPressed: _openQuizModal,
                            badgeCount: quizzesDisponiveis,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600),
                                const SizedBox(width: 8),
                                const Text('CHANCES ZERADAS ✅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          temQuizDisponivel 
                            ? 'Você tem $quizzesDisponiveis chance(s) pendente(s)!' 
                            : 'Aguarde o próximo gol, intervalo ou fim de jogo para ganhar mais chances.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  if (match.isScratchUnlocked)
                    ElevatedButton(
                      onPressed: () {
                        if (freePlays > 0) {
                          ref.read(freePlaysProvider.notifier).state = freePlays - 1;
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScratchGameScreen()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(freePlays > 0 ? 'Jogar Raspadinha' : 'Comprar Mais Raspadinhas'),
                    )
                  else
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Aguardando lances importantes...',
                          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Conectando à partida...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _QuizWidget extends ConsumerStatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final int fixtureId;
  const _QuizWidget({required this.homeTeam, required this.awayTeam, required this.fixtureId});

  @override
  ConsumerState<_QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends ConsumerState<_QuizWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _quizData;
  String? _errorMessage;
  int? _selectedOption;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    try {
      final aiService = ref.read(aiQuizServiceProvider);
      final quiz = await aiService.generateQuiz(widget.homeTeam, widget.awayTeam);
      if (mounted) {
        setState(() {
          _quizData = quiz;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAnswer(int index) async {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      _isLoading = true;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('answerQuiz').call({
        'quizId': _quizData!['quizId'],
        'answerId': index,
        'fixtureId': widget.fixtureId,
        'matchName': '${widget.homeTeam} x ${widget.awayTeam}',
      });

      final data = result.data;
      final isCorrect = data['isCorrect'] == true;
      final earnedTokens = data['earnedTokens'] ?? 0;

      final auth = ref.read(authServiceProvider);
      final user = auth.currentUser;
      if (user != null) {
        ref.invalidate(appUserFutureProvider(user.uid));
      }

      if (mounted) {
        setState(() {
          _quizData!['respostaCorreta'] = isCorrect ? index : -1;
          _isLoading = false;
        });

        if (isCorrect) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Resposta Exata! Você ganhou $earnedTokens Tokens 🪙'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Resposta Incorreta! Tente outro quiz depois.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _quizData!['respostaCorreta'] = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao enviar resposta: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.75,
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 24),
                  Text('A Inteligência Artificial está formulando uma pergunta curiosa...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erro: $_errorMessage', textAlign: TextAlign.center),
                    ],
                  ),
                )
              : _quizData == null
                  ? const Center(child: Text('Não foi possível gerar a pergunta.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Ganhe Tokens Respondendo:', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(
                          _quizData!['pergunta'] ?? 'Pergunta Indisponível',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 32),
                        if (_quizData!['opcoes'] != null)
                          ...List.generate(
                            (_quizData!['opcoes'] as List).length,
                            (index) {
                              final text = _quizData!['opcoes'][index];
                              final isCorrect = index == _quizData!['respostaCorreta'];
                              
                              Color btnColor = Colors.grey.shade50;
                              Color textColor = Colors.black87;
                              Color borderColor = Colors.grey.shade300;
                              
                              if (_isAnswered) {
                                if (isCorrect) {
                                  btnColor = Colors.green.shade100;
                                  textColor = Colors.green.shade900;
                                  borderColor = Colors.green;
                                } else if (index == _selectedOption) {
                                  btnColor = Colors.red.shade100;
                                  textColor = Colors.red.shade900;
                                  borderColor = Colors.red;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: btnColor,
                                    foregroundColor: textColor,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: borderColor, width: 1.5),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isAnswered ? null : () => _submitAnswer(index),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(text, style: const TextStyle(fontSize: 16)),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
    );
  }
}

class _AnimatedQuizButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int badgeCount;
  const _AnimatedQuizButton({required this.onPressed, this.badgeCount = 1});

  @override
  State<_AnimatedQuizButton> createState() => _AnimatedQuizButtonState();
}

class _AnimatedQuizButtonState extends State<_AnimatedQuizButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
              Container(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.5 * (_scaleAnimation.value - 1.0) * 20), blurRadius: 16)],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.psychology, size: 28),
                  label: const Text('NOVO QUIZ DISPONÍVEL! (Ganhar Tokens)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textDark,
                    foregroundColor: AppTheme.accentGold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: widget.onPressed,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                  child: Text(widget.badgeCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
                color: const Color(0xFF39FF14).withOpacity(_glowAnim.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39FF14)
                      .withOpacity(_glowAnim.value * 0.5),
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

