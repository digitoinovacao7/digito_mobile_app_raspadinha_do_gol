import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_quiz_service.dart';
import '../core/theme.dart';

class QuizStandaloneScreen extends ConsumerStatefulWidget {
  const QuizStandaloneScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizStandaloneScreen> createState() => _QuizStandaloneScreenState();
}

class _QuizStandaloneScreenState extends ConsumerState<QuizStandaloneScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _quizData = null;
      _selectedOption = null;
      _isAnswered = false;
    });
    
    try {
      final aiService = ref.read(aiQuizServiceProvider);
      // Passa times genéricos para a IA criar um quiz de futebol geral
      final quiz = await aiService.generateQuiz('Futebol Brasileiro', 'Seleção Brasileira');
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

  void _submitAnswer(int index) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
    });

    final correctAnswer = _quizData!['respostaCorreta'] as int?;
    
    if (correctAnswer != null && index == correctAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Resposta Exata! Parabéns! ⚽'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Incorreta! A resposta certa era a opção ${(correctAnswer ?? 0) + 1}.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz por Diversão'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryGreen),
                    SizedBox(height: 24),
                    Text('Buscando um desafio de futebol pra você...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
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
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text('Erro: $_errorMessage', textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchQuiz,
                          child: const Text('Tentar Novamente'),
                        )
                      ],
                    ),
                  )
                : _quizData == null
                    ? const Center(child: Text('Não foi possível gerar a pergunta.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_soccer, size: 64, color: AppTheme.primaryGreen),
                          const SizedBox(height: 24),
                          Text(
                            _quizData!['pergunta'] ?? 'Pergunta Indisponível',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            textAlign: TextAlign.center,
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
                          
                          if (_isAnswered) ...[
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _fetchQuiz,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Próxima Pergunta'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            )
                          ]
                        ],
                      ),
      ),
    );
  }
}
