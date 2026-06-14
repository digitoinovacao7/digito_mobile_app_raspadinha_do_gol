import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'scratch_game_screen.dart';
import 'checkout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(matchStreamProvider);
    final freePlays = ref.watch(freePlaysProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raspadinha do Gol'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Saldo: R\$ ${user?.balance.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: matchState.when(
        data: (match) {
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
                    child: Text(freePlays > 0 ? 'Jogar Agora (Grátis)!' : 'Desbloquear (R\$ 0,99)'),
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
      ),
    );
  }
}
