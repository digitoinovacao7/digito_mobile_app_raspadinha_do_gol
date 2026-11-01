import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/league_info.dart';
import '../providers/game_provider.dart';

import 'matches_screen.dart';
import 'active_match_screen.dart';
import '../widgets/smart_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _featuredMatches = [];
  bool _isLoading = true;
  Map<String, dynamic>? _featuredPrize;
  static bool _hasShownPrizeModalThisSession = false;

  final GlobalKey _nativeAdKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAdData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadAdData() {
    _loadDashboardData();
  }

  List<LeagueInfo> _allLeagues = [];
  Set<int> _activeLeagueIdsToday = {};

  Future<void> _loadDashboardData() async {
    final service = ref.read(footballServiceProvider);

    final popularLeaguesFuture = service.getPopularLeagues();
    final activeLeaguesFuture = service.getActiveLeaguesForToday();
    final featuredMatchesFuture = service.getFeaturedMatchesForToday();

    final popularLeagues = await popularLeaguesFuture;
    final activeLeagues = await activeLeaguesFuture;
    final featuredMatches = await featuredMatchesFuture;

    final activeIds = activeLeagues.map((l) => l.id).toSet();

    // Buscar prêmio físico ativo cadastrado para a rodada
    Map<String, dynamic>? prizeData;
    try {
      final prizeSnap = await FirebaseFirestore.instance
          .collection('prizes')
          .where('active', isEqualTo: true)
          .limit(5)
          .get();

      if (prizeSnap.docs.isNotEmpty) {
        for (final doc in prizeSnap.docs) {
          final data = doc.data();
          final pLeagueId = data['leagueId'];
          if (pLeagueId != null && activeIds.contains(pLeagueId)) {
            prizeData = data;
            break;
          }
        }
        prizeData ??= prizeSnap.docs.first.data();
      }
    } catch (e) {
      debugPrint('Erro ao buscar prêmio ativo: $e');
    }

    if (mounted) {
      setState(() {
        _allLeagues = popularLeagues;
        _activeLeagueIdsToday = activeIds;
        _featuredMatches = featuredMatches;
        _featuredPrize = prizeData;
        _isLoading = false;
      });

      // Exibir modal de prêmio cadastrado logo na entrada da Home
      if (!_hasShownPrizeModalThisSession && prizeData != null) {
        _hasShownPrizeModalThisSession = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showPrizeModal(context, prizeData!);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadDashboardData();
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Banner de Destaque do Prêmio Cadastrado
                  _buildPrizeHighlightBanner(),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_featuredMatches.isNotEmpty) ...[
                    _buildSectionTitle('Jogos em Destaque', Icons.sports_soccer),
                    const SizedBox(height: 12),
                    _buildFeaturedMatchesCarousel(),
                    const SizedBox(height: 22),
                  ],

                  if (!_isLoading) ...[
                    _buildSectionTitle('Campeonatos', Icons.emoji_events),
                    const SizedBox(height: 12),
                    _allLeagues.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaguesGrid(),
                    const SizedBox(height: 28), // Espaçamento generoso para não colar
                  ],

                  // Placas de Patrocinadores & Parceiros Oficiais (agora no rodapé elegante, sem poluir os jogos)
                  _buildSponsorsSection(),
                  const SizedBox(height: 24),

                  if (!kIsWeb) ...[
                    _buildAdContainer(),
                    const SizedBox(height: 36),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMatchesCarousel() {
    return SizedBox(
      height: 215,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredMatches.length,
        itemBuilder: (context, index) {
          final match = _featuredMatches[index];
          return _buildFeaturedMatchCard(context, match);
        },
      ),
    );
  }

  Widget _buildFeaturedMatchCard(BuildContext context, dynamic match) {
    final homeTeam = match['teams']['home']['name'];
    final awayTeam = match['teams']['away']['name'];
    final homeLogo = match['teams']['home']['logo'];
    final awayLogo = match['teams']['away']['logo'];
    final status = match['fixture']['status']['short'];
    final leagueName = match['league']?['name']?.toString() ?? '';
    final isLive = ['1H', '2H', 'HT', 'ET', 'P'].contains(status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveMatchScreen(
              fixtureId: match['fixture']['id'],
              homeTeam: homeTeam,
              awayTeam: awayTeam,
              leagueName: leagueName.isEmpty ? null : leagueName,
              homeLogo: homeLogo?.isNotEmpty == true
                  ? homeLogo!
                  : 'https://media.api-sports.io/football/teams/${match['teams']['home']['id']}.png',
              awayLogo: awayLogo?.isNotEmpty == true
                  ? awayLogo!
                  : 'https://media.api-sports.io/football/teams/${match['teams']['away']['id']}.png',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive ? Colors.red.shade300 : Colors.grey.shade200,
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 14,
                        color: AppTheme.accentGold,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          leagueName.isEmpty ? 'Campeonato' : leagueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isLive ? 'AO VIVO' : status,
                        style: TextStyle(
                          color: isLive ? Colors.red : Colors.grey.shade700,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTeamColumn(
                    homeTeam,
                    homeLogo?.isNotEmpty == true
                        ? homeLogo!
                        : 'https://media.api-sports.io/football/teams/${match['teams']['home']['id']}.png',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isLive
                        ? '${match['goals']['home'] ?? 0} - ${match['goals']['away'] ?? 0}'
                        : status,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isLive ? 24 : 16,
                      color: isLive ? Colors.red : AppTheme.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTeamColumn(
                    awayTeam,
                    awayLogo?.isNotEmpty == true
                        ? awayLogo!
                        : 'https://media.api-sports.io/football/teams/${match['teams']['away']['id']}.png',
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Botão claro e direto para quem tá no sofá assistindo ao jogo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                      : [AppTheme.primaryGreen, const Color(0xFF007A33)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLive ? Icons.live_tv : Icons.sports_soccer,
                    color: AppTheme.accentGold,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLive ? 'AO VIVO • RASPAR AGORA' : 'VER JOGO & RASPAR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.4,
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

  Widget _buildTeamColumn(String name, String? logoUrl) {
    return Column(
      children: [
        SmartImage(
          logoUrl ?? '',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.shield, color: Colors.grey, size: 48),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaguesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 108,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _allLeagues.length,
      itemBuilder: (context, index) {
        final league = _allLeagues[index];
        final hasGamesToday = _activeLeagueIdsToday.contains(league.id);
        return _buildLeagueCard(
          context,
          title: league.name,
          id: league.id,
          season: league.season,
          logoUrl: league.logoUrl,
          hasGamesToday: hasGamesToday,
        );
      },
    );
  }

  Widget _buildLeagueCard(
    BuildContext context, {
    required String title,
    required int id,
    int? season,
    String? logoUrl,
    required bool hasGamesToday,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MatchesScreen(leagueId: id, leagueName: title, season: season),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasGamesToday ? AppTheme.primaryGreen : Colors.grey.shade200,
            width: hasGamesToday ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasGamesToday
                  ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  child: SmartImage(
                    (logoUrl != null && logoUrl.isNotEmpty)
                        ? logoUrl
                        : 'https://media.api-sports.io/football/leagues/$id.png',
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports_soccer, color: Colors.grey),
                  ),
                ),
                if (hasGamesToday)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HOJE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 11,
                fontWeight: hasGamesToday ? FontWeight.w900 : FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Nenhum campeonato disponível',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeHighlightBanner() {
    if (_featuredPrize == null) {
      return _buildFixedKnowledgeBar();
    }

    final name = _featuredPrize!['name'] ?? 'Super Prêmio Físico';
    final imageUrl = _featuredPrize!['image_url'] ?? _featuredPrize!['imageUrl'] ?? '';
    final leagueName = _featuredPrize!['leagueName'] ??
        _featuredPrize!['league_name'] ??
        _featuredPrize!['matchLabel'] ??
        'Brasileirão Série A';

    return InkWell(
      onTap: () => _showPrizeModal(context, _featuredPrize!),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF032211), Color(0xFF0A4020)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentGold, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SmartImage(
                    imageUrl,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.emoji_events,
                      color: AppTheme.accentGold,
                      size: 26,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentGold),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.accentGold,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRÊMIO DA RODADA 🏆',
                          style: TextStyle(
                            color: Color(0xFF072917),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          leagueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CONCORRER',
                    style: TextStyle(
                      color: Color(0xFF072917),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Color(0xFF072917),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPrizeActionTap(Map<String, dynamic> prize) {
    Navigator.of(context, rootNavigator: true).pop(); // Fechar o modal

    final fixtureId = prize['fixtureId'];
    final leagueId = prize['leagueId'];
    final leagueName =
        prize['leagueName'] ?? prize['league_name'] ?? 'Campeonato';

    if (fixtureId != null) {
      final fId = fixtureId is int
          ? fixtureId
          : int.tryParse(fixtureId.toString()) ?? 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveMatchScreen(
            fixtureId: fId,
            homeTeam: prize['homeTeam'] ?? 'Time 1',
            awayTeam: prize['awayTeam'] ?? 'Time 2',
            leagueName: leagueName,
          ),
        ),
      );
    } else if (leagueId != null) {
      final lId =
          leagueId is int ? leagueId : int.tryParse(leagueId.toString()) ?? 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchesScreen(
            leagueId: lId,
            leagueName: leagueName,
          ),
        ),
      );
    } else if (_featuredMatches.isNotEmpty) {
      final match = _featuredMatches.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveMatchScreen(
            fixtureId: match['fixture']['id'],
            homeTeam: match['teams']['home']['name'],
            awayTeam: match['teams']['away']['name'],
            leagueName: match['league']?['name']?.toString(),
            homeLogo: match['teams']['home']['logo'],
            awayLogo: match['teams']['away']['logo'],
          ),
        ),
      );
    }
  }

  void _showPrizeModal(BuildContext context, Map<String, dynamic> prize) {
    final name = prize['name'] ?? 'Super Prêmio da Rodada';
    final imageUrl = prize['image_url'] ?? prize['imageUrl'] ?? '';
    final leagueName = prize['leagueName'] ??
        prize['league_name'] ??
        prize['matchLabel'] ??
        'Brasileirão Série A';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF003800), Color(0xFF006828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentGold,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: AppTheme.accentGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRÊMIO DA RODADA ⚽',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Concorra assistindo ao jogo!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 22),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // Badge do Campeonato / Jogo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sports_soccer,
                              size: 14,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              leagueName,
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Prize Image with Frame
                      if (imageUrl.isNotEmpty)
                        Container(
                          height: 145,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: SmartImage(
                                imageUrl,
                                height: 140,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(
                                    Icons.card_giftcard,
                                    size: 64,
                                    color: AppTheme.accentGold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 54,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Prize Title
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Free / Physical info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 13,
                                  color: Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Prêmio Físico Entregue em Casa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Tome uma cerveja, acompanhe os lances e acerte o quiz para raspar e levar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _onPrizeActionTap(prize),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt,
                                  color: AppTheme.accentGold, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'QUERO CONCORRER AGORA',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Ver todos os jogos da rodada',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Seção de Patrocinadores em Faixa Elegante e Compacta
  Widget _buildSponsorsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sponsors')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>? ?? {};
          final dataB = b.data() as Map<String, dynamic>? ?? {};
          final orderA = dataA['order'] as int? ?? 999;
          final orderB = dataB['order'] as int? ?? 999;
          return orderA.compareTo(orderB);
        });

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'PARCEIROS OFICIAIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final logoUrl =
                        data['logoUrl'] ?? data['image_url'] ?? '';
                    final siteUrl =
                        data['siteUrl'] ?? data['site_url'] ?? '';

                    return InkWell(
                      onTap: () async {
                        if (siteUrl.isNotEmpty) {
                          final uri = Uri.tryParse(siteUrl);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (logoUrl.isNotEmpty) ...[
                              SmartImage(
                                logoUrl,
                                width: 28,
                                height: 28,
                                errorBuilder: (_, __, ___) =>
                                    _buildSponsorFallbackIcon(name),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new,
                                size: 11, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Container isolado da publicidade com respiro e identificação clara
  Widget _buildAdContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'PUBLICIDADE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        StandaloneNativeAd(key: _nativeAdKey),
      ],
    );
  }

  Widget _buildSponsorFallbackIcon(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryGreen,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedKnowledgeBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF072917),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Seu conhecimento pode te dar prêmios!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class StandaloneNativeAd extends StatefulWidget {
  const StandaloneNativeAd({super.key});

  @override
  State<StandaloneNativeAd> createState() => _StandaloneNativeAdState();
}

class _StandaloneNativeAdState extends State<StandaloneNativeAd> {
  NativeAd? _nativeAd;
  AdWidget? _adWidget;
  bool _isAdLoaded = false;
  bool _isNativeAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-9124633416063149/3728390385',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Standalone Native ad loaded.');
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _adWidget = AdWidget(ad: _nativeAd!);
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Standalone Ad failed to load: $error');
          if (mounted) {
            setState(() {
              _isNativeAdFailed = true;
            });
          }
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppTheme.primaryGreen,
        cornerRadius: 24.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.textDark,
          backgroundColor: AppTheme.accentGold,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isNativeAdFailed || !_isAdLoaded || _adWidget == null) {
      return const SizedBox(height: 24);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 90,
          maxHeight: 120,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _adWidget,
          ),
        ),
      ),
    );
  }
}

