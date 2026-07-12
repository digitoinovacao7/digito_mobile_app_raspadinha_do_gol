import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class ScratchGameScreen extends ConsumerStatefulWidget {
  final bool useTokens;
  const ScratchGameScreen({super.key, this.useTokens = false});

  @override
  ConsumerState<ScratchGameScreen> createState() => _ScratchGameScreenState();
}

class _ScratchGameScreenState extends ConsumerState<ScratchGameScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScratcherState> scratchKey = GlobalKey<ScratcherState>();
  late ConfettiController _confettiController;
  late AnimationController _pulseController;

  bool _isLoading = true;
  bool _isRevealed = false;

  List<bool> _gridBalls = List.generate(9, (_) => false);
  int _winCount = 0;
  String _resultMessage = "";
  String? _prizeLink;
  int _ticketCost = 1000;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchCost();
    _playScratchcard();
  }

  Future<void> _fetchCost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('economy')) {
        setState(() {
          _ticketCost =
              doc.data()!['economy']['scratchcard_token_cost'] ?? 1000;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playScratchcard() async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('playScratchcard').call({
        'useTokens': widget.useTokens,
      });

      final data = result.data;
      if (data['success'] == true) {
        setState(() {
          _gridBalls = List<bool>.from(data['gridBalls']);
          _winCount = data['winCount'];
          _resultMessage = data['message'];
          _prizeLink = data['prizeLink'] ?? data['prize_link'];
          _isLoading = false;
        });
        ref.invalidate(appUserFutureProvider);
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.message ?? 'Erro ao jogar.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro de conexão com o servidor.');
    }
  }

  void _onScratchFinished() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
    _pulseController.stop();

    if (_winCount >= 3) {
      _confettiController.play();
      Future.delayed(const Duration(milliseconds: 500), () => _showResultDialog(true));
    } else if (_winCount == 2) {
      Future.delayed(const Duration(milliseconds: 500), () => _showResultDialog(true));
    } else {
      Future.delayed(const Duration(milliseconds: 800), () => _showResultDialog(false));
    }
  }

  void _showResultDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: won ? AppTheme.accentGold : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              won ? (_winCount == 3 ? 'GOLAÇO!!!' : 'Na Trave!') : 'Que pena!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(
          _resultMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (_prizeLink != null && _prizeLink!.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(_prizeLink!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Acessar Prêmio', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ops!'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Raspadinha do Gol'),
          elevation: 0,
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Preparando sua sorte...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Raspadinha do Gol'),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background Gradient
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.15),
                  Colors.grey.shade100,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  _buildTicketHeader(),
                  const SizedBox(height: 24),
                  _buildScratchArea(),
                  const SizedBox(height: 32),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 80,
            minBlastForce: 40,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.yellow,
              Colors.amber,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              size: 48,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TICKET DA SORTE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.useTokens
                ? 'Você gastou $_ticketCost tokens'
                : 'Ticket especial do jogo marcado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final scratchSize = availableWidth.clamp(280.0, 380.0);

        return Container(
          width: scratchSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Decorative ticket edge
              Container(
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Scratcher(
                    key: scratchKey,
                    brushSize: 48,
                    threshold: 70,
                    color: const Color(0xFFC5A059), // Premium Gold Cover
                    onThreshold: _onScratchFinished,
                    child: Container(
                      width: scratchSize - 44, // Account for padding and border
                      height: scratchSize - 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final hasBall = _gridBalls[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: hasBall
                                  ? AppTheme.accentGold.withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasBall
                                    ? AppTheme.accentGold.withValues(alpha: 0.5)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: hasBall
                                  ? _buildWinningSymbol()
                                  : _buildLosingSymbol(),
                            ),
                          );
                        },
                      ),
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

  Widget _buildWinningSymbol() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.shade100,
                  AppTheme.accentGold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 34,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLosingSymbol() {
    return Icon(
      Icons.close_rounded,
      size: 38,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildInstructions() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRevealed ? 1.0 : 1.0 + (_pulseController.value * 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _isRevealed ? Colors.white : AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _isRevealed ? Colors.grey.shade200 : AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isRevealed ? Icons.check_circle : Icons.touch_app,
                  color: _isRevealed ? Colors.grey.shade500 : AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRevealed
                      ? 'Resultado revelado!'
                      : 'Raspe a cartela para descobrir',
                  style: TextStyle(
                    color: _isRevealed ? Colors.grey.shade600 : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
