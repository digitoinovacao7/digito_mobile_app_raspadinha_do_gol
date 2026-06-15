import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum jogo rolando agora ⚽',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fique ligado! Suas raspadinhas grátis vão aparecer aqui assim que a partida começar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: AppTheme.textDark, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conheça Nossos Parceiros',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPartnerCard(
                    context,
                    title: 'Plantão do Bar',
                    subtitle: 'EQUIPE EXTRA EM 30 MINUTOS.',
                    description: 'Conectamos os melhores estabelecimentos aos profissionais de elite em tempo real. Sem burocracia, com tecnologia e total transparência.',
                    icon: Icons.storefront,
                    url: 'https://plantaodobar.com.br/',
                    gradientColors: [Colors.orange.shade700, Colors.deepOrange],
                  ),
                  const SizedBox(height: 16),
                  _buildPartnerCard(
                    context,
                    title: 'Shortener.tec.br',
                    subtitle: 'Sua ferramenta de Marketing de Influência.',
                    description: 'Do Link na Bio ao Marketplace de Marcas. Capture leads, encurte URLs e ganhe dinheiro com parcerias exclusivas.',
                    icon: Icons.campaign_outlined,
                    url: 'https://shortener.tec.br/',
                    gradientColors: [Colors.blue.shade700, Colors.indigo],
                  ),
                  const SizedBox(height: 32),
                ],
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

  Widget _buildPartnerCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String url,
    required List<Color> gradientColors,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Could not launch $url: $e');
          }
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Acessar plataforma',
                        style: TextStyle(
                          color: gradientColors.last,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14, color: gradientColors.last),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
