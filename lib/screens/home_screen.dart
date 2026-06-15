import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../core/theme.dart';
import 'scratch_game_screen.dart';
import 'checkout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(matchStreamProvider);
    final freePlays = ref.watch(freePlaysProvider);
    return matchState.when(
        data: (match) {
          if (match.fixtureId == -1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 100,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Nenhum jogo rolando agora ⚽',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fique ligado! Assim que a próxima partida começar, suas raspadinhas grátis vão aparecer aqui.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${match.homeTeam} ${match.homeScore} x ${match.awayScore} ${match.awayTeam}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tempo: ${match.elapsed}\' - Status: ${match.status}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700]
                  ),
                ),
                const SizedBox(height: 48),
                
                if (match.isScratchUnlocked)
                  ElevatedButton(
                    onPressed: () {
                      if (freePlays > 0) {
                        ref.read(freePlaysProvider.notifier).state = freePlays - 1;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScratchGameScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    ),
                    child: Text(freePlays > 0 ? 'Jogar Agora (Grátis)!' : 'Desbloquear (R\$ 1,00)'),
                  )
                else
                  const Text(
                    'Aguardando próximo lance...',
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar partida: $err')),
      );
  }
}
