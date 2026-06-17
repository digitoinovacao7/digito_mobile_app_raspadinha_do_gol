import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_quiz_service.dart';
import '../services/db_service.dart';
import '../core/theme.dart';
import 'scratch_game_screen.dart';
import 'checkout_screen.dart';

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
        return _QuizWidget(homeTeam: widget.homeTeam, awayTeam: widget.awayTeam);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o stream do provider passando o fixtureId
    final matchState = ref.watch(matchStreamProvider(widget.fixtureId));
    final freePlays = ref.watch(freePlaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala da Partida'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: matchState.when(
        data: (match) {
          if (match.fixtureId == -1) {
            return const Center(child: Text('Erro ao conectar com a partida.'));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${match.homeTeam.isNotEmpty ? match.homeTeam : widget.homeTeam} ${match.homeScore} x ${match.awayScore} ${match.awayTeam.isNotEmpty ? match.awayTeam : widget.awayTeam}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tempo: ${match.elapsed}\' - Status: ${match.status}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text('Responder Quiz com IA (Ganhar Tokens)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openQuizModal(),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _QuizWidget extends ConsumerStatefulWidget {
  final String homeTeam;
  final String awayTeam;
  const _QuizWidget({required this.homeTeam, required this.awayTeam});

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
    });

    final isCorrect = index == _quizData!['respostaCorreta'];
    
    if (isCorrect) {
      final dbService = DbService();
      final auth = ref.read(authServiceProvider);
      final user = auth.currentUser;
      if (user != null) {
        final economy = await dbService.getEconomySettings();
        final reward = economy['quiz_reward'] ?? 250;
        await dbService.addTokens(user.uid, reward);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Resposta Exata! Você ganhou $reward Tokens 🪙'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Resposta Incorreta! Tente outro quiz depois.'),
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
