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
  const ScratchGameScreen({Key? key}) : super(key: key);

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Chama o backend imediatamente para gerar o grid seguro e debitar os tokens
    _fetchCost();
    _playScratchcard();
  }

  Future<void> _fetchCost() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('general').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('economy')) {
        setState(() {
          _ticketCost = doc.data()!['economy']['scratchcard_token_cost'] ?? 1000;
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
      final result = await functions.httpsCallable('playScratchcard').call();
      
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
        title: Text(won ? (_winCount == 3 ? 'GOLAÇO!!!' : 'Na Trave!') : 'Fim de Jogo'),
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
          )
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
              Text('Preparando sua raspadinha...')
            ],
          )
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Raspadinha do Gol')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ache 3 bolas para ganhar prêmios!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Scratcher(
                key: scratchKey,
                brushSize: 45,
                threshold: 60,
                color: Colors.grey[400]!,
                onThreshold: _onScratchFinished,
                image: Image.asset('assets/sponsor_cover.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[400])), // Fallback se imagem faltar
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.primaryGreen, width: 4),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        bool hasBall = _gridBalls[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Center(
                            child: hasBall 
                              ? Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [Colors.yellow.shade200, AppTheme.accentGold]),
                                    boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.sports_soccer, size: 40, color: Colors.black87),
                                )
                              : const Icon(Icons.close, size: 48, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text('Raspar Tudo Rápido'),
                onPressed: () {
                  scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
                },
              )
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2, // Pra cima
            emissionFrequency: 0.1,
            numberOfParticles: 50,
            maxBlastForce: 100,
            minBlastForce: 80,
            gravity: 0.2,
            colors: const [Colors.green, Colors.yellow, Colors.blue, Colors.white],
          ),
        ],
      ),
    );
  }
}
