import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/league_info.dart';
import '../providers/game_provider.dart';
import 'matches_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<LeagueInfo> _activeLeagues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    final service = ref.read(footballServiceProvider);
    final leagues = await service.getActiveLeaguesForToday();
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
          Text(
            'Escolha o Campeonato',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ligas com jogos ativos hoje.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            if (logoUrl != null)
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(4),
                child: Image.network(logoUrl, errorBuilder: (c,e,s) => const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen)),
              )
            else
              const Icon(Icons.sports_soccer, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
