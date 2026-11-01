import 'package:flutter/material.dart';
import '../core/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Como funciona?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF072917), Color(0xFF0e3d23)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_soccer, color: AppTheme.accentGold, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guia Oficial do Torcedor',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Conheça todas as formas de torcer, jogar e conquistar prêmios reais no Raspadinha do Gol.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            icon: Icons.monetization_on,
            iconColor: AppTheme.accentGold,
            title: 'O que são Moedas (Tokens)?',
            description:
                'Tokens (🟡) são a moeda do torcedor no app! Você ganha moedas respondendo aos Quizzes diários, acompanhando jogos ao vivo na Arquibancada ou acertando cartelas. Use suas moedas para adquirir mais raspadinhas e resgatar recompensas na Loja!',
          ),
          const SizedBox(height: 14),
          _buildHelpCard(
            icon: Icons.local_shipping,
            iconColor: Colors.teal,
            title: 'Prêmios Físicos & Entrega Oficial',
            description:
                'Você conquista Camisas Oficiais de clubes, tênis, bolas e produtos de parceiros como a Shopisa! Ao ser contemplado ou resgatar com tokens, você conclui seu pedido e o produto é enviado com código de rastreio para o seu endereço sem custo de frete.',
          ),
          const SizedBox(height: 14),
          _buildHelpCard(
            icon: Icons.sports_soccer,
            iconColor: Colors.indigo,
            title: 'Bolão do Gol (Galera & Bares)',
            description:
                'Crie ou participe de disputas de palpites de placar exato com amigos ou em bares parceiros! A apuração é 100% automatizada assim que o árbitro encerra o jogo, consagrando quem cravar o placar da partida.',
          ),
          const SizedBox(height: 14),
          _buildHelpCard(
            icon: Icons.card_giftcard,
            iconColor: Colors.amber.shade800,
            title: 'Raspadinha & Prêmios Oficiais',
            description:
                'A cada gol, intervalo ou vitória nas partidas ao vivo, você pode raspar cartelas. Ao encontrar 3 bolas de futebol douradas, você fatura na hora: Camisas Oficiais de clubes, produtos Shopisa, bolas oficiais ou lotes de tokens bônus!',
          ),
          const SizedBox(height: 14),
          _buildHelpCard(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Quiz de Futebol Diário',
            description:
                'Desafie seus conhecimentos sobre a história do futebol, copas do mundo e grandes clássicos. Acerte as 4 alternativas para acumular moedas bônus todos os dias!',
          ),
          const SizedBox(height: 14),
          _buildHelpCard(
            icon: Icons.handshake,
            iconColor: Colors.blue.shade700,
            title: 'Patrocinadores & Parceiros',
            description:
                'Nossas empresas parceiras apoiam o futebol e financiam os prêmios oficiais entregues aos torcedores vencedores. Visite os sites oficiais através dos banners na página inicial!',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
