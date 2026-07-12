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

class _ScratchGameScreenState extends ConsumerState<ScratchGameScreen> {
  final GlobalKey<ScratcherState> scratchKey = GlobalKey<ScratcherState>();
  late ConfettiController _confettiController;

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
      duration: const Duration(seconds: 3),
    );

    // Chama o backend imediatamente para gerar o grid seguro e debitar os tokens
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

        // Atualizar saldo de tokens do usuário forçando refresh (caso o Stream já não faça)
        // O Stream do authProvider geralmente cuida do Firebase,
        // mas vamos invalidar a authStateProvider para garantir atualização instantânea.
        ref.invalidate(appUserFutureProvider);
      }
    } on FirebaseFunctionsException catch (e) {
      // Se não tiver saldo ou ocorrer outro erro
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

    if (_winCount >= 3) {
      _confettiController.play();
      _showResultDialog(true);
    } else if (_winCount == 2) {
      _showResultDialog(true); // Premiação de tokens (na trave)
    } else {
      _showResultDialog(false); // Perdeu
    }
  }

  void _showResultDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          won ? (_winCount == 3 ? 'GOLAÇO!!!' : 'Na Trave!') : 'Fim de Jogo',
        ),
        content: Text(_resultMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fechar dialog
              Navigator.pop(context); // Voltar
            },
            child: const Text('Voltar'),
          ),
          if (_prizeLink != null && _prizeLink!.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(_prizeLink!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: const Text('Acessar Cupom'),
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
        appBar: AppBar(title: const Text('Raspadinha do Gol')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparando sua raspadinha...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Raspadinha do Gol')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: AppTheme.backgroundWhite,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 32;
                  final availableHeight = constraints.maxHeight - 188;
                  final scratchSize = min(
                    availableWidth,
                    availableHeight,
                  ).clamp(260.0, 430.0);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ScratchHeader(
                          subtitle: widget.useTokens
                              ? 'Custo: $_ticketCost tokens'
                              : 'Chance liberada pelo jogo marcado',
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Raspe a área cinza e encontre 3 bolas para ganhar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: _buildScratchCard(scratchSize),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isRevealed
                              ? 'Resultado revelado'
                              : 'Passe o dedo sobre a cartela para revelar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2, // Pra cima
            emissionFrequency: 0.1,
            numberOfParticles: 50,
            maxBlastForce: 100,
            minBlastForce: 80,
            gravity: 0.2,
            colors: const [
              Colors.green,
              Colors.yellow,
              Colors.blue,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScratchCard(double scratchSize) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Scratcher(
          key: scratchKey,
          brushSize: 42,
          threshold: 92,
          color: Colors.grey.shade400,
          onThreshold: _onScratchFinished,
          child: Container(
            width: scratchSize,
            height: scratchSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.primaryGreen, width: 4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final hasBall = _gridBalls[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: hasBall
                          ? AppTheme.accentGold.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: hasBall
                          ? Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.yellow.shade200,
                                    AppTheme.accentGold,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 40,
                                color: Colors.black87,
                              ),
                            )
                          : Icon(
                              Icons.close,
                              size: 46,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScratchHeader extends StatelessWidget {
  final String subtitle;

  const _ScratchHeader({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua raspadinha',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
