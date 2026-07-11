import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_quiz_service.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class QuizStandaloneScreen extends ConsumerStatefulWidget {
  const QuizStandaloneScreen({super.key});

  @override
  ConsumerState<QuizStandaloneScreen> createState() =>
      _QuizStandaloneScreenState();
}

class _QuizStandaloneScreenState extends ConsumerState<QuizStandaloneScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _quizData;
  String? _errorMessage;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _isSubmitting = false;
  bool? _wasCorrect;
  int _earnedTokens = 0;

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
      _isSubmitting = false;
      _wasCorrect = null;
      _earnedTokens = 0;
    });

    try {
      final aiService = ref.read(aiQuizServiceProvider);
      // Passa times genéricos para a IA criar um quiz de futebol geral
      final quiz = await aiService.generateQuiz(
        'Futebol Brasileiro',
        'Seleção Brasileira',
      );
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
    if (_isAnswered || _isSubmitting || _quizData == null) return;

    setState(() {
      _selectedOption = index;
      _isSubmitting = true;
    });

    try {
      final result = await ref
          .read(aiQuizServiceProvider)
          .answerQuiz(
            quizId: _quizData!['quizId'] as String,
            answerId: index,
            fixtureId: 'quiz_extra',
            matchName: 'Quiz Extra',
          );

      final isCorrect = result['isCorrect'] == true;
      final earnedTokens = (result['earnedTokens'] as num?)?.toInt() ?? 0;
      final user = ref.read(currentUserProvider);

      if (isCorrect && user != null && earnedTokens > 0) {
        ref.read(currentUserProvider.notifier).state = user.copyWith(
          tokens: user.tokens + earnedTokens,
        );
      }

      if (!mounted) return;
      setState(() {
        _isAnswered = true;
        _isSubmitting = false;
        _wasCorrect = isCorrect;
        _earnedTokens = earnedTokens;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCorrect
                ? 'Resposta certa! Você ganhou $earnedTokens tokens.'
                : 'Não foi dessa vez. Sua resposta foi registrada.',
          ),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _quizData == null
            ? const Center(child: Text('Não foi possível gerar a pergunta.'))
            : _buildQuizContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 24),
          Text(
            'Buscando um desafio de futebol pra você...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final message = _errorMessage!.replaceAll('Exception: ', '');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quiz indisponível',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            if (!message.toLowerCase().contains('limite')) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final options = List<String>.from(_quizData!['opcoes'] as List);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Text(
                    'Quiz Extra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _quizData!['pergunta'] ?? 'Pergunta Indisponível',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isAnswered
                      ? (_wasCorrect == true
                            ? 'Você acertou e ganhou $_earnedTokens tokens.'
                            : 'Resposta enviada. Tente a próxima rodada.')
                      : 'Escolha uma alternativa para validar no placar oficial.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...List.generate(options.length, (index) {
            return _buildOptionButton(index, options[index]);
          }),
          if (_isAnswered) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Próxima Pergunta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String text) {
    final isSelected = _selectedOption == index;

    Color btnColor = Colors.white;
    Color textColor = AppTheme.textDark;
    Color borderColor = Colors.grey.shade200;
    IconData? trailingIcon;

    if (_isAnswered && isSelected) {
      if (_wasCorrect == true) {
        btnColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        borderColor = Colors.green;
        trailingIcon = Icons.check_circle;
      } else {
        btnColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        borderColor = Colors.red;
        trailingIcon = Icons.cancel;
      }
    } else if (_isSubmitting && isSelected) {
      btnColor = AppTheme.accentGold.withValues(alpha: 0.18);
      borderColor = AppTheme.accentGold;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: textColor,
          disabledBackgroundColor: btnColor,
          disabledForegroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1.4),
          ),
          elevation: 0,
        ),
        onPressed: (_isAnswered || _isSubmitting)
            ? null
            : () => _submitAnswer(index),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_isSubmitting && isSelected)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (trailingIcon != null)
              Icon(trailingIcon, color: textColor),
          ],
        ),
      ),
    );
  }
}
