import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../core/theme.dart';

class ScratchGameScreen extends StatefulWidget {
  const ScratchGameScreen({Key? key}) : super(key: key);

  @override
  State<ScratchGameScreen> createState() => _ScratchGameScreenState();
}

class _ScratchGameScreenState extends State<ScratchGameScreen> {
  final GlobalKey<ScratcherState> scratchKey = GlobalKey<ScratcherState>();
  late ConfettiController _confettiController;
  bool _isRevealed = false;
  late List<bool> _gridBalls; // 9 items, se tiver 3 ou mais true, ganha
  int _winCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Gera o grid de forma aleatória
    // ~30% de chance de cada espaço ser uma bola
    final random = Random();
    _gridBalls = List.generate(9, (_) => random.nextDouble() < 0.35);
    _winCount = _gridBalls.where((b) => b).length;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onScratchFinished() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);

    if (_winCount >= 3) {
      _confettiController.play();
      _showResultDialog(true);
    } else {
      _showResultDialog(false);
    }
  }

  void _showResultDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(won ? 'GOOOOL! Você Ganhou!' : 'Não foi dessa vez...'),
        content: Text(won ? 'Parabéns, seu prêmio em PIX está garantido!' : 'Continue acompanhando a partida para mais chances.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fechar dialog
              Navigator.pop(context); // Voltar pra home
            },
            child: const Text('Voltar para o Jogo'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raspadinha do Gol')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ache 3 bolas e ganhe o PIX!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Scratcher(
                key: scratchKey,
                brushSize: 40,
                threshold: 50,
                color: Colors.grey[400]!,
                onThreshold: _onScratchFinished,
                // image: Image.asset('assets/sponsor_cover.png', fit: BoxFit.cover),
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.white,
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
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: hasBall 
                            ? const Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen)
                            : const Icon(Icons.close, size: 32, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text('Revelar Tudo Rapidão'),
                onPressed: () {
                  scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
                },
              )
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2, // Pra cima
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }
}
