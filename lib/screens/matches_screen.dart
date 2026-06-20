import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/game_provider.dart';
import '../core/theme.dart';
import 'active_match_screen.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final String leagueName;
  final int? season;

  const MatchesScreen({Key? key, required this.leagueId, required this.leagueName, this.season}) : super(key: key);

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  List<dynamic> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final service = ref.read(footballServiceProvider);
    final matches = await service.getMatchesForLeague(widget.leagueId, season: widget.season);
    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum jogo hoje.',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tente selecionar outro campeonato.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final fixtureId = match['fixture']?['id'];
                    final statusStr =
                        (match['fixture']?['status'] as Map?)?['short'] ?? 'NS';
                    final dateStr = match['fixture']?['date'];
                    final homeTeam =
                        (match['teams']?['home'] as Map?)?['name'] ?? 'Casa';
                    final awayTeam =
                        (match['teams']?['away'] as Map?)?['name'] ??
                            'Visitante';

                    final goalsHome = (match['goals'] as Map?)?['home'] ?? 0;
                    final goalsAway = (match['goals'] as Map?)?['away'] ?? 0;

                    DateTime matchDate;
                    try {
                      matchDate = DateTime.parse(dateStr ?? '').toLocal();
                    } catch (_) {
                      matchDate = DateTime.now();
                    }

                    final timeFormat = DateFormat('HH:mm').format(matchDate);

                    bool isLive =
                        ['1H', '2H', 'HT', 'ET', 'P', 'LIVE'].contains(statusStr);
                    bool isFinished =
                        ['FT', 'AET', 'PEN'].contains(statusStr);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          if (isFinished) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Esta partida já foi encerrada.')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ActiveMatchScreen(fixtureId: fixtureId, homeTeam: homeTeam, awayTeam: awayTeam)),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    timeFormat,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLive ? Colors.red : (isFinished ? Colors.grey : AppTheme.primaryGreen),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isLive ? 'AO VIVO' : (isFinished ? 'ENCERRADO' : 'AGENDADO'),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      homeTeam,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      isFinished || isLive ? '$goalsHome x $goalsAway' : 'vs',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      awayTeam,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
