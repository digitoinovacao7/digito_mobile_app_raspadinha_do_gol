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

    if (mounted) {
      setState(() {
        _allLeagues = popularLeagues;
        _activeLeagueIdsToday = activeIds;
        _featuredMatches = featuredMatches;
        _isLoading = false;
      });
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
                  _buildFixedKnowledgeBar(),
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
                    const SizedBox(height: 14),
                    _buildFeaturedMatchesCarousel(),
                    const SizedBox(height: 24),
                  ],

                  // Placas de Patrocinadores & Parceiros Oficiais (Entre jogos e campeonatos)
                  _buildSponsorsSection(),
                  const SizedBox(height: 20),

                  if (!_isLoading) ...[
                    _buildSectionTitle('Campeonatos', Icons.emoji_events),
                    const SizedBox(height: 14),
                    _allLeagues.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaguesGrid(),
                  ],

                  if (!kIsWeb) ...[
                    StandaloneNativeAd(key: _nativeAdKey),
                    const SizedBox(height: 40),
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
      height: 180,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.withValues(alpha: 0.1)
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
                          fontWeight: FontWeight.bold,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Patrocinadores & Parceiros Oficiais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 84,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? '';
                  final logoUrl = data['logoUrl'] ?? data['image_url'] ?? '';
                  final siteUrl = data['siteUrl'] ?? data['site_url'] ?? '';

                  return InkWell(
                    onTap: () async {
                      if (siteUrl.isNotEmpty) {
                        final uri = Uri.tryParse(siteUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: logoUrl.isNotEmpty
                                ? SmartImage(
                                    logoUrl,
                                    width: 52,
                                    height: 52,
                                    errorBuilder: (_, __, ___) => _buildSponsorFallbackIcon(name),
                                  )
                                : _buildSponsorFallbackIcon(name),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 9, color: Colors.amber.shade900),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Parceiro',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.open_in_new, size: 12, color: Colors.grey.shade400),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildSponsorFallbackIcon(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Container(
        width: 36,
        height: 36,
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
              fontSize: 16,
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
  const StandaloneNativeAd({Key? key}) : super(key: key);

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

