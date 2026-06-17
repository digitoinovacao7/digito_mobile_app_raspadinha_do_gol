import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/league_info.dart';
import '../providers/game_provider.dart';
import 'matches_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<LeagueInfo> _activeLeagues = [];
  bool _isLoading = true;
  Map<String, dynamic>? _featuredPrize;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    final service = ref.read(footballServiceProvider);
    List<LeagueInfo> leagues = await service.getActiveLeaguesForToday();
    
    try {
      final prizesSnap = await FirebaseFirestore.instance.collection('prizes').where('active', isEqualTo: true).get();
      bool hasGlobalPrize = prizesSnap.docs.any((doc) => doc['scope'] == 'global');
      
      if (prizesSnap.docs.isNotEmpty) {
        _featuredPrize = prizesSnap.docs.first.data();
      } else {
        _featuredPrize = null;
      }

      if (!hasGlobalPrize) {
        final Set<int> validLeagueIds = prizesSnap.docs
            .where((doc) => doc.data().containsKey('leagueId') && doc['leagueId'] != null)
            .map((doc) => doc['leagueId'] as int)
            .toSet();
            
        leagues = leagues.where((l) => validLeagueIds.contains(l.id)).toList();
      }
    } catch (e) {
      print('Erro ao filtrar ligas por prêmios: $e');
      leagues = [];
    }

    if (mounted) {
      setState(() {
        _activeLeagues = leagues;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (_featuredPrize != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, Colors.green.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            _featuredPrize!['type'] == 'pix' ? 'SAQUE PIX 💸' : 'PRÊMIO FÍSICO 🎁',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _featuredPrize!['name'] ?? 'Prêmio Especial!',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _featuredPrize!['scope'] == 'global' 
                              ? 'Prêmio global liberado! Raspe em qualquer jogo.' 
                              : 'Prêmios exclusivos rolando nos campeonatos de hoje!',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(_featuredPrize!['type'] == 'pix' ? Icons.pix : Icons.card_giftcard, size: 64, color: Colors.white24),
                ],
              ),
            ),
          if (_featuredPrize != null) const SizedBox(height: 32),
          Text(
            'Escolha o Campeonato',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A lista de campeonatos é 100% dinâmica. Nós buscamos na API e só mostramos campeonatos que realmente têm alguma partida rolando no dia de hoje.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activeLeagues.isEmpty
                  ? const Center(child: Text('Nenhum jogo rolando hoje no mundo.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeLeagues.length,
                      itemBuilder: (context, index) {
                        final league = _activeLeagues[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildLeagueCard(
                            context,
                            title: league.name,
                            id: league.id,
                            season: league.season,
                            logoUrl: league.logoUrl,
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildLeagueCard(BuildContext context, {required String title, required int id, int? season, String? logoUrl}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchesScreen(leagueId: id, leagueName: title, season: season)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('AO VIVO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (logoUrl != null)
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.all(8),
                      child: Image.network(logoUrl, errorBuilder: (c,e,s) => const Icon(Icons.sports_soccer, color: Colors.grey)),
                    )
                  else
                    const Icon(Icons.sports_soccer, color: Colors.grey, size: 56),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Toque para ver os jogos', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
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
