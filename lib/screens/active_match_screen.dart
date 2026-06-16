import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
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
                    child: Text(freePlays > 0 ? 'Resgatar Recompensa!' : 'Desbloquear Raspadinha'),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}
